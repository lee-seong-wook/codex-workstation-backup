---
name: security-review
description: Security review, secure coding guidance, threat modeling, attack-surface analysis, and security ownership mapping. Use for "security best practices", "secure coding review", "threat model", "abuse path", "trust boundary", "security ownership", "보안 리뷰", "위협 모델링", and sensitive auth/schema/deploy changes.
---

# Security Review

## Workflow

1. Define scope: code diff, architecture, deployment, data flow, dependency, or ownership map.
2. Identify assets, trust boundaries, actors, entry points, sensitive data, and privileged actions.
3. Check likely failures: authn/authz, injection, output encoding, secrets, SSRF, deserialization, file upload, CORS, CSRF, logging leakage, dependency/supply-chain risk, and unsafe deploy config.
4. For threat modeling, list abuse paths with preconditions, impact, mitigations, and verification tests.
5. For ownership mapping, identify sensitive modules, likely maintainers, review bottlenecks, and bus-factor risks.
6. Return findings first, ordered by severity, with file/line references when reviewing code.

Use OWASP ASVS, OWASP Cheat Sheets, and OWASP threat-modeling guidance as primary references. Do not make compliance claims unless the user provides the relevant standard and evidence.
