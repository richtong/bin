#!/mnt/c/WINDOWS/System32/WindowsPowerShell/v1.0/powershell.exe
# https://stackoverflow.com/questions/52113738/starting-ssh-agent-on-windows-10-fails-unable-to-start-ssh-agent-service-erro
#runas.exe /savecred /user:"$ADMIN" \
# "choco install openssh -params /SSHServerFeature /KeyBasedAuthenticationFeature" 
# https://mangolassi.it/topic/9954/installing-openssh-on-windows-via-chocolatey
#-ArgumentList ('-noexit choco.exe install openssh')
# make sure Windows OpenSSH is not installed as it is very old
Remove-WindowsCapability -Onlin -Name OpenSSH.Client
Remove-WindowsCapabiltiy -Online -Name OpenSSH.Server
# Has version 8.2
 choco.exe install openssh -params '"/SSHServerFeature /KeyBasedAuthenticationFeature"'
# Has the latest OpenSSH 8.5
#scoop install git-with-openssh

# https://dmtavt.com/post/2020-08-03-ssh-agent-powershell/
# needs to run as an admin
Get-Service -Name ssh-agent | Set-Service -StartupType Automatic
Start-Service ssh-agent

# start the ssh server
# https://www.pugetsystems.com/labs/hpc/How-To-Use-SSH-Client-and-Server-on-Windows-10-1470/
Get-Service -Name sshd | Set-Service -StartupType Automatic
# make sure port 22 is open
Get-NetFirewallRule -Name *ssh*

# https://stackoverflow.com/questions/10574267/cannot-spawn-ssh-when-connecting-to-github-but-ssh-t-gitgithub-com-works
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_environment_variables?view=powershell-7.1#:~:text=Environment%20variables%2C%20unlike%20other%20types%20of%20variables%20in,are%20needed%20in%20both%20parent%20and%20child%20processes.
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_environment_variables?view=powershell-7.1
$env:GIT_SSH="c:\Program Files\OpenSSH-Win64\ssh.exe"

# Need to set the User too so it is not overridden
[Environment]::SetEnvironmentVariable("GIT_SSH", "c:\Program Files\OpenSSH-Win64\ssh.exe", 'Machine')
[Environment]::SetEnvironmentVariable("GIT_SSH", "c:\Program Files\OpenSSH-Win64\ssh.exe", 'User')

# Enable sshd server
# https://zamarax.com/2020/02/14/installing-sftp-ssh-ftp-server-on-windows-with-openssh/
Get-Service -Name sshd | Set-Service -StartupType Automatic
Start-Service sshd

# https://www.technig.com/manage-windows-firewall-using-powershell/#:~:text=1.%20Try%20to%20run%20PowerShell%20as%20administrator%20and,networking%20and%20security%20cmdlets%20with%20Firewall%20PowerShell%20commands.
# allow port 22 traffic this should already be done
#New-NetFirewallRule -Protocol TCP -LocalPort 22 -Direction Inbound -Action Allow -DisplayName SSH
# assume we are using the private network rules so display them
Get-NetFirewallProfile -Profile Private
Get-NetFirewallRule -Enable True | Select-String -Pattern ssh
Get-NetFirewallRule -Enable True | Select-String -Pattern RemoteDesktop

# you need to reboot
# Restart-Computer
