#!/usr/bin/env python3
"""
CTF Challenge: Forensics – Hidden in PDF
Creates a PDF with a suspiciously large size and an embedded flag.txt attachment.

The visible page shows innocent text; the flag lives in an EmbeddedFiles entry
accessible via:
    pdfinfo challenge.pdf
    pdfdetach -list challenge.pdf
    pdfdetach -saveall challenge.pdf

Or the Python extractor: exploits/extract_pdf_flag.py

Run:
    pip install pypdf fpdf2
    python create_challenge.py   # produces challenge.pdf
"""
import io
import os

from fpdf import FPDF
from pypdf import PdfReader, PdfWriter


def _make_visible_pdf() -> bytes:
    """Generate a normal-looking PDF page with fpdf2."""
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Helvetica", size=12)
    pdf.cell(text="Annual Security Report - Q1 2026")
    pdf.ln(10)
    pdf.set_font("Helvetica", size=10)
    for i in range(1, 30):
        pdf.cell(text=f"Line {i}: Lorem ipsum dolor sit amet, consectetur adipiscing elit.")
        pdf.ln(6)
    return bytes(pdf.output())


def create_challenge(output_path: str = "challenge.pdf") -> None:
    visible_bytes = _make_visible_pdf()
    reader = PdfReader(io.BytesIO(visible_bytes))
    writer = PdfWriter()
    writer.append_pages_from_reader(reader)

    # Embed the hidden flag file
    flag_data = b"flag{pdf_attachment_found}\n"
    writer.add_attachment("flag.txt", flag_data)

    # Pad the file to make the size "suspiciously large"
    padding = b"%% " + b"A" * 4096 + b"\n"
    writer.add_attachment("notes.bin", padding)

    with open(output_path, "wb") as f:
        writer.write(f)

    size_kb = os.path.getsize(output_path) // 1024
    print(f"[+] Created {output_path} ({size_kb} KB)")
    print("[+] Flag hidden in embedded attachment: flag.txt")
    print("[+] Extract with:  pdfdetach -saveall challenge.pdf")
    print("[+]            or:  python ../../exploits/extract_pdf_flag.py challenge.pdf")


if __name__ == "__main__":
    create_challenge()
