#!/bin/bash

# Benchmark script for colabsearch_msa.sh
# Runs the script multiple times and collects statistics

SCRIPT="./colabsearch_msa.sh"
INPUT="6dw1_combined.fasta"
RUNS=10

# Create a separate directory for logs and outputs
BENCHMARK_DIR="benchmark_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BENCHMARK_DIR"

LOG_FILE="$BENCHMARK_DIR/benchmark_results.log"
RESULTS_FILE="$BENCHMARK_DIR/benchmark_summary.txt"

# Arrays to store results
declare -a execution_times
declare -a exit_codes
successful_runs=0
failed_runs=0

# Initialize log files
echo "Benchmark started at: $(date)" > "$LOG_FILE"
echo "Script: $SCRIPT $INPUT" >> "$LOG_FILE"
echo "Number of runs: $RUNS" >> "$LOG_FILE"
echo "=================================" >> "$LOG_FILE"

echo "Starting benchmark of $SCRIPT with $INPUT..."
echo "Running $RUNS iterations..."
echo ""

# Main benchmark loop
for i in $(seq 1 $RUNS); do
    echo "=== Run $i/$RUNS ===" | tee -a "$LOG_FILE"
    
    # Kill any existing mmseqs processes
    echo "Killing any existing mmseqs processes..." | tee -a "$LOG_FILE"
    sudo pkill -f mmseqs || true
    sleep 1  # Give processes time to terminate
    
    # Clear system caches before each run
    echo "Clearing system caches..." | tee -a "$LOG_FILE"
    #sudo sh -c 'sync && sudo tee /proc/sys/vm/drop_caches <<< 3'
    sudo sh -c 'sync; echo 3 > /proc/sys/vm/drop_caches'
    
    # Record start time
    start_time=$(date +%s.%N)
    
    # Run the script and capture exit code
    timeout 1800 $SCRIPT $INPUT >> "$LOG_FILE" 2>&1  # 30 minute timeout
    exit_code=$?
    
    # Record end time and calculate duration
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc -l)
    
    # Store results
    execution_times[$i]=$duration
    exit_codes[$i]=$exit_code
    
    if [ $exit_code -eq 0 ]; then
        successful_runs=$((successful_runs + 1))
        status="SUCCESS"
    elif [ $exit_code -eq 124 ]; then
        failed_runs=$((failed_runs + 1))
        status="TIMEOUT"
    else
        failed_runs=$((failed_runs + 1))
        status="FAILED"
    fi
    
    echo "Run $i: $status (Exit code: $exit_code, Duration: ${duration}s)" | tee -a "$LOG_FILE"
    
    # Move output directory for next run (preserve results)
    # The output directory name is based on input filename (basename without .fasta + _output)
    base=$(basename "$INPUT" .fasta)
    output_dir="${base}_output"
    if [ -d "$output_dir" ]; then
        mv "$output_dir" "$BENCHMARK_DIR/run_${i}_output"
    fi
    
    # Small delay between runs
    sleep 2
done

echo "" | tee -a "$LOG_FILE"
echo "=== BENCHMARK SUMMARY ===" | tee -a "$LOG_FILE"

# Calculate statistics
total_time=0
min_time=""
max_time=""
successful_times=()

for i in $(seq 1 $RUNS); do
    if [ ${exit_codes[$i]} -eq 0 ]; then
        time=${execution_times[$i]}
        successful_times+=($time)
        total_time=$(echo "$total_time + $time" | bc -l)
        
        if [ -z "$min_time" ] || [ $(echo "$time < $min_time" | bc -l) -eq 1 ]; then
            min_time=$time
        fi
        
        if [ -z "$max_time" ] || [ $(echo "$time > $max_time" | bc -l) -eq 1 ]; then
            max_time=$time
        fi
    fi
done

# Calculate average for successful runs
if [ $successful_runs -gt 0 ]; then
    avg_time=$(echo "scale=2; $total_time / $successful_runs" | bc -l)
else
    avg_time="N/A"
fi

# Success rate
success_rate=$(echo "scale=2; $successful_runs * 100 / $RUNS" | bc -l)

# Generate summary
{
    echo "Benchmark completed at: $(date)"
    echo ""
    echo "RESULTS:"
    echo "--------"
    echo "Total runs: $RUNS"
    echo "Successful runs: $successful_runs"
    echo "Failed runs: $failed_runs"
    echo "Success rate: ${success_rate}%"
    echo ""
    if [ $successful_runs -gt 0 ]; then
        echo "EXECUTION TIME STATISTICS (successful runs only):"
        echo "------------------------------------------------"
        printf "Average time: %.2f seconds (%.2f minutes)\n" $avg_time $(echo "$avg_time / 60" | bc -l)
        printf "Minimum time: %.2f seconds (%.2f minutes)\n" $min_time $(echo "$min_time / 60" | bc -l)
        printf "Maximum time: %.2f seconds (%.2f minutes)\n" $max_time $(echo "$max_time / 60" | bc -l)
        printf "Total time (successful): %.2f seconds (%.2f minutes)\n" $total_time $(echo "$total_time / 60" | bc -l)
    else
        echo "No successful runs - cannot calculate time statistics"
    fi
    echo ""
    echo "DETAILED RESULTS:"
    echo "----------------"
    for i in $(seq 1 $RUNS); do
        if [ ${exit_codes[$i]} -eq 0 ]; then
            status="SUCCESS"
        elif [ ${exit_codes[$i]} -eq 124 ]; then
            status="TIMEOUT"
        else
            status="FAILED"
        fi
        printf "Run %2d: %-7s (Exit: %3d, Time: %8.2fs)\n" $i "$status" ${exit_codes[$i]} ${execution_times[$i]}
    done
} | tee "$RESULTS_FILE" | tee -a "$LOG_FILE"

echo ""
echo "All benchmark results saved to directory: $BENCHMARK_DIR"
echo "Detailed logs saved to: $LOG_FILE"
echo "Summary saved to: $RESULTS_FILE"
base=$(basename "$INPUT" .fasta)
echo "Individual run outputs (${base}_output) saved in: $BENCHMARK_DIR/run_*_output/"
echo "Summary saved to: $RESULTS_FILE"
