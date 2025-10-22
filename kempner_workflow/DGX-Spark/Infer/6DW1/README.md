# Inference

This example demonstrates how to run **Boltz2 inference** on a given FASTA file.  
The inference is performed **without MSA (Multiple Sequence Alignment)**.

## Scripts

- **`process_single_file.sh`** — Runs inference on a single FASTA file.

```bash
 python3 ../Script/query_boltz.py -f 6dw1.fasta 
```

- **`process_single_batch.sh`** — Runs inference on all FASTA files within a specified directory.  

Both scripts call the Python query script located at:  
```bash
../Script/query_boltz.py
```

The output files are

boltz2_C1_prediction_metadata_20251006_095625.json
boltz2_C1_prediction_metrics_20251006_095625.json
boltz2_C1_prediction_structure_1_20251006_095625_0.721.cif
boltz2_C1_prediction_summary_20251006_095625.txt
fasta_processing_summary_20251006_094845.txt

The file with extension `.cif` is the predicted structure. The file fasta_processing_summary contains the summary results including the computing time. 
