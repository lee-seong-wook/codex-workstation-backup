---
name: miccai_paper_assistant
description: MICCAI 학회 논문 작성 및 리뷰 지원을 위한 전문 스킬
---

# MICCAI Paper Writing Assistant

MICCAI (Medical Image Computing and Computer Assisted Intervention) 학회 논문 작성을 위한 종합 가이드라인입니다.

---

## 1. MICCAI 논문 기본 규칙

### 페이지 제한
- **Main Conference**: 8 페이지 (참고문헌 제외), 최대 2페이지 추가 가능 (참고문헌)
- **Workshop**: 보통 8-10 페이지
- **LNCS 포맷** 필수 사용

### 스타일 규칙
- `\documentclass[runningheads]{llncs}` 사용
- 폰트 크기, 마진 변경 금지
- `\vspace`, `\hspace` 남용 금지 (페이지 제한 우회로 간주)
- 익명 리뷰: 저자 정보, 감사의 글 제거

---

## 2. 섹션별 작성 가이드

### Abstract (150-250 단어)
**구조**: Problem → Existing Gap → Proposed Method → Results

**체크리스트**:
- [ ] 첫 문장: 임상적/기술적 중요성
- [ ] 기존 방법의 한계점 명시
- [ ] 제안 방법의 핵심 아이디어 (1-2문장)
- [ ] 주요 컴포넌트 나열 (numbered list 권장)
- [ ] 정량적 결과 포함 (DSC, HD95 등)
- [ ] 단어 수 150-250 이내

**피해야 할 것**:
- 실험으로 검증되지 않은 claim
- 과도한 기술적 세부사항
- "novel", "state-of-the-art" 과용

### Introduction (약 1.5 페이지)
**구조**: Context → Problem → Related Work Gap → Contribution

**단락 구성**:
1. **임상적/기술적 배경** (2-3문장)
2. **기존 연구 소개** (CNN, Transformer, Foundation Model 등)
3. **기존 방법의 한계점** (구체적으로)
4. **제안 방법 소개** (핵심 원리/철학)
5. **Contributions** (itemize로 3-4개)

**팁**:
- Contribution은 "What"보다 "Why it matters" 강조
- 각 contribution이 limitation에 대응되도록 구성

### Method (약 2-2.5 페이지)
**구조**: Overview → Component 1 → Component 2 → ... → Training

**체크리스트**:
- [ ] Architecture figure 포함 (필수)
- [ ] 각 컴포넌트에 수식 포함
- [ ] 변수 정의 명확히 (dimension 포함)
- [ ] 다른 방법과의 차이점 강조
- [ ] Training objective (loss function) 명시

**수식 작성 규칙**:
```latex
\begin{equation}
    \mathbf{y} = f(\mathbf{x}; \theta), \quad \mathbf{y} \in \mathbb{R}^{C \times H \times W}
\end{equation}
```
- 모든 변수에 dimension 기술
- 행렬/벡터는 boldface (`\mathbf{}`)
- 수식 뒤 설명 반드시 추가

### Experiments (약 2-2.5 페이지)

**필수 구성요소**:
1. **Dataset & Implementation** (0.5 페이지)
   - 데이터셋 통계 (samples, resolution, split ratio)
   - 학습 파라미터 (optimizer, lr, epochs, batch size)
   - 평가 메트릭 정의
   
2. **Comparison with Baselines** (1 페이지)
   - Table 필수 (최소 5개 baseline)
   - 우리 방법 볼드체 표시
   - 통계적 유의성 표기 권장 (p-value)
   
3. **Ablation Study** (0.5 페이지)
   - 각 컴포넌트의 기여도 분석
   - Progressive addition 방식 권장
   
4. **Qualitative Results** (선택)
   - Figure로 시각화
   - 성공 케이스 + 실패 케이스 모두

**Table 작성 팁**:
```latex
\begin{table}[!t]
\centering
\caption{Comparison on Dataset X. Best in \textbf{bold}.}
\setlength{\tabcolsep}{4pt}
\begin{tabular}{l|ccc}
\toprule
Method & Dice (\%) $\uparrow$ & HD95 (mm) $\downarrow$ & Params (M) \\
\midrule
Baseline & 85.2 & 12.3 & 31 \\
\textbf{Ours} & \textbf{88.5} & \textbf{8.7} & \textbf{5.2} \\
\bottomrule
\end{tabular}
\end{table}
```

### Conclusion (0.5 페이지)
**구조**: Summary → Key Findings → Limitations → Future Work

**체크리스트**:
- [ ] 제안 방법 한 문장 요약
- [ ] 주요 결과 언급
- [ ] **Limitations 명시** (MICCAI 2024+ 강조사항)
- [ ] Future work 간략히

---

## 3. 리뷰어 대응 전략

### 흔한 리뷰 코멘트 & 대응

| 코멘트 유형 | 대응 전략 |
|------------|----------|
| "Novelty가 부족하다" | Contribution에서 "왜 기존과 다른지" 강조, Related Work 보강 |
| "실험이 부족하다" | Ablation 추가, 다른 데이터셋 실험, Statistical test |
| "Claim이 검증되지 않았다" | 해당 claim에 대한 정량적 분석 추가 |
| "글이 이해하기 어렵다" | Figure 추가, 문장 분리, 예시 추가 |
| "SOTA와 비교가 없다" | 최신 방법 추가, 또는 왜 비교하지 않았는지 설명 |

### 리뷰어 톤에 따른 대응
- **긍정적**: 간결하게 감사 표시 + 개선점 반영
- **중립적**: 상세히 설명 + Evidence 제공
- **부정적**: 정중히 반박 + 실험 결과로 증명

---

## 4. LaTeX 팁

### 자주 쓰는 패키지
```latex
\usepackage{amsmath,amssymb}  % 수식
\usepackage{graphicx}         % 이미지
\usepackage{booktabs}         % 깔끔한 표
\usepackage{multirow}         % 표 병합
\usepackage{xcolor}           % 색상
\usepackage[hidelinks]{hyperref}  % 하이퍼링크
```

### 공간 절약 팁 (윤리적 범위)
- Figure를 `[!t]`로 상단 배치
- 긴 URL은 footnote로
- Related Work를 Introduction에 통합
- 반복되는 표현 축약

### 피해야 할 것
- `\vspace{-10pt}` 등 강제 간격 조절
- 폰트 크기 변경
- 마진 변경

---

## 5. 체크리스트 (제출 전)

### 내용
- [ ] Abstract에 정량적 결과 포함
- [ ] 모든 Figure/Table이 본문에서 참조됨
- [ ] 모든 수식의 변수가 정의됨
- [ ] Limitations 섹션 포함
- [ ] References 최신성 (최근 2-3년 논문 포함)

### 형식
- [ ] 페이지 제한 준수 (8 페이지)
- [ ] 익명화 완료 (저자, 감사의 글, GitHub 링크 제거)
- [ ] Figure 해상도 충분 (300 DPI 이상)
- [ ] 맞춤법/문법 검사 완료

### 파일
- [ ] PDF 파일 크기 적정 (보통 <10MB)
- [ ] Supplementary material 필요시 별도 준비

---

## 6. 유용한 표현 모음

### Problem Statement
- "remains challenging because..."
- "a fundamental limitation is..."
- "existing methods suffer from..."

### Contribution
- "We propose X, the first method that..."
- "Our key insight is that..."
- "Unlike prior work, we..."

### Results
- "achieves state-of-the-art performance with..."
- "outperforms baseline by X% in terms of..."
- "demonstrates the effectiveness of..."

### Limitations
- "Our method has several limitations..."
- "One potential concern is..."
- "Future work could address..."

---

## 사용 방법

이 스킬을 호출하면:
1. Abstract, Introduction, Method 등 각 섹션 작성/검토 지원
2. MICCAI 규칙 준수 여부 체크
3. 리뷰어 코멘트 대응 전략 제안
4. LaTeX 코드 최적화

**예시 명령**: 
- "abstract 검토해줘"
- "method 섹션 작성해줘"
- "이 리뷰어 코멘트에 어떻게 대응할지 알려줘"
