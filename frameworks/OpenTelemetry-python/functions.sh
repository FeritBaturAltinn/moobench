MOOBENCH_CONFIGURATIONS="0 1 2"
TITLE[0]="No Instrumentation"
TITLE[1]="OpenTelemetry No Export"
TITLE[2]="OpenTelemetry Zipkin"

function updateConfigFilename {
    local filename=$1
    # Overwrite the output_filename line in the config file
    grep -v "output_filename" "$CONFIG_TEMPLATE" > "$CONFIG_FILE"
    echo "output_filename = $filename" >> "$CONFIG_FILE"
}

# Windows vs Mac Paths
function get_os_path {
    local raw_path=$1
    # If cygpath exists (Windows Git Bash), convert it. Otherwise return as is (Mac/Linux).
    if command -v cygpath &>/dev/null; then
        cygpath -w "$raw_path"
    else
        echo "$raw_path"
    fi
}
function runNoInstrumentation {
    k=$1; i=$2

    RAW_CSV="${RESULTS_DIR}/results-${i}-${RECURSION_DEPTH}-${k}.csv"
    CSV_FILE=$(get_os_path "$RAW_CSV")
    LOG_FILE="${RESULTS_DIR}/output_${i}_${RECURSION_DEPTH}_${k}.txt"
    
    echo " # Running Config $k: ${TITLE[$k]} (Iter $i)"
    
    updateConfigFilename "$CSV_FILE"
    python3 "$PYTHON_SCRIPT" "$CONFIG_FILE" > "$LOG_FILE" 2>&1
}
function runOpenTelemetryNoExport {
    k=$1; i=$2
    
    RAW_CSV="${RESULTS_DIR}/results-${i}-${RECURSION_DEPTH}-${k}.csv"
    CSV_FILE=$(get_os_path "$RAW_CSV")
    LOG_FILE="${RESULTS_DIR}/output_${i}_${RECURSION_DEPTH}_${k}.txt"
    
    echo " # Running Config $k: ${TITLE[$k]} (Iter $i)"
    
    updateConfigFilename "$CSV_FILE"
    
    export OTEL_TRACES_EXPORTER="none"
    export OTEL_METRICS_EXPORTER="none"
    export OTEL_LOGS_EXPORTER="none"
   
    python3 "$PYTHON_SCRIPT" "$CONFIG_FILE" > "$LOG_FILE" 2>&1
}

function runOpenTelemetryZipkin {
    k=$1; i=$2
    
    RAW_CSV="${RESULTS_DIR}/results-${i}-${RECURSION_DEPTH}-${k}.csv"
    CSV_FILE=$(get_os_path "$RAW_CSV")
    LOG_FILE="${RESULTS_DIR}/output_${i}_${RECURSION_DEPTH}_${k}.txt"
    
    echo " # Running Config $k: ${TITLE[$k]} (Iter $i)"
    
    updateConfigFilename "$CSV_FILE"
    
    export OTEL_SERVICE_NAME="moobench-python"
    export OTEL_TRACES_EXPORTER="zipkin"
    export OTEL_EXPORTER_ZIPKIN_ENDPOINT="http://localhost:9411/api/v2/spans"
    export OTEL_METRICS_EXPORTER="none"
    export OTEL_LOGS_EXPORTER="none"
    
    python3 "$PYTHON_SCRIPT" "$CONFIG_FILE" > "$LOG_FILE" 2>&1
}

function executeBenchmark {
   if [ -z "$NUM_OF_LOOPS" ]; then NUM_OF_LOOPS=1; fi
   
   for ((i=1; i<=NUM_OF_LOOPS; i++))
   do
       echo "Starting Loop $i / $NUM_OF_LOOPS"
       for index in $MOOBENCH_CONFIGURATIONS
       do
          case $index in
             0) runNoInstrumentation 0 $i ;;
             1) runOpenTelemetryNoExport 1 $i ;;
             2) runOpenTelemetryZipkin 2 $i ;;
          esac
          sleep 1
       done
   done
}