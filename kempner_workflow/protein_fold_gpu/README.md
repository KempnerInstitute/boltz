

# Protein Folding on GPU 

This directory provides an example workflow for running **Boltz-based protein folding using GPU resources**.  
It is designed for environments with GPU access, offering reproducible and accessible protein structure prediction.

---

## Overview

This workflow executes a protein structure prediction pipeline on GPU using the **Boltz** framework. It demonstrates:

- Running **ColabFold** search locally on the Kempner Cluster  
- Using the generated MSA file (`.a3m` extension) as input to **Boltz** for structure prediction

---

## Prerequisites

- Python ≥ 3.10
- cuda and cudann libraries
- **Boltz** library  
- **ColabFold**  
- **Boltz database**  
- **ColabFold database**  

> **Note:** All of these are pre-installed on the Kempner Cluster.  
> Installation in your own space is optional.

---

## Input Format

Create an input FASTA file.  
**Important:** Currently, the pipeline supports only FASTA format.

**Example:**
```fasta
>A|protein|
QLEDSEVEAVAKGLEEMYANGVTEDNFKNYVKNNFAQQEISSVEEELNVNISDSCVANKIKDEFFAMISISAIVKAAQKKAWKELAVTVLRFAKANGLKTNAIIVAGQLALWAVQCG
```

---

## Running the Workflow

Open the file file `boltz_single_pipeline_gpu.slrm` and define the variable with the correct input fasta filename, and the GPU specifications. 
```
INPUT_FASTA="input.fa"
export CUDA_VISIBLE_DEVICES=0
export NUM_GPU_DEVICES=1
```
Make sure you are setting up the GPU device specficiations properly. For using two GPUs, the GPU device specification is defined as CUDA_VISIBLE_DEVICES=0,1 and NUM_GPU_DEVICES=2.

To submit the Slurm batch job:

```bash
sbatch boltz_single_pipeline_gpu.slrm
```

Update the SLURM script to adjust job resources (e.g., GPU. CPU cores, memory) as needed. You need to add partition name and account name. 

---

## Output

### 1. ColabFold Search Output
Generates the MSA file:
```
Output_colabfold/local_search_gpu/
└── A_protein_.a3m
```

### 2. Boltz Workflow Output
Includes:
- 3D structures (PDB/CIF) of predicted protein conformations  
- Logs of runtime performance and errors  
- Folding quality metrics (if implemented)  

Example structure:
```
Output_boltz/prot_pipeline_gpu
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

