@ECHO OFF
REM Version 0.1
REM Created by Josh Lamb on 9AUG18
SETLOCAL EnableDelayedExpansion
TITLE DNSFILTER UNINSTALLER
CLS

GOTO CHECK_PERMISSIONS

:CHECK_PERMISSIONS
ECHO Administrative permissions required. Detecting permissions...
net session >nul 2>&1
IF %errorLevel% == 0 (
    ECHO Success: Administrative permissions confirmed.
    GOTO UNINSTALL_AGENTS
) ELSE (
    ECHO Failure: Current permissions inadequate. Launch CMD as Admin.
    PAUSE >nul
    GOTO :EOF
)

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
	IF /I [%serviceuninstall%]==[n] GOTO ENDMESSAGE
	IF /I [%serviceuninstall%]==[] GOTO ENDMESSAGE

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
GOTO ENDMESSAGE

:ENDMESSAGE
ECHO ...............................................
ECHO DNSFILTER PRODUCTS REMOVED
ECHO ...............................................
PAUSE

ENDLOCAL
