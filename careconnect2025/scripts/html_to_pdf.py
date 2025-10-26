#!/usr/bin/env python3

import os
import sys
import argparse

def convert_with_browser_print():
    """
    Instructions for manual conversion using browser print
    """
    print("\n" + "="*60)
    print("   MANUAL PDF CONVERSION INSTRUCTIONS")
    print("="*60)
    print()
    print("Since automatic PDF generation requires additional system libraries,")
    print("here are instructions for manual conversion:")
    print()
    print("1. Open each HTML file in your web browser:")

    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    pdf_dir = os.path.join(base_dir, "docs", "pdf")

    html_files = []
    if os.path.exists(pdf_dir):
        for file in os.listdir(pdf_dir):
            if file.endswith('.html'):
                html_files.append(file)
                file_path = os.path.join(pdf_dir, file)
                print(f"   • file://{file_path}")

    print()
    print("2. In your browser, press Cmd+P (Mac) or Ctrl+P (Windows/Linux)")
    print("3. Choose 'Save as PDF' as the destination")
    print("4. Recommended settings:")
    print("   • Paper size: A4 or Letter")
    print("   • Margins: Default or Minimum")
    print("   • Include headers and footers: Optional")
    print("   • Background graphics: Yes (recommended)")
    print()
    print("5. Save the PDFs with these names:")

    for html_file in html_files:
        pdf_name = html_file.replace('.html', '.pdf')
        print(f"   • {html_file} → {pdf_name}")

    print()
    print("The HTML files are professionally formatted and will print well!")
    print("="*60)
    print()

def try_alternative_methods():
    """Try alternative PDF conversion methods"""

    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    pdf_dir = os.path.join(base_dir, "docs", "pdf")

    if not os.path.exists(pdf_dir):
        print("PDF directory not found!")
        return

    html_files = [f for f in os.listdir(pdf_dir) if f.endswith('.html')]

    if not html_files:
        print("No HTML files found to convert!")
        return

    print("Found HTML files to convert:")
    for html_file in html_files:
        print(f"  • {html_file}")
    print()

    # Try different conversion methods
    methods_tried = []

    # Method 1: Try pdfkit (if available)
    try:
        import pdfkit
        print("✓ Trying pdfkit conversion...")

        for html_file in html_files:
            html_path = os.path.join(pdf_dir, html_file)
            pdf_path = os.path.join(pdf_dir, html_file.replace('.html', '.pdf'))

            try:
                pdfkit.from_file(html_path, pdf_path)
                print(f"  ✓ Converted: {html_file} → {os.path.basename(pdf_path)}")
            except Exception as e:
                print(f"  ✗ Failed to convert {html_file}: {e}")

        methods_tried.append("pdfkit")
        return True

    except ImportError:
        print("✗ pdfkit not available")

    # Method 2: Try reportlab (if available)
    try:
        from reportlab.pdfgen import canvas
        from reportlab.lib.pagesizes import A4
        print("✗ reportlab available but needs HTML parsing - skipping")
    except ImportError:
        print("✗ reportlab not available")

    # If no methods worked, show manual instructions
    if not methods_tried:
        print("No automatic conversion methods available.")
        convert_with_browser_print()
        return False

    return True

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Convert HTML documentation to PDF')
    parser.add_argument('--manual', action='store_true', help='Show manual conversion instructions')

    args = parser.parse_args()

    if args.manual:
        convert_with_browser_print()
    else:
        print("Attempting automatic PDF conversion...")
        if not try_alternative_methods():
            print("\nAutomatic conversion failed. Use --manual flag for instructions.")