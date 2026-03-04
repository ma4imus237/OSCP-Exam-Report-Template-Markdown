# Windows Installation Guide

## Prerequisites

Install the following dependencies on your Windows machine:

### 1. Pandoc

```powershell
winget install JohnMacFarlane.Pandoc
```

Or download from [pandoc.org/installing](https://pandoc.org/installing.html).

### 2. LaTeX Engine (MiKTeX)

```powershell
winget install MiKTeX.MiKTeX
```

On first use, MiKTeX will prompt to install missing LaTeX packages automatically.

Alternatively, install TeX Live: `winget install TeXLive.TeXLive`

### 3. Eisvogel LaTeX Template

1. Download the latest release from [github.com/Wandmalfarbe/pandoc-latex-template/releases](https://github.com/Wandmalfarbe/pandoc-latex-template/releases)
2. Extract `eisvogel.latex` and copy it to your Pandoc templates folder:

```powershell
mkdir "$env:APPDATA\pandoc\templates" -Force
Copy-Item eisvogel.latex "$env:APPDATA\pandoc\templates\"
```

### 4. 7-Zip

```powershell
winget install 7zip.7zip
```

Make sure `7z` is in your PATH. Default install location: `C:\Program Files\7-Zip\`.

Add to PATH if needed:

```powershell
$env:Path += ";C:\Program Files\7-Zip"
```

## Usage

### Initialize a Report Template

```powershell
.\osert.ps1 init -o .\my-report
```

This will interactively ask you to choose a certification, template, OS ID, and email, then copy the template to the output folder with your metadata.

### Generate PDF Report

```powershell
.\osert.ps1 generate -i .\my-report\report.md -o .\output -e OSCP -s 12345
```

This will:
1. Convert your Markdown report to PDF via Pandoc
2. Offer to preview the PDF
3. Create a 7z archive for submission
4. Optionally add a lab report to the archive
5. Display the MD5 hash for upload integrity verification

### All CLI Options

```
.\osert.ps1 <init|generate> [options]

  -i, -Input         Markdown report file path (generate)
  -o, -Output        Output directory (init/generate)
  -e, -Exam          Exam short name, e.g. OSCP (generate)
  -s, -OSID          Your Offensive Security ID (generate)
  -r, -ResourcePath  Additional resource path [Default: .] (generate)
```

### Execution Policy

If PowerShell blocks the script, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\osert.ps1 init
```

Or set the policy for the current user:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
