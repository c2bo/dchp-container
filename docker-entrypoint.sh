#!/usr/bin/env bash
# Replicates the dchp Makefile targets inside the container, replacing the
# `docker run danielfett/markdown2rfc` step with a direct mmark + xml2rfc call
# (that image's entrypoint does exactly that under the hood).
# done to avoid docker-in-docker problems
#
# Usage: docker-entrypoint.sh [all|html|docx|test|clean]
set -euo pipefail

DOC="${DOC:-digital-credentials-harmonized-presentation}"
SRC="draft/${DOC}.md"
TOOLS="tools"
BUILD="build"

target="${1:-all}"

need_src() {
  if [[ ! -f "$SRC" ]]; then
    echo "error: $SRC not found — run this container from the repo root, e.g.:" >&2
    echo '  docker run --rm -v "$PWD:/work" dchp-build' >&2
    exit 1
  fi
}

build_html() {
  need_src
  mkdir -p "$BUILD"
  echo "==> HTML Editor's Copy (mmark + xml2rfc)"
  mmark "$SRC" > "$BUILD/${DOC}.xml"
  xml2rfc --html "$BUILD/${DOC}.xml" -o "$BUILD/${DOC}-editors-copy.html"
  rm -f "$BUILD/${DOC}.xml"
  echo "HTML Editor's Copy -> $BUILD/${DOC}-editors-copy.html"
}

build_docx() {
  need_src
  mkdir -p "$BUILD"
  echo "==> ISO Word document (pandoc)"
  python "$TOOLS/mmark-to-pandoc.py" < "$SRC" > "$BUILD/${DOC}.pandoc.md"
  pandoc "$BUILD/${DOC}.pandoc.md" \
    --reference-doc="$TOOLS/template/iso-reference.docx" \
    --lua-filter="$TOOLS/iso-styles.lua" \
    -o "$BUILD/${DOC}.docx"
  rm -f "$BUILD/${DOC}.pandoc.md"
  echo "ISO Word document -> $BUILD/${DOC}.docx"
}

run_tests() {
  echo "==> Test suite"
  for t in "$TOOLS"/tests/test_*.py; do
    python "$t"
  done
}

case "$target" in
  all)   build_html; build_docx ;;
  html)  build_html ;;
  docx)  build_docx ;;
  test)  run_tests ;;
  clean) rm -rf "$BUILD" ;;
  *)
    echo "usage: [all|html|docx|test|clean]" >&2
    exit 2
    ;;
esac