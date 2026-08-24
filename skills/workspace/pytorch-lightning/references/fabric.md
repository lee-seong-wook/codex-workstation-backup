# Lightning Fabric

Use Fabric when standard `Trainer` structure is too restrictive but you still want Lightning-managed device placement, precision, distributed setup, and checkpoint utilities.

## When to Prefer Fabric

- Reinforcement learning or GAN loops.
- Custom multi-optimizer schedules.
- Existing PyTorch loops that should not be rewritten as `LightningModule`.
- Research code that needs explicit loop control.

## Minimal Pattern

```python
import lightning as L

fabric = L.Fabric(accelerator="gpu", devices=2, strategy="ddp")
fabric.launch()

model, optimizer = fabric.setup(model, optimizer)
loader = fabric.setup_dataloaders(loader)

for batch in loader:
    optimizer.zero_grad()
    loss = model(batch)
    fabric.backward(loss)
    optimizer.step()
```

## Checks

- Remove manual `.to(device)` calls after `fabric.setup`.
- Use `fabric.backward(loss)` instead of `loss.backward()`.
- Wrap dataloaders with `fabric.setup_dataloaders`.
- Verify current Lightning docs before relying on version-specific APIs.

