# インフラストラクチャバイナリユーティリティコマンド

[English](README.md) | [日本語](README-JP.md) | [中文](README-ZH.md) | [Español](README-ES.md)

このリポジトリには、開発環境のインストールと管理のための便利なスクリプトのコレクションが含まれています。

## 概要

これらのスクリプトは主にmacOSとLinux（Ubuntu）向けに設計されており、様々なツール、アプリケーション、システム設定のセットアップを支援します。これらは実験的なものであり、積極的に開発されています。

## ドキュメント

各スクリプトの詳細情報（目的、使用方法、パラメータを含む）については、包括的なガイドを参照してください：

**[>> スクリプトとツールのドキュメント (PROMPT.md)](PROMPT.md)**

## クイックスタート

ほとんどのインストールスクリプトは、この`bin`ディレクトリから見つけて実行できます。特定のインストーラーを見つけるには、`grep`を使用できます：

```bash
bash grep -i "docker" install-*.sh `
```

主要なインストールスクリプトは`install.sh`で、コアセットアップを処理し、`pre-install.sh`はHomebrewなどの必須ツールをブートストラップします。

## 環境管理

- **バージョン管理：** `.tool-versions`ファイルを介してツールバージョン（Node、Pythonなど）を管理するために`asdf`が使用されます。
- **ディレクトリレベルの環境：** `.envrc`ファイルを使用してディレクトリごとの環境変数を管理するために`direnv`が推奨されます。これは1Passwordからシークレットをロードしたり、Python仮想環境をアクティベートしたりするのに理想的です。

## シークレット管理

シークレットを「静的に」保存することは強く推奨されません。このリポジトリには、暗号化されたシークレットを管理するためのVeracryptと`stow`を使用した独自のフレームワークが含まれています。詳細については[`install-secrets.sh`](./install-secrets.sh)と[`PROMPT.md`](./PROMPT.md)のドキュメントを参照してください。

### `add-user.sh`

ローカルマシンに新しいユーザーを追加し、UID、グループ、パスワード、SSHキーを設定します。

### `change-string.sh`

1つ以上のファイルで文字列のグローバル検索と置換を実行するユーティリティ。

### `change-user.sh`

ユーザーファイルで指定された値に一致するようにユーザーのUIDとGIDを変更します。

### `checkaws.py`

環境内のAWS認証情報を確認および検証するPythonスクリプト。

### `cleanup-brew.sh`

macOSでHomebrewパッケージをクリーンアップするスクリプト。

### `conda-activate.sh`

`restart` conda環境をアクティベートするシンプルなスクリプト。

### `create-agents-authorized-keys.sh`

エージェントアカウントへのアクセスを許可するためにユーザーの公開鍵を集約します。

### `create-prebuild-private.sh`

（Linux）プレビルドシークレット用の暗号化ディレクトリを作成します。

### `create-private-prebuild.sh`

（macOS）プレビルドスクリプト用の暗号化ディスクイメージを作成します。

### `delete-google-user.sh`

Google Workspaceユーザーを削除し、そのデータをアーカイブします。

### `disk-info.sh`

接続されたストレージデバイスに関する詳細情報を表示します。

### `disk-wipe.sh`

ディスクを安全に消去します。**極めて慎重に使用してください。**

### `docker-list-tags.sh`

パブリックレジストリ上のDockerイメージのすべてのタグを一覧表示します。

### `docker-machine-create.sh`

一連のホスト上にDocker Swarmを作成します。

### `dotfiles-backup.sh`

リポジトリからリンクする前に既存のドットファイルをバックアップします。

### `dotfiles-to-repo.sh`

ドットファイルを`stow`管理のリポジトリに移動します。

### `download-acml.sh`

AMD Core Math Library（ACML）をダウンロードします。

### `exif-copy.sh`

画像ファイル間でEXIFメタデータをコピーします。

### `find-broken-symlinks.sh`

壊れたシンボリックリンクを見つけて一覧表示します。

### `fix-ssh-permissions.sh`

SSHキーやその他の機密ディレクトリのファイル権限を修正します。

### `gcloud-create.sh`

Terraform用にGoogle Cloud Platformプロジェクトをセットアップします。

### `gcloud-serviceaccount-create.sh`

Google Cloudサービスアカウントを作成します。

### `get-ip.sh`

ホストのIPアドレスを取得します。

### `git-ls-large.sh`

gitリポジトリ内の大きなファイルを一覧表示します。

### `git-merge-repos.sh`

1つのgitリポジトリを別のリポジトリにマージします。

### `git-set-default-branch.sh`

GitHubリポジトリのデフォルトブランチを変更します。

### `git-submodule-rm.sh`

gitサブモジュールを削除します。

### `git-submodule-update.sh`

gitサブモジュールを初期化および更新します。

### `hashdeep-audit.sh`

hashdeepファイルに対してディレクトリを監査します。

### `hashdeep-create.sh`

ファイルまたはディレクトリのセット用にhashdeepファイルを作成します。

### `install-1password.sh`

1PasswordとそのCLIをインストールします。

### `install-11template.sh`

11templateをインストールします。

### `install-accounts.sh`

ファイルからグループとユーザーを追加します（非推奨）。

### `install-agent.sh`

無人エージェントの設定をインストールします。

### `install-agents.sh`

各エージェント用にsshとプレビルドスクリプトをコピーします。

### `install-ai.sh`

デスクトップAIツールをインストールします。

### `install-android-tools.sh`

Android Studioとプラットフォームツールをインストールします。

### `install-android.sh`

Android Studioをインストールします。

### `install-ansible.sh`

Ansibleをインストールします。

### `install-asdf.sh`

複数のランタイムバージョンを管理するためのasdfをインストールします。

### `install-auth0.sh`

Auth0 CLIをインストールします。

### `install-aws-config.sh`

AWS認証情報と設定を構成します。

### `install-aws-local.sh`

ローカルAWS開発用のツールをインストールします。

### `install-bash-completion.sh`

bash補完をインストールします。

### `install-bazel.sh`

Bazelビルドツールをインストールします。

### `install-bcm43228.sh`

BCM43228 Wi-Fiドライバーをインストールします。

### `install-benchmark.sh`

ベンチマークツールをインストールします。

### `install-chezmoi.sh`

ドットファイル管理用のchezmoiをインストールします。

### `install-choco.ps1`

（Windows）Chocolateyパッケージマネージャーをインストールします。

### `install-comfyui.sh`

ComfyUIとそのモデルをインストールします。

### `install-conda.sh`

MinicondaまたはAnacondaをインストールします。

### `install-cssh.sh`

ClusterSSHをインストールします。

### `install-deluge.sh`

Deluge BitTorrentクライアントをインストールします。

### `install-dev-repos.sh`

標準的なヘルパー開発リポジトリをインストールします。

### `install-divvy.sh`

macOS用のウィンドウマネージャーDivvyをインストールします。

### `install-docker-alternative.sh`

Podman、Lima、ColimaなどのDocker代替をインストールします。

### `install-docker-for-mac.sh`

Docker for Macをインストールします。

### `install-docker.sh`

Docker、Docker Machine、Docker Composeをインストールします。

### `install-dorothy.sh`

ドットファイルマネージャーDorothyをインストールします。

### `install-dropbox.sh`

Dropboxをインストールします。

### `install-dwa182.sh`

D-Link DWA-182 Wi-Fiアダプタードライバーをインストールします。

### `install-ecryptfs.sh`

eCryptfsをインストールおよびセットアップします。

### `install-enpass.sh`

Enpassパスワードマネージャーをインストールします。

### `install-flocker.sh`

Flocker Dockerボリュームマネージャーをインストールします。

### `install-fonts.sh`

様々なフォントをインストールします。

### `install-gazebo.sh`

GazeboとOpenDroneMapをインストールします。

### `install-gitter.sh`

Gitterインスタントメッセージングツールをインストールします。

### `install-google-chrome.sh`

Google ChromeとChrome Remote Desktopをインストールします。

### `install-google-drive.sh`

MacではGoogle Drive、Linuxではrcloneをインストールします。

### `install-gpg.sh`

GPGをインストールし、秘密鍵をエクスポートします。

### `install-grub.sh`

ブート時にサイレントにならないようにGRUBを設定します。

### `install-hammerspoon.sh`

Hammerspoonと様々なウィンドウ管理Spoonsをインストールします。

### `install-hfs.sh`

Linux上でHFS+ドライブをマウントするためのツールをインストールします。

### `install-hugin.sh`

Mac上でHuginパノラマスティッチャーとその依存関係をインストールします。

### `install-iam-key-daemon.sh`

AWS IAMキーをLinuxマシンに同期するデーモンをインストールします。

### `install-intel-opencl.sh`

Intel OpenCL SRB 5パッケージをインストールします。

### `install-intel-realsense.sh`

Mac上でIntel RealSense SDKをインストールします。

### `install-iterm2.sh`

iTerm2、動的プロファイル、シェル統合をインストールします。

### `install-java.sh`

jenvまたはasdfのサポート付きでJava SDKをインストールします。

### `install-jenv.sh`

Java環境を管理するためのjenvをインストールします。

### `install-jupyter.sh`

JupyterLabと多くの便利な拡張機能をインストールします。

### `install-lint.sh`

様々なプログラミング言語用のリンターのスイートをインストールします。

### `install-mac-wireless.sh`

macOSでワイヤレスネットワークを管理するユーティリティ。

### `install-machines.sh`

（非推奨）テストおよびデプロイメントマシン用のアカウントをインストールおよび設定します。

### `install-menumeters.sh`

macOSでシステム監視用のMenuMetersをインストールします。

### `install-minikube.sh`

ローカルKubernetesクラスターを実行するためのMinikubeをインストールします。

### `install-ml.sh`

機械学習フレームワーク用の様々なDockerイメージをプルします。

### `install-models.sh`

Ollama用のAIモデルをインストールおよび管理します。

### `install-mongodb.sh`

MongoDB Community Editionをインストールします。

### `install-node.sh`

Node.jsと関連ツールをインストールします。

### `install-nordvpn.sh`

NordVPNクライアントをインストールします。

### `install-nvidia-docker.sh`

Dockerコンテナでのサポートを有効にするためにnvidia-dockerをインストールします。

### `install-nvidia.sh`

プロプライエタリなNVIDIAグラフィックスドライバーをインストールします。

### `install-nvim.sh`

Neovimとその設定をインストールします。

### `install-nvm.sh`

Node Version Manager（nvm）をインストールします。

### `install-packages.sh`

パッケージをインストールする汎用スクリプト。

### `install-pia.sh`

Private Internet Access VPNクライアントをインストールします。

### `install-post-macos-upgrade.sh`

Homebrewを修正するためにmacOSの主要アップグレード後に実行するスクリプト。

### `install-qgc.sh`

QGroundControlをインストールします。

### `install-quicktile.sh`

XFCE用のタイリングウィンドウマネージャー`quicktile`をインストールします。

### `install-rkt.sh`

CoreOSのコンテナランタイム`rkt`をインストールします。

### `install-rpi-os.sh`

Raspberry Pi OSイメージをSDカードに書き込みます。

### `install-rstudio.sh`

RとRStudioをインストールします。

### `install-ruby.sh`

Rubyをインストールします。

### `install-rust.sh`

Rustプログラミング言語をインストールします。

### `install-samba.sh`

Sambaをインストールおよび設定します。

### `install-scoop.ps1`

（Windows）Scoopパッケージマネージャーをインストールします。

### `install-shiftit.sh`

macOS用のウィンドウマネージャーShiftItをインストールします。

### `install-sound.sh`

Rogue Amoebaからサウンド関連のアプリケーションをインストールします。

### `install-sphinx.sh`

Sphinxとその拡張機能をインストールします。

### `install-ssh-keys.sh`

暗号化されたソースからSSHキーをインストールします。

### `install-ssh.ps1`

（Windows）OpenSSHをインストールおよび設定します。

### `install-ssh.sh`

OpenSSHとSSHサーバーをインストールします。

### `install-sshfs.sh`

SSH経由でリモートファイルシステムをマウントするための`sshfs`をインストールします。

### `install-ssmtp.sh`

電子メールを送信するための`ssmtp`をインストールおよび設定します。

### `install-stylelint.sh`

CSSとPostCSS用の`stylelint`をインストールします。

### `install-sublime.sh`

Sublime Textと推奨パッケージをインストールします。

### `install-tailscale.sh`

ゼロコンフィグVPNのTailscaleをインストールします。

### `install-tensorflow.sh`

TensorFlowをインストールします。

### `install-thefuck.sh`

コマンドラインエラー修正ツール`thefuck`をインストールします。

### `install-tlp.sh`

ラップトップの電源管理用のTLPをインストールします。

### `install-travis.sh`

Travis CIコマンドラインツールをインストールします。

### `install-typescript.sh`

TypeScriptをインストールします。

### `install-ufw.sh`

UFW（Uncomplicated Firewall）をインストールおよび設定します。

### `install-vagrant.sh`

VagrantとVirtualBoxをインストールします。

### `install-veracrypt.sh`

VeraCryptディスク暗号化ソフトウェアをインストールします。

### `install-vim.py`

カスタマイズされたVim設定をインストールするPythonスクリプト。

### `install-vscode.sh`

Visual Studio Codeと拡張機能のリストをインストールします。

### `install-yubikey.sh`

YubiKey ManagerとAuthenticatorアプリケーションをインストールします。

### `install-zfs-quotas.sh`

ユーザーとデータセット用のZFSクォータを設定します。

### `install-zotero.sh`

Zotero参照管理ツールをインストールします。