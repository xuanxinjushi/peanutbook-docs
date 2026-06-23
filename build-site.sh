#!/bin/bash
# Build MkDocs site from peanutbook-docs and deploy to ~/peanutbook.com
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
VENV="$ROOT/.venv"
SITE_DIR="$ROOT/site"
DEPLOY_DIR="/home/ubuntu/peanutbook.com"

if [[ ! -x "$VENV/bin/mkdocs" ]]; then
	python3 -m venv "$VENV"
	"$VENV/bin/pip" install -r "$ROOT/docs/requirements.txt"
fi

"$VENV/bin/mkdocs" build --strict -f "$ROOT/mkdocs.yml"
rsync -a --delete --exclude '.well-known' "$SITE_DIR/" "$DEPLOY_DIR/"
echo "Deployed to $DEPLOY_DIR (https://peanutbook.com/)"
