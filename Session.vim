let SessionLoad = 1
if &cp | set nocp | endif
let s:so_save = &so | let s:siso_save = &siso | set so=0 siso=0
let v:this_session=expand("<sfile>:p")
silent only
silent tabonly
cd ~/ws.richtong/git/src/bin
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
set shortmess=aoO
argglobal
%argdel
$argadd install-lfs.sh
$argadd install-lint.sh
$argadd install-linux-debug.sh
$argadd install-mac-photo-tools.sh
$argadd install-mac-wireless.sh
$argadd install-macapp.sh
$argadd install-machines.sh
$argadd install-macports.sh
$argadd install-mail.sh
$argadd install-markdown.sh
$argadd install-minikube.sh
$argadd install-ml.sh
$argadd install-modular-boost.sh
$argadd install-mongodb.sh
$argadd install-mysql.sh
$argadd install-neon.sh
$argadd install-neovim.sh
$argadd install-nfs-client.sh
$argadd install-node.sh
$argadd install-nonfree.sh
$argadd install-norton.sh
$argadd install-nosleep.sh
$argadd install-nvidia-docker.sh
$argadd install-nvidia-drv.sh
$argadd install-nvidia.sh
$argadd install-nvm.sh
$argadd install-openssh-server.sh
$argadd install-packages.sh
$argadd install-phoronix.sh
$argadd install-pia.sh
$argadd install-post-upgrade.sh
$argadd install-powerline.sh
$argadd install-pyenv.sh
$argadd install-python.sh
$argadd install-quicktile.sh
$argadd install-repos.sh
$argadd install-rkt.sh
$argadd install-rstudio.sh
$argadd install-ruby.sh
$argadd install-secrets.sh
$argadd install-selfhost.sh
$argadd install-shiftit.sh
$argadd install-slack.sh
$argadd install-solarized.sh
$argadd install-sphinx.sh
$argadd install-spotify.sh
$argadd install-ssh-keys.sh
$argadd install-sshfs.sh
$argadd install-ssmtp.sh
$argadd install-streamlit.sh
$argadd install-stylelint.sh
$argadd install-sublime.sh
$argadd install-terraform-gcloud.sh
$argadd install-terraform.sh
$argadd install-tlp.sh
$argadd install-tmux.sh
$argadd install-torbrowser.sh
$argadd install-travis-env.sh
$argadd install-travis.sh
$argadd install-ufw.sh
$argadd install-unifi-controller.sh
$argadd install-vagrant.sh
$argadd install-veracrypt.sh
$argadd install-vim.sh
$argadd install-virtualbox.sh
$argadd install-vmware-tools.sh
$argadd install-vpn.sh
$argadd install-vscode.sh
$argadd install-wordpress.sh
$argadd install-wxpython.sh
$argadd install-xhyve.sh
$argadd install-xquartz.sh
$argadd install-xrdp-custom.sh
$argadd install-yay.sh
$argadd install-yeoman.sh
$argadd install-zfs-auto-snapshot.sh
$argadd install-zfs-datasets.sh
$argadd install-zfs-quotas.sh
$argadd install-zfs.sh
$argadd install-zsh.sh
$argadd mac-install.sh
$argadd macports-migrate.sh
$argadd make-bin.sh
$argadd make-password.sh
$argadd mk-sshfs-files.sh
$argadd mkdir-accounts.sh
$argadd mount-and-copy-ecryptfs.sh
$argadd mount-ecryptfs.sh
$argadd mount-nfs.sh
$argadd mount-private-dmg.sh
$argadd mount-sshfs.sh
$argadd mount-volume.sh
$argadd phoronix-run.sh
$argadd prebuild.sh
$argadd propagate-ssh-keys.sh
$argadd remove-accounts.sh
$argadd remove-agents.sh
$argadd remove-all.sh
$argadd remove-crontab.sh
$argadd remove-nvidia.sh
$argadd remove-prebuild.sh
$argadd rm-port.sh
$argadd rsync-and-hash.sh
$argadd rsync-existing.sh
$argadd run-ubuntu.sh
$argadd run-vino.sh
$argadd secrets-bootstrap.sh
$argadd secrets-create.sh
$argadd secrets-find-file-sharing.sh
$argadd secrets-generate.sh
$argadd secrets-keygen.sh
$argadd secrets-mount-ecryptfs-and-dmg.sh
$argadd secrets-mount.sh
$argadd secrets-op.sh
$argadd secrets-passwd.sh
$argadd secrets-stow.sh
$argadd secrets-to-veracrypt.sh
$argadd set-console-or-graphical.sh
$argadd set-hostname.sh
$argadd set-passwd.sh
$argadd set-profile.sh
$argadd set-ssh-agent.sh
$argadd sphinx-configure.sh
$argadd ssh-copy-ids.sh
$argadd start-vpn.sh
$argadd stow-all.sh
$argadd stress.sh
$argadd surround.sh
$argadd system-run.sh
$argadd system-test.sh
$argadd test-lib-config.sh
$argadd upgrade-release.sh
$argadd veracrypt-create.sh
$argadd veracrypt-find.sh
$argadd veracrypt-mount.sh
$argadd verify-docker.sh
$argadd zfs-add.sh
$argadd zfs-fix.sh
$argadd zfs-rename.sh
$argadd zfs-shapshot-rm.sh
$argadd zfs-snapshot.sh
edit install-solarized.sh
set splitbelow splitright
set nosplitbelow
set nosplitright
wincmd t
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
argglobal
44argu
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=20
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let s:l = 1 - ((0 * winheight(0) + 24) / 48)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
1
normal! 0
tabnext 1
badd +53 install-lfs.sh
badd +1 install-lint.sh
badd +1 install-linux-debug.sh
badd +1 install-mac-photo-tools.sh
badd +1 install-mac-wireless.sh
badd +1 install-macapp.sh
badd +1 install-machines.sh
badd +1 install-macports.sh
badd +1 install-mail.sh
badd +1 install-markdown.sh
badd +1 install-minikube.sh
badd +1 install-ml.sh
badd +57 install-modular-boost.sh
badd +1 install-mongodb.sh
badd +1 install-mysql.sh
badd +0 install-neon.sh
badd +1 install-neovim.sh
badd +64 install-nfs-client.sh
badd +1 install-node.sh
badd +1 install-nonfree.sh
badd +1 install-norton.sh
badd +15 install-nosleep.sh
badd +83 install-nvidia-docker.sh
badd +106 install-nvidia-drv.sh
badd +224 install-nvidia.sh
badd +48 install-nvm.sh
badd +118 install-openssh-server.sh
badd +48 install-packages.sh
badd +33 install-phoronix.sh
badd +112 install-pia.sh
badd +1 install-post-upgrade.sh
badd +1 install-powerline.sh
badd +63 install-pyenv.sh
badd +1 install-python.sh
badd +162 install-quicktile.sh
badd +2 install-repos.sh
badd +35 install-rkt.sh
badd +55 install-rstudio.sh
badd +1 install-ruby.sh
badd +176 install-secrets.sh
badd +63 install-selfhost.sh
badd +1 install-shiftit.sh
badd +2 install-slack.sh
badd +1 install-solarized.sh
badd +1 install-sphinx.sh
badd +1 install-spotify.sh
badd +1 install-ssh-keys.sh
badd +1 install-sshfs.sh
badd +1 install-ssmtp.sh
badd +1 install-streamlit.sh
badd +1 install-stylelint.sh
badd +1 install-sublime.sh
badd +1 install-terraform-gcloud.sh
badd +1 install-terraform.sh
badd +1 install-tlp.sh
badd +1 install-tmux.sh
badd +1 install-torbrowser.sh
badd +1 install-travis-env.sh
badd +1 install-travis.sh
badd +1 install-ufw.sh
badd +1 install-unifi-controller.sh
badd +1 install-vagrant.sh
badd +1 install-veracrypt.sh
badd +1 install-vim.sh
badd +1 install-virtualbox.sh
badd +1 install-vmware-tools.sh
badd +1 install-vpn.sh
badd +1 install-vscode.sh
badd +1 install-wordpress.sh
badd +1 install-wxpython.sh
badd +1 install-xhyve.sh
badd +1 install-xquartz.sh
badd +1 install-xrdp-custom.sh
badd +1 install-yay.sh
badd +1 install-yeoman.sh
badd +1 install-zfs-auto-snapshot.sh
badd +1 install-zfs-datasets.sh
badd +1 install-zfs-quotas.sh
badd +1 install-zfs.sh
badd +1 install-zsh.sh
badd +1 mac-install.sh
badd +1 macports-migrate.sh
badd +1 make-bin.sh
badd +1 make-password.sh
badd +1 mk-sshfs-files.sh
badd +1 mkdir-accounts.sh
badd +1 mount-and-copy-ecryptfs.sh
badd +1 mount-ecryptfs.sh
badd +1 mount-nfs.sh
badd +1 mount-private-dmg.sh
badd +1 mount-sshfs.sh
badd +1 mount-volume.sh
badd +1 phoronix-run.sh
badd +1 prebuild.sh
badd +1 propagate-ssh-keys.sh
badd +1 remove-accounts.sh
badd +1 remove-agents.sh
badd +1 remove-all.sh
badd +1 remove-crontab.sh
badd +1 remove-nvidia.sh
badd +1 remove-prebuild.sh
badd +1 rm-port.sh
badd +1 rsync-and-hash.sh
badd +1 rsync-existing.sh
badd +1 run-ubuntu.sh
badd +1 run-vino.sh
badd +1 secrets-bootstrap.sh
badd +1 secrets-create.sh
badd +1 secrets-find-file-sharing.sh
badd +1 secrets-generate.sh
badd +1 secrets-keygen.sh
badd +1 secrets-mount-ecryptfs-and-dmg.sh
badd +1 secrets-mount.sh
badd +1 secrets-op.sh
badd +1 secrets-passwd.sh
badd +1 secrets-stow.sh
badd +1 secrets-to-veracrypt.sh
badd +1 set-console-or-graphical.sh
badd +1 set-hostname.sh
badd +1 set-passwd.sh
badd +1 set-profile.sh
badd +1 set-ssh-agent.sh
badd +1 sphinx-configure.sh
badd +1 ssh-copy-ids.sh
badd +1 start-vpn.sh
badd +1 stow-all.sh
badd +1 stress.sh
badd +1 surround.sh
badd +1 system-run.sh
badd +1 system-test.sh
badd +1 test-lib-config.sh
badd +1 upgrade-release.sh
badd +1 veracrypt-create.sh
badd +1 veracrypt-find.sh
badd +1 veracrypt-mount.sh
badd +1 verify-docker.sh
badd +1 zfs-add.sh
badd +1 zfs-fix.sh
badd +1 zfs-rename.sh
badd +1 zfs-shapshot-rm.sh
badd +1 zfs-snapshot.sh
badd +14 install-1password.sh
badd +334 Session.vim
if exists('s:wipebuf') && len(win_findbuf(s:wipebuf)) == 0
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20 shortmess=filnxtToOSc
set winminheight=1 winminwidth=1
let s:sx = expand("<sfile>:p:r")."x.vim"
if filereadable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &so = s:so_save | let &siso = s:siso_save
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
