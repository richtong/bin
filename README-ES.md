# Comandos de Utilidad Binaria de Infraestructura

Este repositorio contiene una colección de scripts de conveniencia para instalar y gestionar entornos de desarrollo.

## Resumen

Estos scripts están diseñados principalmente para macOS y Linux (Ubuntu) y ayudan en la configuración de varias herramientas, aplicaciones y configuraciones del sistema. Son experimentales y están en desarrollo activo.

## Documentación

Para información detallada sobre cada script, incluyendo su propósito, uso y parámetros, consulte la guía completa:

**[>> Documentación de Scripts y Herramientas (PROMPT.md)](PROMPT.md)**

## Inicio Rápido

La mayoría de los scripts de instalación se pueden encontrar y ejecutar desde este directorio `bin`. Para encontrar un instalador específico, puede usar `grep`:

```bash
bash grep -i "docker" install-*.sh `
```

El script de instalación principal es `install.sh`, que maneja la configuración central, mientras que `pre-install.sh` inicializa herramientas esenciales como Homebrew.

## Gestión del Entorno

- **Gestión de Versiones:** Se usa `asdf` para gestionar versiones de herramientas (Node, Python, etc.) a través de archivos `.tool-versions`.
- **Entornos a Nivel de Directorio:** Se recomienda `direnv` para gestionar variables de entorno por directorio usando archivos `.envrc`. Esto es ideal para cargar secretos desde 1Password o activar entornos virtuales de Python.

## Gestión de Secretos

Se recomienda encarecidamente evitar almacenar secretos "en reposo". Este repositorio incluye un marco personalizado usando Veracrypt y `stow` para gestionar secretos cifrados. Consulte [`install-secrets.sh`](./install-secrets.sh) y la documentación en [`PROMPT.md`](./PROMPT.md) para más detalles.

### `add-user.sh`

Añade un nuevo usuario a la máquina local, configurando su UID, grupos, contraseña y claves SSH.

### `change-string.sh`

Una utilidad para realizar una búsqueda y reemplazo global de una cadena en uno o más archivos.

### `change-user.sh`

Cambia el UID y GID de un usuario para que coincidan con los valores especificados en un archivo de usuario.

### `checkaws.py`

Un script de Python para verificar y validar las credenciales de AWS en el entorno.

### `cleanup-brew.sh`

Un script para limpiar paquetes de Homebrew en macOS.

### `conda-activate.sh`

Un script simple para activar el entorno conda `restart`.

### `create-agents-authorized-keys.sh`

Agrega claves públicas de usuarios para otorgar acceso a cuentas de agente.

### `create-prebuild-private.sh`

(Linux) Crea un directorio cifrado para secretos de pre-compilación.

### `create-private-prebuild.sh`

(macOS) Crea una imagen de disco cifrada para scripts de pre-compilación.

### `delete-google-user.sh`

Elimina un usuario de Google Workspace y archiva sus datos.

### `disk-info.sh`

Muestra información detallada sobre los dispositivos de almacenamiento conectados.

### `disk-wipe.sh`

Borra de forma segura un disco. **Use con extrema precaución.**

### `docker-list-tags.sh`

Lista todas las etiquetas de una imagen Docker en un registro público.

### `docker-machine-create.sh`

Crea un Docker Swarm en una serie de hosts.

### `dotfiles-backup.sh`

Hace una copia de seguridad de los dotfiles existentes antes de enlazar desde un repositorio.

### `dotfiles-to-repo.sh`

Mueve los dotfiles a un repositorio gestionado por `stow`.

### `download-acml.sh`

Descarga la AMD Core Math Library (ACML).

### `exif-copy.sh`

Copia metadatos EXIF entre archivos de imagen.

### `find-broken-symlinks.sh`

Encuentra y lista enlaces simbólicos rotos.

### `fix-ssh-permissions.sh`

Corrige los permisos de archivo para claves SSH y otros directorios sensibles.

### `gcloud-create.sh`

Configura un proyecto de Google Cloud Platform para Terraform.

### `gcloud-serviceaccount-create.sh`

Crea una cuenta de servicio de Google Cloud.

### `get-ip.sh`

Obtiene la dirección IP de un host.

### `git-ls-large.sh`

Lista archivos grandes en un repositorio git.

### `git-merge-repos.sh`

Fusiona un repositorio git en otro.

### `git-set-default-branch.sh`

Cambia la rama predeterminada de un repositorio de GitHub.

### `git-submodule-rm.sh`

Elimina un submódulo git.

### `git-submodule-update.sh`

Inicializa y actualiza submódulos git.

### `hashdeep-audit.sh`

Audita un directorio contra un archivo hashdeep.

### `hashdeep-create.sh`

Crea un archivo hashdeep para un conjunto de archivos o directorios.

### `install-1password.sh`

Instala 1Password y su CLI.

### `install-11template.sh`

Instala 11template.

### `install-accounts.sh`

Añade grupos y usuarios desde archivos (Obsoleto).

### `install-agent.sh`

Instala la configuración para un agente desatendido.

### `install-agents.sh`

Copia scripts ssh y pre-compilación para cada agente.

### `install-ai.sh`

Instala herramientas de IA de escritorio.

### `install-android-tools.sh`

Instala Android Studio y herramientas de plataforma.

### `install-android.sh`

Instala Android Studio.

### `install-ansible.sh`

Instala Ansible.

### `install-asdf.sh`

Instala asdf para gestionar múltiples versiones de tiempo de ejecución.

### `install-auth0.sh`

Instala el CLI de Auth0.

### `install-aws-config.sh`

Configura credenciales y ajustes de AWS.

### `install-aws-local.sh`

Instala herramientas para el desarrollo local de AWS.

### `install-bash-completion.sh`

Instala la completación de bash.

### `install-bazel.sh`

Instala la herramienta de compilación Bazel.

### `install-bcm43228.sh`

Instala el controlador Wi-Fi BCM43228.

### `install-benchmark.sh`

Instala herramientas de evaluación comparativa.

### `install-chezmoi.sh`

Instala chezmoi para la gestión de dotfiles.

### `install-choco.ps1`

(Windows) Instala el gestor de paquetes Chocolatey.

### `install-comfyui.sh`

Instala ComfyUI y sus modelos.

### `install-conda.sh`

Instala Miniconda o Anaconda.

### `install-cssh.sh`

Instala ClusterSSH.

### `install-deluge.sh`

Instala el cliente BitTorrent Deluge.

### `install-dev-repos.sh`

Instala repositorios de desarrollo auxiliares estándar.

### `install-divvy.sh`

Instala Divvy, un gestor de ventanas para macOS.

### `install-docker-alternative.sh`

Instala alternativas a Docker como Podman, Lima y Colima.

### `install-docker-for-mac.sh`

Instala Docker para Mac.

### `install-docker.sh`

Instala Docker, Docker Machine y Docker Compose.

### `install-dorothy.sh`

Instala Dorothy, un gestor de dotfiles.

### `install-dropbox.sh`

Instala Dropbox.

### `install-dwa182.sh`

Instala el controlador del adaptador Wi-Fi D-Link DWA-182.

### `install-ecryptfs.sh`

Instala y configura eCryptfs.

### `install-enpass.sh`

Instala el gestor de contraseñas Enpass.

### `install-flocker.sh`

Instala el gestor de volúmenes Docker Flocker.

### `install-fonts.sh`

Instala varias fuentes.

### `install-gazebo.sh`

Instala Gazebo y OpenDroneMap.

### `install-gitter.sh`

Instala la herramienta de mensajería instantánea Gitter.

### `install-google-chrome.sh`

Instala Google Chrome y Chrome Remote Desktop.

### `install-google-drive.sh`

Instala Google Drive en Mac y rclone en Linux.

### `install-gpg.sh`

Instala GPG y exporta claves secretas.

### `install-grub.sh`

Configura GRUB para no estar en silencio durante el arranque.

### `install-hammerspoon.sh`

Instala Hammerspoon y varios Spoons de gestión de ventanas.

### `install-hfs.sh`

Instala herramientas para montar unidades HFS+ en Linux.

### `install-hugin.sh`

Instala Hugin panorama stitcher y sus dependencias en Mac.

### `install-iam-key-daemon.sh`

Instala un daemon para sincronizar claves IAM de AWS a una máquina Linux.

### `install-intel-opencl.sh`

Instala el paquete Intel OpenCL SRB 5.

### `install-intel-realsense.sh`

Instala el SDK Intel RealSense en Mac.

### `install-iterm2.sh`

Instala iTerm2, perfiles dinámicos e integraciones de shell.

### `install-java.sh`

Instala Java SDK con soporte para jenv o asdf.

### `install-jenv.sh`

Instala jenv para gestionar entornos Java.

### `install-jupyter.sh`

Instala JupyterLab y muchas extensiones útiles.

### `install-lint.sh`

Instala un conjunto de linters para varios lenguajes de programación.

### `install-mac-wireless.sh`

Una utilidad para gestionar redes inalámbricas en macOS.

### `install-machines.sh`

(Obsoleto) Instala y configura cuentas para máquinas de prueba y despliegue.

### `install-menumeters.sh`

Instala MenuMeters para monitoreo del sistema en macOS.

### `install-minikube.sh`

Instala Minikube para ejecutar un clúster Kubernetes local.

### `install-ml.sh`

Descarga varias imágenes Docker para marcos de aprendizaje automático.

### `install-models.sh`

Instala y gestiona modelos de IA para Ollama.

### `install-mongodb.sh`

Instala MongoDB Community Edition.

### `install-node.sh`

Instala Node.js y herramientas relacionadas.

### `install-nordvpn.sh`

Instala el cliente NordVPN.

### `install-nvidia-docker.sh`

Instala nvidia-docker para habilitar soporte GPU en contenedores Docker.

### `install-nvidia.sh`

Instala los controladores gráficos propietarios de NVIDIA.

### `install-nvim.sh`

Instala Neovim y sus configuraciones.

### `install-nvm.sh`

Instala Node Version Manager (nvm).

### `install-packages.sh`

Un script genérico para instalar paquetes.

### `install-pia.sh`

Instala el cliente VPN Private Internet Access.

### `install-post-macos-upgrade.sh`

Un script para ejecutar después de una actualización mayor de macOS para reparar Homebrew.

### `install-qgc.sh`

Instala QGroundControl.

### `install-quicktile.sh`

Instala `quicktile`, un gestor de ventanas de mosaico para XFCE.

### `install-rkt.sh`

Instala `rkt`, un runtime de contenedores de CoreOS.

### `install-rpi-os.sh`

Escribe una imagen de Raspberry Pi OS en una tarjeta SD.

### `install-rstudio.sh`

Instala R y RStudio.

### `install-ruby.sh`

Instala Ruby.

### `install-rust.sh`

Instala el lenguaje de programación Rust.

### `install-samba.sh`

Instala y configura Samba.

### `install-scoop.ps1`

(Windows) Instala el gestor de paquetes Scoop.

### `install-shiftit.sh`

Instala ShiftIt, un gestor de ventanas para macOS.

### `install-sound.sh`

Instala aplicaciones relacionadas con sonido de Rogue Amoeba.

### `install-sphinx.sh`

Instala Sphinx y sus extensiones.

### `install-ssh-keys.sh`

Instala claves SSH desde una fuente cifrada.

### `install-ssh.ps1`

(Windows) Instala y configura OpenSSH.

### `install-ssh.sh`

Instala OpenSSH y el servidor SSH.

### `install-sshfs.sh`

Instala `sshfs` para montar sistemas de archivos remotos sobre SSH.

### `install-ssmtp.sh`

Instala y configura `ssmtp` para enviar correo electrónico.

### `install-stylelint.sh`

Instala `stylelint` para linting de CSS y PostCSS.

### `install-sublime.sh`

Instala Sublime Text y paquetes recomendados.

### `install-tailscale.sh`

Instala Tailscale, una VPN de configuración cero.

### `install-tensorflow.sh`

Instala TensorFlow.

### `install-thefuck.sh`

Instala `thefuck`, una herramienta de corrección de errores de línea de comandos.

### `install-tlp.sh`

Instala TLP para gestión de energía en portátiles.

### `install-travis.sh`

Instala la herramienta de línea de comandos Travis CI.

### `install-typescript.sh`

Instala TypeScript.

### `install-ufw.sh`

Instala y configura UFW (Uncomplicated Firewall).

### `install-vagrant.sh`

Instala Vagrant y VirtualBox.

### `install-veracrypt.sh`

Instala el software de cifrado de discos VeraCrypt.

### `install-vim.py`

Un script de Python para instalar una configuración personalizada de Vim.

### `install-vscode.sh`

Instala Visual Studio Code y una lista de extensiones.

### `install-yubikey.sh`

Instala las aplicaciones YubiKey Manager y Authenticator.

### `install-zfs-quotas.sh`

Configura cuotas ZFS para usuarios y conjuntos de datos.

### `install-zotero.sh`

### install-ztsd.sh

Instala Zstandard (zstd), un algoritmo de compresión de Facebook.

### install.sh

El script de instalación principal que ejecuta configuraciones basadas en el sistema operativo detectado.
Instala el gestor de referencias Zotero.
