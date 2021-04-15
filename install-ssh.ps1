#!/mnt/c/WINDOWS/System32/WindowsPowerShell/v1.0/powershell.exe
# https://stackoverflow.com/questions/52113738/starting-ssh-agent-on-windows-10-fails-unable-to-start-ssh-agent-service-erro
#runas.exe /savecred /user:"$ADMIN" \
# "choco install openssh -params /SSHServerFeature /KeyBasedAuthenticationFeature" 
# https://mangolassi.it/topic/9954/installing-openssh-on-windows-via-chocolatey
#-ArgumentList ('-noexit choco.exe install openssh')
choco.exe install openssh -params '"/SSHServerFeature /KeyBasedAuthenticationFeature"'

# https://dmtavt.com/post/2020-08-03-ssh-agent-powershell/
# needs to run as an admin
Get-Service -Name ssh-agent | Set-Service -StartupType Automatic
Start-Service ssh-agent
# https://stackoverflow.com/questions/10574267/cannot-spawn-ssh-when-connecting-to-github-but-ssh-t-gitgithub-com-works
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_environment_variables?view=powershell-7.1#:~:text=Environment%20variables%2C%20unlike%20other%20types%20of%20variables%20in,are%20needed%20in%20both%20parent%20and%20child%20processes.
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_environment_variables?view=powershell-7.1
$env:GIT_SSH="c:\Program Files\OpenSSH-Win64\ssh.exe"

# Need to set the User too so it is not overridden
[Environment]::SetEnvironmentVariable("GIT_SSH", "c:\Program Files\OpenSSH-Win64\ssh.exe", 'Machine')
[Environment]::SetEnvironmentVariable("GIT_SSH", "c:\Program Files\OpenSSH-Win64\ssh.exe", 'User')