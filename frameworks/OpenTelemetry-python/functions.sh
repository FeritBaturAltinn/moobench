
#!/bin/bash

MOOBENCH_CONFIGURATIONS="0 1 2"
TITLE[0]="No Instrumentation"
TITLE[1]="OpenTelemetry No Export"
TITLE[2]="OpenTelemetry Zipkin"

# Helper to inject Windows-safe filename
function updateConfigFilename {
    local filename=$1
    grep -v "output_filename" "$CONFIG_TEMPLATE" > "$CONFIG_FILE"
    echo "output_filename = $filename" >> "$CONFIG_FILE"
}

function runNoInstrumentation {
    k=$1; i=$2
    # Convert path to Windows format for Python
    CSV_FILE=$(cygpath -w "${RESULTS_DIR}/results-${i}-${RECURSION_DEPTH}-${k}.csv")
    
    echo " # Running Config $k (Iter $i)..."
    updateConfigFilename "$CSV_FILE"
    
    # Run Python directly
    python "$PYTHON_SCRIPT" "$CONFIG_FILE" > "${RESULTS_DIR}/output_${i}_${k}.txt" 2>&1
}

function runOpenTelemetryNoExport {
    k=$1; i=$2
    CSV_FILE=$(cygpath -w "${RESULTS_DIR}/results-${i}-${RECURSION_DEPTH}-${k}.csv")
    
    echo " # Running Config $k (Iter $i)..."
    updateConfigFilename "$CSV_FILE"
    
    export OTEL_TRACES_EXPORTER="none"
    
    python "$PYTHON_SCRIPT" "$CONFIG_FILE" > "${RESULTS_DIR}/output_${i}_${k}.txt" 2>&1
}

function runOpenTelemetryZipkin {
    k=$1; i=$2
    CSV_FILE=$(cygpath -w "${RESULTS_DIR}/results-${i}-${RECURSION_DEPTH}-${k}.csv")
    
    echo " # Running Config $k (Iter $i)..."
    updateConfigFilename "$CSV_FILE"
    
    export OTEL_TRACES_EXPORTER="zipkin"
    
    python "$PYTHON_SCRIPT" "$CONFIG_FILE" > "${RESULTS_DIR}/output_${i}_${k}.txt" 2>&1
}

function executeBenchmark {
   if [ -z "$NUM_OF_LOOPS" ]; then NUM_OF_LOOPS=1; fi
   for ((i=1; i<=NUM_OF_LOOPS; i++)); do
       echo "Starting Loop $i"
       for index in $MOOBENCH_CONFIGURATIONS; do
          case $index in
             0) runNoInstrumentation 0 $i ;;
             1) runOpenTelemetryNoExport 1 $i ;;
             2) runOpenTelemetryZipkin 2 $i ;;
          esac
          sleep 1
       done
   done
}