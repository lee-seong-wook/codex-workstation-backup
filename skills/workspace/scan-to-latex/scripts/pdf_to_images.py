#!/usr/bin/env python3
"""
PDF를 페이지별 이미지로 변환하는 스크립트.

사용법:
    python pdf_to_images.py <input.pdf> <output_dir> [--dpi 300] [--format png]

의존성:
    pip install PyMuPDF
"""

import argparse
import sys
from pathlib import Path

try:
    import fitz  # PyMuPDF
except ImportError:
    print("PyMuPDF가 필요합니다: pip install PyMuPDF")
    sys.exit(1)


def pdf_to_images(pdf_path: str, output_dir: str, dpi: int = 300, fmt: str = "png"):
    pdf_path = Path(pdf_path)
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    if not pdf_path.exists():
        print(f"오류: 파일을 찾을 수 없습니다: {pdf_path}")
        sys.exit(1)

    doc = fitz.open(str(pdf_path))
    total_pages = len(doc)
    print(f"총 {total_pages}페이지 변환 시작 (DPI: {dpi})")

    zoom = dpi / 72
    matrix = fitz.Matrix(zoom, zoom)
    output_files = []

    for page_num in range(total_pages):
        page = doc[page_num]
        pix = page.get_pixmap(matrix=matrix)
        filename = f"page_{page_num + 1:03d}.{fmt}"
        output_path = output_dir / filename
        pix.save(str(output_path))
        output_files.append(str(output_path))
        print(f"  [{page_num + 1}/{total_pages}] {filename}")

    doc.close()
    print(f"\n완료: {len(output_files)}개 이미지 생성 → {output_dir}")
    return output_files


def main():
    parser = argparse.ArgumentParser(description="PDF를 페이지별 이미지로 변환")
    parser.add_argument("input_pdf", help="입력 PDF 파일 경로")
    parser.add_argument("output_dir", help="출력 이미지 저장 디렉토리")
    parser.add_argument("--dpi", type=int, default=300, help="해상도 (기본: 300)")
    parser.add_argument("--format", choices=["png", "jpg"], default="png")
    args = parser.parse_args()
    pdf_to_images(args.input_pdf, args.output_dir, args.dpi, args.format)


if __name__ == "__main__":
    main()
