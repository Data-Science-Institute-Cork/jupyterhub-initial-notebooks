#!/bin/bash
# Script to find empty CSV files in the project
# Checks for files with 0 bytes or only whitespace

echo "Searching for .csv files in all nested directories..."
echo ""

# Count total CSV files first
total_count=$(find . -name "*.csv" -type f | wc -l | tr -d ' ')

if [ "$total_count" -eq 0 ]; then
    echo "No .csv files found in the project."
    exit 0
fi

echo "Found $total_count CSV file(s)"
echo ""

empty_csv_file=$(mktemp)
valid_count=0
empty_count=0

# Check each CSV file
find . -name "*.csv" -type f | sort | while read -r csv_file; do
    # Check if file is empty (0 bytes)
    if [ ! -s "$csv_file" ]; then
        echo "✗ $csv_file"
        echo "  └─ Empty file (0 bytes)"
        echo "$csv_file" >> "$empty_csv_file"
        empty_count=$(cat <<< $((empty_count + 1)))
    else
        # Check if file contains only whitespace
        if [ -z "$(tr -d '[:space:]' < "$csv_file")" ]; then
            echo "✗ $csv_file"
            echo "  └─ File contains only whitespace"
            echo "$csv_file" >> "$empty_csv_file"
        else
            echo "✓ $csv_file"
            valid_count=$(cat <<< $((valid_count + 1)))
        fi
    fi
done

# Count empty files
empty_count=$(wc -l < "$empty_csv_file" | tr -d ' ')
valid_count=$((total_count - empty_count))

# Summary
echo ""
echo "============================================================"
echo "SUMMARY"
echo "============================================================"
echo "Total CSV files: $total_count"
echo "Valid CSV files: $valid_count"
echo "Empty CSV files: $empty_count"

if [ "$empty_count" -gt 0 ]; then
    echo ""
    echo "============================================================"
    echo "EMPTY CSV FILES"
    echo "============================================================"
    while read -r csv_path; do
        echo ""
        echo "$csv_path"
    done < "$empty_csv_file"
fi

# Cleanup
rm -f "$empty_csv_file"
