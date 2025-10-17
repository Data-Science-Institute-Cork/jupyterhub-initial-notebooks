#!/bin/bash
# Script to validate Jupyter notebook files (.ipynb) in the project
# Checks for invalid JSON, empty files, and missing required structure

echo "Searching for .ipynb files in all nested directories..."
echo ""

# Count total notebooks first
total_count=$(find . -name "*.ipynb" -type f | wc -l | tr -d ' ')

if [ "$total_count" -eq 0 ]; then
    echo "No .ipynb files found in the project."
    exit 0
fi

echo "Found $total_count notebook file(s)"
echo ""

invalid_notebooks_file=$(mktemp)
valid_count_file=$(mktemp)
invalid_count_file=$(mktemp)

echo "0" > "$valid_count_file"
echo "0" > "$invalid_count_file"

# Validate each notebook
find . -name "*.ipynb" -type f | sort | while read -r notebook; do
    error_msg=""

    # Check if file is empty
    if [ ! -s "$notebook" ]; then
        error_msg="Empty file (0 bytes)"
    else
        # Try to parse JSON and check required keys
        if ! jq empty "$notebook" 2>/dev/null; then
            error_msg="Invalid JSON"
        elif ! jq -e '.cells' "$notebook" >/dev/null 2>&1; then
            error_msg="Missing 'cells' key"
        elif ! jq -e '.metadata' "$notebook" >/dev/null 2>&1; then
            error_msg="Missing 'metadata' key"
        elif ! jq -e '.nbformat' "$notebook" >/dev/null 2>&1; then
            error_msg="Missing 'nbformat' key"
        elif ! jq -e '.nbformat_minor' "$notebook" >/dev/null 2>&1; then
            error_msg="Missing 'nbformat_minor' key"
        elif ! jq -e '.cells | type == "array"' "$notebook" >/dev/null 2>&1; then
            error_msg="'cells' is not an array"
        elif ! jq -e '.metadata | type == "object"' "$notebook" >/dev/null 2>&1; then
            error_msg="'metadata' is not an object"
        fi
    fi

    if [ -z "$error_msg" ]; then
        echo "✓ $notebook"
        valid_count=$(cat "$valid_count_file")
        echo $((valid_count + 1)) > "$valid_count_file"
    else
        echo "✗ $notebook"
        echo "  └─ $error_msg"
        echo "$notebook|$error_msg" >> "$invalid_notebooks_file"
        invalid_count=$(cat "$invalid_count_file")
        echo $((invalid_count + 1)) > "$invalid_count_file"
    fi
done

# Read final counts
valid_count=$(cat "$valid_count_file")
invalid_count=$(cat "$invalid_count_file")

# Summary
echo ""
echo "============================================================"
echo "SUMMARY"
echo "============================================================"
echo "Total notebooks: $total_count"
echo "Valid notebooks: $valid_count"
echo "Invalid notebooks: $invalid_count"

if [ "$invalid_count" -gt 0 ]; then
    echo ""
    echo "============================================================"
    echo "INVALID NOTEBOOKS"
    echo "============================================================"
    while IFS='|' read -r notebook_path message; do
        echo ""
        echo "$notebook_path"
        echo "  Issue: $message"
    done < "$invalid_notebooks_file"
fi

# Cleanup
rm -f "$invalid_notebooks_file" "$valid_count_file" "$invalid_count_file"
