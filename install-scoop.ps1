#!/c/WINDOWS/System32/WindowsPowerShell/v1.0/powershell
# https://www.how2shout.com/how-to/install-scoop-windows-package-manager.html#:~:text=How%20to%20Install%20Scoop%20Package%20Manager%20on%20Windows,7%20Here%20are%20the%20Scoop%20Useful%20Commands%20list
Set-ExecutionPolicy RemoteSigned -scope CurrentUser
iwr -useb get.scoop.sh | iex
