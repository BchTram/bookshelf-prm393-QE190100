param([Parameter(Mandatory=$true)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$StudentCode)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$outputDirectory = Join-Path $projectRoot 'submission'
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
$archivePath = Join-Path $outputDirectory "$StudentCode.zip"
if (Test-Path -LiteralPath $archivePath) { throw "Archive already exists: $archivePath. Rename it before packaging again." }
if ((Get-Content -Raw (Join-Path $projectRoot 'lib/firebase_options.dart')) -match 'Bootstrap only') {
    throw 'Run flutterfire configure with your real Firebase project before creating the submission ZIP.'
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression
$archive = [System.IO.Compression.ZipFile]::Open($archivePath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    $allowed = @('pubspec.yaml','pubspec.lock','analysis_options.yaml','README.md','.gitignore','.metadata','firestore.rules','firestore.indexes.json','firebase.json','.firebaserc','package.json','package-lock.json','lib','android','test','integration_test','test_driver','rules_test','docs','scripts','assets')
    foreach ($entry in $allowed) {
        $entryPath = Join-Path $projectRoot $entry
        if (!(Test-Path -LiteralPath $entryPath)) { continue }
        $items = if (Test-Path -LiteralPath $entryPath -PathType Container) { Get-ChildItem -LiteralPath $entryPath -File -Recurse -Force } else { Get-Item -LiteralPath $entryPath }
        foreach ($item in $items) {
            $relativePath = $item.FullName.Substring($projectRoot.Length + 1).Replace('\','/')
            if ($relativePath -match '(^|/)(build|\.dart_tool|\.git|\.gradle|\.cxx|node_modules)/|(^|/)(local.properties|key.properties|GeneratedPluginRegistrant.java)$|service.account|adminsdk|\.(jks|keystore|log|iml)$') { continue }
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $item.FullName, $relativePath) | Out-Null
        }
    }
} finally { $archive.Dispose() }
$check = [System.IO.Compression.ZipFile]::OpenRead($archivePath)
try {
    foreach ($required in @('pubspec.yaml','pubspec.lock','lib/main.dart','firestore.rules','android/app/build.gradle.kts')) {
        if ($null -eq $check.GetEntry($required)) { throw "Missing required entry: $required" }
    }
} finally { $check.Dispose() }
Write-Output "Source archive ready: $archivePath"
