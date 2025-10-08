# Frederick Andrews' LaTeX Resumes

This repository stores Frederick Andrews' resumes written in LaTeX, along with a simple build script to generate PDFs.

## Requirements

Install a TeX distribution and tools:

- Ubuntu/Debian:
  - Minimal recommended: `sudo apt-get update && sudo apt-get install -y texlive-latex-recommended texlive-latex-extra texlive-fonts-recommended texlive-xetex latexmk biber ghostscript texlive-fonts-extra`
  - Simplest (large): `sudo apt-get install -y texlive-full`
- macOS:
  - `brew install --cask mactex-no-gui`
  - `brew install latexmk biber ghostscript`
- Windows:
  - Use WSL with Ubuntu (recommended), or install MiKTeX (with latexmk) and run the script in Git Bash/PowerShell.

Notes:
- latexmk is recommended; the script falls back to direct engine if missing.
- If you use bibliographies, install biber (preferred) or rely on bibtex (comes with TeX Live).

## Build

From the Resume directory:

1) Make the script executable (once):
- `chmod +x build.sh`

2) Build:
- Auto-detect main .tex: `./build.sh`
- Specify file: `./build.sh -f Resume.tex`
- Choose engine: `./build.sh -e xelatex -f Resume.tex`
- Change output dir: `./build.sh -o ./build`
- Clean aux files: `./build.sh -c`

Output:
- PDFs are written to `build/<name>.pdf` by default.

### Monolithic Combined Resume

To build the full multi-page combined resume containing both software and hardware versions plus all projects:

```
./build.sh -f monolith.tex
```

This will generate `build/monolith.pdf`.

Engines:
- Supports `pdflatex`, `xelatex`, `lualatex` (default: `xelatex`).
- If you use system fonts or unicode-heavy content, prefer `xelatex` or `lualatex`.

Bibliographies:
- If `\addbibresource`/`\printbibliography` is detected and `biber` is installed, the script runs biber automatically. For legacy `\bibliography{...}`, it runs bibtex if available.

Troubleshooting:
- Missing packages: install `texlive-full` (Linux) or ensure MacTeX/MiKTeX installs on demand.
- Build errors: run with `-e pdflatex`/`-e xelatex` as appropriate, check the `.log` in `build/`.
