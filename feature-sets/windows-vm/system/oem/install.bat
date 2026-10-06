@echo off
rem Runs once at the first logon after the unattended install, as the admin user from USERNAME.
rem Installs and starts sshd, and allows key login for the keys in C:\OEM\authorized_keys.
rem Output goes to C:\OEM\install.log only if the container sets LOG.

rem If Windows Update cannot serve the capability (for example 0x8024402C), install the MSI from GitHub.
powershell -NoProfile -Command "Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -ErrorAction Stop"
if errorlevel 1 (
  curl.exe -fsSL --retry 10 --retry-delay 15 --retry-all-errors -o C:\OEM\OpenSSH-Win64.msi https://github.com/PowerShell/Win32-OpenSSH/releases/download/10.0.0.0p2-Preview/OpenSSH-Win64-v10.0.0.0.msi
  msiexec /i C:\OEM\OpenSSH-Win64.msi /qn /norestart
)

rem sshd creates C:\ProgramData\ssh on its first start.
powershell -NoProfile -Command "Set-Service sshd -StartupType Automatic; Start-Service sshd"
powershell -NoProfile -Command "if (-not (Get-NetFirewallRule -Name OpenSSH-Server-In-TCP -ErrorAction SilentlyContinue)) { New-NetFirewallRule -Name OpenSSH-Server-In-TCP -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 }"

rem sshd reads this file for members of Administrators. It ignores the file unless only Administrators and SYSTEM have access.
copy /y C:\OEM\authorized_keys C:\ProgramData\ssh\administrators_authorized_keys
icacls C:\ProgramData\ssh\administrators_authorized_keys /inheritance:r /grant *S-1-5-32-544:F /grant *S-1-5-18:F
