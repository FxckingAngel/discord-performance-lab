# Functional result records

Store one redacted Markdown record here for each stock or candidate functional run. Do not commit screenshots of private conversations, message text, account identifiers, tokens, or crash dumps.

Use this minimum structure:

```markdown
# Functional run

- Date:
- Operator:
- Client build:
- Profile and launch arguments:
- Windows version:
- Scope: stock, foreground candidate, or background candidate

## Results

| Checklist area | Result | Evidence |
| --- | --- | --- |
| Identity and lifecycle | pass/fail/not tested | redacted observation or local evidence path |
| Navigation and messaging | pass/fail/not tested | redacted observation or local evidence path |
| Voice, video, and media | pass/fail/not tested | redacted observation or local evidence path |
| User-facing behavior | pass/fail/not tested | redacted observation or local evidence path |

## Notes

Record regressions and cleanup behavior. Keep private raw evidence outside the repository.
```

Process-level smoke checks do not replace this record. A candidate cannot be accepted for normal foreground use while account-level items remain untested.
