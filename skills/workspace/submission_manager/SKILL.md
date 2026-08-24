---
name: submission-manager
description: >
  Handles conference and journal paper submission logistics. Use when preparing
  a paper for submission, checking anonymization for double-blind review, creating
  submission zip packages, verifying page/figure limits, preparing camera-ready
  versions, or preparing arXiv preprints. Triggers include "submit", "submission
  deadline", "anonymize", "blind review", "zip the paper", "prepare for upload",
  "page limit", "camera ready", "arXiv upload", "final check before submitting",
  "제출", "제출 마감", "익명화", "블라인드 리뷰", "카메라 레디", "arXiv 업로드",
  "제출 준비", "최종 점검", and "논문 패키지".
---

# submission-manager Skill

## Description

This skill takes the stress out of the final submission hour. It acts as a strict checklist enforcer and file manager. It ensures all headers are correct, author names are removed for double-blind review, and file sizes meet conference limits.

## When to Use

- 제출 마감 직전 체크리스트 검증이 필요할 때
- 블라인드 제출용 익명화(저자/감사의 글/메타데이터 제거)를 점검할 때
- 제출용 zip 패키지 생성 및 불필요 파일 제외가 필요할 때
- 페이지 제한, figure 참조, citation 깨짐 여부를 최종 점검할 때
- Overleaf 프로젝트에서 제출 패키지를 준비할 때

## Output Format

1. `Readiness Checklist`: 제출 요건별 PASS/FAIL 표
2. `Anonymization Findings`: 익명화 위반 가능 지점과 수정안
3. `Packaging Plan`: 포함/제외 파일 및 산출물 경로
4. `Final Blocking Issues`: 제출 차단 이슈와 즉시 조치 항목

## Submission Modes

| Mode | Anonymization | Acknowledgments | Author List |
|------|--------------|-----------------|-------------|
| **Double-blind** | Remove all author info | Remove | Hidden |
| **Camera-ready** | Restore author info | Add back | Full |
| **arXiv preprint** | Restore (or add) | Add/expand | Full |

Ask the user which mode if not stated.

## Key Capabilities

### 1. Double-Blind Anonymization

- **Scan**: Check `.tex` for `\author{}`, `\thanks{}`, `\affiliation{}`, acknowledgments, self-citations ("our prior work"), GitHub links
- **Redaction**: Replace with `[Anonymized]` or `Anonymous et al.`
- **PDF Metadata**: Warn if compiled PDF has author names (`pdfinfo`)

### 2. Package Builder

- **Clean Zip**: Creates submission-ready zip in `_submission/` (never modify originals)
- **Exclusion**: Remove `.git`, `.vscode`, `wandb/`, `__pycache__/`, `*.log`, `*.aux`, large data files
- **Flattening**: Can flatten LaTeX projects (all images in root) if required
- **Source inclusion**: Many venues require complete LaTeX source, not just PDF

### 3. Pre-flight Checklist

- [ ] Page limit respected (count pages in compiled PDF)
- [ ] No broken `?` references (`LaTeX Warning: Reference` in `.log`)
- [ ] No overfull `\hbox` warnings spilling into margins
- [ ] All figures referenced in text exist as files
- [ ] Figure resolution ≥ 300 DPI (`identify -verbose fig.png | grep Resolution`)
- [ ] No `AUTHOR unknown` or missing venue fields in BibTeX
- [ ] Supplementary page limit respected separately
- [ ] File size under venue limit (typically 30-100 MB)

### 4. LaTeX Compilation Check

```bash
pdflatex main.tex 2>&1 | grep -E "Warning|Error|Overfull"
bibtex main
pdflatex main.tex && pdflatex main.tex
```

### 5. arXiv-Specific Checklist

- [ ] Re-add author names, affiliations, acknowledgments
- [ ] Add `\hypersetup{hidelinks}` or remove colored links
- [ ] All fonts embedded (`pdffonts main.pdf | grep "no"` → nothing)
- [ ] Remove `\ifdefined\arxiv` guards if applicable
- [ ] Category selection: cs.CV, cs.LG, eess.SP, q-bio.NC, etc.

### 6. Overleaf Workflow

**Downloading from Overleaf:**
```
Menu → Download → Source (.zip)
```

**Pre-submission from Overleaf:**
1. Download source zip
2. Unzip locally → run pre-flight checks
3. Clean up: remove `.git`, comment files, unused figures
4. Re-compile locally to verify no Overleaf-specific dependencies
5. Create submission zip from cleaned folder

**Overleaf → arXiv shortcut:**
1. Download source
2. Ensure `\pdfoutput=1` is in first 5 lines of main `.tex`
3. Replace `\bibliography{refs}` with `\input{main.bbl}` (arXiv doesn't run bibtex)
4. Upload zip to arXiv

### 7. Figure Size Optimization

Large figures often cause submission rejections:

```bash
# Check figure sizes
find . -name "*.png" -o -name "*.jpg" | xargs ls -lhS

# Optimize PNG (lossless)
optipng -o7 figure.png

# Convert high-res PNG to PDF (vector-quality for line art)
inkscape figure.svg --export-pdf=figure.pdf

# Reduce JPEG quality for photographs
convert figure.jpg -quality 85 figure_optimized.jpg

# Check total submission size
du -sh _submission/
```

## Guidelines

1. **Safety First**: Never modify originals. Always work in `_submission/` copy.
2. **Ask the mode**: Blind vs. camera-ready vs. arXiv have opposite requirements.
3. **Check the log, not just the PDF**: Many issues only appear in `.log`.
4. **Test locally**: Even if using Overleaf, download and compile locally before submission.

## Example Usage

**User**: "I need to submit to MICCAI. Zip it up."

**Agent**:
```
Running pre-flight for MICCAI double-blind submission:

1. Mode: Double-blind → scanning for author info...
   - Found \author{John Doe} in main.tex → replaced with [Anonymized]
   - Found self-citation "our previous work [5]" → flagged for manual review
2. Page check: 8 pages (MICCAI limit: 8) ✓
3. References: No broken ? references ✓
4. Figures: fig3.png is 90 DPI — below 300 DPI threshold. Regenerate.
5. Package: Created _submission/miccai2025_blind.zip (12 MB)
   — .git/ and __pycache__/ excluded.

Blocking: fix fig3.png resolution before uploading.
```
