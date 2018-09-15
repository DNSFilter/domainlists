@ECHO OFF
REM Version 0.3
REM Created by Joshua Lamb on 8AUG18
SETLOCAL EnableDelayedExpansion
TITLE DNSFILTER INSTALLER/DEBUGGER
SET workdir=C:\temp
IF not exist %workdir% mkdir %workdir%
SET mspagenturl="https://download.dnsfilter.com/User_Agent/Windows/DNS_Agent_Setup.msi"
SET mspmsi=DNS_Agent_Setup.msi
SET retailagenturl="https://download.dnsfilter.com/User_Agent/Windows/DNSFilter_Agent_Setup.msi"
SET retailmsi=DNSFilter_Agent_Setup.msi
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
ECHO DNSFILTER.COM USER AGENT INSTALLER/DEBUGGER v0.1
ECHO ................................................
Echo:
Echo:
ECHO PRESS NUMBER CORRESPONDING TO YOUR TASK.
Echo:
Echo:
ECHO 1 - Change DNS Resolver
ECHO 2 - Install DNSFilter Agent
ECHO 3 - Uninstall DNSFilter Agents
ECHO 4 - Flush Local Resolver Cache
ECHO 5 - Reset TCPIP and Winsock
ECHO 6 - DEBUG
ECHO 7 - EXIT
Echo:
SET /P M=Type number then press ENTER: 
IF %M%==1 GOTO CHANGE_DNS
IF %M%==2 GOTO INSTALL_AGENT
IF %M%==3 GOTO UNINSTALL_AGENTS
IF %M%==4 GOTO FLUSH_CACHE
IF %M%==5 GOTO RESET_TCPIP
IF %M%==6 GOTO DEBUG
IF %M%==7 ECHO Goodbye & GOTO :EOF

:CHANGE_DNS
CLS
Echo:
ECHO ...............................................
ECHO CHANGE LOCAL DNS
ECHO ...............................................
Echo:
Echo:
ECHO This changes DNS resolver for common interfaces
Echo:
Echo:
ECHO WARNING: IF DNS Agent is installed
ECHO You must remove it first.
Echo:
Echo:
Echo:
SET "dnschoice="
SET /p dnschoice="[1] DHCP (default) or [2] DNSFilter or [3] Google: "
	IF [%dnschoice%]==[1] GOTO DHCPSET
	IF [%dnschoice%]==[2] SET dnschoice=103.247.36.36 & GOTO STATICSET
	IF [%dnschoice%]==[3] SET dnschoice=8.8.8.8 & GOTO STATICSET
	IF [%dnschoice%]==[] GOTO DHCPSET

:DHCPSET
(FOR %%a in (%adapterlist%) DO ( 
   netsh interface ip set dns %%a dhcp
   netsh interface ip show config %%a
))
Echo:
ECHO Set all adapters use DNS provided by DHCP
Echo:
ECHO Flushing DNS resolver cache
Echo:
ipconfig /flushdns
PAUSE
GOTO MENU

:STATICSET
(FOR %%a in (%adapterlist%) DO ( 
   netsh interface ip set dns %%a static %dnschoice%
   netsh interface ip show config %%a
))
Echo:
ECHO Set all adapters to static DNS %dnschoice%
Echo:
ECHO Flushing DNS resolver cache
Echo:
ipconfig /flushdns
PAUSE
GOTO MENU

:INSTALL_AGENT
CLS
Echo:
ECHO ...............................................
ECHO DNSFILTER AGENT INSTALLER.
ECHO ...............................................
Echo:
Echo:
ECHO Which Agent do you wish to install?
Echo:
Echo:
SET /P installer1=Select [1] MSP, [2] Retail, or [3] Abort:
     IF [%installer1%]==[1] GOTO MSP
     IF [%installer1%]==[2] GOTO RETAIL
     IF [%installer1%]==[3] GOTO MENU
	 IF [%installer1%]==[] GOTO MENU
:MSP
SET dldest=%workdir%\%mspmsi%
IF exist %dldest% del %dldest%
bitsadmin.exe /transfer "MSP Agent" %mspagenturl% %dldest%
GOTO INSTALLER2

:RETAIL
SET dldest=%workdir%\%retailmsi%
IF exist %dldest% del %dldest%
bitsadmin.exe /transfer "Retail Agent" %retailagenturl% %dldest%
GOTO INSTALLER2

:INSTALLER2
CLS
Echo:
Echo:
ECHO Answer the following Questions
Echo:
Echo:
ECHO DO NOT PASTE OR TYPE WITH QUOTES
Echo:
Echo:
REM resetting variables
SET "sitekey="
SET "tags="
SET "hostname="
SET "trayicon="
SET "controlpanel="
SET /p sitekey="Enter Site Secret Key [REQUIRED]: "
	IF [%sitekey%]==[] GOTO INSTALLER2
SET /p tags="Enter tags, in a comma spaced list [OPTIONAL]: "
SET /p hostname="Enter custom hostname or press enter to use computer name: "
	IF [%hostname%]==[] SET hostname=%computername%
SET /p trayicon=Show tray icon [Y/n]?
	IF /I [%trayicon%]==[n] SET trayicon=disabled
	IF /I [%trayicon%]==[y] SET trayicon=enabled
	IF /I [%trayicon%]==[] SET trayicon=enabled
SET /p controlpanel=Show in add/remove programs [Y/n]?
	IF /I [%controlpanel%]==[y] SET controlpanel=0
	IF /I [%controlpanel%]==[n] SET controlpanel=1
	IF /I [%controlpanel%]==[] SET controlpanel=0
GOTO INSTALLER3

:INSTALLER3
CLS
Echo:
Echo:
ECHO INSTALLING AGENT
Echo:
Echo:
IF [%hostname%]==[] (
    msiexec /qn /i %dldest% NKEY="%sitekey%" TAGS="%tags%" TRAYICON="%trayicon%" ARPSYSTEMCOMPONENT="%controlpanel%"
) ELSE (
    msiexec /qn /i %dldest% NKEY="%sitekey%" TAGS="%tags%" HOSTNAME="%hostname%" TRAYICON="%trayicon%" ARPSYSTEMCOMPONENT="%controlpanel%"
)
Echo:
Echo:
ECHO INSTALL PROCESS COMPLETE
PAUSE
GOTO MENU

:UNINSTALL_AGENTS
Echo:
ECHO ...............................................
ECHO DNSFILTER AGENTS UNINSTALLER.
ECHO ...............................................
Echo:
Echo:
ECHO THIS WILL REMOVE ALL PRODUCTS
Echo:
Echo:
GOTO UNINSTALL_MSI_QUESTION

:UNINSTALL_MSI_QUESTION
SET /p msiuninstall=Do you wish to uninstall MSI [Y/n]?
	IF /I [%msiuninstall%]==[y] GOTO UNINSTALL_MSI_ACTION
	IF /I [%msiuninstall%]==[n] GOTO UNINSTALL_REGISTRY_QUESTION
	IF /I [%msiuninstall%]==[] GOTO UNINSTALL_MSI_ACTION

:UNINSTALL_MSI_ACTION
REM Uninstall MSP Version
wmic product where name="DNS Agent" call uninstall
REM Uninstall Retail Version
wmic product where name="DNSFilter Agent" call uninstall
Echo:
ECHO MSI uninstalled
Echo:
GOTO UNINSTALL_REGISTRY_QUESTION

:UNINSTALL_REGISTRY_QUESTION
SET /p reguninstall=Do you wish to uninstall from registry [y/N]?
	IF /I [%reguninstall%]==[y] GOTO UNINSTALL_REGISTRY_ACTION
	IF /I [%reguninstall%]==[n] GOTO UNINSTALL_SERVICES_QUESTION
	IF /I [%reguninstall%]==[] GOTO UNINSTALL_SERVICES_QUESTION

:UNINSTALL_REGISTRY_ACTION
REM Remove MSP registry entries
REG DELETE HKEY_LOCAL_MACHINE\SOFTWARE\DNSAgent /f
REM Remove Retail registry entries
REG DELETE HKEY_LOCAL_MACHINE\SOFTWARE\DNSFilter /f
Echo:
ECHO Registry entries removed
Echo:
GOTO UNINSTALL_SERVICES_QUESTION

:UNINSTALL_SERVICES_QUESTION
SET /p serviceuninstall=Do you wish to remove the service [y/N]?
	IF /I [%serviceuninstall%]==[y] GOTO UNINSTALL_SERVICES_ACTION
	IF /I [%serviceuninstall%]==[n] GOTO MENU
	IF /I [%serviceuninstall%]==[] GOTO MENU

:UNINSTALL_SERVICES_ACTION
REM MSP Version
SC STOP "DNS Agent"
SC DELETE "DNS Agent"
REM Retail Version
SC STOP "DNSFilter Agent"
SC DELETE "DNSFilter Agent"
Echo:
ECHO Service removed
Echo:
PAUSE
GOTO MENU

:FLUSH_CACHE
CLS
Echo:
ECHO Flushing DNS resolver cache
Echo:
ipconfig /flushdns
PAUSE
GOTO MENU

:GOTO RESET_TCPIP
CLS
Echo:
ECHO Resetting TCPIP and Winsock
Echo:
netsh int ip reset
netsh winsock reset
Echo:
ECHO Computer restart is recommended
Echo:
PAUSE
GOTO MENU

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
ECHO This will take awhile
ECHO -------------------- >> %debugfile%
ECHO ATTEMPTING NSLOOKUPS >> %debugfile%
ECHO -------------------- >> %debugfile%
ECHO nslookup -type=txt debug.dnsfilter.com >> %debugfile%
nslookup -type=txt debug.dnsfilter.com >> %debugfile%
ECHO nslookup -type=txt debug.dnsfilter.com 103.247.36.36 >> %debugfile%
nslookup -type=txt debug.dnsfilter.com 103.247.36.36 >> %debugfile%
ECHO nslookup -type=txt debug.dnsfilter.com 103.247.37.37 >> %debugfile%
nslookup -type=txt debug.dnsfilter.com 103.247.37.37 >> %debugfile%
ECHO nslookup -type=txt debug.dnsfilter.com 8.8.8.8 >> %debugfile%
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
GOTO MENU

ENDLOCAL
