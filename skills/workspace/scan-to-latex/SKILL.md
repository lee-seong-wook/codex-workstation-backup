---
name: scan-to-latex
description: >
  Convert scanned book pages, PDFs, or images into faithful LaTeX source (.tex).
  Use when the user asks for scan-to-LaTeX, OCR-to-TeX conversion, reconstruction
  of scanned textbook pages, math formulas, tables, figures, captions, or a
  compilable LaTeX project matching the source scan. Triggers include "scan to
  latex", "OCR to tex", "scanned book to latex", "PDF page to LaTeX",
  "image to formula", "scanned page to tex", "book page to LaTeX",
  "math scan to TeX", "formula OCR", "스캔을 LaTeX로", "책을 tex로 변환",
  "스캔 PDF를 LaTeX로", "스캔한 책 변환", "페이지 이미지를 tex로",
  "이미지를 수식으로", and "책 페이지 tex 변환".
---

# Scan-to-LaTeX: 스캔 책 페이지 → LaTeX 변환

## 개요

스캔된 기술서/학술서의 각 페이지를 읽어 LaTeX 소스(.tex)로 충실하게 재구성하는 스킬이다.
수학 수식, 알고리즘, 표, 그림 캡션, 참고문헌 등 기술 서적의 모든 요소를 처리한다.

## 워크플로우 선택

> 환경에 따라 최적의 방법을 선택한다.

| 방법 | 장점 | 단점 | 적합한 경우 |
|------|------|------|------------|
| **AI 비전 직접 읽기** | 수식 인식 우수, 컨텍스트 이해 | 느림, 토큰 사용량 큼 | 수식 밀도 높은 학술서 |
| **Mathpix API** | 수식 인식 최고 수준 | 유료, API 키 필요 | 대량 변환, 상업적 사용 |
| **Tesseract + 후처리** | 무료, 오프라인 | 수식 인식 약함 | 텍스트 위주 문서 |
| **Nougat (Meta)** | 학술 PDF 특화, 무료 | GPU 필요, 영어 중심 | 학술 논문 PDF |

### 방법별 설정

**AI 비전 (기본)**:
- 이미지를 직접 읽어 LaTeX로 변환
- 수식이 많은 페이지에 가장 적합

**Mathpix API**:
```bash
pip install mathpix-markdown-it
# API 키 설정
export MATHPIX_APP_ID="your_app_id"
export MATHPIX_APP_KEY="your_app_key"
```

**Tesseract OCR + 후처리**:
```bash
# 설치
pip install pytesseract
# Windows: https://github.com/UB-Mannheim/tesseract/wiki
# Linux: sudo apt install tesseract-ocr

# 기본 OCR 후 AI가 수식을 LaTeX로 변환
# Optional helper: create a project-local OCR script only if the workflow needs one.
# Otherwise use AI vision directly or run Tesseract/Mathpix/Nougat manually.
```

**Nougat (학술 PDF 전용)**:
```bash
pip install nougat-ocr
nougat <input.pdf> -o <output_dir>  # Mathpix Markdown 형식 출력
```

## Phase 1: 입력 분석

1. **폴더 탐색**: 사용자가 지정한 폴더 스캔, 파일 목록 파악
   - 지원 형식: `.pdf`, `.jpg`, `.jpeg`, `.png`, `.tiff`, `.bmp`
   - 파일명 숫자 순서로 정렬 (페이지 순서 보장)

2. **입력 유형 판별**:
   - **다중 페이지 PDF**: `scripts/pdf_to_images.py`로 개별 이미지 추출
   - **개별 이미지**: 그대로 사용
   - **개별 PDF**: 각각 이미지로 변환

3. **샘플 페이지 분석** (첫 2-3페이지):
   - 레이아웃: 단일 vs 이중 컬럼
   - 주요 요소: 수식 밀도, 표/그림 빈도
   - 이 정보로 LaTeX 프리앰블 결정

## Phase 2: LaTeX 프리앰블 설정

`references/preamble_template.tex`를 기본으로, 책 특성에 맞게 조정:
- **문서 클래스**: `book` 또는 `article`
- **필수 패키지**: `amsmath`, `amssymb`, `amsthm`, `graphicx`, `hyperref`
- **한글 지원**: `kotex` 또는 `xeCJK`
- **알고리즘**: `algorithm2e` 또는 `algorithmic`

## Phase 3: 페이지별 변환

각 페이지에 대해:

1. **이미지 읽기** → **구조 분석** → **LaTeX 생성**

2. **LaTeX 생성 규칙**:
   - **수식** (가장 중요): 인라인 vs 디스플레이 구분, `equation`/`align` 적절히 사용
   - **표**: `tabular` + `\toprule`/`\midrule`/`\bottomrule`
   - **그림**: 플레이스홀더 `\fbox{}` 사용 (원본 재현 불가)
   - **텍스트**: 특수문자 이스케이프, 강조 정확히 변환

## Phase 4: 통합 및 검증

1. 메인 `.tex` 파일 생성 (`\input{}`으로 결합)
2. 컴파일 테스트: `pdflatex -interaction=nonstopmode output.tex`
3. 오류 수정 (최대 3회 반복)

## 품질 기준

1. **텍스트 정확도**: 오탈자 없이 원문 그대로
2. **수식 정확도**: 모든 기호, 첨자, 연산자 정확 (가장 중요)
3. **구조 충실도**: 섹션 계층, 번호 매기기 일치
4. **컴파일 성공**: 에러 없이 PDF 생성

## 주의사항

- 한 번에 5-10페이지씩 배치 처리
- 수식 복잡한 페이지는 특히 꼼꼼하게 확인
- 그림은 플레이스홀더로 대체
- 원본 저작권 존중 — 개인 학습/참고 목적으로만 사용

## 참고 파일

- `references/preamble_template.tex` — 기본 LaTeX 프리앰블 템플릿
- `references/math_symbols.md` — 자주 쓰이는 수학 기호 LaTeX 매핑
- `scripts/pdf_to_images.py` — PDF → 페이지별 이미지 변환
