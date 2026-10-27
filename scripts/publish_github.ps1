param([string]$RepositoryName = 'bookshelf-prm393-QE190100')
$ErrorActionPreference = 'Stop'
$env:DEBUG = ''
$projectRoot = Split-Path $PSScriptRoot -Parent
$gh = Join-Path $projectRoot '.tools/github-cli/unpacked/bin/gh.exe'
$archive = Join-Path $projectRoot 'submission/QE190100.zip'
$apk = Join-Path $projectRoot 'build/app/outputs/flutter-apk/app-release.apk'
function CheckExit([string]$step) { if ($LASTEXITCODE -ne 0) { throw "Failed: $step" } }
& $gh auth status
CheckExit 'GitHub authentication'
$account = (& $gh api user | ConvertFrom-Json)
CheckExit 'GitHub account lookup'
$repository = "$($account.login)/$RepositoryName"
$stage = Join-Path $projectRoot '.private/github_stage'
if (Test-Path -LiteralPath $stage) { throw 'Staging directory already exists. Inspect it before retrying.' }
if (!(Test-Path -LiteralPath $archive) -or !(Test-Path -LiteralPath $apk)) { throw 'Source ZIP and release APK are required.' }
Expand-Archive -LiteralPath $archive -DestinationPath $stage
Push-Location $stage
try {
    git init -b main
    CheckExit 'git init'
    git config user.name 'Pham Ngo Bich Tram'
    git config user.email "$($account.id)+$($account.login)@users.noreply.github.com"
    git add .
    CheckExit 'git add'
    git commit -m 'Complete BookShelf PRM393 Android project'
    CheckExit 'git commit'
    & $gh repo create $repository --public --source . --description 'BookShelf PRM393 - QE190100 - Pham Ngo Bich Tram'
    CheckExit 'public repository creation'
    git config credential.https://github.com.helper "!$($gh.Replace('\','/')) auth git-credential"
    CheckExit 'local Git authentication setup'
    git push -u origin main
    CheckExit 'source push'
    & $gh release create v1.0 $apk --repo $repository --title 'BookShelf v1.0' --notes 'Android release APK for PRM393. Source matches the submitted QE190100.zip.'
    CheckExit 'APK release upload'
    $release = (& $gh release view v1.0 --repo $repository --json assets | ConvertFrom-Json)
    CheckExit 'release verification'
    $asset = $release.assets | Where-Object name -eq 'app-release.apk'
    if (!$asset -or $asset.size -ne (Get-Item -LiteralPath $apk).Length) { throw 'Uploaded APK verification failed.' }
    @{ repository_url = "https://github.com/$repository"; apk_url = $asset.url } |
        ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $projectRoot '.private/submission_metadata.json')
    Write-Output "Published: https://github.com/$repository"
} finally { Pop-Location }
