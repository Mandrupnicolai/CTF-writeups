---
title: "Hidden in PDF"
category: "Forensics"
difficulty: "Easy"
tags: ["pdf", "embedded-files", "attachments", "pypdf"]
challenge: "challenges/forensics-hidden-pdf/create_challenge.py"
exploit: "exploits/extract_pdf_flag.py"
last_updated: "2026-03-23"
---

# Forensics: Hidden in PDF

## Summary
Extract an embedded attachment (`flag.txt`) from a PDF using either standard CLI tools or a Python script.

## Challenge
- File: `challenges/forensics-hidden-pdf/challenge.pdf`
- The flag is embedded as an attachment in the PDF name tree (`/EmbeddedFiles`).

## Solution
### Approach
1. Inspect the PDF for embedded files.
2. Extract attachments and look for a flag string.

### Tooling options
- Poppler tools (Linux/macOS): `pdfdetach -list` and `pdfdetach -saveall`
- Included Python extractor: `exploits/extract_pdf_flag.py`

## Reproduction
1. (Optional) Regenerate the PDF: `python challenges/forensics-hidden-pdf/create_challenge.py`
2. Extract attachments: `python exploits/extract_pdf_flag.py challenges/forensics-hidden-pdf/challenge.pdf`

## Flag
`flag{pdf_attachment_found}`

## Mitigation
- Strip attachments from untrusted PDFs before redistribution.
- Validate/sanitize PDFs in ingestion pipelines.

---
Ethics note: this writeup targets the intentionally vulnerable code in this repository only. Do not use these techniques on systems you do not own or have explicit permission to test.

