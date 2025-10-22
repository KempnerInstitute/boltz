export NGC_API_KEY=$NGC_APIKEY
export LOCAL_NIM_CACHE=~/.cache/nim
mkdir -p ${LOCAL_NIM_CACHE}
chmod 777 ${LOCAL_NIM_CACHE}
docker run --rm --gpus=all \
     --shm-size=16G \
    -e NGC_API_KEY \
    -e NIM_HTTP_API_PORT=8000 \
    -v $LOCAL_NIM_CACHE:/opt/nim/.cache \
    -p 8000:8000 \
    nvcr.io/nim/mit/boltz2:1.3.0
