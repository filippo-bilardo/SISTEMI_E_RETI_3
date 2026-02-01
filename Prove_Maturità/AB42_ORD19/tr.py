import sys
from pathlib import Path
import PyPDF2
pdf_path = Path('AB42_ORD19.pdf')
reader = PyPDF2.PdfReader(str(pdf_path))
texts=[]
for i,p in enumerate(reader.pages, start=1):
    t=p.extract_text() or ''
    texts.append(f"\n\n---\n\n## Pagina {i}\n\n"+t.strip()+"\n")
print('PAGES', len(reader.pages))
print('CHARS', sum(len(x) for x in texts))
print(texts[0][:1000])

from pathlib import Path
import PyPDF2
pdf_path = Path('AB42_ORD19.pdf')
reader = PyPDF2.PdfReader(str(pdf_path))
out = []
# Intestazione
out.append('# AB42 - ESAME DI STATO (Sessione ordinaria 2019)')
out.append('## Seconda prova scritta')
out.append('')
out.append('> Trascrizione da PDF in formato Markdown (estrazione testo tramite PyPDF2).')

for i, page in enumerate(reader.pages, start=1):
    text = (page.extract_text() or '').strip()
    out.append('\n---\n')
    out.append(f'## Pagina {i}')
    out.append('')
    # Normalizza spazi e righe (conservativo)
    lines = [ln.rstrip() for ln in text.splitlines()]
    # rimuove righe vuote ripetute
    cleaned=[]
    prev_empty=False
    for ln in lines:
        ln = ln.replace('\u00a0',' ').strip()
        if not ln:
            if not prev_empty:
                cleaned.append('')
            prev_empty=True
        else:
            cleaned.append(ln)
            prev_empty=False
    out.extend(cleaned)
    out.append('')

md = '\n'.join(out).strip() + '\n'
Path('AB42_ORD19.md').write_text(md, encoding='utf-8')
print('WROTE', Path('AB42_ORD19.md').resolve())
print('LEN', len(md))
