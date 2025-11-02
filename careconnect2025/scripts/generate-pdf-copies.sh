#!/bin/bash

# Script to generate PDF copies of CareConnect documentation
# Original Markdown files remain unchanged

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if pandoc is installed
check_pandoc() {
    if ! command -v pandoc &> /dev/null; then
        print_error "pandoc is required but not installed."
        echo ""
        echo "To install pandoc:"
        echo "  macOS: brew install pandoc"
        echo "  Ubuntu/Debian: sudo apt-get install pandoc"
        echo "  Or download from: https://pandoc.org/installing.html"
        exit 1
    fi
    print_info "pandoc found: $(pandoc --version | head -1)"
}

# Generate PDF from Markdown
generate_pdf() {
    local input_file="$1"
    local output_file="$2"
    local title="$3"

    print_info "Generating PDF: $(basename "$output_file")"

    if [ ! -f "$input_file" ]; then
        print_error "Source file not found: $input_file"
        return 1
    fi

    # Use pandoc with LaTeX engine for better formatting
    pandoc "$input_file" \
        -o "$output_file" \
        --pdf-engine=pdflatex \
        --variable geometry:margin=1in \
        --variable fontsize=11pt \
        --variable documentclass=article \
        --variable colorlinks=true \
        --variable linkcolor=blue \
        --variable urlcolor=blue \
        --variable toccolor=blue \
        --table-of-contents \
        --toc-depth=3 \
        --number-sections \
        --highlight-style=github \
        --metadata title="$title" \
        --metadata author="CareConnect Development Team" \
        --metadata date="$(date +'%B %Y')" \
        2>/dev/null

    if [ $? -eq 0 ]; then
        local size=$(du -h "$output_file" | cut -f1)
        print_info "✅ Successfully generated: $(basename "$output_file") ($size)"
        return 0
    else
        print_warning "LaTeX failed, trying HTML method..."

        # Fallback to HTML method
        pandoc "$input_file" \
            -o "$output_file" \
            --pdf-engine=wkhtmltopdf \
            --css=<(echo "
                body { font-family: Arial, sans-serif; font-size: 11pt; line-height: 1.6; margin: 1in; }
                h1, h2, h3 { color: #2c3e50; page-break-after: avoid; }
                pre { background: #f8f9fa; padding: 10px; border-radius: 4px; page-break-inside: avoid; }
                code { background: #f8f9fa; padding: 2px 4px; border-radius: 3px; }
                table { border-collapse: collapse; width: 100%; margin: 10px 0; }
                th, td { border: 1px solid #ddd; padding: 8px; }
                th { background: #f2f2f2; }
            ") \
            --metadata title="$title" \
            --metadata author="CareConnect Development Team" \
            --metadata date="$(date +'%B %Y')" \
            2>/dev/null

        if [ $? -eq 0 ]; then
            local size=$(du -h "$output_file" | cut -f1)
            print_info "✅ Successfully generated: $(basename "$output_file") ($size)"
        else
            print_error "❌ Failed to generate: $(basename "$output_file")"
            return 1
        fi
    fi
}

main() {
    echo "=============================================="
    echo "  CareConnect Documentation PDF Generator"
    echo "=============================================="
    echo ""

    check_pandoc

    # Set up directories
    local base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    local docs_dir="$base_dir/docs"
    local pdf_dir="$docs_dir/pdf"

    print_info "Base directory: $base_dir"
    print_info "Documentation directory: $docs_dir"
    print_info "PDF output directory: $pdf_dir"
    echo ""

    # Create PDF output directory
    mkdir -p "$pdf_dir"

    # Generate PDF for Programmer's Guide
    local prog_guide_md="$docs_dir/PROGRAMMERS_GUIDE.md"
    local prog_guide_pdf="$pdf_dir/CareConnect_Programmers_Guide.pdf"

    if [ -f "$prog_guide_md" ]; then
        generate_pdf "$prog_guide_md" "$prog_guide_pdf" "CareConnect Programmer's Guide"
    else
        print_warning "Programmer's Guide not found: $prog_guide_md"
    fi

    echo ""

    # Generate PDF for Deployment & Operations Guide
    local deploy_guide_md="$docs_dir/DEPLOYMENT_AND_OPERATIONS_GUIDE.md"
    local deploy_guide_pdf="$pdf_dir/CareConnect_Deployment_Operations_Guide.pdf"

    if [ -f "$deploy_guide_md" ]; then
        generate_pdf "$deploy_guide_md" "$deploy_guide_pdf" "CareConnect Deployment & Operations Guide"
    else
        print_warning "Deployment Guide not found: $deploy_guide_md"
    fi

    echo ""
    echo "=============================================="
    print_info "PDF Generation Complete!"
    echo "=============================================="
    echo ""

    # List generated files
    if [ -d "$pdf_dir" ]; then
        print_info "Generated PDF files in $pdf_dir:"
        for pdf_file in "$pdf_dir"/*.pdf; do
            if [ -f "$pdf_file" ]; then
                local size=$(du -h "$pdf_file" | cut -f1)
                echo "  📄 $(basename "$pdf_file") ($size)"
            fi
        done
        echo ""
        print_info "Original Markdown files remain unchanged in $docs_dir"
    fi
}

# Run the script
main "$@"