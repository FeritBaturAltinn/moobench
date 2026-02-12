DIR=$(cd "$(dirname "$0")" && pwd)
source "$DIR/config.rc"

source "$DIR/functions.sh"
source "$DIR/../../common-functions.sh"

echo " # Preparing Environment..."
if [ -d "$VENV_DIR" ]; then rm -rf "$VENV_DIR"; fi

# For windows compatibility
if command -v python3 &>/dev/null; then
    PYTHON_EXE=python3
else
    PYTHON_EXE=python
fi

$PYTHON_EXE -m venv "$VENV_DIR"


if [ -f "$VENV_DIR/Scripts/activate" ]; then
    source "$VENV_DIR/Scripts/activate"
else
    source "$VENV_DIR/bin/activate"
fi

pip install -q --upgrade pip
pip install -q -r "$REQUIREMENTS_FILE"
opentelemetry-bootstrap -a install

cp "$CONFIG_TEMPLATE" "$CONFIG_FILE"
executeAllLoops

deactivate
rm "$CONFIG_FILE" 2>/dev/null
echo " # Completed."