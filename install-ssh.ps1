#!/mnt/c/Users/rich/scoop/shims/pwsh.exe 
# there is no way to escape a space in shebang so need a symlink formed
# this needs the later Powershell 7 but shebang requires no escale
#
# Microsoft App Store Powershell installs into
#
# choco install powershell-core installed into so it will not work
# C:\Program Files\PowerShell\7\pwsh.exe
#
# scoop install pwsh installed into C:\Users\rich\scoop\shims\pwsh.exe so this 
# works but is User specific
#
# winget install pwsh installs into which has no spaces but is user specific
# C:\Users\rich\AppData\Local\Microsoft\WindowsApps\Microsoft.PowerShell_8wekyb3d8bbwe\pwsh.exe
#
# This is for the older Powershell 5.x
#!/mnt/c/WINDOWS/System32/WindowsPowerShell/v1.0/powershell.exe
#
# https://lists.gnu.org/archive/html/bug-bash/2008-05/msg00052.html
# https://stackoverflow.com/questions/52113738/starting-ssh-agent-on-windows-10-fails-unable-to-start-ssh-agent-service-erro
Write-Host "Most command need sudo"

# Has version 8.2 not working well but does have working SSH Client
# Has the latest OpenSSH 8.5 which we can use sort of but ssh-agent does not work
Write-Host "scoop install git-with-openssh"
scoop install git-with-openssh

# Remove the Windows sshd and ssh-agent
# https://stackoverflow.com/questions/10832000/best-way-to-write-to-the-console-in-powershell
Write-Host "Removing ssh and ssh-agents"
# https://mangolassi.it/topic/9954/installing-openssh-on-windows-via-chocolatey
# make sure Windows OpenSSH is not installed as it is very old
# https://devblogs.microsoft.com/scripting/powertip-find-windows-capabilities-with-powershell/
# cannot figure out how to get this and see if it is NotPresent
Get-WindowsCapability -Online -Name OpenSSH.Client
Get-WindowsCapability -Online -Name OpenSSH.Server

Remove-WindowsCapability -Online -Name OpenSSH.Client
Remove-WindowsCapability -Online -Name OpenSSH.Server
if ( Get-Service sshd ) {
    Remove-Service -Name sshd
}

if ( Get-Service ssh-agent  ) {
    Remove-Service -Name ssh-agent
}


# this does not work so use sudo instead from scoop install psutils
#runas.exe /savecred /user:"$ADMIN" \
#-ArgumentList ('-noexit choco.exe install openssh')

Write-Host "Install opensh with choco"
# keybased authentication assumed and neeed to explictly install the ssh-agent
# this does not work
#choco install wincrypt-sshagent
# -pre gives us version 8.1 vs 8.0
choco install openssh -pre -params "/SSHServerFeature /SSHAgentFeature" 
# https://community.chocolatey.org/packages/wincrypt-sshagent
# Uses the Windows encryption system

# https://dmtavt.com/post/2020-08-03-ssh-agent-powershell/
# needs to run as an admin and this is for the older OpenSSH not the choco one
# this should be done automatically by the installer above but check anyway
if ((Get-Service -Name ssh-agent).Service -ne "Running") {
    Get-Service -Name ssh-agent | Set-Service -StartupType Automatic
    Get-Service -Name ssh-agent | Start-Service
}

# start the ssh server
# https://www.pugetsystems.com/labs/hpc/How-To-Use-SSH-Client-and-Server-on-Windows-10-1470/
# https://zamarax.com/2020/02/14/installing-sftp-ssh-ftp-server-on-windows-with-openssh/
if ((Get-Service -Name sshd).Service -ne "Running") {
    Get-Service -Name sshd | Set-Service -StartupType Automatic
    Get-Service -Name sshd | Start-Service
    Get-NetFirewallRule -Name *ssh*
}

# https://stackoverflow.com/questions/10574267/cannot-spawn-ssh-when-connecting-to-github-but-ssh-t-gitgithub-com-works
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_environment_variables?view=powershell-7.1#:~:text=Environment%20variables%2C%20unlike%20other%20types%20of%20variables%20in,are%20needed%20in%20both%20parent%20and%20child%20processes.
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_environment_variables?view=powershell-7.1
# scoop sets this automatically
$env:GIT_SSH="c:\Program Files\OpenSSH-Win64\ssh.exe"

# Need to set the User too so it is not overridden this is set automatically by scoop
[System.Environment]::SetEnvironmentVariable("GIT_SSH", "c:\Program Files\OpenSSH-Win64\ssh.exe", 'Machine')
[System.Environment]::SetEnvironmentVariable("GIT_SSH", "c:\Program Files\OpenSSH-Win64\ssh.exe", 'User')

# https://www.technig.com/manage-windows-firewall-using-powershell/#:~:text=1.%20Try%20to%20run%20PowerShell%20as%20administrator%20and,networking%20and%20security%20cmdlets%20with%20Firewall%20PowerShell%20commands.
# allow port 22 traffic this should already be done
#New-NetFirewallRule -Protocol TCP -LocalPort 22 -Direction Inbound -Action Allow -DisplayName SSH
# assume we are using the private network rules so display them
# these do not seem to be needed
Get-NetFirewallProfile -Profile Private
Get-NetFirewallRule -Enable True | Select-String -Pattern ssh
Get-NetFirewallRule -Enable True | Select-String -Pattern RemoteDesktop

# you need to reboot
# Restart-Computer
