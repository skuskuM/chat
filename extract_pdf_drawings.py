#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path
import re
import sys

try:
    import fitz  # PyMuPDF
except ImportError as exc:  # pragma: no cover - runtime guard
    sys.stderr.write(
        "PyMuPDF is not installed. Run: python3 -m pip install -r requirements.txt\n"
    )
    raise SystemExit(1) from exc


SAFE_CHARS_RE = re.compile(r"[^A-Za-z0-9._-]+")


def safe_name(value: str) -> str:
    cleaned = SAFE_CHARS_RE.sub("_", value.strip())
    return cleaned or "file"


def collect_pdfs(input_path: Path, output_dir: Path) -> list[Path]:
    if input_path.is_file():
        return [input_path] if input_path.suffix.lower() == ".pdf" else []

    output_dir_resolved = output_dir.resolve()
    pdfs: list[Path] = []
    for path in input_path.rglob("*.pdf"):
        try:
            if output_dir_resolved in path.resolve().parents:
                continue
        except OSError:
            continue
        pdfs.append(path)
    return sorted(pdfs)


def render_pages(doc: "fitz.Document", out_dir: Path, dpi: int) -> int:
    out_dir.mkdir(parents=True, exist_ok=True)
    count = 0
    for page_index in range(doc.page_count):
        page = doc.load_page(page_index)
        pix = page.get_pixmap(dpi=dpi)
        out_path = out_dir / f"page-{page_index + 1:03d}.png"
        pix.save(out_path.as_posix())
        count += 1
    return count


def extract_embedded_images(doc: "fitz.Document", out_dir: Path) -> int:
    out_dir.mkdir(parents=True, exist_ok=True)
    count = 0
    for page_index in range(doc.page_count):
        page = doc.load_page(page_index)
        image_list = page.get_images(full=True)
        for img_index, img in enumerate(image_list, start=1):
            xref = img[0]
            base_image = doc.extract_image(xref)
            image_bytes = base_image["image"]
            ext = base_image.get("ext", "png")
            out_path = out_dir / f"page-{page_index + 1:03d}_img-{img_index:03d}.{ext}"
            out_path.write_bytes(image_bytes)
            count += 1
    return count


def process_pdf(
    pdf_path: Path, output_root: Path, mode: str, dpi: int
) -> tuple[int, int]:
    pdf_out_root = output_root / safe_name(pdf_path.stem)
    pages_count = 0
    images_count = 0

    doc = fitz.open(pdf_path)
    try:
        if mode in {"pages", "both"}:
            pages_dir = pdf_out_root / "pages"
            pages_count = render_pages(doc, pages_dir, dpi)
        if mode in {"embedded", "both"}:
            images_dir = pdf_out_root / "embedded"
            images_count = extract_embedded_images(doc, images_dir)
    finally:
        doc.close()

    return pages_count, images_count


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Extract drawings from PDF files as images. "
            "Use 'pages' to render each page (captures vector drawings), "
            "'embedded' to extract embedded images only, or 'both'."
        )
    )
    parser.add_argument(
        "-i",
        "--input",
        default=".",
        help="PDF file or directory to scan (default: current directory).",
    )
    parser.add_argument(
        "-o",
        "--output",
        default="output_images",
        help="Output directory for extracted images.",
    )
    parser.add_argument(
        "--mode",
        choices=("pages", "embedded", "both"),
        default="pages",
        help="Extraction mode (default: pages).",
    )
    parser.add_argument(
        "--dpi",
        type=int,
        default=200,
        help="DPI for page rendering (only for pages/both).",
    )
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if args.dpi <= 0:
        parser.error("--dpi must be a positive integer.")

    input_path = Path(args.input).expanduser()
    output_root = Path(args.output).expanduser()
    pdfs = collect_pdfs(input_path, output_root)

    if not pdfs:
        print(f"No PDF files found in: {input_path}")
        return 0

    output_root.mkdir(parents=True, exist_ok=True)

    total_pages = 0
    total_images = 0
    errors = 0

    for pdf_path in pdfs:
        try:
            pages_count, images_count = process_pdf(
                pdf_path, output_root, args.mode, args.dpi
            )
        except Exception as exc:  # keep running on other PDFs
            errors += 1
            print(f"[ERROR] {pdf_path}: {exc}")
            continue

        total_pages += pages_count
        total_images += images_count
        print(
            f"[OK] {pdf_path} -> pages: {pages_count}, embedded: {images_count}"
        )

    print(
        f"Done. PDFs: {len(pdfs)}, pages rendered: {total_pages}, "
        f"embedded images: {total_images}, errors: {errors}"
    )
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
