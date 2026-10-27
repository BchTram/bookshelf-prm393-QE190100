"""Read every DOCX paragraph and table cell in body order, without Word."""
import sys
from pathlib import Path
from zipfile import ZipFile
from xml.etree import ElementTree as ET

NS = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}


def text(element):
    if element.tag.endswith('}tc'):
        return '<br>'.join(text(p) for p in element.findall('.//w:p', NS))
    return ''.join(t.text or '' for t in element.findall('.//w:t', NS))


def extract(source):
    with ZipFile(source) as archive:
        body = ET.fromstring(archive.read('word/document.xml')).find('w:body', NS)
    output = []
    for node in body:
        if node.tag.endswith('}p'):
            output.append(text(node))
        elif node.tag.endswith('}tbl'):
            rows = node.findall('w:tr', NS)
            for index, row in enumerate(rows):
                cells = [text(cell).replace('|', '\\|') for cell in row.findall('w:tc', NS)]
                output.append('| ' + ' | '.join(cells) + ' |')
                if index == 0:
                    output.append('| ' + ' | '.join('---' for _ in cells) + ' |')
            output.append('')
    return '\n'.join(output)


if __name__ == '__main__':
    source = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('../BookShelf_Codex_Starter/BookShelf_Requirements.docx')
    destination = Path('docs/requirements_extracted.md')
    destination.write_text(extract(source), encoding='utf-8')
    print(f'Complete text and tables extracted to {destination}')
