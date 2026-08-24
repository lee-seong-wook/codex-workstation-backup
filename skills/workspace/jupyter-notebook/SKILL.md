---
name: jupyter-notebook
description: Read, edit, inspect, repair, and summarize Jupyter notebooks (`.ipynb`). Use when the user mentions notebook, Jupyter, `.ipynb`, cells, kernels, outputs, execution order, "주피터", or asks to convert notebooks to scripts or reports.
---

# Jupyter Notebook

## Workflow

1. Treat `.ipynb` as structured JSON. Preserve metadata unless there is a reason to change it.
2. Inspect notebook shape first: cell count, code vs markdown, kernelspec, outputs, and execution counts.
3. For edits, modify specific cells and keep JSON valid. Avoid broad text replacement across the whole file.
4. Do not execute notebooks unless the user asks or verification requires it. Execution can be slow, stateful, or destructive.
5. When executing, prefer a project virtual environment, report kernel/dependency errors, and preserve or clear outputs according to the user request.
6. For conversion, use `jupyter nbconvert` when available; otherwise parse JSON and write a script/markdown carefully.
