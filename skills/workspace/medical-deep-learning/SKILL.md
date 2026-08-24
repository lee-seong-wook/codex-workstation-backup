---
name: medical-deep-learning
description: Medical deep learning and healthcare ML coding guidance, including MONAI, PyHealth, 3D medical volumes, segmentation, classification, survival/readmission tasks, DICOM/NIfTI workflows, and privacy-aware experiments. Use for "medical deep learning coding", "MONAI", "PyHealth", "3D medical volumes", "의료영상 딥러닝", and clinical ML pipelines.
---

# Medical Deep Learning

## Workflow

1. Identify data modality: tabular EHR, time series, DICOM, NIfTI, pathology WSI, 2D images, or 3D/4D volumes.
2. Confirm task and leakage risks: patient-level split, study-level split, temporal split, label source, censoring, and site/domain shift.
3. Choose supporting local skills:
   - `pytorch-lightning` for training loops and experiment structure.
   - `torch-geometric` for graph/EHR relation modeling.
   - `transformers` for text or multimodal clinical models.
   - `exploratory-data-analysis` for dataset inspection.
   - `statistical-analysis` for evaluation and confidence intervals.
4. For MONAI-style imaging, verify spacing, orientation, normalization, patch sampling, augmentation, sliding-window inference, and metric definitions.
5. For PyHealth-style EHR, verify code mappings, visits, temporal ordering, cohort definitions, and task construction.
6. Protect privacy: do not expose PHI, patient identifiers, or institution-specific secrets in logs, filenames, figures, or prompts.
