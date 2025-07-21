# 基础设施二进制实用程序命令

本仓库包含一系列用于安装和管理开发环境的便捷脚本。

## 概述

这些脚本主要为 macOS 和 Linux（Ubuntu）设计，协助设置各种工具、应用程序和系统配置。它们是实验性的，并且正在积极开发中。

## 文档

有关每个脚本的详细信息，包括其用途、使用方法和参数，请参阅综合指南：

**[>> 脚本和工具文档 (PROMPT.md)](PROMPT.md)**

## 快速开始

大多数安装脚本可以在这个 `bin` 目录中找到并运行。要查找特定的安装程序，您可以使用 `grep`：

```bash
bash grep -i "docker" install-*.sh `
```

主要的安装脚本是 `install.sh`，它处理核心设置，而 `pre-install.sh` 引导安装必要的工具，如 Homebrew。

## 环境管理

- **版本管理：** 使用 `asdf` 通过 `.tool-versions` 文件管理工具版本（Node、Python 等）。
- **目录级环境：** 建议使用 `direnv` 通过 `.envrc` 文件管理每个目录的环境变量。这非常适合从 1Password 加载密钥或激活 Python 虚拟环境。

## 密钥管理

强烈建议避免"静态"存储密钥。本仓库包含一个使用 Veracrypt 和 `stow` 管理加密密钥的自定义框架。详情请参见 [`install-secrets.sh`](./install-secrets.sh) 和 [`PROMPT.md`](./PROMPT.md) 中的文档。

### `add-user.sh`

向本地机器添加新用户，配置其 UID、组、密码和 SSH 密钥。

### `change-string.sh`

在一个或多个文件中执行全局搜索和替换字符串的实用程序。

### `change-user.sh`

更改用户的 UID 和 GID 以匹配用户文件中指定的值。

### `checkaws.py`

用于检查和验证环境中 AWS 凭据的 Python 脚本。

### `cleanup-brew.sh`

用于清理 macOS 上 Homebrew 包的脚本。

### `conda-activate.sh`

激活 `restart` conda 环境的简单脚本。

### `create-agents-authorized-keys.sh`

聚合用户公钥以授予对代理账户的访问权限。

### `create-prebuild-private.sh`

（Linux）为预构建密钥创建加密目录。

### `create-private-prebuild.sh`

（macOS）为预构建脚本创建加密磁盘映像。

### `delete-google-user.sh`

删除 Google Workspace 用户并存档其数据。

### `disk-info.sh`

显示有关连接的存储设备的详细信息。

### `disk-wipe.sh`

安全擦除磁盘。**请极其谨慎使用。**

### `docker-list-tags.sh`

列出公共注册表上 Docker 镜像的所有标签。

### `docker-machine-create.sh`

在一系列主机上创建 Docker Swarm。

### `dotfiles-backup.sh`

在从仓库链接之前备份现有的点文件。

### `dotfiles-to-repo.sh`

将点文件移动到 `stow` 管理的仓库中。

### `download-acml.sh`

下载 AMD 核心数学库（ACML）。

### `exif-copy.sh`

在图像文件之间复制 EXIF 元数据。

### `find-broken-symlinks.sh`

查找并列出损坏的符号链接。

### `fix-ssh-permissions.sh`

修正 SSH 密钥和其他敏感目录的文件权限。

### `gcloud-create.sh`

为 Terraform 设置 Google Cloud Platform 项目。

### `gcloud-serviceaccount-create.sh`

创建 Google Cloud 服务账号。

### `get-ip.sh`

获取主机的 IP 地址。

### `git-ls-large.sh`

列出 git 仓库中的大文件。

### `git-merge-repos.sh`

将一个 git 仓库合并到另一个仓库中。

### `git-set-default-branch.sh`

更改 GitHub 仓库的默认分支。

### `git-submodule-rm.sh`

删除 git 子模块。

### `git-submodule-update.sh`

初始化和更新 git 子模块。

### `hashdeep-audit.sh`

根据 hashdeep 文件审计目录。

### `hashdeep-create.sh`

为一组文件或目录创建 hashdeep 文件。

### `install-1password.sh`

安装 1Password 及其 CLI。

### `install-11template.sh`

安装 11template。

### `install-accounts.sh`

从文件添加组和用户（已弃用）。

### `install-agent.sh`

安装无人值守代理的配置。

### `install-agents.sh`

为每个代理复制 ssh 和预构建脚本。

### `install-ai.sh`

安装桌面 AI 工具。

### `install-android-tools.sh`

安装 Android Studio 和平台工具。

### `install-android.sh`

安装 Android Studio。

### `install-ansible.sh`

安装 Ansible。

### `install-asdf.sh`

安装用于管理多个运行时版本的 asdf。

### `install-auth0.sh`

安装 Auth0 CLI。

### `install-aws-config.sh`

配置 AWS 凭据和设置。

### `install-aws-local.sh`

安装本地 AWS 开发工具。

### `install-bash-completion.sh`

安装 bash 自动补全。

### `install-bazel.sh`

安装 Bazel 构建工具。

### `install-bcm43228.sh`

安装 BCM43228 Wi-Fi 驱动程序。

### `install-benchmark.sh`

安装基准测试工具。

### `install-chezmoi.sh`

安装用于点文件管理的 chezmoi。

### `install-choco.ps1`

（Windows）安装 Chocolatey 包管理器。

### `install-comfyui.sh`

安装 ComfyUI 及其模型。

### `install-conda.sh`

安装 Miniconda 或 Anaconda。

### `install-cssh.sh`

安装 ClusterSSH。

### `install-deluge.sh`

安装 Deluge BitTorrent 客户端。

### `install-dev-repos.sh`

安装标准辅助开发仓库。

### `install-divvy.sh`

安装 macOS 的窗口管理器 Divvy。

### `install-docker-alternative.sh`

安装 Docker 替代品，如 Podman、Lima 和 Colima。

### `install-docker-for-mac.sh`

安装 Docker for Mac。

### `install-docker.sh`

安装 Docker、Docker Machine 和 Docker Compose。

### `install-dorothy.sh`

安装点文件管理器 Dorothy。

### `install-dropbox.sh`

安装 Dropbox。

### `install-dwa182.sh`

安装 D-Link DWA-182 Wi-Fi 适配器驱动程序。

### `install-ecryptfs.sh`

安装并设置 eCryptfs。

### `install-enpass.sh`

安装 Enpass 密码管理器。

### `install-flocker.sh`

安装 Flocker Docker 卷管理器。

### `install-fonts.sh`

安装各种字体。

### `install-gazebo.sh`

安装 Gazebo 和 OpenDroneMap。### `install-gitter.sh`

安装 Gitter 即时消息工具。

### `install-google-chrome.sh`

安装 Google Chrome 和 Chrome 远程桌面。

### `install-google-drive.sh`

在 Mac 上安装 Google Drive，在 Linux 上安装 rclone。

### `install-gpg.sh`

安装 GPG 并导出密钥。

### `install-grub.sh`

配置 GRUB 以在启动时不静默。

### `install-hammerspoon.sh`

安装 Hammerspoon 和各种窗口管理 Spoons。

### `install-hfs.sh`

安装在 Linux 上挂载 HFS+ 驱动器的工具。

### `install-hugin.sh`

在 Mac 上安装 Hugin 全景拼接器及其依赖项。

### `install-iam-key-daemon.sh`

安装将 AWS IAM 密钥同步到 Linux 机器的守护进程。

### `install-intel-opencl.sh`

安装 Intel OpenCL SRB 5 包。

### `install-intel-realsense.sh`

在 Mac 上安装 Intel RealSense SDK。

### `install-iterm2.sh`

安装 iTerm2、动态配置文件和 shell 集成。

### `install-java.sh`

安装支持 jenv 或 asdf 的 Java SDK。

### `install-jenv.sh`

安装用于管理 Java 环境的 jenv。

### `install-jupyter.sh`

安装 JupyterLab 和许多有用的扩展。### `install-lint.sh`

安装各种编程语言的代码检查工具套件。

### `install-mac-wireless.sh`

macOS 上管理无线网络的实用程序。

### `install-machines.sh`

（已弃用）为测试和部署机器安装和配置账户。

### `install-menumeters.sh`

在 macOS 上安装用于系统监控的 MenuMeters。

### `install-minikube.sh`

安装用于运行本地 Kubernetes 集群的 Minikube。

### `install-ml.sh`

为机器学习框架拉取各种 Docker 镜像。

### `install-models.sh`

安装和管理 Ollama 的 AI 模型。

### `install-mongodb.sh`

安装 MongoDB 社区版。

### `install-node.sh`

安装 Node.js 和相关工具。

### `install-nordvpn.sh`

安装 NordVPN 客户端。

### `install-nvidia-docker.sh`

安装 nvidia-docker 以在 Docker 容器中启用 GPU 支持。

### `install-nvidia.sh`

安装专有的 NVIDIA 图形驱动程序。

### `install-nvim.sh`

安装 Neovim 及其配置。

### `install-nvm.sh`

安装 Node 版本管理器 (nvm)。### `install-packages.sh`

安装包的通用脚本。

### `install-pia.sh`

安装 Private Internet Access VPN 客户端。

### `install-post-macos-upgrade.sh`

主要 macOS 升级后运行的脚本，用于修复 Homebrew。

### `install-qgc.sh`

安装 QGroundControl。

### `install-quicktile.sh`

安装 XFCE 的平铺窗口管理器 `quicktile`。

### `install-rkt.sh`

安装 CoreOS 的容器运行时 `rkt`。

### `install-rpi-os.sh`

将 Raspberry Pi OS 镜像写入 SD 卡。

### `install-rstudio.sh`

安装 R 和 RStudio。

### `install-ruby.sh`

安装 Ruby。

### `install-rust.sh`

安装 Rust 编程语言。

### `install-samba.sh`

安装和配置 Samba。

### `install-scoop.ps1`

（Windows）安装 Scoop 包管理器。

### `install-shiftit.sh`

安装 macOS 的窗口管理器 ShiftIt。

### `install-sound.sh`

从 Rogue Amoeba 安装声音相关应用程序。

### `install-sphinx.sh`

安装 Sphinx 及其扩展。### `install-ssh-keys.sh`

从加密源安装 SSH 密钥。

### `install-ssh.ps1`

（Windows）安装和配置 OpenSSH。

### `install-ssh.sh`

安装 OpenSSH 和 SSH 服务器。

### `install-sshfs.sh`

安装用于通过 SSH 挂载远程文件系统的 `sshfs`。

### `install-ssmtp.sh`

安装和配置用于发送电子邮件的 `ssmtp`。

### `install-stylelint.sh`

安装用于检查 CSS 和 PostCSS 的 `stylelint`。

### `install-sublime.sh`

安装 Sublime Text 和推荐的包。

### `install-tailscale.sh`

安装零配置 VPN Tailscale。

### `install-tensorflow.sh`

安装 TensorFlow。

### `install-thefuck.sh`

安装命令行错误更正工具 `thefuck`。

### `install-tlp.sh`

安装用于笔记本电脑电源管理的 TLP。

### `install-travis.sh`

安装 Travis CI 命令行工具。

### `install-typescript.sh`

安装 TypeScript。

### `install-ufw.sh`

安装和配置 UFW（简单防火墙）。

### `install-vagrant.sh`

安装 Vagrant 和 VirtualBox。

### `install-veracrypt.sh`

安装 VeraCrypt 磁盘加密软件。

### `install-vim.py`

安装自定义 Vim 配置的 Python 脚本。

### `install-vscode.sh`

安装 Visual Studio Code 和扩展列表。

### `install-yubikey.sh`

安装 YubiKey Manager 和 Authenticator 应用程序。

### `install-zfs-quotas.sh`

为用户和数据集配置 ZFS 配额。

### `install-zotero.sh`

安装 Zotero 参考文献管理器。