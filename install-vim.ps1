#!/mnt/c/Users/rich/scoop/shims/pwsh.exe
#
# Has version 8.2 not working well but does have working SSH Client
# Has the latest OpenSSH 8.5 which we can use sort of but ssh-agent does not work

Get-ChildItem -Path 'c:\Program Files\Vim'
if (! $?) {
    Write-Host "winget install vim there is no way to see if it is already installled automatically"
    winget install vim
}


# https://www.thewindowsclub.com/where-are-the-windows-registry-files-located-in-windows-7
# HKEY_LOCAL_MACHINE\SYSTEM is really in \system32\config\system
# HKEY_LOCAL_MACHINE\USER\UserProfile is really in \winnt\profiles\$USER
# https://stackoverflow.com/questions/37663602/powershell-add-to-path-temporarily
# this changes the path for the total machine we just want to change the user path
# https://stackoverflow.com/questions/8358265/how-to-update-path-variable-permanently-from-windows-command-line/10411111#10411111
# https://stackoverflow.com/questions/573817/where-are-environment-variables-stored-in-the-windows-registry
# you can use HKCU for Registry::HKEY_CURRENT_UsER and HKLM: for Registry::HKEY_LOCAL_MACHINE
# Because these are Powerscript vritual drives
$user_env = 'HKCU:\Environment'
# there is another path as welll as these are blank
$machine_env = 'HKLM:\System\CurrentControlSet\Control\Session Manager\Environment'
$path = (Get-ItemProperty -Path $user_env).path
Write-Host "Got" $path

# https://morgantechspace.com/2016/08/powershell-check-if-string-contains-word.html
# https://searchitoperations.techtarget.com/answer/Manage-the-Windows-PATH-environment-variable-with-PowerShell
# use -split ';' to create an array but we just do a string search here
if ($path.Contains('\Program Files\Vim\vim')) {
    Write-Host "vim already in path"
    return
}

# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/split-path?view=powershell-7.1
$vim_path=Get-ChildItem -Path 'c:\Program Files\Vim' -Filter 'vim.exe' -Recurse | Split-Path -Parent

# https://stackoverflow.com/questions/36197304/how-can-i-check-in-powershell-if-get-childitem-has-failed
if  (! $?) {
    Write-Host "could not find vim.exe"
    return
}

Write-Host 'adding to path'
$path = "$path;$vim_path"
sudo Set-ItemProperty -Path $user_env -Name path -Value $path
(Get-ItemProperty -Path $user_env).path
Write-Host 'to pick up new path exit terminal'
