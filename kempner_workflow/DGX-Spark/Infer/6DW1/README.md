

# Inference

This example demonstrates how to run **Boltz2 inference** on a given FASTA file.  
The inference is performed **without MSA (Multiple Sequence Alignment)**.

## Scripts

- **`process_single_file.sh`** — Runs inference on a single FASTA file.

The scripts call the Python query script located at:
```bash
../Script/query_boltz.py
```
For example, 
```bash
python3 ../Script/query_boltz.py -f 6dw1.fasta
```

## Output Files

After running the inference, the following output files will be generated:

```
boltz2_C1_prediction_metadata_20251006_095625.json
boltz2_C1_prediction_metrics_20251006_095625.json
boltz2_C1_prediction_structure_1_20251006_095625_0.721.cif
boltz2_C1_prediction_summary_20251006_095625.txt
fasta_processing_summary_20251006_094845.txt
```

### Notes
- The file with the `.cif` extension contains the **predicted protein structure**.  
- The `fasta_processing_summary` file includes **summary results** such as the total **computation time**.
