#!/bin/bash
# Build MkDocs site from peanutbook-docs.
#
# Dual publishing (same docs, two hosts):
#   1. peanutbook.com  — run:  ./build-site.sh
#   2. readthedocs.io  — push peanutbook-docs to git; RTD rebuilds automatically
#
# site_url in mkdocs.yml uses READTHEDOCS_CANONICAL_URL on RTD, else peanutbook.com.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
VENV="$ROOT/.venv"
SITE_DIR="$ROOT/site"
DEPLOY_DIR="/home/ubuntu/peanutbook.com"
TARGET="${1:-deploy}"

if [[ ! -x "$VENV/bin/mkdocs" ]]; then
	python3 -m venv "$VENV"
	"$VENV/bin/pip" install -r "$ROOT/docs/requirements.txt"
fi

case "$TARGET" in
	deploy|peanutbook|peanutbook.com)
		unset READTHEDOCS_CANONICAL_URL
		OUT="$SITE_DIR"
		"$VENV/bin/mkdocs" build --strict -f "$ROOT/mkdocs.yml" -d "$OUT"
		rsync -a --delete --exclude '.well-known' "$OUT/" "$DEPLOY_DIR/"
		echo "Deployed to $DEPLOY_DIR (https://peanutbook.com/)"
		echo "For Read the Docs: git push peanutbook-docs ? https://peanutbook.readthedocs.io/en/latest/"
		;;
	rtd|readthedocs)
		export READTHEDOCS_CANONICAL_URL="https://peanutbook.readthedocs.io/en/latest/"
		OUT="$ROOT/site-rtd"
		"$VENV/bin/mkdocs" build --strict -f "$ROOT/mkdocs.yml" -d "$OUT"
		echo "Built RTD preview at $OUT (https://peanutbook.readthedocs.io/en/latest/)"
		echo "Not deployed — push to git to update the live Read the Docs site."
		;;
	both)
		"$0" deploy
		"$0" rtd
		;;
	*)
		echo "Usage: $0 [deploy|rtd|both]" >&2
		exit 1
		;;
esac
