# Troubleshooting Common Issues

## ConvergenceWarning

**Issue:** Model did not converge.

**Solution:** Increase `max_iter` or scale features.

```python
model = LogisticRegression(max_iter=1000)
```

## Poor Performance on Test Set

**Issue:** Overfitting.

**Solution:** Use regularization, cross-validation, or a simpler model.

```python
# Add regularization
model = Ridge(alpha=1.0)

# Use cross-validation
scores = cross_val_score(model, X, y, cv=5)
```

## Memory Error with Large Datasets

**Solution:** Use algorithms designed for large data.

```python
# Use SGD for large datasets
from sklearn.linear_model import SGDClassifier
model = SGDClassifier()

# Or MiniBatchKMeans for clustering
from sklearn.cluster import MiniBatchKMeans
model = MiniBatchKMeans(n_clusters=8, batch_size=100)
```

## Additional Resources

- Official Documentation: https://scikit-learn.org/stable/
- User Guide: https://scikit-learn.org/stable/user_guide.html
- API Reference: https://scikit-learn.org/stable/api/index.html
- Examples Gallery: https://scikit-learn.org/stable/auto_examples/index.html

