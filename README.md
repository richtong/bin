# Infrastructure Binary Utility commands

This repository contains a collection of convenience scripts for installing and
managing development environments.

## Overview

These scripts are primarily designed for macOS and Linux (Ubuntu) and assist in
setting up various tools, applications, and system configurations. They are
intended to be experimental and are actively developed.

## Documentation

For detailed information on every script, including its purpose, usage, and
parameters, please refer to the comprehensive guide:

**[>> Script and Tool Documentation (PROMPT.md)](PROMPT.md)**

## Quickstart

Most installation scripts can be found and run from this `bin` directory. To
find a specific installer, you can `grep` for it:

```bash
bash grep -i "docker" install-*.sh `
```

The primary installation script is `install.sh`, which handles core setup, while
`pre-install.sh` bootstraps essential tools like Homebrew.

## Environment Management

- **Version Management:** `asdf` is used to manage tool versions (Node, Python,
  etc.) via `.tool-versions` files.
- **Directory-level Environments:** `direnv` is recommended for managing
  environment variables on a per-directory basis using `.envrc` files. This is
  ideal for loading secrets from 1Password or activating Python virtual
  environments.

## Secrets Management

It is strongly recommended to avoid storing secrets "at rest." This repository
includes an opinionated framework using Veracrypt and `stow` for managing
encrypted secrets. See [`install-secrets.sh`](./install-secrets.sh) and the
documentation in [`PROMPT.md`](./PROMPT.md) for more details.

### `add-user.sh`

Adds a new user to the local machine, configuring their UID, groups, password,
and SSH keys.

### `change-string.sh`

A utility to perform a global search and replace for a string in one or more
files.

### `change-user.sh`

Changes the UID and GID of a user to match the values specified in a user file.

### `checkaws.py`

A Python script to check for and validate AWS credentials in the environment.

### `cleanup-brew.sh`

A script for cleaning up Homebrew packages on macOS.

### `conda-activate.sh`

A simple script to activate the `restart` conda environment.

### `create-agents-authorized-keys.sh`

Aggregates user public keys to grant access to agent accounts.

### `create-prebuild-private.sh`

(Linux) Creates an encrypted directory for pre-build secrets.

### `create-private-prebuild.sh`

(macOS) Creates an encrypted disk image for pre-build scripts.

### `delete-google-user.sh`

Deletes a Google Workspace user and archives their data.

### `disk-info.sh`

Displays detailed information about connected storage devices.

### `disk-wipe.sh`

Securely wipes a disk. **Use with extreme caution.**

### `docker-list-tags.sh`

Lists all tags for a Docker image on a public registry.

### `docker-machine-create.sh`

Creates a Docker Swarm on a series of hosts.

### `dotfiles-backup.sh`

Backs up existing dotfiles before linking from a repository.

### `dotfiles-to-repo.sh`

Moves dotfiles into a `stow`-managed repository.

### `download-acml.sh`

Downloads the AMD Core Math Library (ACML).

### `exif-copy.sh`

Copies EXIF metadata between image files.

### `find-broken-symlinks.sh`

Finds and lists broken symbolic links.

### `fix-ssh-permissions.sh`

Corrects file permissions for SSH keys and other sensitive directories.

### `gcloud-create.sh`

Sets up a Google Cloud Platform project for Terraform.

### `gcloud-serviceaccount-create.sh`

Creates a Google Cloud service account.

### `get-ip.sh`

Gets the IP address of a host.

### `git-ls-large.sh`

Lists large files in a git repository.

### `git-merge-repos.sh`

Merges one git repository into another.

### `git-set-default-branch.sh`

Changes the default branch of a GitHub repository.

### `git-submodule-rm.sh`

Deletes a git submodule.

### `git-submodule-update.sh`

Initializes and updates git submodules.

### `hashdeep-audit.sh`

Audits a directory against a hashdeep file.

### `hashdeep-create.sh`

Creates a hashdeep file for a set of files or directories.

### `install-1password.sh`

Installs 1Password and its CLI.

### `install-11template.sh`

Installs 11template.

### `install-accounts.sh`

Adds groups and users from files (Deprecated).

### `install-agent.sh`

Installs the configuration for an unattended agent.

### `install-agents.sh`

Copies ssh and prebuild scripts for each agent.

### `install-ai.sh`

Installs desktop AI tools.

### `install-android-tools.sh`

Installs Android Studio and platform tools.

### `install-android.sh`

Installs Android Studio.

### `install-ansible.sh`

Installs Ansible.

### `install-asdf.sh`

Installs asdf for managing multiple runtime versions.

### `install-auth0.sh`

Installs the Auth0 CLI.

### `install-aws-config.sh`

Configures AWS credentials and settings.

### `install-aws-local.sh`

Installs tools for local AWS development.

### `install-bash-completion.sh`

Installs bash completion.

### `install-bazel.sh`

Installs the Bazel build tool.

### `install-bcm43228.sh`

Installs the BCM43228 Wi-Fi driver.

### `install-benchmark.sh`

Installs benchmarking tools.

### `install-chezmoi.sh`

Installs chezmoi for dotfile management.

### `install-choco.ps1`

(Windows) Installs the Chocolatey package manager.

### `install-comfyui.sh`

Installs ComfyUI and its models.

### `install-conda.sh`

Installs Miniconda or Anaconda.

### `install-cssh.sh`

Installs ClusterSSH.

### `install-deluge.sh`

Installs the Deluge BitTorrent client.

### `install-dev-repos.sh`

Installs standard helper development repositories.

### `install-divvy.sh`

Installs Divvy, a window manager for macOS.

### `install-docker-alternative.sh`

Installs Docker alternatives like Podman, Lima, and Colima.

### `install-docker-for-mac.sh`

Installs Docker for Mac.

### `install-docker.sh`

Installs Docker, Docker Machine, and Docker Compose.

### `install-dorothy.sh`

Installs Dorothy, a dotfile manager.

### `install-dropbox.sh`

Installs Dropbox.

### `install-dwa182.sh`

Installs the D-Link DWA-182 Wi-Fi adapter driver.

### `install-ecryptfs.sh`

Installs and sets up eCryptfs.

### `install-enpass.sh`

Installs the Enpass password manager.

### `install-flocker.sh`

Installs the Flocker Docker volume manager.

### `install-fonts.sh`

Installs various fonts.

### `install-gazebo.sh`

Installs Gazebo and OpenDroneMap. ### `install-gitter.sh`

Installs the Gitter instant messaging tool.

### `install-google-chrome.sh`

Installs Google Chrome and Chrome Remote Desktop.

### `install-google-drive.sh`

Installs Google Drive on Mac and rclone on Linux.

### `install-gpg.sh`

Installs GPG and exports secret keys.

### `install-grub.sh`

Configures GRUB to not be silent during boot.

### `install-hammerspoon.sh`

Installs Hammerspoon and various window management Spoons.

### `install-hfs.sh`

Installs tools to mount HFS+ drives on Linux.

### `install-hugin.sh`

Installs Hugin panorama stitcher and its dependencies on Mac.

### `install-iam-key-daemon.sh`

Installs a daemon to sync AWS IAM keys to a Linux machine.

### `install-intel-opencl.sh`

Installs the Intel OpenCL SRB 5 package.

### `install-intel-realsense.sh`

Installs the Intel RealSense SDK on Mac.

### `install-iterm2.sh`

Installs iTerm2, dynamic profiles, and shell integrations.

### `install-java.sh`

Installs Java SDK with support for jenv or asdf.

### `install-jenv.sh`

Installs jenv for managing Java environments.

### `install-jupyter.sh`

Installs JupyterLab and many useful extensions. ### `install-lint.sh`

Installs a suite of linters for various programming languages.

### `install-mac-wireless.sh`

A utility for managing wireless networks on macOS.

### `install-machines.sh`

(Deprecated) Installs and configures accounts for testing and deployment
machines.

### `install-menumeters.sh`

Installs MenuMeters for system monitoring on macOS.

### `install-minikube.sh`

Installs Minikube for running a local Kubernetes cluster.

### `install-ml.sh`

Pulls various Docker images for machine learning frameworks.

### `install-models.sh`

Installs and manages AI models for Ollama.

### `install-mongodb.sh`

Installs the MongoDB Community Edition.

### `install-node.sh`

Installs Node.js and related tools.

### `install-nordvpn.sh`

Installs the NordVPN client.

### `install-nvidia-docker.sh`

Installs nvidia-docker to enable GPU support in Docker containers.

### `install-nvidia.sh`

Installs the proprietary NVIDIA graphics drivers.

### `install-nvim.sh`

Installs Neovim and its configurations.

### `install-nvm.sh`

Installs Node Version Manager (nvm). ### `install-packages.sh`

A generic script to install packages.

### `install-pia.sh`

Installs the Private Internet Access VPN client.

### `install-post-macos-upgrade.sh`

A script to run after a major macOS upgrade to fix Homebrew.

### `install-qgc.sh`

Installs QGroundControl.

### `install-quicktile.sh`

Installs `quicktile`, a tiling window manager for XFCE.

### `install-rkt.sh`

Installs `rkt`, a container runtime from CoreOS.

### `install-rpi-os.sh`

Writes a Raspberry Pi OS image to an SD card.

### `install-rstudio.sh`

Installs R and RStudio.

### `install-ruby.sh`

Installs Ruby.

### `install-rust.sh`

Installs the Rust programming language.

### `install-samba.sh`

Installs and configures Samba.

### `install-scoop.ps1`

(Windows) Installs the Scoop package manager.

### `install-shiftit.sh`

Installs ShiftIt, a window manager for macOS.

### `install-sound.sh`

Installs sound-related applications from Rogue Amoeba.

### `install-sphinx.sh`

Installs Sphinx and its extensions. ### `install-ssh-keys.sh`

Installs SSH keys from an encrypted source.

### `install-ssh.ps1`

(Windows) Installs and configures OpenSSH.

### `install-ssh.sh`

Installs OpenSSH and the SSH server.

### `install-sshfs.sh`

Installs `sshfs` for mounting remote filesystems over SSH.

### `install-ssmtp.sh`

Installs and configures `ssmtp` for sending email.

### `install-stylelint.sh`

Installs `stylelint` for linting CSS and PostCSS.

### `install-sublime.sh`

Installs Sublime Text and recommended packages.

### `install-tailscale.sh`

Installs Tailscale, a zero-config VPN.

### `install-tensorflow.sh`

Installs TensorFlow.

### `install-thefuck.sh`

Installs `thefuck`, a command-line error correcting tool.

### `install-tlp.sh`

Installs TLP for laptop power management.

### `install-travis.sh`

Installs the Travis CI command-line tool.

### `install-typescript.sh`

Installs TypeScript.

### `install-ufw.sh`

Installs and configures UFW (Uncomplicated Firewall).

### `install-vagrant.sh`

Installs Vagrant and VirtualBox.

### `install-veracrypt.sh`

Installs the VeraCrypt disk encryption software.

### `install-vim.py`

A Python script to install a customized Vim configuration.

### `install-vscode.sh`

Installs Visual Studio Code and a list of extensions.

### `install-yubikey.sh`

Installs the YubiKey Manager and Authenticator applications.

### `install-zfs-quotas.sh`

Configures ZFS quotas for users and datasets.

### `install-zotero.sh`

Installs the Zotero reference manager.
