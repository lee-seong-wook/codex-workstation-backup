---
name: transformers
description: >
  Work with pre-trained transformer models via Hugging Face for NLP, vision, audio,
  and multimodal tasks. Covers pipelines, model loading, text generation, training
  with Trainer API, PEFT/LoRA/QLoRA fine-tuning, and deployment patterns.
  Triggers on: "transformers", "huggingface", "pre-trained model", "fine-tune",
  "LoRA", "QLoRA", "PEFT", "LLM", "text generation", "pipeline",
  "트랜스포머", "파인튜닝", "사전학습 모델", "허깅페이스".
license: Apache-2.0 license
metadata:
    skill-author: K-Dense Inc.
---

# Transformers

## Overview

The Hugging Face Transformers library provides access to thousands of pre-trained models for NLP, computer vision, audio, and multimodal tasks.

## Installation

```bash
uv pip install torch transformers datasets evaluate accelerate
# Vision: uv pip install timm pillow
# Audio: uv pip install librosa soundfile
# PEFT: uv pip install peft bitsandbytes trl
```

## Authentication

```python
from huggingface_hub import login
login()  # or export HUGGINGFACE_TOKEN="your_token"
```

## Quick Start

```python
from transformers import pipeline

generator = pipeline("text-generation", model="gpt2")
result = generator("The future of AI is", max_length=50)
```

## Core Capabilities

### 1. Pipelines — Quick Inference
Optimized inference for 30+ tasks. See `references/pipelines.md`.

### 2. Model Loading — Fine-Grained Control
See `references/models.md`.

### 3. Text Generation — LLMs
See `references/generation.md`.

### 4. Training — Trainer API
See `references/training.md`.

### 5. Tokenization
See `references/tokenizers.md`.

### 6. PEFT — Parameter-Efficient Fine-Tuning (2025-2026)

The modern standard for adapting LLMs efficiently.

#### LoRA (Low-Rank Adaptation)

```python
from peft import LoraConfig, get_peft_model, TaskType

lora_config = LoraConfig(
    task_type=TaskType.CAUSAL_LM,
    r=16,                    # rank
    lora_alpha=32,           # scaling factor
    lora_dropout=0.05,
    target_modules=["q_proj", "v_proj", "k_proj", "o_proj",
                    "gate_proj", "up_proj", "down_proj"],
    use_rslora=True,         # rank-stabilized LoRA (best practice 2026)
)

model = get_peft_model(base_model, lora_config)
model.print_trainable_parameters()  # ~0.1-1% of total
```

#### QLoRA (Quantized LoRA)

```python
from transformers import BitsAndBytesConfig
import torch

bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_quant_type="nf4",        # NormalFloat4
    bnb_4bit_compute_dtype=torch.bfloat16,
    bnb_4bit_use_double_quant=True,   # nested quantization
)

model = AutoModelForCausalLM.from_pretrained(
    "model-id",
    quantization_config=bnb_config,
    device_map="auto",
)
# Then apply LoraConfig as above
```

#### SFTTrainer (TRL) — Streamlined Fine-Tuning

```python
from trl import SFTTrainer, SFTConfig

training_args = SFTConfig(
    output_dir="./results",
    num_train_epochs=3,
    per_device_train_batch_size=4,
    gradient_accumulation_steps=4,
    gradient_checkpointing=True,
    bf16=True,
    packing=True,              # efficient sequence packing
)

trainer = SFTTrainer(
    model=model,
    args=training_args,
    train_dataset=dataset,
    peft_config=lora_config,   # automatically applies PEFT
)
trainer.train()
```

#### PEFT Best Practices (2026)

| Practice | Recommendation |
|----------|---------------|
| **Starting point** | `r=16`, `lora_alpha=32` |
| **Target modules** | All linear layers (not just q/v) for better quality |
| **Precision** | Always `bf16` for training stability |
| **Rank-stabilized** | `use_rslora=True` for higher ranks |
| **Memory** | Enable gradient checkpointing + gradient accumulation |
| **Inference** | `model.merge_and_unload()` to eliminate adapter overhead |
| **Adapter management** | Version adapters on HF Hub, hotswap for multi-task |
| **RAG vs fine-tuning** | Fine-tune for style/format; RAG for factual knowledge |

#### Native Adapter Support (PeftAdapterMixin)

```python
# Load adapter directly on base model (no PeftModel wrapper needed)
model.load_adapter("adapter-id")
model.set_adapter("adapter-name")
model.disable_adapters()  # temporarily disable
```

## Common Patterns

### Simple Inference
```python
pipe = pipeline("task-name", model="model-id")
output = pipe(input_data)
```

### Custom Model
```python
tokenizer = AutoTokenizer.from_pretrained("model-id")
model = AutoModelForCausalLM.from_pretrained("model-id", device_map="auto")
inputs = tokenizer("text", return_tensors="pt")
outputs = model.generate(**inputs, max_new_tokens=100)
```

### Full Fine-Tuning (Trainer)
```python
from transformers import Trainer, TrainingArguments
training_args = TrainingArguments(output_dir="./results", num_train_epochs=3)
trainer = Trainer(model=model, args=training_args, train_dataset=dataset)
trainer.train()
```

## Reference Documentation

- `references/pipelines.md` — All tasks and optimization
- `references/models.md` — Loading, saving, configuration
- `references/generation.md` — Text generation strategies
- `references/training.md` — Fine-tuning with Trainer API
- `references/tokenizers.md` — Tokenization and preprocessing
