# 자주 쓰이는 수학 기호 LaTeX 매핑

## 그리스 문자

| 기호 | LaTeX | 기호 | LaTeX |
|------|-------|------|-------|
| α | `\alpha` | β | `\beta` |
| γ | `\gamma` | Γ | `\Gamma` |
| δ | `\delta` | Δ | `\Delta` |
| ε | `\varepsilon` | θ | `\theta` |
| λ | `\lambda` | μ | `\mu` |
| π | `\pi` | σ | `\sigma` |
| τ | `\tau` | φ | `\varphi` |
| ψ | `\psi` | ω | `\omega` |
| Σ | `\Sigma` | Ω | `\Omega` |
| ∇ | `\nabla` | ∂ | `\partial` |

## 연산자 & 관계

| 기호 | LaTeX | 기호 | LaTeX |
|------|-------|------|-------|
| ± | `\pm` | × | `\times` |
| · | `\cdot` | ⊗ | `\otimes` |
| ≤ | `\leq` | ≥ | `\geq` |
| ≠ | `\neq` | ≈ | `\approx` |
| ∝ | `\propto` | ∼ | `\sim` |
| ∞ | `\infty` | ∅ | `\emptyset` |

## 집합 & 논리

| 기호 | LaTeX | 기호 | LaTeX |
|------|-------|------|-------|
| ∈ | `\in` | ∉ | `\notin` |
| ⊂ | `\subset` | ⊆ | `\subseteq` |
| ∪ | `\cup` | ∩ | `\cap` |
| ∀ | `\forall` | ∃ | `\exists` |
| ⇒ | `\Rightarrow` | ⇔ | `\Leftrightarrow` |

## 자주 쓰는 패턴

```latex
% 적분
\int_{a}^{b} f(x)\,dx

% 합/곱
\sum_{i=1}^{n} x_i \qquad \prod_{i=1}^{n} x_i

% 극한
\lim_{x \to \infty} f(x)

% 분수
\frac{a}{b} \qquad \dfrac{a}{b}  % 디스플레이용

% 제곱근
\sqrt{x} \qquad \sqrt[n]{x}

% 행렬 (소괄호)
\begin{pmatrix} a & b \\ c & d \end{pmatrix}

% 행렬 (대괄호)
\begin{bmatrix} a & b \\ c & d \end{bmatrix}

% 벡터
\mathbf{x} \qquad \bm{x} \qquad \vec{x}

% 전치
\mathbf{A}^\top

% 기대값
\mathbb{E}[X]

% 다중 줄 수식
\begin{align}
  f(x) &= ax^2 + bx + c \\
       &= a(x - r_1)(x - r_2)
\end{align}
```

## 강화학습 표기 (DDPG 등)

| 개념 | LaTeX |
|------|-------|
| 상태공간 | `\mathcal{S}` |
| 행동공간 | `\mathcal{A}` |
| 정책 | `\pi_\theta` |
| 가치함수 | `V^\pi(s)` |
| Q함수 | `Q^\pi(s, a)` |
| 할인율 | `\gamma` |
| 기대값 | `\mathbb{E}` |
| 손실함수 | `\mathcal{L}` |
| 파라미터 | `\theta` |
| 타겟 파라미터 | `\theta'` |
| 학습률 | `\alpha` |
| 소프트 업데이트 | `\tau` |
| 경사 | `\nabla_\theta` |
| 리플레이 버퍼 | `\mathcal{D}` |
