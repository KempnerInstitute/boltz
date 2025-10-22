

# GFP Inference

This example demonstrates how to run **Boltz2 inference** on a given FASTA file.  
The inference is performed **without MSA (Multiple Sequence Alignment)**.

## Scripts

- **`process_single_file.sh`** — Runs inference on a single FASTA file.  
- **`process_single_batch.sh`** — Runs inference on all FASTA files within a specified directory.  

Both scripts call the Python query script located at:  
```bash
../Script/query_boltz.py
```

## Example Usage

### Run inference on a single FASTA file
bash process_single_file.sh input.fasta

### Run inference on all FASTA files in a directory
bash process_single_batch.sh /path/to/fasta_directory
