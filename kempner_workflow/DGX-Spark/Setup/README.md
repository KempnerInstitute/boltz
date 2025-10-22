
# Boltz Server Setup

## Installation

Please refer to NVIDIA’s official documentation for detailed instructions:  
[NVIDIA Boltz2 Getting Started](https://docs.nvidia.com/nim/bionemo/boltz2/latest/getting-started.html#ngc-authentication)

### Export the API Key

Pass your NVIDIA API key to the Docker container as the `NGC_API_KEY` environment variable. This allows the container to download the required models and resources at startup.

If you’re not familiar with creating the `NGC_API_KEY` environment variable, you can set it in your terminal:

```bash
export NGC_API_KEY=<value>
```

To make the key available automatically at startup, add it to your shell configuration:

```bash
echo "export NGC_API_KEY=<value>" >> ~/.bashrc
```

### Docker Login to NGC

To pull the NIM container image from NVIDIA Container Registry (NGC), authenticate with:

```bash
echo "$NGC_API_KEY" | docker login nvcr.io --username '$oauthtoken' --password-stdin
```

- Use `$oauthtoken` as the username and your `NGC_API_KEY` as the password.  
- The `$oauthtoken` username indicates that you are authenticating with an API key, not a standard username/password.

## Start Boltz Server

```bash
./start_boltz2_server.sh
```

---

# ColabSearch and MMSeq2 Installation

## Download ColabFold Databases

```bash
mkdir -p databases && cd databases
export COLABFOLD_DBS_PATH=$(pwd -P)

wget https://steineggerlab.s3.amazonaws.com/colabfold/colabfold_envdb_202108.db.tar.gz
wget https://steineggerlab.s3.amazonaws.com/colabfold/uniref30_2302.db.tar.gz

tar -xzf colabfold_envdb_202108.db.tar.gz
tar -xzf uniref30_2302.db.tar.gz
```

## Create Index Files

```bash
cd databases

mmseqs createindex "colabfold_envdb_202108_db" tmp1 --remove-tmp-files 1 --split 1 --index-subset 2
mmseqs createindex "uniref30_2302_db" tmp2 --remove-tmp-files 1 --split 1 --index-subset 2
```

## Run ColabSearch

```bash
INPUT_FILE=<your_fasta_file>

mmseqs gpuserver $COLABFOLD_DBS_PATH/colabfold_envdb_202108_db --max-seqs 10000 --db-load-mode 0 & PID1=$!
mmseqs gpuserver $COLABFOLD_DBS_PATH/uniref30_2302_db --max-seqs 10000 --db-load-mode 0 & PID2=$!

time colabfold_search     --mmseqs mmseqs     --gpu 1     --gpu-server 1     --db1 uniref30_2302_db     --db-load-mode 2     $INPUT_FILE $COLABFOLD_DBS_PATH testout/ | tee testout.txt

kill -9 $PID1
kill -9 $PID2
```

**Notes:**
- Replace `<your_fasta_file>` with the path to your input FASTA file.  
- The `testout/` directory will contain the results of the ColabSearch run.  
- Running `kill -9` ensures the MMSeqs2 GPU servers are properly terminated after the search.
