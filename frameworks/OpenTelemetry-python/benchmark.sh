DIR=$(cd "$(dirname "$0")" && pwd)
source "$DIR/config.rc"

if [ -z "$RECURSION_DEPTH" ]; then export RECURSION_DEPTH=10; fi
if [ -z "$NUM_OF_LOOPS" ]; then export NUM_OF_LOOPS=1; fi

source "$DIR/functions.sh"

echo " # Preparing Environment..."

if [ -d "$VENV_DIR" ]; then rm -rf "$VENV_DIR"; fi
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

pip install -q --upgrade pip
pip install -q -r "$REQUIREMENTS_FILE"

# kieker needed for imports in the shared script
if [ ! -d "$KIEKER_DIR" ]; then
    git clone -q "$KIEKER_REPO_URL" "$KIEKER_DIR"
fi
pip install -q "$KIEKER_DIR"

opentelemetry-bootstrap -a install



executeBenchmark

deactivate
rm "$CONFIG_FILE" 2>/dev/null
echo " # Completed. Results are in $RESULTS_DIR"