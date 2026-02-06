# chat

## Extract drawings from PDFs

If you drop multiple PDF files into this repo, you can extract drawings as images
using the script below. The **pages** mode renders each page to a PNG, which
captures vector drawings and diagrams. The **embedded** mode only extracts
embedded bitmap images (it may miss vector content).

### Install

```bash
python3 -m pip install -r requirements.txt
```

### Usage

Render each page as an image (recommended for drawings):

```bash
python3 extract_pdf_drawings.py --input . --output extracted --mode pages
```

Extract both page renders and embedded images:

```bash
python3 extract_pdf_drawings.py --input . --output extracted --mode both --dpi 300
```

### Output structure

```
extracted/
  <pdf-name>/
    pages/
      page-001.png
      page-002.png
    embedded/
      page-001_img-001.png
      page-001_img-002.jpg
```