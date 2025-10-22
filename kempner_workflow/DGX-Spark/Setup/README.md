
# Boltz Server Setup 

### Installation 

Please refer NVIDIA's page for a detailed documentation in here: https://docs.nvidia.com/nim/bionemo/boltz2/latest/getting-started.html#ngc-authentication

Export the API key
Pass the value of the API key to the docker run command in the next section as the NGC_API_KEY environment variable to download the appropriate models and resources when starting the NIM.

If you’re not familiar with how to create the NGC_API_KEY environment variable, the simplest way is to export it in your terminal:

export NGC_API_KEY=<value>
Run one of the following commands to make the key available at startup:


echo "export NGC_API_KEY=<value>" >> ~/.bashrc


### Docker Login to NGC
To pull the NIM container image from NGC, first authenticate with the NVIDIA Container Registry with the following command:

echo "$NGC_API_KEY" | docker login nvcr.io --username '$oauthtoken' --password-stdin
Use $oauthtoken as the username and NGC_API_KEY as the password. The $oauthtoken username is a special name that indicates that you will authenticate with an API key and not a username and password.


## Start Boltz Server

```bash
./start_boltz2_server.sh
```

# Colabsearch and MMSeq2 Installation. 

### download colabfold databases
mkdir -p databases && cd databases
export COLABFOLD_DBS_PATH=$(pwd -P)
wget https://steineggerlab.s3.amazonaws.com/colabfold/colabfold_envdb_202108.db.tar.gz
wget https://steineggerlab.s3.amazonaws.com/colabfold/uniref30_2302.db.tar.gz
tar -xzf colabfold_envdb_202108.db.tar.gz
tar -xzf uniref30_2302.db.tar.gz

### create the index files
cd databases
mmseqs createindex "colabfold_envdb_202108_db" tmp1 --remove-tmp-files 1 --split 1 --index-subset 2
mmseqs createindex "uniref30_2302_db" tmp2 --remove-tmp-files 1 --split 1 --index-subset 2

### simple script to run the colabsearch

INPUT_FILE=
mmseqs gpuserver $COLABFOLD_DBS_PATH/colabfold_envdb_202108_db --max-seqs 10000 --db-load-mode 0 & PID1=$!
mmseqs gpuserver $COLABFOLD_DBS_PATH/uniref30_2302_db --max-seqs 10000 --db-load-mode 0 & PID2=$!

time colabfold_search --mmseqs mmseqs --gpu 1 --gpu-server 1 --db1 uniref30_2302_db --db-load-mode 2 $INPUT_FILE  $COLABFOLD_DBS_PATH testout/ | tee testout.txt

kill -9 $PID1
kill -9 $PID2

