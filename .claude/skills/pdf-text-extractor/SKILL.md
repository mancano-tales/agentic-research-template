---
name: pdf-text-extractor
description: Automatically extracts plain text and markdown content from PDF files in the workspace or local drives, saving them as text files to save LLM tokens.
---

# PDF Text Extractor Skill

This skill provides utilities to extract raw text content from PDF files, clean up common formatting issues resulting from PDF extraction, and save the output as `.txt` files in designated references directories.

## How to Use

When you need to read a local PDF file, instead of reading the binary file or parsing it page-by-page manually, you can execute the R script provided in `scripts/extract_pdf.R` using the command-line interface.

### Running the Extractor

```bash
Rscript scripts/extract_pdf.R --src "/path/to/input.pdf" --dest "/path/to/output.txt"
```

You can also convert a directory of PDFs:

```bash
Rscript scripts/extract_pdf.R --src-dir "/path/to/pdf/folder" --dest-dir "/path/to/txt/folder"
```

## Structure

- `scripts/extract_pdf.R`: The core extraction script using the R `pdftools` library.
