# oocut: Sovereign Column, Byte, Character & Field Extractor

<div align="center">

```
================================================================================
                                 oocut
               Sovereign openOODA Column & Field Stream Extractor
================================================================================
```

**Sovereign Stream & Column Extractor**  
*Byte, character, and delimiter-aware field extractor with Unicode preservation and streaming MCP stdio.*  
*Two Faces, One Engine:* Modern terminal ergonomics for humans • Streaming MCP stdio for AI agents  
Written in 100% pure [openOODA](https://github.com/openOODA).

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![openOODA](https://img.shields.io/badge/openOODA-1.0-emerald.svg)](https://openooda.org)
[![Architecture: x86_64 | aarch64](https://img.shields.io/badge/Arch-x86__64%20%7C%20aarch64-lightgrey.svg)]()

</div>

---

## 1. Quick Install

### Automated Installer (Linux x86_64 & aarch64)
```bash
curl -fsSL https://openooda-tools.github.io/oocut/install.sh | bash
```

### Native Package Managers
```bash
# Arch Linux (AUR / PKGBUILD)
yay -S oocut-bin
# Or manual PKGBUILD:
cd packaging/arch && makepkg -si

# Debian / Ubuntu (.deb)
curl -fsSL https://openooda-tools.github.io/oocut/install.sh | bash -s -- --deb

# Fedora / RHEL (.rpm)
curl -fsSL https://openooda-tools.github.io/oocut/install.sh | bash -s -- --rpm
```

### Uninstallation
```bash
oocut-uninstall
# or: curl -fsSL https://openooda-tools.github.io/oocut/uninstall.sh | bash
```

---

## 2. CLI Usage

```
Usage: oocut [OPTIONS] [FILE]

Byte, character, and delimiter-aware field stream extractor in pure openOODA.

Options:
  -b, --bytes <LIST>          Select only these 1-based byte positions
  -c, --characters <LIST>     Select only these 1-based UTF-8 character positions
  -f, --fields <LIST>         Select only these delimiter-separated fields [default: 1-]
  -d, --delimiter <CHAR>      Field delimiter character [default: TAB]
      --output-delimiter <S>  String used for output delimiter [default: input delimiter]
      --complement            Invert the selection: output elements NOT selected
  -s, --only-delimited        Do not print lines containing no delimiters
  -z, --zero-terminated       Line delimiter is NUL (\0), not newline (\n)
  -j, --json                  Format output as structured JSON records
  -D, --demo                  Execute demonstration pipeline on synthetic passwd & TSV data
      --theme <THEME>         Select terminal color theme (ember, ocean, matrix, cyber, monochrome)
      --mcp                   Run streaming Model Context Protocol (MCP) stdio server
  -h, --help                  Show this help message and exit
  -v, --version               Show version information and exit
```

---

## 3. Extraction Examples

```bash
# Extract colon-delimited user and shell from /etc/passwd
oocut -d : -f 1,7 /etc/passwd

# Extract fields with custom output delimiter
oocut -d : -f 1,6,7 --output-delimiter=" -> " /etc/passwd

# Extract fields and invert selection (all fields except passwords)
oocut -d : -f 2 --complement /etc/passwd

# Extract character positions from Unicode UTF-8 streams
printf "αβγδε\n" | oocut -c 1,3-4

# Extract fixed-width byte columns
oocut -b 1-10,20-30 data.log

# Suppress lines without delimiters
cat mixed.txt | oocut -d : -f 1,2 -s

# Pipeline stream processing with structured JSON output
cat data.tsv | oocut -f 1,3 -j

# Run synthetic extraction demonstration
oocut --demo
```

---

## 4. Theming Integration (`oote`)

`oocut` synchronizes visual styles and status colors with [oote](https://github.com/openOODA-tools/oote):
* **Palettes:** `ember`, `ocean`, `matrix`, `cyber`, `monochrome`.
* **Environment Overrides:** Respects `$OODA_THEME` and `$NO_COLOR`.

---

## 5. Model Context Protocol (MCP)

When invoked with `--mcp`, `oocut` acts as a streaming JSON-RPC 2.0 stdio server for AI agents:

```bash
oocut --mcp
```

### Exposed Sovereign Tools
1. `cut_fields`: Extract delimiter-separated fields from text or files.
2. `cut_bytes`: Extract 1-based byte positions and ranges.
3. `cut_characters`: Extract 1-based UTF-8 character positions and ranges.
4. `cut_slice`: Universal stream slicer supporting byte, character, and field modes.
5. `cut_demo`: Return synthetic Unix passwd and TSV column extraction demonstration.

---

## 6. Security & Zero Ambient Authority

* **Pure Capability Bounded:** Operates strictly with explicit capability tokens (`&FsReadCap`, `&ProcessCap`, `&EnvCap`). Physical absence of ambient filesystem writing or network leakage.
* **Negative-Trust Architecture:** Strict bounds checking, memory safety, and Unicode-safe parsing.
* **Hermetic Binary:** Standalone zero-dependency executable compiled natively via `oodac`.

---

## 7. License

Apache License, Version 2.0. See [LICENSE](LICENSE) for details.
