@ECHO OFF
REM Version 0.2
REM Created by Joshua Lamb on 12SEP18

SETLOCAL EnableDelayedExpansion
TITLE DNS Agent Hang Fix
CLS

GOTO CHECK_PERMISSIONS

:CHECK_PERMISSIONS
ECHO Administrative permissions required. Detecting permissions...
net session >nul 2>&1
IF %errorLevel% == 0 (
    ECHO Success: Administrative permissions confirmed.
    GOTO FIX
) ELSE (
    ECHO Failure: Current permissions inadequate. Launch CMD as Admin.
    PAUSE >nul
    GOTO :EOF
)

:FIX

REM Set variables
SET workdir=C:\uafix
IF not exist %workdir% mkdir %workdir%
SET dnsresetbatfile=%workdir%\dnsreset.bat
SET dnsresetxmlurl=https://raw.githubusercontent.com/airbornelamb/DNSF/master/useragent/windows/hangfix/dnsreset.xml
SET dnsresetxmlfile=%workdir%\dnsreset.xml
SET retailxmlurl=https://raw.githubusercontent.com/airbornelamb/DNSF/master/useragent/windows/hangfix/retail.xml
SET retailxmlfile=%workdir%\retail.xml
SET mspxmlurl=https://raw.githubusercontent.com/airbornelamb/DNSF/master/useragent/windows/hangfix/msp.xml
SET mspxmlfile=%workdir%\msp.xml

REM Write dns reset
(
ECHO SETLOCAL EnableDelayedExpansion
ECHO SET adapterlist="Local Area Connection" "Ethernet" "Wireless Network Connection" "Wi-Fi"
ECHO ^(FOR %%%%a in ^(%%adapterlist%%^) DO ^(
ECHO    netsh interface ip set dns %%%%a dhcp
ECHO ^)^)
) > %dnsresetbatfile%

REM Add dns reset to startup
BITSADMIN /transfer "DNS Reset Task" %dnsresetxmlurl% %dnsresetxmlfile%
SCHTASKS /Create /RU "SYSTEM" /TN dnsreset /XML %dnsresetxmlfile%

REM Query and write startup task for Retail
SC QUERY "DNSFilter Agent" >nul 2>&1
IF %errorlevel%==0 (
    SC STOP "DNSFilter Agent"
    REG ADD "HKLM\System\CurrentControlSet\services\DNSFilter Agent" /v Start /t REG_DWORD /d 3 /f
    BITSADMIN /transfer "Agent Task" %retailxmlurl% %retailxmlfile%
    SCHTASKS /Create /RU "SYSTEM" /TN uaretailstartup /XML %retailxmlfile%
)

REM Query and write startup task for MSP
SC QUERY "DNS Agent" >nul 2>&1
IF %errorlevel%==0 (
    SC STOP "DNS Agent"
    REG ADD "HKLM\System\CurrentControlSet\services\DNS Agent" /v Start /t REG_DWORD /d 3 /f
    BITSADMIN /transfer "Agent Task" %mspxmlurl% %mspxmlfile%
    SCHTASKS /Create /RU "SYSTEM" /TN uastartup /XML %mspxmlfile%
)

CLS
ECHO:
ECHO Fix applied please restart your computer now.
ECHO:
ECHO:
PAUSE
