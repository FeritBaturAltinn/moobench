MOOBENCH_CONFIGURATIONS="0 1 2"
TITLE[0]="No Instrumentation"
TITLE[1]="OpenTelemetry No Export"
TITLE[2]="OpenTelemetry Zipkin"

# Helper to inject filename
function updateConfigFilename {
    local filename=$1
    grep -v "output_filename" "$CONFIG_TEMPLATE" > "$CONFIG_FILE"
    echo "output_filename = $filename" >> "$CONFIG_FILE"
}

# Helper for Paths
function get_os_path {
    local raw_path=$1
    if command -v cygpath &>/dev/null; then cygpath -w "$raw_path"; else echo "$raw_path"; fi
}

function run_benchmark_logic {
    local k=$1
    local i=$2

    local RES_DIR="${RESULTS_DIR}/../results-OpenTelemetry-python"
    mkdir -p "$RES_DIR"
    
    local RAW_CSV="${RES_DIR}/raw-${i}-${RECURSION_DEPTH}-${k}.csv"
    local CSV_FILE=$(get_os_path "$RAW_CSV")
    local LOG_FILE="${RES_DIR}/output-raw-${i}-${RECURSION_DEPTH}-${k}.txt"
    
    echo " # Running Config $k: ${TITLE[$k]} (Iter $i)"
    
    updateConfigFilename "$CSV_FILE"
    
    # Config specific env vars
    if [ "$k" -eq "0" ]; then
        export ENABLE_OTEL="false"
    elif [ "$k" -eq "1" ]; then
        export ENABLE_OTEL="true"
        export OTEL_TRACES_EXPORTER="none"
        export OTEL_METRICS_EXPORTER="none"
        export OTEL_LOGS_EXPORTER="none"
    elif [ "$k" -eq "2" ]; then
        export ENABLE_OTEL="true"
        export OTEL_SERVICE_NAME="moobench-python"
        export OTEL_TRACES_EXPORTER="zipkin"
        export OTEL_EXPORTER_ZIPKIN_ENDPOINT="http://localhost:9411/api/v2/spans"
        export OTEL_METRICS_EXPORTER="none"
        export OTEL_LOGS_EXPORTER="none"
    fi
    
    python3 "$PYTHON_SCRIPT" "$CONFIG_FILE" > "$LOG_FILE" 2>&1
}

function executeBenchmark {
   if [ -z "$NUM_OF_LOOPS" ]; then NUM_OF_LOOPS=1; fi
   
   for ((i=1; i<=NUM_OF_LOOPS; i++))
   do
       echo "Starting Loop $i / $NUM_OF_LOOPS"
       for index in $MOOBENCH_CONFIGURATIONS
       do
          run_benchmark_logic $index $i
          sleep 1
       done
   done
}