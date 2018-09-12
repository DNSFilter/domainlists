@ECHO OFF
REM Version 0.2
REM Created by Josh Lamb on 24AUG18
SETLOCAL EnableDelayedExpansion
TITLE DNSFILTER DEBUGGER
SET workdir=C:\temp
IF not exist %workdir% mkdir %workdir%
SET adapterlist="Local Area Connection" "Ethernet" "Wireless Network Connection" "Wi-Fi"
CLS

GOTO CHECK_PERMISSIONS

:CHECK_PERMISSIONS
ECHO Administrative permissions required. Detecting permissions...
net session >nul 2>&1
IF %errorLevel% == 0 (
    ECHO Success: Administrative permissions confirmed.
    GOTO MENU
) ELSE (
    ECHO Failure: Current permissions inadequate. Launch CMD as Admin.
    PAUSE >nul
    GOTO :EOF
)


:MENU
CLS
Echo:
ECHO ................................................
ECHO DNSFILTER.COM DEBUGGER v0.2
ECHO ................................................
Echo:
Echo:
PAUSE
GOTO DEBUG
:DEBUG
CLS
SET debugfile=%workdir%\debugfile.txt
IF exist %debugfile% del %debugfile%
Echo:
ECHO ...............................................
ECHO DEBUGGING DUMP
ECHO ...............................................
Echo:
Echo:
ECHO This will run a series of network commands
ECHO so that the output can be evaluated.
Echo:
Echo:
ECHO The results will be written to %debugfile%
Echo:
Echo:
ECHO Checking User Agent registry values
ECHO ----------------------------------- > %debugfile%
ECHO Checking User Agent registry values >> %debugfile%
ECHO ----------------------------------- >> %debugfile%
Echo:
Echo:
REG QUERY HKLM\SOFTWARE\DNSFilter\Agent >> %debugfile%
REG QUERY HKLM\SOFTWARE\DNSAgent\Agent >> %debugfile%
ECHO Checking for HyperV
ECHO --------------------------- >> %debugfile%
SC QUERY vmms >nul
IF %errorlevel%==0 ECHO HYPERV INSTALLED >> %debugfile%
IF %errorlevel%==1060 ECHO hyperv not installed >> %debugfile%
IF %errorlevel%==1722 ECHO hyperv test inconclusive >> %debugfile%
ECHO --------------------------- >> %debugfile%
Echo:
Echo:
ECHO Getting adapter information
ECHO --------------------------- >> %debugfile%
ECHO GETTING ADAPTER INFORMATION >> %debugfile%
ECHO --------------------------- >> %debugfile%
Echo:
Echo:
ipconfig /all >> %debugfile%
REM (FOR %%a in (%adapterlist%) DO ( 
REM    netsh interface ip show config %%a  >> %debugfile%
REM ))
ECHO Attempting ping to 8.8.8.8
ECHO -------------------------- >> %debugfile%
ECHO ATTEMPTING PING TO 8.8.8.8 >> %debugfile%
ECHO -------------------------- >> %debugfile%
Echo:
Echo:
ping -n 4 8.8.8.8 >> %debugfile%
ECHO Attempting nslookups
ECHO -------------------- >> %debugfile%
ECHO ATTEMPTING NSLOOKUPS >> %debugfile%
ECHO -------------------- >> %debugfile%
ECHO nslookup -type=txt debug.dnsfilter.com >> %debugfile%
ECHO -------------------------------------- >> %debugfile%
nslookup -type=txt debug.dnsfilter.com >> %debugfile%
ECHO ---------------------------------------------------- >> %debugfile%
ECHO nslookup -type=txt debug.dnsfilter.com 103.247.36.36 >> %debugfile%
ECHO ---------------------------------------------------- >> %debugfile%
nslookup -type=txt debug.dnsfilter.com 103.247.36.36 >> %debugfile%
ECHO ---------------------------------------------------- >> %debugfile%
ECHO nslookup -type=txt debug.dnsfilter.com 103.247.37.37 >> %debugfile%
ECHO ---------------------------------------------------- >> %debugfile%
nslookup -type=txt debug.dnsfilter.com 103.247.37.37 >> %debugfile%
ECHO ---------------------------------------------------- >> %debugfile%
ECHO nslookup -type=txt debug.dnsfilter.com 8.8.8.8 >> %debugfile%
ECHO ---------------------------------------------------- >> %debugfile%
nslookup -type=txt debug.dnsfilter.com 8.8.8.8 >> %debugfile%
Echo:
Echo:
ECHO Checking for conflicting local resolvers
ECHO ---------------------------------------- >> %debugfile%
ECHO CHECKING FOR CONFLICTING LOCAL RESOLVERS >> %debugfile%
ECHO ---------------------------------------- >> %debugfile%
Echo:
Echo:
netstat -an | findstr 53 >> %debugfile%
ECHO FINISHED!!
ECHO THE RESULTS HAVE BEEN WRITTEN TO %debugfile%
Echo:
Echo:
PAUSE

ENDLOCAL
