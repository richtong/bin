#!/c/WINDOWS/System32/WindowsPowerShell/v1.0/powershell
# https://stackoverflow.com/questions/52113738/starting-ssh-agent-on-windows-10-fails-unable-to-start-ssh-agent-service-erro
log_verbose "by default sshd is not started so set to automatic then start"
Get-Service -Name ssh-agent | Start-Service -StartupType Automatic
Start-Service ssh-agent
log_verbose "make sure GIT_SSH points to this and not default Windows OpenSSH"
# https://stackoverflow.com/questions/10574267/cannot-spawn-ssh-when-connecting-to-github-but-ssh-t-gitgithub-com-works
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_environment_variables?view=powershell-7.1#:~:text=Environment%20variables%2C%20unlike%20other%20types%20of%20variables%20in,are%20needed%20in%20both%20parent%20and%20child%20processes.
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_environment_variables?view=powershell-7.1
$env:GIT_SSH="c:\Program Files\OpenSSH-Win64\ssh.exe"

# this is not sticky for some reason
[Environment]::SetEnvironmentVariable("GIT_SSH", "c:\Program Files\OpenSSH-Win64\ssh.exe", 'Machine')
