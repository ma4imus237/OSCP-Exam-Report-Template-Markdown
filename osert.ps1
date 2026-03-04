<#
.SYNOPSIS
    OSCP Exam Report Template Builder (PowerShell Port)
.DESCRIPTION
    Markdown Templates for Offensive Security OSCP, OSWE, OSEE, OSWP, OSEP, OSED Exam Report.
    Converts Markdown reports to PDF via Pandoc/LaTeX and creates 7z archives.
.EXAMPLE
    .\osert.ps1 init [-o OutputPath]
    .\osert.ps1 generate [-i Input] [-o Output] [-e Exam] [-s OSID] [-r ResourcePath]
#>

param(
    [Parameter(Position = 0)]
    [ValidateSet('init', 'generate')]
    [string]$Command,

    [Alias('i')]
    [string]$Input,

    [Alias('o')]
    [string]$Output,

    [Alias('e')]
    [string]$Exam,

    [Alias('s')]
    [string]$OSID,

    [Alias('r')]
    [string]$ResourcePath = '.'
)

# --- Data ---

$certifications = @(
    @{ exam = 'OSCP'; templates = @(
        @{ name = 'Whoisflynn Improved Template v3.2'; path = 'src/OSCP-exam-report-template_whoisflynn_v3.2.md' }
        @{ name = 'Official Offensive Security Template v1'; path = 'src/OSCP-exam-report-template_OS_v1.md' }
        @{ name = 'Official Offensive Security Template v2'; path = 'src/OSCP-exam-report-template_OS_v2.md' }
    )}
    @{ exam = 'OSWA'; templates = @(
        @{ name = 'Official Offensive Security Template v1'; path = 'src/OSWA-exam-report-template_OS_v1.md' }
    )}
    @{ exam = 'OSWE'; templates = @(
        @{ name = 'Official Offensive Security Template v1'; path = 'src/OSWE-exam-report-template_OS_v1.md' }
        @{ name = 'Noraj Improved Template v1'; path = 'src/OSWE-exam-report-template_noraj_v1.md' }
        @{ name = 'XL-SEC Improved Template v1'; path = 'src/OSWE-exam-report-template_xl-sec_v1.md' }
    )}
    @{ exam = 'OSCE'; templates = @(
        @{ name = 'Official Offensive Security Template v1'; path = 'src/OSCE-exam-report-template_OS_v1.md' }
    )}
    @{ exam = 'OSEE'; templates = @(
        @{ name = 'Official Offensive Security Template v1'; path = 'src/OSEE-exam-report-template_OS_v1.md' }
    )}
    @{ exam = 'OSWP'; templates = @(
        @{ name = 'Official Offensive Security Template v1'; path = 'src/OSWP-exam-report-template_OS_v1.md' }
    )}
    @{ exam = 'OSED'; templates = @(
        @{ name = 'Official Offensive Security Template v1'; path = 'src/OSED-exam-report-template_OS_v1.md' }
        @{ name = 'Epi Improved Template v1'; path = 'src/OSED-exam-report-template_epi_v1.md' }
    )}
    @{ exam = 'OSEP'; templates = @(
        @{ name = 'Official Offensive Security Template v1'; path = 'src/OSEP-exam-report-template_OS_v1.md' }
        @{ name = 'Ceso Improved Template v1'; path = 'src/OSEP-exam-report-template_ceso_v1.md' }
    )}
    @{ exam = 'OSDA'; templates = @(
        @{ name = 'Official Offensive Security Template v1'; path = 'src/OSDA-exam-report-template_OS_v1.md' }
    )}
    @{ exam = 'OSMR'; templates = @(
        @{ name = 'Official Offensive Security Template v1'; path = 'src/OSMR-exam-report-template_OS_v1.md' }
    )}
    @{ exam = 'OSTH'; templates = @(
        @{ name = 'Official Offensive Security Template v1'; path = 'src/OSTH-exam-report-template_OS_v1.md' }
    )}
    @{ exam = 'OSIR'; templates = @(
        @{ name = 'Official Offensive Security Template v1'; path = 'src/OSIR-exam-report-template_OS_v1.md' }
    )}
)

# --- Helper Functions ---

function Read-Prompt {
    param([string]$Message)
    if ($Message) { Write-Host $Message }
    return (Read-Host -Prompt '>').Trim()
}

function Select-FromList {
    param(
        [string]$Title,
        [array]$Items,
        [scriptblock]$DisplayFunc
    )
    Write-Host $Title
    for ($i = 0; $i -lt $Items.Count; $i++) {
        Write-Host -ForegroundColor Red "$i. $(& $DisplayFunc $Items[$i])"
    }
    $choice = (Read-Host -Prompt '>').Trim()
    if ($choice -eq '') { return 0 }
    return [int]$choice
}

function Update-FileContent {
    param(
        [string]$FilePath,
        [string]$Pattern,
        [string]$Replacement
    )
    $content = Get-Content -Path $FilePath -Raw
    $content = $content -replace $Pattern, $Replacement
    Set-Content -Path $FilePath -Value $content -NoNewline
}

# --- Show help if no command ---

if (-not $Command) {
    Write-Host @"
Usage: osert.ps1 <subcommand> [options]

Markdown Templates for Offensive Security OSCP, OSWE, OSEE, OSWP, OSEP, OSED Exam Report.

Sub-commands:
  init      :  Copy a template that you will use to write your report
  generate  :  Generate your PDF report and 7z archive

Options:
  -i, -Input         File path to the markdown report (generate)
  -o, -Output        Output file/directory path (init/generate)
  -e, -Exam          The exam short name (generate)
  -s, -OSID          Your Offensive Security ID (generate)
  -r, -ResourcePath  Complementary resources path [Default: .] (generate)

Examples:
  .\osert.ps1 init -o .\my-report
  .\osert.ps1 generate -i report.md -o .\output -e OSCP -s 12345
"@
    exit 0
}

# --- Init Command ---

if ($Command -eq 'init') {
    # Choose a certification
    $certIdx = Select-FromList -Title '[+] Choose a Certification:' -Items $certifications -DisplayFunc { param($c) $c.exam }
    $cert = $certifications[$certIdx]

    # Choose a template
    $tmplIdx = Select-FromList -Title '[+] Choose a Template:' -Items $cert.templates -DisplayFunc { param($t) "[$($cert.exam)] $($t.name)" }
    $src = $cert.templates[$tmplIdx].path

    # Enter OS ID
    Write-Host '[+] Enter your OS ID:'
    Write-Host '> OS-' -NoNewline
    $osid = "OS-$((Read-Host).Trim())"

    # Enter email address
    $author = Read-Prompt '[+] Enter your email address as author:'

    # Output path
    if ($Output) {
        $outputPath = $Output
    } else {
        $outputPath = Read-Prompt '[+] Enter the path where you want to copy the report template:'
    }

    # Copy template
    if (-not (Test-Path $outputPath)) {
        New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
    }
    try {
        Copy-Item -Path $src -Destination $outputPath -Force -ErrorAction Stop
    } catch {
        Write-Host -ForegroundColor Red "[!] Could not copy template: $src"
        Write-Host -ForegroundColor Red "[!] Make sure you are running the script from the repository root."
        exit 1
    }

    # Replace metadata
    $report = Join-Path $outputPath (Split-Path $src -Leaf)
    Update-FileContent -FilePath $report -Pattern '(?m)^author:.*' -Replacement "author: [`"$author`", `"OSID: $osid`"]"
    Update-FileContent -FilePath $report -Pattern '(?m)^date:.*' -Replacement "date: `"$(Get-Date -Format 'yyyy-MM-dd')`""

    $basename = Split-Path $src -Leaf
    Write-Host -NoNewline "[+] The "
    Write-Host -NoNewline -ForegroundColor Red $basename
    Write-Host -NoNewline " file is saved in "
    Write-Host -NoNewline -ForegroundColor Red $outputPath
    Write-Host " folder. Edit it with your exam notes."
    Write-Host -NoNewline "[+] Then, run "
    Write-Host -NoNewline -ForegroundColor Red ".\osert.ps1 generate -i $outputPath\$basename -o $outputPath"
    Write-Host " for getting your report."
}

# --- Generate Command ---

if ($Command -eq 'generate') {
    Write-Host '[+] Preparing your final report...'

    # Choose syntax highlight style
    $style = 'breezedark'
    Write-Host "[+] Choose syntax highlight style [$style]:"
    try {
        $styles = (& pandoc --list-highlight-styles) | Where-Object { $_ -ne '' }
    } catch {
        Write-Host -ForegroundColor Red '[!] Error: pandoc not found. Please install Pandoc first.'
        exit 1
    }
    for ($i = 0; $i -lt $styles.Count; $i++) {
        Write-Host -ForegroundColor Red "$i. $($styles[$i])"
    }
    $choice = (Read-Host -Prompt '>').Trim()
    if ($choice -ne '') {
        $style = $styles[[int]$choice]
    }

    # Input file
    if (-not $Input) {
        $Input = Read-Prompt '[+] Enter the file path where is your markdown report:'
    }

    # Output directory
    if (-not $Output) {
        $Output = Read-Prompt '[+] Enter the path where you want to store the PDF report:'
    }

    # Certification
    if ($Exam) {
        $examName = $Exam
    } else {
        $certIdx = Select-FromList -Title '[+] Choose a Certification:' -Items $certifications -DisplayFunc { param($c) $c.exam }
        $examName = $certifications[$certIdx].exam
    }

    # OS ID
    if ($OSID) {
        $osid = $OSID
    } else {
        Write-Host '[+] Enter your OS ID:'
        Write-Host '> OS-' -NoNewline
        $osid = "OS-$((Read-Host).Trim())"
    }

    # Ensure output directory exists
    if (-not (Test-Path $Output)) {
        New-Item -ItemType Directory -Path $Output -Force | Out-Null
    }

    # Generate PDF
    Write-Host '[+] Generating report...'
    $pdf = Join-Path $Output "$examName-$osid-Exam-Report.pdf"

    $pandocArgs = @(
        $Input
        '-o', $pdf
        '--from', 'markdown+yaml_metadata_block+raw_html'
        '--template', 'eisvogel'
        '--table-of-contents'
        '--toc-depth', '6'
        '--number-sections'
        '--top-level-division=chapter'
        '--highlight-style', $style
        "--resource-path=.;src;$ResourcePath"
    )

    & pandoc @pandocArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Host -ForegroundColor Red '[!] Error: pandoc failed to generate the PDF.'
        exit 1
    }

    Write-Host -NoNewline '[+] PDF generated at '
    Write-Host -ForegroundColor Red $pdf

    # Preview
    $choice = Read-Prompt '[+] Do you want to preview the report? [Y/n]'
    if ($choice -eq '' -or $choice -match '^[Yy]') {
        Start-Process $pdf
    }

    # Generate 7z archive
    Write-Host '[+] Generating archive...'
    $archive = Join-Path $Output "$examName-$osid-Exam-Report.7z"
    $pdfFull = (Resolve-Path $pdf).Path

    & 7z a $archive $pdfFull
    if ($LASTEXITCODE -ne 0) {
        Write-Host -ForegroundColor Red '[!] Error: 7z failed to create the archive.'
        exit 1
    }

    # Optional lab report
    $choice = Read-Prompt '[+] Do you want to add an external lab report? [Y/n]'
    if ($choice -eq '' -or $choice -match '^[Yy]') {
        $lab = Read-Prompt '[+] Write the path of your lab PDF:'
        Write-Host '[+] Updating archive...'
        $labFull = (Resolve-Path $lab).Path
        & 7z a $archive $labFull
    }

    Write-Host -NoNewline '[+] Archive generated at '
    Write-Host -ForegroundColor Red $archive

    # Calculate MD5
    Write-Host '[+] Calculating MD5 of the archive...'
    $md5 = (Get-FileHash -Path $archive -Algorithm MD5).Hash.ToLower()
    Write-Host -NoNewline '[+] Archive MD5 (upload integrity check): '
    Write-Host -ForegroundColor Red $md5
}
