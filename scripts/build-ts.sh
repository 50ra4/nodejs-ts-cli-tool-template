#!/usr/bin/env bash
set -e

# ----------------------------------------
# Parse arguments
# ----------------------------------------
BUILD_TARGET=""
PASSTHROUGH_ARGS=()

for arg in "$@"; do
  case "$arg" in
    --build-target-src=*)
      BUILD_TARGET="${arg#*=}"
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

# ----------------------------------------
# Determine output path
# ----------------------------------------
RELATIVE_PATH="${BUILD_TARGET#src/}"              # api/user.ts
OUT_PATH="dist/${RELATIVE_PATH%.*}.mjs"           # dist/api/user.mjs
OUT_DIR=$(dirname "$OUT_PATH")

# ----------------------------------------
# Build command
# ----------------------------------------
BUILD_CMD=$(cat <<EOF
esbuild "$BUILD_TARGET" \
  --bundle \
  --splitting=false \
  --minify \
  --keep-names \
  --sourcemap=inline \
  --platform=node \
  --format=esm \
  --out-extension:.js=.mjs \
  --banner:js='import {createRequire} from "module";import url from "url";const require=createRequire(import.meta.url);const __filename=url.fileURLToPath(import.meta.url);const __dirname=url.fileURLToPath(new URL(".",import.meta.url));' \
  --alias:@=src \
  --entry-names='[name]' \
  --outdir="$OUT_DIR"
EOF
)

# ----------------------------------------
# Dry-run check
# ----------------------------------------
IS_DRY_RUN=false
for arg in "${PASSTHROUGH_ARGS[@]}"; do
  [[ "$arg" == "--dry-run" ]] && IS_DRY_RUN=true
done

echo "[INFO] Build Target: $BUILD_TARGET"
echo "[INFO] Output File : $OUT_PATH"
echo "[INFO] Build Cmd   : $BUILD_CMD"
echo "[INFO] Node Args   : ${PASSTHROUGH_ARGS[*]}"

# ----------------------------------------
# Dry-run: only show information
# ----------------------------------------
if $IS_DRY_RUN; then
  echo "[DRY-RUN] Build skipped"
  echo "[DRY-RUN] Execution skipped"
  exit 0
fi

# ----------------------------------------
# Execute build
# ----------------------------------------
echo "[INFO] Running esbuild..."
eval "$BUILD_CMD"

# ----------------------------------------
# Output built file for piping
# ----------------------------------------
echo "[INFO] Outputting script via cat (pipe into node)"
echo "[INFO] Example: npm run execute ... | node"
