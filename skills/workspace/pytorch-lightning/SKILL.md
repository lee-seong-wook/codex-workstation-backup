---
name: pytorch-lightning
description: >
  Deep learning framework (PyTorch Lightning 2.x). Organize PyTorch code into
  LightningModules, configure Trainers for multi-GPU/TPU, implement data pipelines,
  callbacks, logging (W&B, TensorBoard), distributed training (DDP, FSDP, DeepSpeed).
  Also covers Lightning Fabric for maximum control over training loops.
  Use when building, training, or scaling neural networks with PyTorch Lightning.
  Triggers on: "lightning", "pytorch lightning", "LightningModule", "Trainer",
  "Fabric", "lightning fabric", "파이토치 라이트닝", "라이트닝", "트레이너 설정".
license: Apache-2.0 license
metadata:
    skill-author: K-Dense Inc.
---

# PyTorch Lightning 2.x

## Overview

PyTorch Lightning organizes PyTorch code to eliminate boilerplate while maintaining full flexibility. Version 2.x introduces a stable API, `torch.compile` support, and **Lightning Fabric** for fine-grained control.

## When to Use

- Building, training, or deploying neural networks
- Organizing PyTorch code into LightningModules
- Configuring multi-GPU/TPU training
- Working with callbacks, logging, distributed training
- Need fine-grained loop control → use **Fabric**

## Choosing: Trainer vs Fabric

| Feature | Trainer | Fabric |
|---------|---------|--------|
| **Abstraction level** | High (automatic loop) | Low (you write the loop) |
| **Best for** | Standard training workflows | RL, GANs, custom research |
| **Migration effort** | Must restructure into LightningModule | Minimal (add 5 lines to existing PyTorch) |
| **torch.compile** | ✅ Full support | ✅ Full support |
| **Distributed** | DDP, FSDP, DeepSpeed | DDP, FSDP, DeepSpeed |

**Rule of thumb:** Start with Trainer. Use Fabric only when Trainer's structure constrains your research.

## Core Capabilities

### 1. LightningModule

Organize models into six logical sections:
1. `__init__()` / `setup()` — Initialization
2. `training_step()` — Training logic
3. `validation_step()` — Validation logic
4. `test_step()` / `predict_step()` — Test/prediction
5. `configure_optimizers()` — Optimizer & scheduler

See `scripts/template_lightning_module.py` and `references/lightning_module.md`.

### 2. Trainer (2.x)

Key 2.x features:
- **`torch.compile` support**: `trainer.fit(torch.compile(model), ...)`
- **Stable API**: Backward compatible within 2.x series
- **Removed legacy**: TorchScript deprecated, simpler codebase

```python
import lightning as L

trainer = L.Trainer(
    max_epochs=10,
    accelerator="gpu",
    devices=2,
    strategy="ddp",
    precision="bf16-mixed",  # 2.x: string-based precision
    gradient_clip_val=1.0,
)
trainer.fit(model, datamodule=dm)
```

See `references/trainer.md`.

### 3. Lightning Fabric (NEW in 2.x)

Minimal changes to existing PyTorch code for distributed training:

```python
import lightning as L

fabric = L.Fabric(accelerator="gpu", devices=2, strategy="ddp")
fabric.launch()

model, optimizer = fabric.setup(model, optimizer)
dataloader = fabric.setup_dataloaders(dataloader)

for batch in dataloader:
    optimizer.zero_grad()
    loss = model(batch)
    fabric.backward(loss)  # replaces loss.backward()
    optimizer.step()
```

**Key differences from raw PyTorch:**
- Replace `loss.backward()` → `fabric.backward(loss)`
- Remove all `.to(device)` calls — Fabric handles placement
- Wrap model/optimizer with `fabric.setup()`

See `references/fabric.md` for local Fabric guidance; use official Lightning docs when API details may have changed.

### 4. LightningDataModule

See `scripts/template_datamodule.py` and `references/data_module.md`.

### 5. Callbacks

Built-in: ModelCheckpoint, EarlyStopping, LearningRateMonitor, BatchSizeFinder.
See `references/callbacks.md`.

### 6. Logging

Supports: TensorBoard, W&B, MLflow, Neptune, Comet, CSV.
See `references/logging.md`.

### 7. Distributed Training

| Strategy | Model Size | Use Case |
|----------|-----------|----------|
| **DDP** | < 500M params | Standard multi-GPU |
| **FSDP** | 500M+ params | Large transformers (recommended) |
| **DeepSpeed** | 500M+ params | Fine-grained control, ZeRO stages |

See `references/distributed_training.md`.

## Best Practices (2.x)

- Use `self.device` instead of `.cuda()` — device agnostic
- Use `self.save_hyperparameters()` in `__init__()`
- Use `self.log()` for automatic aggregation across devices
- Use `seed_everything()` and `Trainer(deterministic=True)` for reproducibility
- Use `Trainer(fast_dev_run=True)` for debugging
- Use `precision="bf16-mixed"` (string format in 2.x) for mixed precision
- Use `torch.compile()` with Lightning for JIT compilation speedups

See `references/best_practices.md`.

## Migration from 1.x to 2.x

Key changes:
- `import pytorch_lightning as pl` → `import lightning as L`
- `pl.LightningModule` → `L.LightningModule`
- `Trainer(gpus=N)` → `Trainer(accelerator="gpu", devices=N)`
- `Trainer(precision=16)` → `Trainer(precision="16-mixed")`
- TorchScript support removed — use `torch.compile` instead

## Resources

### scripts/
- `template_lightning_module.py` — LightningModule boilerplate
- `template_datamodule.py` — LightningDataModule boilerplate
- `quick_trainer_setup.py` — Trainer configuration examples

### references/
- `lightning_module.md`, `trainer.md`, `data_module.md`
- `callbacks.md`, `logging.md`, `distributed_training.md`
- `best_practices.md`
