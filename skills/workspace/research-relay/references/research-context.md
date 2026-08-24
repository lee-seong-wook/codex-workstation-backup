# 연구 배경 및 목표

## 연구 도메인
**Federated Learning + Knowledge Distillation + Noisy Label Robustness** (의료 영상 세그멘테이션)

## 출발점 논문
- **BHI 논문**: `{{WORKSPACE_ROOT}}/BHI/_Sejong_Federated__Research.pdf`
  - Future work: *"data noise across clients"* 해결

## 현재 선정 가설
**Prototype-Guided Noise-Robust Federated Knowledge Distillation**
- 세부 내용: `{{WORKSPACE_ROOT}}/BHI/02_hypothesis/selected.md`

## 워크스페이스
`{{WORKSPACE_ROOT}}/BHI/`

## 실험 환경
- GPU: NVIDIA RTX 4060 8GB
- POC: CIFAR-10 + synthetic noise
- 최종: BHI 동일 세팅 (7 clients, abdominal CT)

## 기존 코드 자산
- `{{WORKSPACE_ROOT}}/fl-segmentation/` — FL 학습 프레임워크
