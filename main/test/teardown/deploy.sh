#!/bin/bash
set -euo pipefail

echo "teardown test! $RENDER_DIR"
shrenddLog "main/test/teardown/deploy: teardown test: rm ${RENDER_DIR}"
rm -rf "$RENDER_DIR"