#!/bin/bash



# Parse command line arguments
INPUT_FILE="$1"
OUTPUT_DIR="$2"

# Check if input file is provided
if [ -z "$INPUT_FILE" ]; then
    echo "Usage: $0 <input_fasta_file> [output_directory]"
    echo "Example: $0 6dw1_1.fasta"
    echo "Example: $0 6dw1_1.fasta custom_output"
    exit 1
fi

# Set default output directory if not provided
if [ -z "$OUTPUT_DIR" ]; then
    # Get basename without extension and add _output suffix
    base=$(basename "$INPUT_FILE" .fasta)
    OUTPUT_DIR="${base}_output"
fi

echo "Input file: $INPUT_FILE"
echo "Output directory: $OUTPUT_DIR"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

source /home/bala/Work/MSA_Work/venv/bin/activate
# Setup logging
LOG_FILE="msa_inference.log"
TIMING_FILE="msa_inference_timing.log"
exec > >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

# Function to log with timestamp
log_step() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to record timing
record_time() {
    local step_name="$1"
    local start_time="$2"
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $step_name: ${duration}s (Start: $(date -d @$start_time '+%H:%M:%S'), End: $(date -d @$end_time '+%H:%M:%S'))" >> "$TIMING_FILE"
    log_step "$step_name completed in ${duration} seconds"
}

# Initialize timing log
echo "=== MSA Inference Timing Log ===" > "$TIMING_FILE"
echo "Started: $(date '+%Y-%m-%d %H:%M:%S')" >> "$TIMING_FILE"
echo "" >> "$TIMING_FILE"

log_step "=== Starting MSA Inference Pipeline ==="
SCRIPT_START=$(date +%s)

export COLABFOLD_DBS_PATH=/home/bala/Work/MSA_Work/databases
log_step "Database path set to: $COLABFOLD_DBS_PATH"

# Step 1: Start ColabFold EnvDB GPU Server
log_step "Step 1: Starting ColabFold EnvDB GPU Server..."
STEP1_START=$(date +%s)

mmseqs gpuserver $COLABFOLD_DBS_PATH/colabfold_envdb_202108_db --max-seqs 10000 --db-load-mode 0 & PID1=$!

log_step "ColabFold EnvDB GPU Server started with PID: $PID1"
record_time "ColabFold EnvDB GPU Server Startup" $STEP1_START

# Step 2: Wait for first server to initialize
log_step "Step 2: Waiting 30 seconds for ColabFold EnvDB server initialization..."
STEP2_START=$(date +%s)
sleep 30
record_time "ColabFold EnvDB Server Wait" $STEP2_START

# Step 3: Start UniRef30 GPU Server
log_step "Step 3: Starting UniRef30 GPU Server..."
STEP3_START=$(date +%s)
mmseqs gpuserver $COLABFOLD_DBS_PATH/uniref30_2302_db --max-seqs 10000 --db-load-mode 0 & PID2=$!

log_step "UniRef30 GPU Server started with PID: $PID2"
record_time "UniRef30 GPU Server Startup" $STEP3_START

# Step 4: Wait for second server to initialize
log_step "Step 4: Waiting 30 seconds for UniRef30 server initialization..."
STEP4_START=$(date +%s)
sleep 30
record_time "UniRef30 Server Wait" $STEP4_START

log_step "Input file: $INPUT_FILE"
log_step "Output directory: $OUTPUT_DIR"

# Step 5: Run ColabFold Search
log_step "Step 5: Starting ColabFold search..."
STEP5_START=$(date +%s)
if [ -f "$INPUT_FILE" ]; then
    log_step "Running: colabfold_search --mmseqs mmseqs --gpu 1 --gpu-server 1 $INPUT_FILE $COLABFOLD_DBS_PATH $OUTPUT_DIR/"
    colabfold_search --mmseqs mmseqs --gpu 1 --gpu-server 1 --db1 uniref30_2302_db --db-load-mode 2 $INPUT_FILE  $COLABFOLD_DBS_PATH $OUTPUT_DIR/ 2>&1
    
    SEARCH_EXIT_CODE=$?
    log_step "ColabFold search completed with exit code: $SEARCH_EXIT_CODE"
else
    log_step "ERROR: Input file $INPUT_FILE not found!"
    SEARCH_EXIT_CODE=1
fi
record_time "ColabFold Search Execution" $STEP5_START

# Step 6: Cleanup - Kill GPU servers
log_step "Step 6: Cleaning up GPU servers..."
STEP6_START=$(date +%s)
log_step "Killing ColabFold EnvDB GPU Server (PID: $PID1)..."
kill -9 $PID1 2>/dev/null && log_step "ColabFold EnvDB GPU Server terminated" || log_step "Failed to terminate ColabFold EnvDB GPU Server"
log_step "Killing UniRef30 GPU Server (PID: $PID2)..."
kill -9 $PID2 2>/dev/null && log_step "UniRef30 GPU Server terminated" || log_step "Failed to terminate UniRef30 GPU Server"
record_time "GPU Servers Cleanup" $STEP6_START

# Final timing summary
SCRIPT_END=$(date +%s)
TOTAL_DURATION=$((SCRIPT_END - SCRIPT_START))

log_step "=== MSA Inference Pipeline Completed ==="
log_step "Total execution time: ${TOTAL_DURATION} seconds ($(($TOTAL_DURATION / 60))m $(($TOTAL_DURATION % 60))s)"
log_step "Search exit code: $SEARCH_EXIT_CODE"

# Add final summary to timing file
echo "" >> "$TIMING_FILE"
echo "=== SUMMARY ===" >> "$TIMING_FILE"
echo "Total Pipeline Duration: ${TOTAL_DURATION}s ($(($TOTAL_DURATION / 60))m $(($TOTAL_DURATION % 60))s)" >> "$TIMING_FILE"
echo "Completed: $(date '+%Y-%m-%d %H:%M:%S')" >> "$TIMING_FILE"
echo "Final Exit Code: $SEARCH_EXIT_CODE" >> "$TIMING_FILE"

exit $SEARCH_EXIT_CODE
