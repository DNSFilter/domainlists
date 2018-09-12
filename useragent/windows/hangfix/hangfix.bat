@ECHO OFF
REM Version 0.1
REM Created by Joshua Lamb on 11SEP18

SETLOCAL EnableDelayedExpansion
TITLE DNSFilter Agent Hang Fix
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
SET schedfile=%workdir%\dnsreset.bat
IF not exist %workdir% mkdir %workdir%


REM Query and write startup task for Retail
SC QUERY "DNSFilter Agent" >nul 2>&1
IF %errorlevel%==0 (
    SC STOP "DNSFilter Agent"
    REG ADD "HKLM\System\CurrentControlSet\services\DNSFilter Agent" /v Start /t REG_DWORD /d 3 /f
    SCHTASKS /Create /RU "SYSTEM" /TN startagent /TR "SC START \"DNSFilter Agent\"" /SC onlogon
)

REM Query and write startup task for MSP
SC QUERY "DNS Agent" >nul 2>&1
IF %errorlevel%==0 (
    SC STOP "DNS Agent"
    REG ADD "HKLM\System\CurrentControlSet\services\DNS Agent" /v Start /t REG_DWORD /d 3 /f
    SCHTASKS /Create /RU "SYSTEM" /TN startagent /TR "SC START \"DNS Agent\"" /SC onlogon
)


REM Write dns reset

(
ECHO SETLOCAL EnableDelayedExpansion
ECHO SET adapterlist="Local Area Connection" "Ethernet" "Wireless Network Connection" "Wi-Fi"
ECHO ^(FOR %%%%a in ^(%%adapterlist%%^) DO ^(
ECHO    netsh interface ip set dns %%%%a dhcp
ECHO    netsh interface ip show config %%%%a
ECHO ^)^)
) > %schedfile%

REM Add dns reset to startup
SCHTASKS /Create /RU "SYSTEM" /TN dnsreset /TR %schedfile% /SC onstart


CLS
ECHO:
ECHO Fix applied please restart your computer now.
ECHO:
ECHO:
PAUSE
