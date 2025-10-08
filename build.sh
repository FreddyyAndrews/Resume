#!/usr/bin/env bash
set -Eeuo pipefail

# Build LaTeX to PDF with latexmk if available, otherwise with the chosen engine.
# Usage:
#   ./build.sh [-f main.tex] [-e {pdflatex|xelatex|lualatex}] [-o build_dir] [-c] [-h]
# Defaults: engine=xelatex, outdir=./build, auto-detect main.tex or resume.tex or a single *.tex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

ENGINE="xelatex"
OUTDIR="$SCRIPT_DIR/build"
MAIN_TEX=""
DO_CLEAN=0

usage() {
  echo "Usage: $(basename "$0") [-f file.tex] [-e pdflatex|xelatex|lualatex] [-o outdir] [-c] [-h]"
  echo "  -f  Main .tex file (if omitted, tries resume.tex, main.tex, or the only .tex in dir)"
  echo "  -e  Engine (default: xelatex)"
  echo "  -o  Output directory (default: ./build)"
  echo "  -c  Clean auxiliary files in output directory and exit"
  echo "  -h  Help"
}

while getopts ":f:e:o:ch" opt; do
  case "$opt" in
    f) MAIN_TEX="$OPTARG" ;;
    e) ENGINE="$OPTARG" ;;
    o) OUTDIR="$OPTARG" ;;
    c) DO_CLEAN=1 ;;
    h) usage; exit 0 ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage; exit 2 ;;
    :)  echo "Option -$OPTARG requires an argument." >&2; usage; exit 2 ;;
  esac
done

case "$ENGINE" in
  pdflatex|xelatex|lualatex) : ;;
  *) echo "Unsupported engine: $ENGINE (use pdflatex|xelatex|lualatex)"; exit 2 ;;
esac

mkdir -p "$OUTDIR"

clean_aux() {
  # Remove typical aux files in OUTDIR; keep PDFs
  find "$OUTDIR" -maxdepth 1 -type f \( \
    -name "*.aux" -o -name "*.bbl" -o -name "*.bcf" -o -name "*.blg" -o \
    -name "*.fdb_latexmk" -o -name "*.fls" -o -name "*.log" -o -name "*.out" -o \
    -name "*.run.xml" -o -name "*.toc" -o -name "*.synctex.gz" \
  \) -delete || true
}

if [[ $DO_CLEAN -eq 1 ]]; then
  clean_aux
  echo "Cleaned auxiliary files in: $OUTDIR"
  exit 0
fi

if [[ -z "$MAIN_TEX" ]]; then
  if [[ -f "resume.tex" ]]; then
    MAIN_TEX="resume.tex"
  elif [[ -f "Resume.tex" ]]; then
    MAIN_TEX="Resume.tex"
  elif [[ -f "main.tex" ]]; then
    MAIN_TEX="main.tex"
  else
    mapfile -t TEX_FILES < <(find . -maxdepth 1 -type f -name "*.tex" -printf "%f\n")
    if (( ${#TEX_FILES[@]} == 1 )); then
      MAIN_TEX="${TEX_FILES[0]}"
    else
      echo "Could not auto-detect a single .tex file. Use -f file.tex"
      exit 2
    fi
  fi
fi

if [[ ! -f "$MAIN_TEX" ]]; then
  echo "Main TeX file not found: $MAIN_TEX"
  exit 2
fi

has_cmd() { command -v "$1" >/dev/null 2>&1; }

BASENAME="${MAIN_TEX%.*}"
PDF_OUT="$OUTDIR/$BASENAME.pdf"

build_with_latexmk() {
  # Use latexmk with the chosen engine
  local pdflatex_cmd="$ENGINE -interaction=nonstopmode -halt-on-error -file-line-error"
  latexmk -outdir="$OUTDIR" -pdf -pdflatex="$pdflatex_cmd" "$MAIN_TEX"
}

needs_biber() { grep -q '\\addbibresource\|\\printbibliography' "$MAIN_TEX"; }
needs_bibtex() { grep -q '\\bibliography{' "$MAIN_TEX"; }

build_fallback() {
  local eng="$ENGINE"
  local eng_cmd=( "$eng" -interaction=nonstopmode -halt-on-error -file-line-error -output-directory="$OUTDIR" "$MAIN_TEX" )

  echo "Running $eng (1st pass)..."
  "${eng_cmd[@]}"

  local base="$BASENAME"
  if needs_biber && has_cmd biber; then
    echo "Running biber..."
    ( cd "$OUTDIR" && biber "$base" )
  elif needs_bibtex && has_cmd bibtex; then
    echo "Running bibtex..."
    ( cd "$OUTDIR" && bibtex "$base" )
  fi

  echo "Running $eng (2nd pass)..."
  "${eng_cmd[@]}"
  echo "Running $eng (final pass)..."
  "${eng_cmd[@]}"
}

echo "Building $MAIN_TEX -> $PDF_OUT (engine: $ENGINE)"
if has_cmd latexmk; then
  build_with_latexmk
else
  echo "latexmk not found, using fallback."
  build_fallback
fi

if [[ -f "$PDF_OUT" ]]; then
  echo "Success: $PDF_OUT"
else
  echo "Build failed; PDF not found at $PDF_OUT"
  exit 1
fi
