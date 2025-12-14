#!/usr/bin/env bash
set -e

DRY_RUN=false

# -----------------------------
# Parse arguments
# -----------------------------
BUILD_TARGET=""
PASSTHROUGH_ARGS=()

for arg in "$@"; do
  case "$arg" in
    --build-target-src=*)
      BUILD_TARGET="${arg#*=}"
      ;;
    --)  # 無視する
      ;;
    *)
      PASSTHROUGH_ARGS+=("$arg")
      ;;
  esac
done


# ----------------------------------------
# Validation
# ----------------------------------------
if [[ -z "$BUILD_TARGET" ]]; then
  echo "Error: --build-target-src=src/... is required" >&2
  exit 1
fi

if [[ "$BUILD_TARGET" != src/* ]]; then
  echo "Error: --build-target-src must start with 'src/'" >&2
  exit 1
fi

if [[ ! -f "$BUILD_TARGET" ]]; then
  echo "Error: File not found: $BUILD_TARGET" >&2
  exit 1
fi

# -----------------------------
# Compute output paths
# -----------------------------
REL_PATH="${BUILD_TARGET#src/}"              # path/to/file.ts
OUT_PATH="dist/${REL_PATH%.ts}.mjs"    # dist/path/to/file.mjs
OUT_DIR=$(dirname "$OUT_PATH")         # dist/path/to

# ----------------------------------------
# Build command
# ----------------------------------------
BUILD_CMD="./scripts/build-ts.sh $@"
EXECUTE_CMD="node $OUT_PATH ${PASSTHROUGH_ARGS[*]}"

# ----------------------------------------
# Dry-run check
# ----------------------------------------
IS_DRY_RUN=false
for arg in "${PASSTHROUGH_ARGS[@]}"; do
  [[ "$arg" == "--dry-run" ]] && IS_DRY_RUN=true
done

# echo "[INFO] Build Target: $BUILD_TARGET"
# echo "[INFO] Output File : $OUT_PATH"
# echo "[INFO] Node Args   : ${PASSTHROUGH_ARGS[*]}"
# echo "[INFO] Build Cmd   : $BUILD_CMD"
echo "[INFO] Execute Cmd   : $EXECUTE_CMD"

# ----------------------------------------
# Dry-run: only show information
# ----------------------------------------
if $IS_DRY_RUN; then
  echo "[DRY-RUN] Build skipped"
  echo "[DRY-RUN] Execution skipped"
  exit 0
fi

# ----------------------------------------
# Build
# ----------------------------------------
echo "[INFO] Running build script..."
eval "$BUILD_CMD"

# -----------------------------
# Run output file
# -----------------------------
echo "[INFO] Running output file..."
eval "$EXECUTE_CMD"
