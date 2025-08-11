# Protein Folding on CPU — Kempner Workflow

This directory provides an example workflow for running **Boltz-based protein folding using CPU-only resources**. It is optimized for environments without GPU access, providing reproducible and accessible structure prediction.

---

##  Overview

Execute a protein structure prediction pipeline on CPU using the Boltz framework. This workflow demonstrates how to:

- Runs the Colabfold search on the locally on the Kempner Cluster
- The MSA file (.a3m extention) is used by Boltz for the next stage prediction

---

##  Prerequisites

- Python ≥ 3.10
- Boltz library
- Colabfold
- Boltz database
- Colabfold database

All of these are pre-built on the cluster. It is optional to install them in your space. 

  ---

##  Input Format

Create input fasta file. **Important** For now, the pipeline only supports fasta format. 

example
```
>A|protein|
QLEDSEVEAVAKGLEEMYANGVTEDNFKNYVKNNFAQQEISSVEEELNVNISDSCVANKIKDEFFAMISISAIVKAAQKKAWKELAVTVLRFAKANGLKTNAIIVAGQLALWAVQCG
```


---



##  Running the Workflow

### 1. Local Execution

```bash
cd kempner_workflow/protein_fold_cpu
python run_fold_cpu.py --input <input.yaml> --output <output_dir>
```

### 2. Cluster Execution (e.g., SLURM)

If your system uses job scheduling:

```bash
sbatch run_fold_cpu.slurm
```

Make sure to update job resource settings (e.g., CPU cores, memory) as needed.

---

##  Output

Output from Colabfold search that generates the msa file. 
```
Output_colabfold/local_search_cpu/
└── A_protein_.a3m
```
Boltz workflow outputs:

- 3D structures (typically PDB files) of the predicted protein conformations
- Logs detailing runtime performance and runtime errors
- Optional metrics for folding quality, if implemented
```
Output_boltz/prot_pipeline_cpu
└── boltz_results_prot_pipeline
    ├── lightning_logs
    │   └── version_29566540
    │       ├── events.out.tfevents.1754934413.holygpu8a11302.rc.fas.harvard.edu
    │       └── hparams.yaml
    ├── msa
    ├── predictions
    │   └── prot_pipeline
    │       ├── confidence_prot_pipeline_model_0.json
    │       ├── pae_prot_pipeline_model_0.npz
    │       ├── pde_prot_pipeline_model_0.npz
    │       ├── plddt_prot_pipeline_model_0.npz
    │       └── prot_pipeline_model_0.cif
    └── processed
        ├── constraints
        │   └── prot_pipeline.npz
        ├── manifest.json
        ├── mols
        │   └── prot_pipeline.pkl
        ├── msa
        │   └── prot_pipeline_0.npz
        ├── records
        │   └── prot_pipeline.json
        ├── structures
        │   └── prot_pipeline.npz
        └── templates
```   


---

