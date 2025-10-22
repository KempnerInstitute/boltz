#!/bin/bash

# Check if batch number is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <batch_number>"
    echo "Example: $0 001"
    echo "Available batches:"
    ls -1 / | grep batch_ | sed 's/batch_/  /'
    exit 1
fi

BATCH_NUM=$1
ORGANIZED_DIR="fasta_dir/"
BATCH_DIR="$ORGANIZED_DIR/batch_$BATCH_NUM"
SCRIPT_PATH="../Script/query_boltz.py"
OUTPUT_DIR="output_results/batch_$BATCH_NUM"

# Check if batch directory exists
if [ ! -d "$BATCH_DIR" ]; then
    echo "Error: Batch directory $BATCH_DIR does not exist"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "Processing batch_$BATCH_NUM..."

# Counter for files in this batch
counter=0
total=$(find "$BATCH_DIR" -name "*.fasta" | wc -l)

echo "Found $total files in batch_$BATCH_NUM"

# Process each FASTA file in this batch
for fasta_file in "$BATCH_DIR"/*.fasta; do
    if [ -f "$fasta_file" ]; then
        counter=$((counter + 1))
        filename=$(basename "$fasta_file")
        
        echo "Processing $counter/$total: $filename"
        
        # Run the command
        python3 "$SCRIPT_PATH" -f "$fasta_file"
        
        # Check if the command was successful
        if [ $? -ne 0 ]; then
            echo "Error processing $fasta_file"
            echo "$fasta_file" >> "$OUTPUT_DIR/failed_files.txt"
        else
            echo "$fasta_file" >> "$OUTPUT_DIR/processed_files.txt"
        fi
    fi
done

echo "Completed batch_$BATCH_NUM: $counter files processed"
