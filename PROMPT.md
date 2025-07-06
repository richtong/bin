# Infrastructure Binary Utility Commands

This document provides a comprehensive overview of the shell scripts and
utilities available in this repository. These scripts are designed to streamline
development environment setup, configuration, and management.

## Script Categories

The scripts are organized into the following categories for clarity and ease of use:

- **Core Development Tools:** Essential tools for any development environment.
- **Application and Service Installers:** Scripts for setting up specific
  applications and services.
- **System and Hardware Configuration:** Utilities for configuring the
  underlying operating system and hardware.
- **Secrets and Access Management:** Tools for securely managing secrets and
  user access.
- **Git and Repository Management:** Helpers for common Git and repository operations.
- **Miscellaneous Utilities:** Various other helpful scripts.

---

## Core Development Tools

### `install-hammerspoon.sh`

- **Description:** Installs and configures Hammerspoon, a powerful automation
  tool for macOS, along with essential "Spoons" (plugins) for window management
  and other tasks.
- **Usage:**

  ```bash
  ./install-hammerspoon.sh
  ```

### `install-bash-completion.sh`

- **Description:** Sets up bash completion for Homebrew and other command-line
  tools, significantly improving shell usability.
- **Usage:**

  ```bash
  ./install-bash-completion.sh
  ```

### `install-dorothy.sh`

- **Description:** Installs Dorothy, a dotfile manager for synchronizing
  configurations across multiple machines.
- **Usage:**

  ```bash
  ./install-dorothy.sh
  ```

### `install-java.sh`

- **Description:** Installs specified versions of the Java SDK, with support for
  version management via `jenv` or `asdf`.
- **Usage:**

  ```bash
  # Install default Java version
  ./install-java.sh

  # Install a specific version
  ./install-java.sh -r 8
  ```

### `install-powerline.sh`

- **Description:** Installs Powerline-Go and Powerline fonts to create a
  feature-rich, visually appealing shell prompt.
- **Usage:**

  ```bash
  ./install-powerline.sh
  ```

---

## Application and Service Installers

### `install-dropbox.sh`

- **Description:** Installs Dropbox on macOS or Linux, with support for both
  graphical and headless (CLI) installations.
- **Usage:**

  ```bash
  ./install-dropbox.sh
  ```

---

## System and Hardware Configuration

### `install-grub.sh`

- **Description:** Modifies the GRUB bootloader configuration on Linux to make
  the boot process visible instead of silent.
- **Usage:**

  ```bash
  sudo ./install-grub.sh
  ```

### `install-ubuntu-to-usb.sh`

- **Description:** Guides the user in creating a bootable Ubuntu USB drive on a
  Mac by installing and launching Balena Etcher.
- **Usage:**

  ```bash
  ./install-ubuntu-to-usb.sh
  ```

### `install-dwa182.sh`

- **Description:** Installs the necessary Realtek drivers for the D-Link DWA-182
  Wi-Fi adapter and other similar devices on Linux.
- **Usage:**

  ```bash
  sudo ./install-dwa182.sh
  ```

### `set-console-or-graphical.sh`

- **Description:** Switches an Ubuntu 16.04 system between graphical (desktop)
  and console (multi-user) mode.
- **Usage:**

  ```bash
  # Switch to console mode
  sudo ./set-console-or-graphical.sh multi-user

  # Switch to graphical mode
  sudo ./set-console-or-graphical.sh graphical
  ```

### `disk-info.sh`

- **Description:** Displays detailed information about connected storage devices
  on both macOS and Linux.
- **Usage:**

  ```bash
  ./disk-info.sh -a
  ```

---

## Secrets and Access Management

### `install-secrets.sh`

- **Description:** Implements an opinionated secret management system using
  Veracrypt and `stow` to deploy SSH keys and other sensitive files.
- **Usage:**

  ```bash
  ./install-secrets.sh
  ```

### `create-private-prebuild.sh`

- **Description:** Creates an encrypted `Private.dmg` volume on macOS and copies
  essential pre-build and secret-management scripts into it.
- **Usage:**

  ```bash
  ./create-private-prebuild.sh
  ```

---

## Git and Repository Management

### `git-set-default-branch.sh`

- **Description:** A utility to change the default branch of a GitHub repository
  from `master` to `main` or another specified name.
- **Usage:**

  ```bash
  ./git-set-default-branch.sh -t main
  ```

### `add-user.sh`

- **Description:** Adds a new user to the local machine, sets up their UID,
  primary and secondary groups, password, and copies their SSH authorized keys.
- **Usage:**

  ```bash
  # Add a new user with default settings
  sudo ./add-user.sh -s newuser

  # Add a new user with a specific UID and groups
  sudo ./add-user.sh -s newuser -i 1001 -g users -e "dev,docker"
  ```

- **Parameters:**
  - `-d`: Toggle debug mode.
  - `-v`: Toggle verbose mode.
  - `-k <key_repo>`: Specifies the directory containing public keys (default: `public-keys`).
  - `-f`: Force a password reset.
  - `-x <password>`: Set a default encrypted password.
  - `-i <uid>`: Set the new user's UID.
  - `-g <group>`: Set the new user's primary group.
  - `-t <type>`: Set the user type (e.g., `user`, `admin`).
  - `-s <username>`: The new user's name.
  - `-e <groups>`: Comma-separated list of extra groups.
  - `-n <github_name>`: GitHub login name.
  - `-m <email>`: Email address for the new user.

### `change-string.sh`

- **Description:** A utility to perform a global search and replace for a string
  in one or more files.
- **Usage:**

  ```bash
  ./change-string.sh -o "old_string" -n "new_string" file1.txt file2.sh
  ```

- **Parameters:**
  - `-o <string>`: The string to be replaced.
  - `-n <string>`: The new string to replace with.

### `change-user.sh`

- **Description:** Changes the UID and GID of a user to match the values
  specified in a user file.
- **Usage:**

  ```bash
  sudo ./change-user.sh -u /path/to/users.txt username
  ```

- **Parameters:**
  - `-u <user_file>`: Path to the file containing user information (default: `$WS_DIR/git/src/infra/etc/users.txt`).

### `cleanup-brew.sh`

- **Description:** A script for cleaning up Homebrew packages on macOS,
  particularly for removing obsolete software or packages that `brew uninstall`
  fails to remove completely.
- **Usage:**

  ```bash
  # Run standard brew cleanup
  ./cleanup-brew.sh

  # Force remove specific packages
  ./cleanup-brew.sh package1 package2
  ```

- **Parameters:**
  - `-r <version>`: Specify a version number (default: 7).

### `create-agents-authorized-keys.sh`

- **Description:** Aggregates all user public SSH keys into a single
  `authorized_keys` file for each agent, allowing users to access agent accounts.
- **Usage:**

  ```bash
  ./create-agents-authorized-keys.sh
  ```

### `create-prebuild-private.sh`

- **Description:** (Linux) Creates an encrypted directory using `ecryptfs` to
  store pre-build secrets.
- **Usage:**

  ```bash
  # Copy to a USB key
  ./create-prebuild-private.sh -u

  # Copy to a Dropbox directory
  ./create-prebuild-private.sh -r
  ```

### `delete-google-user.sh`

- **Description:** Deletes a Google Workspace user, transfers their data, and
  sets up email forwarding. Requires `gam`.
- **Usage:**

  ```bash
  ./delete-google-user.sh user@example.com
  ```

### `disk-wipe.sh`

- **Description:** A utility to completely and securely wipe a disk. **Use with
  extreme caution.**
- **Usage:**

  ```bash
  # Securely wipe a disk (will prompt for confirmation)
  sudo ./disk-wipe.sh -s /dev/sdX
  ```

### `docker-list-tags.sh`

- **Description:** Lists all available tags for a Docker image on a public
  registry.
- **Usage:**

  ```bash
  ./docker-list-tags.sh ubuntu
  ```

### `docker-machine-create.sh`

- **Description:** Creates a Docker Swarm by setting up Docker Machine on a
  series of hosts.
- **Usage:**

  ```bash
  ./docker-machine-create.sh host1 host2
  ```

### `dotfiles-backup.sh`

- **Description:** Backs up existing dotfiles before they are replaced by
  symlinks from a `stow`-managed repository.
- **Usage:**

  ```bash
  ./dotfiles-backup.sh
  ```

### `dotfiles-to-repo.sh`

- **Description:** Moves specified dotfiles into a `stow`-managed dotfiles
  repository.
- **Usage:**

  ```bash
  ./dotfiles-to-repo.sh -p macos .bash_profile
  ```

### `download-acml.sh`

- **Description:** Downloads the AMD Core Math Library (ACML) from an S3 bucket.
- **Usage:**

  ```bash
  ./download-acml.sh
  ```

### `exif-copy.sh`

- **Description:** Copies EXIF metadata from one image file to another. Requires
  `exiftool`.
- **Usage:**

  ```bash
  ./exif-copy.sh -f image.jpg -t image.avif
  ```

### `find-broken-symlinks.sh`

- **Description:** Finds and lists broken symbolic links in a directory.
- **Usage:**

  ```bash
  ./find-broken-symlinks.sh /path/to/search
  ```

### `fix-ssh-permissions.sh`

- **Description:** Corrects file permissions for SSH keys and other sensitive directories.
- **Usage:**

  ```bash
  ./fix-ssh-permissions.sh
  ```

### `gcloud-create.sh`

- **Description:** Sets up a Google Cloud Platform project for use with Terraform.
- **Usage:**

  ```bash
  ./gcloud-create.sh -b YOUR_BILLING_ACCOUNT
  ```

### `conda-activate.sh`

- **Description:** A simple script to activate the `restart` conda environment.
- **Usage:**

  ```bash
  ./conda-activate.sh
  ```

---

## Python Utilities

### `checkaws.py`

- **Description:** Checks for AWS credentials in the environment and validates
  that the profile is complete.
- **Usage:**

  ```bash
  ./checkaws.py
  ```

- **Dependencies:**
  - Requires the `surroundio` Python library. The script attempts to find it in
    a `pymod` directory relative to its location.

### `gcloud-serviceaccount-create.sh`

- **Description:** Creates a Google Cloud service account.
- **Usage:**

  ```bash
  ./gcloud-serviceaccount-create.sh
  ```

- **Parameters:**
  - `-r <version>`: Specify a version number (default: 7).

### `get-ip.sh`

- **Description:** Gets the IP address of a host.
- **Usage:**

  ```bash
  ./get-ip.sh <host>
  ```

### `git-ls-large.sh`

- **Description:** Lists large files in a git repository.
- **Usage:**

  ```bash
  ./git-ls-large.sh [repo...]
  ```

### `git-merge-repos.sh`

- **Description:** Merges one git repository into another.
- **Usage:**

  ```bash
  ./git-merge-repos.sh -t <target_repo> <source_repo>
  ```

- **Parameters:**
  - `-t <target_repo>`: The target repository (default: `richtong/src`).

### `git-submodule-rm.sh`

- **Description:** Deletes a git submodule.
- **Usage:**

  ```bash
  ./git-submodule-rm.sh <submodule_path>
  ```

- **Parameters:**
  - `-m <path>`: Location of the submodules (default: `SOURCEDIR/extern`).
  - `-f`: Force the removal.
  - `-r <path>`: Root of the repo (default: `SOURCE_DIR`).

### `git-submodule-update.sh`

- **Description:** Initializes and updates git submodules to the latest commit
  on their default branch.
- **Usage:**

  ```bash
  ./git-submodule-update.sh [repo...]
  ```

- **Parameters:**
  - `-n`: Dry run.
  - `-l <remote>`: Origin remote name (default: `origin`).
  - `-p <path>`: The location of the mono repo (default: `$DEST_REPO_SRC`).

### `hashdeep-audit.sh`

- **Description:** Audits a directory against a hashdeep file.
- **Usage:**

  ```bash
  ./hashdeep-audit.sh <source> <destination>
  ```

- **Parameters:**
  - `-s <flags>`: hashdeep flags (default: `-c sha256 -rl`).
  - `-a`: Ignore special files and do a full audit.

### `hashdeep-create.sh`

- **Description:** Creates a hashdeep file for a set of files or directories.
- **Usage:**

  ```bash
  ./hashdeep-create.sh [file list]
  ```

- **Parameters:**
  - `-s <flags>`: hashdeep flags (default: `-c sha256 -rl`).

### `install-1password.sh`

- **Description:** Installs 1Password and its CLI, and configures shell integrations.
- **Usage:**

  ```bash
  ./install-1password.sh
  ```

- **Parameters:**
  - `-f`: Force install even if 1Password exists.
  - `-n`: Do not install variables in direnv.
  - `-e <path>`: Install into .envrc for direnv (default: `$HOME/ws/git/src.envrc`).
  - `-s`: Do not install variables in shell.
  - `-r <version>`: 1Password version number (default: 8).
  - `-c <vault>`: 1Password default vault (default: `DevOps`).
  - `-k <key>`: 1Password default key (default: `"api key"`).
  - `-o`: Do not init for 1Password op plugins.

### `install-11template.sh`

- **Description:** Installs 11template.
- **Usage:**

  ```bash
  ./install-11template.sh
  ```

- **Parameters:**
  - `-f`: Force install even if the script exists.

### `install-accounts.sh`

- **Description:** Adds groups and users from files. (Deprecated)
- **Usage:**

  ```bash
  ./install-accounts.sh
  ```

- **Parameters:**
  - `-u <file>`: User and uid file (default: `../etc/users.txt`).
  - `-g <file>`: List of new groups in a text file (default: `../etc/groups.txt`).
  - `-k <dir>`: SSH key directory (default: `public-keys`).
  - `-f`: Force the password reset.
  - `-x <password>`: Default password.

### `install-agent.sh`

- **Description:** Installs the configuration needed for an unattended agent.
- **Usage:**

  ```bash
  ./install-agent.sh
  ```

- **Parameters:**
  - `-u <user>`: git User name.
  - `-e <email>`: Email use for git.
  - `-r <user>`: docker user name.
  - `-m <email>`: eMail for docker.
  - `-w <dir>`: wsdir.
  - `-k <key>`: ssh key to github.
  - `-l <key>`: ssh key for local machines.

### `install-agents.sh`

- **Description:** Copies over the ssh and prebuild script needed for each agent.
- **Usage:**

  ```bash
  ./install-agents.sh [agents...]
  ```

- **Parameters:**
  - `-s <dir>`: ssh dir (default: `$HOME/prebuild/ssh`).
  - `-w <dir>`: workspace.

### `install-ai.sh`

- **Description:** Installs desktop AI tools like Ollama and Open WebUI.
- **Usage:**

  ```bash
  ./install-ai.sh
  ```

- **Parameters:**
  - `-x`: Install extras like ComfyUI.

### `install-android-tools.sh`

- **Description:** Installs Android Studio and the Android platform tools.
- **Usage:**

  ```bash
  ./install-android-tools.sh
  ```

### `install-android.sh`

- **Description:** Installs Android Studio.
- **Usage:**

  ```bash
  ./install-android.sh
  ```

### `install-ansible.sh`

- **Description:** Installs Ansible.
- **Usage:**

  ```bash
  ./install-ansible.sh
  ```

### `install-asdf.sh`

- **Description:** Installs asdf and its plugins for managing multiple runtime
  versions of tools like Node.js, Python, Ruby, and Java.
- **Usage:**

  ```bash
  ./install-asdf.sh
  ```

- **Parameters:**
  - `-p <versions>`: Python versions to install.
  - `-n <versions>`: Node.js versions to install.
  - `-j <versions>`: Java versions to install.
  - `-r <versions>`: Ruby versions to install.
  - `-u <versions>`: UV versions to install.

### `install-auth0.sh`

- **Description:** Installs the Auth0 CLI.
- **Usage:**

  ```bash
  ./install-auth0.sh
  ```

### `install-aws-config.sh`

- **Description:** Configures AWS credentials and settings.
- **Usage:**

  ```bash
  ./install-aws-config.sh
  ```

- **Parameters:**
  - `-t <type>`: Key storage type: `1password`, `sso`, or `veracrypt` (default: `sso`).
  - `-a <dir>`: Directory for key files (default: `$HOME/.ssh/`).
  - `-i <file>`: Access key ID file name.
  - `-k <file>`: Access key file name.
  - `-f`: Force installation.
  - `-p <profile>`: AWS profile (default: `default`).
  - `-r <region>`: AWS region (default: `us-west-2`).
  - `-o <type>`: AWS output type (default: `json`).

### `install-aws-local.sh`

- **Description:** Installs AWS SAM Local and LocalStack for local AWS testing.
- **Usage:**

  ```bash
  ./install-aws-local.sh
  ```

### `install-bazel.sh`

- **Description:** Installs the Bazel build tool.
- **Usage:**

  ```bash
  ./install-bazel.sh
  ```

### `install-bcm43228.sh`

- **Description:** Installs the BCM43228 Wi-Fi adapter driver on Linux.
- **Usage:**

  ```bash
  ./install-bcm43228.sh
  ```

### `install-benchmark.sh`

- **Description:** Installs various benchmarking tools.
- **Usage:**

  ```bash
  ./install-benchmark.sh
  ```

### `install-chezmoi.sh`

- **Description:** Installs and configures chezmoi for dotfile management.
- **Usage:**

  ```bash
  # Initialize a new repo
  ./install-chezmoi.sh -i

  # Apply an existing repo
  ./install-chezmoi.sh -r richtong/dotfiles
  ```

- **Parameters:**
  - `-r <repo>`: Repository to use (default: `richtong/dotfiles`).
  - `-g <dest>`: Destination for dotfiles (default: `$HOME`).
  - `-i`: Initialize a new repo.
  - `-o <suffix>`: OS-specific suffix for the repo.

### `install-choco.ps1`

- **Description:** (Windows) Installs the Chocolatey package manager.
- **Usage:**

  ```powershell
  ./install-choco.ps1
  ```

### `install-comfyui.sh`

- **Description:** Installs ComfyUI and downloads required models.
- **Usage:**

  ```bash
  ./install-comfyui.sh
  ```

- **Parameters:**
  - `-g`: Do not download models.
  - `-n`: Dry run.
  - `-m <%>`: Maximum disk usage percentage (default: 80).
  - `-f`: Force download even if disk is full.

### `install-conda.sh`

- **Description:** Installs Miniconda or Anaconda.
- **Usage:**

  ```bash
  ./install-conda.sh
  ```

- **Parameters:**
  - `-a`: Install full Anaconda.
  - `-c`: Do not install conda-forge.
  - `-p <version>`: Python version to install (default: 3.11).
  - `-r <version>`: Anaconda version to install (default: 2020.11).
  - `-u <url>`: URL to download Miniconda from.

### `install-cssh.sh`

- **Description:** Installs ClusterSSH on Linux or Mac.
- **Usage:**

  ```bash
  ./install-cssh.sh
  ```

### `install-deluge.sh`

- **Description:** Installs the Deluge BitTorrent client.
- **Usage:**

  ```bash
  ./install-deluge.sh
  ```

### `install-dev-repos.sh`

- **Description:** Installs standard helper development repositories.
- **Usage:**

  ```bash
  ./install-dev-repos.sh
  ```

- **Parameters:**
  - `-r`: Rebase against origin/master.
  - `-b <branch>`: Set your downstream branch (default: `master`).
  - `-s <repo>`: Set the source repo (default: `git@github.com:richtong`).
  - `-u <user>`: Set the branch to use for you (default: `$USER`).

### `install-divvy.sh`

- **Description:** Installs Divvy, a window manager for macOS.
- **Usage:**
    ```bash
  ./install-divvy.sh

  ```

  ```

### `install-docker-alternative.sh`

- **Description:** Installs Docker alternatives like Podman, Lima, and Colima.
- **Usage:**
    ```bash
  ./install-docker-alternative.sh

  ```

  ```

- **Parameters:**
  - `-q`: Do not install QEMU.
  - `-p`: Install Podman.
  - `-m`: Install Multipass.
  - `-l`: Install Lima.
  - `-c`: Do not install Colima.
  - `-s`: Install stable Colima release.
  - `-k`: Install Kubernetes.
  - `-r`: Install Rancher Desktop.

### `install-docker-for-mac.sh`

- **Description:** Installs Docker for Mac.
- **Usage:**

  ```bash
  ./install-docker-for-mac.sh
  ```

  ```

  ```

### `install-docker.sh`

- **Description:** Installs Docker, Docker Machine, and Docker Compose.
- **Usage:**

  ```bash
  ./install-docker.sh

  ```

- **Parameters:**
  - `-c`: Enable content trust.
  - `-f`: Force redownload of installation.
  - `-l <size>`: Buildx log size (default: 50000000).
  - `-i <registry>`: Docker image registry (default: `docker.io`).

### `install-ecryptfs.sh`

- **Description:** Installs and sets up eCryptfs for encrypted home directories.
- **Usage:**

  ```bash
  ./install-ecryptfs.sh

  ```

### `install-enpass.sh`

- **Description:** Installs the Enpass password manager.
- **Usage:**

  ```bash
  ./install-enpass.sh
  ```

### `install-flocker.sh`

- **Description:** Installs the Flocker Docker volume manager.
- **Usage:**

  ```bash
  ./install-flocker.sh
  ```

### `install-fonts.sh`

- **Description:** Installs various fonts using Homebrew.
- **Usage:**

  ```bash
  ./install-fonts.sh [fonts...]

  ```

### `install-gazebo.sh`

- **Description:** Installs Gazebo and OpenDroneMap.
- **Usage:**

  ```bash
  ./install-gazebo.sh
  ```

- **Parameters:**
  - `-r <version>`: Version to load (default: 11).

### `install-gitter.sh`

- **Description:** Installs the Gitter instant messaging tool.
- **Usage:**

  ```bash
  ./install-gitter.sh
  ```

### `install-google-chrome.sh`

- **Description:** Installs Google Chrome and Chrome Remote Desktop.
- **Usage:**

  ```bash
  ./install-google-chrome.sh

  ```

### `install-google-drive.sh`

- **Description:** Installs Google Drive on Mac and rclone on Linux.
- **Usage:**

  ```bash
  ./install-google-drive.sh
  ```

### `install-gpg.sh`

- **Description:** Installs GPG and exports secret keys.
- **Usage:**

  ```bash
  ./install-gpg.sh
  ```

### `install-hfs.sh`

- **Description:** Installs tools to mount HFS+ drives on Linux.
- **Usage:**

  ```bash
  ./install-hfs.sh /dev/sdx
  ```

### `install-hugin.sh`

- **Description:** Installs Hugin panorama stitcher and its dependencies on Mac.
- **Usage:**

  ```bash
  ./install-hugin.sh
  ```

### `install-iam-key-daemon.sh`

- **Description:** Installs a daemon to sync AWS IAM keys to a Linux machine.
- **Usage:**

  ```bash
  ./install-iam-key-daemon.sh
  ```

### `install-intel-opencl.sh`

- **Description:** Installs the Intel OpenCL SRB 5 package.
- **Usage:**

  ```bash
  ./install-intel-opencl.sh
  ```

### `install-intel-realsense.sh`

- **Description:** Installs the Intel RealSense SDK on Mac.
- **Usage:**

  ```bash
  ./install-intel-realsense.sh
  ```

### `install-iterm2.sh`

- **Description:** Installs iTerm2, dynamic profiles, and shell integrations.
- **Usage:**

  ```bash
  ./install-iterm2.sh
  ```

- **Parameters:**
  - `-p <profile_path>`: Path to the iTerm2 profile.

### `install-java.sh`

- **Description:** Installs Java SDK with support for jenv or asdf.
- **Usage:**

  ```bash
  ./install-java.sh -r 11
  ```

- **Parameters:**
  - `-r <version>`: Java version to install.
  - `-j`: Use jenv for version management.

### `install-jenv.sh`

- **Description:** Installs jenv for managing Java environments.
- **Usage:**

  ```bash
  ./install-jenv.sh
  ```

### `install-jupyter.sh`

- **Description:** Installs JupyterLab and many useful extensions.
- **Usage:**

  ```bash
  ./install-jupyter.sh
  ```

- **Parameters:**
  - `-i <dir>`: Installation directory.

### `install-lint.sh`

- **Description:** Installs a suite of linters for various programming languages, including JavaScript, Python, and shell scripts.
- **Usage:**

  ```bash
  ./install-lint.sh
  ```

### `install-mac-wireless.sh`

- **Description:** A utility for managing wireless networks on macOS from the
  command line.
- **Usage:**

  ```bash
  ./install-mac-wireless.sh
  ```

### `install-machines.sh`

- **Description:** (Deprecated) Installs and configures accounts for testing and
  deployment machines.
- **Usage:**

  ```bash
  ./install-machines.sh
  ```

### `install-menumeters.sh`

- **Description:** Installs MenuMeters, a system monitoring tool for the macOS
  menu bar.
- **Usage:**

  ```bash
  ./install-menumeters.sh
  ```

### `install-minikube.sh`

- **Description:** Installs Minikube for running a local Kubernetes cluster.
- **Usage:**

  ```bash
  ./install-minikube.sh
  ```

### `install-ml.sh`

- **Description:** Pulls various Docker images for machine learning frameworks
  like TensorFlow and Caffe.
- **Usage:**

  ```bash
  ./install-ml.sh
  ```

- **Parameters:**
  - `-c`: Install CUDA-enabled images as well.

### `install-models.sh`

- **Description:** Installs and manages AI models for Ollama, with options to
  filter by size and type.
- **Usage:**

  ```bash
  # Install models based on available memory
  ./install-models.sh -a

  # Install a specific size of models
  ./install-models.sh -2
  ```

### `install-mongodb.sh`

- **Description:** Installs the MongoDB Community Edition.
- **Usage:**

  ```bash
  ./install-mongodb.sh
  ```

### `install-node.sh`

- **Description:** Installs Node.js and related tools like npm, pnpm, and yarn.
- **Usage:**

  ```bash
  ./install-node.sh -r 22
  ```

- **Parameters:**
  - `-r <version>`: The major version of Node.js to install.

### `install-nordvpn.sh`

- **Description:** Installs the NordVPN client on macOS or Linux.
- **Usage:**

  ```bash
  ./install-nordvpn.sh
  ```

### `install-nvidia-docker.sh`

- **Description:** Installs nvidia-docker to enable GPU support in Docker containers.
- **Usage:**

  ```bash
  ./install-nvidia-docker.sh
  ```

### `install-nvidia.sh`

- **Description:** Installs the proprietary NVIDIA graphics drivers and CUDA
  toolkit on Linux.
- **Usage:**

  ```bash
  sudo ./install-nvidia.sh
  ```

### `install-nvim.sh`

- **Description:** Installs Neovim and configures it with plugins for a
  full-featured development environment, with support for LazyVim and LunarVim.
- **Usage:**

  ```bash
  ./install-nvim.sh -l
  ```

- **Parameters:**
  - `-l`: Install LazyVim configuration.
  - `-u`: Install LunarVim configuration.

### `install-nvm.sh`

- **Description:** Installs Node Version Manager (nvm) for managing multiple
  Node.js versions.
- **Usage:**

  ```bash
  ./install-nvm.sh
  ```

### `install-packages.sh`

- **Description:** A generic script to install packages using the
  `package_install` function.
- **Usage:**

  ```bash
  ./install-packages.sh package1 package2
  ```

### `install-pia.sh`

- **Description:** Installs the Private Internet Access VPN client.
- **Usage:**

  ```bash
  ./install-pia.sh
  ```

### `install-post-macos-upgrade.sh`

- **Description:** A script to run after a major macOS upgrade to fix Homebrew
  and reinstall incompatible casks.
- **Usage:**

  ```bash
  ./install-post-macos-upgrade.sh
  ```

### `install-qgc.sh`

- **Description:** Installs QGroundControl, a ground control station for drones.
- **Usage:**

  ```bash
  ./install-qgc.sh
  ```

### `install-quicktile.sh`

- **Description:** Installs `quicktile`, a tiling window manager for XFCE on Debian.
- **Usage:**

  ```bash
  ./install-quicktile.sh
  ```

### `install-rkt.sh`

- **Description:** Installs `rkt`, a container runtime from CoreOS.
- **Usage:**

  ```bash
  ./install-rkt.sh
  ```

### `install-rpi-os.sh`

- **Description:** A script to write a Raspberry Pi OS image to an SD card on a Mac.
- **Usage:**

  ```bash
  ./install-rpi-os.sh -w -s /dev/diskX
  ```

- **Parameters:**
  - `-w`: Write the image to the SD card.
  - `-s <device>`: The SD card device.
  - `-i <ssid>`: Wi-Fi SSID.
  - `-p <password>`: Wi-Fi password.

### `install-rstudio.sh`

- **Description:** Installs R and RStudio.
- **Usage:**

  ```bash
  ./install-rstudio.sh
  ```

### `install-ruby.sh`

- **Description:** Installs Ruby.
- **Usage:**

  ```bash
  ./install-ruby.sh
  ```

### `install-rust.sh`

- **Description:** Installs the Rust programming language.
- **Usage:**

  ```bash
  ./install-rust.sh
  ```

### `install-samba.sh`

- **Description:** Installs and configures Samba on Linux to share home directories.
- **Usage:**

  ```bash
  ./install-samba.sh
  ```

### `install-scoop.ps1`

- **Description:** A PowerShell script to install the Scoop package manager for Windows.
- **Usage:**

  ```powershell
  ./install-scoop.ps1
  ```

### `install-shiftit.sh`

- **Description:** Installs ShiftIt, a window manager for macOS.
- **Usage:**

  ```bash
  ./install-shiftit.sh
  ```

### `install-sound.sh`

- **Description:** Installs sound-related applications from Rogue Amoeba on macOS.
- **Usage:**

  ```bash
  ./install-sound.sh
  ```

### `install-sphinx.sh`

- **Description:** Installs Sphinx, a documentation generator, along with
  several extensions.
- **Usage:**

  ```bash
  ./install-sphinx.sh
  ```

### `install-ssh-keys.sh`

- **Description:** Installs SSH keys from an encrypted source, such as a
  Veracrypt volume or an eCryptfs directory.
- **Usage:**

  ```bash
  ./install-ssh-keys.sh
  ```

### `install-ssh.ps1`

- **Description:** A PowerShell script to install and configure OpenSSH on Windows.
- **Usage:**

  ```powershell
  ./install-ssh.ps1
  ```

### `install-ssh.sh`

- **Description:** Installs OpenSSH and the SSH server.
- **Usage:**

  ```bash
  ./install-ssh.sh
  ```

### `install-sshfs.sh`

- **Description:** Installs `sshfs` for mounting remote filesystems over SSH.
- **Usage:**

  ```bash
  ./install-sshfs.sh
  ```

### `install-ssmtp.sh`

- **Description:** Installs and configures `ssmtp` for sending email via a
  Gmail account.
- **Usage:**

  ```bash
  ./install-ssmtp.sh
  ```

### `install-stylelint.sh`

- **Description:** Installs `stylelint` for linting CSS and PostCSS.
- **Usage:**
    ```bash
  ./install-stylelint.sh

  ```

  ```

### `install-sublime.sh`

- **Description:** Installs Sublime Text and a number of recommended packages
  for web and Python development.
- **Usage:**

  ```bash
  ./install-sublime.sh
  ```

### `install-tailscale.sh`

- **Description:** Installs Tailscale, a zero-config VPN.
- **Usage:**

  ```bash
  ./install-tailscale.sh
  ```

### `install-tensorflow.sh`

- **Description:** Installs TensorFlow, with support for Apple Silicon (M1) acceleration.
- **Usage:**

  ```bash
  ./install-tensorflow.sh
  ```

### `install-thefuck.sh`

- **Description:** Installs `thefuck`, a command-line tool that corrects errors
  in previous console commands.
- **Usage:**

  ```bash
  ./install-thefuck.sh
  ```

### `install-tlp.sh`

- **Description:** Installs TLP, a power management tool for Linux laptops.
- **Usage:**

  ```bash
  ./install-tlp.sh
  ```

### `install-travis.sh`

- **Description:** Installs the Travis CI command-line tool.
- **Usage:**

  ```bash
  ./install-travis.sh
  ```

### `install-typescript.sh`

- **Description:** Installs TypeScript.
- **Usage:**

  ```bash
  ./install-typescript.sh
  ```

### `install-ufw.sh`

- **Description:** Installs and configures UFW (Uncomplicated Firewall) on Linux.
- **Usage:**

  ```bash
  ./install-ufw.sh
  ```

### `install-vagrant.sh`

- **Description:** Installs Vagrant and VirtualBox for creating and managing
  virtual machines.
- **Usage:**

  ```bash
  ./install-vagrant.sh
  ```

### `install-veracrypt.sh`

- **Description:** Installs Veracrypt, a disk encryption tool.
- **Usage:**

  ```bash
  ./install-veracrypt.sh
  ```

### `install-vim.py`

- **Description:** A Python script to install Vim and a number of plugins and configurations.
- **Usage:**

  ```bash
  ./install-vim.py
  ```

### `install-vmware-tools.sh`

- **Description:** Installs VMware Tools for guest operating systems running in
  VMware Fusion.
- **Usage:**

  ```bash
  ./install-vmware-tools.sh
  ```

### `install-vscode.sh`

- **Description:** Installs Visual Studio Code and a set of recommended extensions.
- **Usage:**

  ```bash
  ./install-vscode.sh
  ```

### `install-window-manager.sh`

- **Description:** Installs a tiling window manager (i3, gTile, or quicktile)
  depending on the desktop environment.
- **Usage:**

  ```bash
  ./install-window-manager.sh
  ```

### `install-wxpython.sh`

- **Description:** Installs the wxPython GUI toolkit.
- **Usage:**

  ```bash
  ./install-wxpython.sh
  ```

### `install-xhyve.sh`

- **Description:** Installs the xhyve driver for Docker Machine on macOS.
- **Usage:**

  ```bash
  ./install-xhyve.sh
  ```

### `install-xquartz.sh`

- **Description:** Installs XQuartz, an X11 server for macOS.
- **Usage:**

  ```bash
  ./install-xquartz.sh
  ```

### `install-xrandr.sh`

- **Description:** A utility to add a new screen resolution using `xrandr` on Linux.
- **Usage:**

  ```bash
  ./install-xrandr.sh DP-2 2560x1440
  ```

### `install-yay.sh`

- **Description:** Installs `yay`, a YAML parser for Bash.
- **Usage:**

  ```bash
  ./install-yay.sh
  ```

### `install-yeoman.sh`

- **Description:** Installs Yeoman, a scaffolding tool for web applications.
- **Usage:**

  ```bash
  ./install-yeoman.sh
  ```

### `install-yq.sh`

- **Description:** Installs `yq`, a command-line YAML processor.
- **Usage:**

  ```bash
  ./install-yq.sh
  ```

### `install-yubikey.sh`

- **Description:** Installs the YubiKey Manager and Authenticator applications.
- **Usage:**

  ```bash
  ./install-yubikey.sh
  ```

### `install-zfs-quotas.sh`

- **Description:** Configures ZFS quotas for users and datasets.
- **Usage:**

  ```bash
  ./install-zfs-quotas.sh
  ```

### `install-zotero.sh`

- **Description:** Installs Zotero, a reference management tool.
- **Usage:**

  ```bash
  ./install-zotero.sh
  ```
