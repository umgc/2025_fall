# PII Policy (M3)
Detect: email, phone, SSN. Default = mask before display/storage; block outbound when policy=block.
API: POST /pii/sanitize {text} -> {masked}.
