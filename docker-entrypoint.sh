#!/usr/bin/env bash
# Replicates the dchp Makefile targets inside the container, replacing the
# `docker run danielfett/markdown2rfc` step with a direct mmark + xml2rfc call
# (that image's entrypoint does exactly that under the hood).
# done to avoid docker-in-docker problems
#
# Usage:
#   docker-entrypoint.sh INPUT.md [all|html|docx]   build from a markdown file
#   docker-entrypoint.sh [all|html|docx|test|clean] build draft/$DOC.md (legacy)
#
# Output files (.html editor's copy and/or .docx) are written to the current
# working directory. Mount it into the container, e.g.:
#   docker run --rm -v "$PWD:/work" dchp-build spec.md
set -euo pipefail

# Build tools (mmark-to-pandoc.py, iso-styles.lua, template/iso-reference.docx)
# are baked into the image; override with TOOLS=... to point at your own copy.
TOOLS="${TOOLS:-/opt/dchp/tools}"

# Output files land in the current working directory by default.
OUT="${OUT:-.}"

usage() {
  cat >&2 <<'EOF'
Usage:
  docker-entrypoint.sh INPUT.md [all|html|docx]   build from a markdown file
  docker-entrypoint.sh [all|html|docx|test|clean] build draft/$DOC.md (legacy)

Output (.html editor's copy and/or .docx) is written to the current directory.
Example:
  docker run --rm -v "$PWD:/work" dchp-build spec.md
EOF
}

# Separate the optional input path from the optional target keyword; either may
# be given in either order, and both are optional.
SRC=""
target="all"
for arg in "$@"; do
  case "$arg" in
    all|html|docx|test|clean) target="$arg" ;;
    -h|--help) usage; exit 0 ;;
    *)
      if [[ -n "$SRC" ]]; then
        echo "error: more than one input file given ('$SRC' and '$arg')" >&2
        usage
        exit 2
      fi
      SRC="$arg"
      ;;
  esac
done

# No path given: fall back to the repo's draft/ layout for backward compatibility.
DOC="${DOC:-digital-credentials-harmonized-presentation}"
if [[ -z "$SRC" ]]; then
  SRC="draft/${DOC}.md"
else
  DOC="$(basename "$SRC")"
  DOC="${DOC%.md}"
fi

need_src() {
  if [[ ! -f "$SRC" ]]; then
    echo "error: input '$SRC' not found — mount its directory into the container, e.g.:" >&2
    echo '  docker run --rm -v "$PWD:/work" dchp-build spec.md' >&2
    exit 1
  fi
}

build_html() {
  need_src
  mkdir -p "$OUT"
  echo "==> HTML Editor's Copy (mmark + xml2rfc)"
  local tmp
  tmp="$(mktemp -d)"
  mmark "$SRC" > "$tmp/${DOC}.xml"
  xml2rfc --html "$tmp/${DOC}.xml" -o "$OUT/${DOC}-editors-copy.html"
  rm -rf "$tmp"
  echo "HTML Editor's Copy -> $OUT/${DOC}-editors-copy.html"
}

build_docx() {
  need_src
  mkdir -p "$OUT"
  echo "==> ISO Word document (pandoc)"
  local tmp
  tmp="$(mktemp -d)"
  python "$TOOLS/mmark-to-pandoc.py" < "$SRC" > "$tmp/${DOC}.pandoc.md"
  pandoc "$tmp/${DOC}.pandoc.md" \
    --reference-doc="$TOOLS/template/iso-reference.docx" \
    --lua-filter="$TOOLS/iso-styles.lua" \
    -o "$OUT/${DOC}.docx"
  rm -rf "$tmp"
  echo "ISO Word document -> $OUT/${DOC}.docx"
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
  clean) rm -f "$OUT/${DOC}-editors-copy.html" "$OUT/${DOC}.docx" ;;
  *)
    usage
    exit 2
    ;;
esac
