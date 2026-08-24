# Integration and Performance Patterns

## Integration Patterns

### With RAG Systems

```python
RAG_PROMPT = """You are a knowledgeable assistant that answers questions based on provided context.

Context (retrieved from knowledge base):
{context}

Instructions:
1. Answer ONLY based on the provided context
2. If the context doesn't contain the answer, say "I don't have information about that in my knowledge base"
3. Cite specific passages using [1], [2] notation
4. If the question is ambiguous, ask for clarification

Question: {question}

Answer:"""
```

### With Validation and Verification

```python
VALIDATED_PROMPT = """Complete the following task:

Task: {task}

After generating your response, verify it meets ALL these criteria:
✓ Directly addresses the original request
✓ Contains no factual errors
✓ Is appropriately detailed (not too brief, not too verbose)
✓ Uses proper formatting
✓ Is safe and appropriate

If verification fails on any criterion, revise before responding.

Response:"""
```

## Performance Optimization

### Token Efficiency

```python
# Before: Verbose prompt (150+ tokens)
verbose_prompt = """
I would like you to please take the following text and provide me with a comprehensive
summary of the main points. The summary should capture the key ideas and important details
while being concise and easy to understand.
"""

# After: Concise prompt (30 tokens)
concise_prompt = """Summarize the key points concisely:

{text}

Summary:"""
```

### Caching Common Prefixes

```python
from anthropic import Anthropic

client = Anthropic()

# Use prompt caching for repeated system prompts
response = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=1000,
    system=[
        {
            "type": "text",
            "text": LONG_SYSTEM_PROMPT,
            "cache_control": {"type": "ephemeral"}
        }
    ],
    messages=[{"role": "user", "content": user_query}]
)
```


## Success Metrics

Track these KPIs for your prompts:

- **Accuracy**: Correctness of outputs
- **Consistency**: Reproducibility across similar inputs
- **Latency**: Response time (P50, P95, P99)
- **Token Usage**: Average tokens per request
- **Success Rate**: Percentage of valid, parseable outputs
- **User Satisfaction**: Ratings and feedback

