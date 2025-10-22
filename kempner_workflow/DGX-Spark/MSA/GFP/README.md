# MSA Benchmark

## Files

- **`6dw1.fasta`** — FASTA file containing the amino acid sequence of the **6DW1** protein.
- **`colabsearch_msa.sh`** — Script that executes the **ColabSearch** workflow step by step.
- **`run_benchmark.sh`** — Runs a benchmark of *N* sample runs to generate statistics on success rates.

## Usage

To test different FASTA files or change the number of runs, edit the variables in **`run_benchmark.sh`**:

```bash
INPUT="gfp.fasta"
RUNS=10
```

Executing run_benchmark.sh will create a directory named benchmark_{TIMESTAMP}, which contains all results, including timing information and the generated A3M files.

