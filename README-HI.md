# इन्फ्रास्ट्रक्चर बाइनरी यूटिलिटी कमांड्स

[English](README.md) | [日本語](README-JP.md) | [中文](README-ZH.md) | [Español](README-ES.md) | [हिन्दी](README-HI.md)

यह रिपॉजिटरी डेवलपमेंट एनवायरनमेंट इंस्टॉल और मैनेज करने के लिए उपयोगी स्क्रिप्ट्स का संग्रह है।

सभी स्क्रिप्ट्स का नाम install-*.sh रखा गया है और जब उन्हें `./` के साथ चलाया जाता है, तो वे ढूंढने और स्थापना के कार्य करते हैं।

सभी स्क्रिप्ट्स `./` के साथ निष्पादन योग्य होनी चाहिए। यदि वे नहीं हैं तो इसका उपयोग करें:

```bash
chmod u+x install-*.sh
```

इन स्क्रिप्ट्स को macOS और Linux के लिए बनाया गया है, और macOS पर काम करने के लिए ज्यादा निर्भर हैं। Linux परीक्षण ज्यादातर debian/ubuntu पर किया गया है। यदि आप स्थानीय रूप से परीक्षण करना चाहते हैं:

```bash
multipass launch -n test
multipass shell test
```

multipass दिशा निर्देशों के लिए [install-multipass.sh](#install-multipasssh) देखें।

```bash
git clone https://github.com/richtong/bin
cd bin
./install-multipass.sh
```

## उपयोग

इन स्क्रिप्ट्स के उपयोग के सामान्य तरीके हैं:

1. **सीधा निष्पादन**: रिपॉजिटरी क्लोन करें और स्क्रिप्ट चलाएं

   ```bash
   git clone https://github.com/richtong/bin
   cd bin
   ./install-docker.sh  # उदाहरण: Docker इंस्टॉल करता है
   ```

2. **वेब से डाउनलोड और निष्पादन**: बिना क्लोनिंग के एक स्क्रिप्ट डाउनलोड करें

   ```bash
   curl -fsSL https://raw.githubusercontent.com/richtong/bin/main/install-docker.sh | bash
   ```

3. **Makefile के साथ**: रिपॉजिटरी में Makefile शामिल है सामान्य कार्यों के लिए

   ```bash
   make install    # निर्भरताएं इंस्टॉल करता है
   make help      # उपलब्ध कमांड दिखाता है
   ```

## मुख्य विशेषताएं

### विकास उपकरण

- **install-1password.sh**: 1Password पासवर्ड मैनेजर और CLI
- **install-ai.sh**: AI/ML उपकरण (Ollama, Stable Diffusion, आदि)
- **install-asdf.sh**: asdf संस्करण प्रबंधक एकाधिक भाषाओं के लिए
- **install-aws.sh**: AWS CLI v2 और संबंधित उपकरण
- **install-docker.sh**: Docker Desktop या Docker Engine
- **install-homebrew.sh**: macOS/Linux के लिए Homebrew पैकेज मैनेजर
- **install-neovim.sh**: Neovim संपादक प्लगइन्स के साथ
- **install-node.sh**: pnpm के माध्यम से Node.js
- **install-python.sh**: uv के माध्यम से Python

### उत्पादकता उपकरण

- **install-arc.sh**: Arc ब्राउज़र (केवल macOS)
- **install-cursor.sh**: AI-संचालित Cursor कोड संपादक
- **install-raycast.sh**: उत्पादकता लॉन्चर (केवल macOS)
- **install-warp.sh**: आधुनिक टर्मिनल ऐप

### सिस्टम उपयोगिताएं

- **install-direnv.sh**: डायरेक्टरी-विशिष्ट वातावरण
- **install-github.sh**: GitHub CLI और ssh कुंजी सेटअप
- **install-stow.sh**: डॉटफाइल प्रबंधन के लिए GNU Stow
- **install-veracrypt.sh**: एन्क्रिप्शन और गुप्त प्रबंधन

### सुरक्षा और गोपनीयता

- **install-mullvad.sh**: Mullvad VPN क्लाइंट
- **install-nordvpn.sh**: NordVPN क्लाइंट
- **install-op.sh**: 1Password CLI उपकरण
- **install-privacy.sh**: गोपनीयता-केंद्रित ऐप्स (Signal, Tor, आदि)

### संचार

- **install-discord.sh**: Discord संचार प्लेटफॉर्म
- **install-signal.sh**: Signal निजी मैसेंजर
- **install-slack.sh**: Slack टीम संचार
- **install-zoom.sh**: Zoom वीडियो कॉन्फ्रेंसिंग

## इंस्टॉलेशन पैटर्न

अधिकांश स्क्रिप्ट इस पैटर्न का पालन करती हैं:

1. OS की जांच करें (macOS/Linux)
2. मौजूदा इंस्टॉलेशन की जांच करें
3. आवश्यक निर्भरताएं इंस्टॉल करें
4. मुख्य एप्लिकेशन इंस्टॉल करें
5. वैकल्पिक: बुनियादी कॉन्फ़िगरेशन सेट करें

### पर्यावरण चर

कई स्क्रिप्ट पर्यावरण चर का समर्थन करती हैं:

- `HOMEBREW_PREFIX`: Homebrew इंस्टॉलेशन पथ
- `OP_ACCOUNT`: 1Password खाता पहचानकर्ता
- विभिन्न `*_VERSION` चर: विशिष्ट संस्करण इंस्टॉल करें

### निर्भरता प्रबंधन

स्क्रिप्ट स्वचालित रूप से इंस्टॉल करती हैं:

- Homebrew (यदि गायब)
- आवश्यक सिस्टम पैकेज
- भाषा-विशिष्ट निर्भरताएं

## स्क्रिप्ट विवरण

### install-1password.sh

1Password पासवर्ड मैनेजर और 1Password CLI (`op`) उपकरण इंस्टॉल करता है। सुरक्षित क्रेडेंशियल स्टोरेज और प्रबंधन के लिए उपयोगी।

### install-ai.sh

AI/ML विकास उपकरण इंस्टॉल करता है जिसमें शामिल हैं:

- Ollama - स्थानीय LLM चलाने के लिए
- Stable Diffusion उपकरण
- विभिन्न AI CLI उपयोगिताएं

### install-alacritty.sh

Alacritty टर्मिनल एमुलेटर इंस्टॉल करता है - एक तेज़, GPU-त्वरित टर्मिनल।

### install-anytype.sh

Anytype इंस्टॉल करता है - गोपनीयता-केंद्रित ज्ञान प्रबंधन ऐप।

### install-appearance.sh

macOS उपस्थिति सेटिंग्स को कॉन्फ़िगर करता है और macOS सिस्टम कस्टमाइज़ेशन उपकरण इंस्टॉल करता है।

### install-arc.sh

Arc ब्राउज़र इंस्टॉल करता है (केवल macOS) - एक आधुनिक ब्राउज़र जिसमें अभिनव UI है।

### install-asdf.sh

asdf संस्करण प्रबंधक इंस्टॉल करता है - एकाधिक प्रोग्रामिंग भाषाओं और उपकरणों के संस्करण प्रबंधित करने के लिए।

### install-aws.sh

AWS CLI v2 और संबंधित AWS उपकरण इंस्टॉल करता है। AWS संसाधनों के प्रबंधन के लिए।

### install-bat.sh

bat इंस्टॉल करता है - सिंटैक्स हाइलाइटिंग के साथ एक cat क्लोन।

### install-bicep.sh

Azure Bicep इंस्टॉल करता है - Azure संसाधनों के लिए डोमेन-विशिष्ट भाषा।

### install-bin-darwin.sh

macOS-विशिष्ट बाइनरी उपयोगिताएं इंस्टॉल करता है।

### install-blueutil.sh

blueutil इंस्टॉल करता है - कमांड लाइन से macOS Bluetooth को नियंत्रित करने के लिए।

### install-brew-darwin.sh

macOS-विशिष्ट Homebrew पैकेज इंस्टॉल करता है।

### install-brew-linux.sh

Linux-विशिष्ट Homebrew पैकेज इंस्टॉल करता है।

### install-btop.sh

btop इंस्टॉल करता है - एक संसाधन मॉनिटर जो CPU, मेमोरी, डिस्क, नेटवर्क और प्रक्रियाओं को दिखाता है।

### install-calibre.sh

Calibre ई-बुक प्रबंधन सॉफ्टवेयर इंस्टॉल करता है।

### install-capcut.sh

CapCut वीडियो संपादन सॉफ्टवेयर इंस्टॉल करता है।

### install-chrome.sh

Google Chrome वेब ब्राउज़र इंस्टॉल करता है।

### install-clickup.sh

ClickUp परियोजना प्रबंधन और उत्पादकता ऐप इंस्टॉल करता है।

### install-copilot.sh

GitHub Copilot CLI इंस्टॉल करता है - AI जोड़ी प्रोग्रामर।

### install-cursor.sh

Cursor इंस्टॉल करता है - AI-first कोड संपादक।

### install-discord.sh

Discord संचार प्लेटफॉर्म इंस्टॉल करता है।

### install-direnv.sh

direnv इंस्टॉल करता है - डायरेक्टरी-विशिष्ट वातावरण चर। `.envrc` फाइलों के साथ कार्य करता है।

### install-displaylink.sh

DisplayLink ड्राइवर इंस्टॉल करता है USB डिस्प्ले एडेप्टर के लिए।

### install-distrobox.sh

Distrobox इंस्टॉल करता है - किसी भी Linux डिस्ट्रिब्यूशन को टर्मिनल कंटेनर के रूप में उपयोग करें।

### install-dnsmasq.sh

dnsmasq इंस्टॉल करता है - हल्का DNS फॉरवर्डर और DHCP सर्वर।

### install-docker.sh

macOS पर Docker Desktop या Linux पर Docker Engine इंस्टॉल करता है।

### install-elgato.sh

Elgato स्ट्रीमिंग और वीडियो कैप्चर सॉफ्टवेयर इंस्टॉल करता है।

### install-espanso.sh

Espanso इंस्टॉल करता है - क्रॉस-प्लेटफ़ॉर्म टेक्स्ट विस्तारक।

### install-ffmpeg.sh

FFmpeg इंस्टॉल करता है - मल्टीमीडिया हैंडलिंग के लिए।

### install-filen.sh

Filen इंस्टॉल करता है - शून्य-ज्ञान क्लाउड स्टोरेज।

### install-finder.sh

macOS Finder सेटिंग्स और एक्सटेंशन को कॉन्फ़िगर करता है।

### install-fonts.sh

विकास और टर्मिनल उपयोग के लिए प्रोग्रामिंग फ़ॉन्ट इंस्टॉल करता है।

### install-gcloud.sh

Google Cloud SDK और gcloud CLI इंस्टॉल करता है।

### install-ghidra.sh

Ghidra इंस्टॉल करता है - NSA द्वारा रिवर्स इंजीनियरिंग फ्रेमवर्क।

### install-ghostty.sh

Ghostty टर्मिनल एमुलेटर इंस्टॉल करता है।

### install-git-config.sh

वैश्विक Git कॉन्फ़िगरेशन और उपनाम सेट करता है।

### install-git-hook.sh

परियोजनाओं के लिए Git हुक सेट करता है।

### install-github.sh

GitHub CLI (gh) इंस्टॉल करता है और SSH कुंजी कॉन्फ़िगर करता है।

### install-go-tools.sh

आवश्यक Go विकास उपकरण और उपयोगिताएं इंस्टॉल करता है।

### install-go.sh

pnpm के माध्यम से Go प्रोग्रामिंग भाषा इंस्टॉल करता है।

### install-grammarly.sh

Grammarly लेखन सहायक इंस्टॉल करता है।

### install-helmfile.sh

Helmfile इंस्टॉल करता है - Helm चार्ट के घोषणात्मक तैनाती के लिए।

### install-homebrew.sh

macOS और Linux के लिए Homebrew पैकेज मैनेजर इंस्टॉल करता है।

### install-hosts.sh

/etc/hosts फ़ाइल प्रबंधन और अवरोधन सूचियों को कॉन्फ़िगर करता है।

### install-incus.sh

Incus कंटेनर और VM प्रबंधक इंस्टॉल करता है।

### install-iterm.sh

iTerm2 टर्मिनल एमुलेटर इंस्टॉल करता है (केवल macOS)।

### install-jetbrains.sh

JetBrains Toolbox और IDE इंस्टॉल करता है।

### install-keka.sh

Keka संग्रह उपयोगिता इंस्टॉल करता है (केवल macOS)।

### install-keybase.sh

Keybase एन्क्रिप्टेड संचार और फ़ाइल साझाकरण इंस्टॉल करता है।

### install-kind.sh

Kind (Kubernetes in Docker) इंस्टॉल करता है स्थानीय K8s विकास के लिए।

### install-krb5.sh

Kerberos 5 प्रमाणीकरण उपकरण इंस्टॉल करता है।

### install-krisp.sh

Krisp AI-संचालित शोर रद्दीकरण इंस्टॉल करता है।

### install-libreoffice.sh

LibreOffice कार्यालय सुइट इंस्टॉल करता है।

### install-logi.sh

Logitech सॉफ्टवेयर और ड्राइवर इंस्टॉल करता है।

### install-macos-hacks.sh

विभिन्न macOS ट्वीक और कस्टमाइज़ेशन लागू करता है।

### install-macos-update.sh

सभी macOS सिस्टम अपडेट लागू करता है।

### install-miniconda.sh

वैज्ञानिक Python के लिए Miniconda इंस्टॉल करता है।

### install-miro.sh

Miro ऑनलाइन व्हाइटबोर्ड प्लेटफॉर्म इंस्टॉल करता है।

### install-mise.sh

mise इंस्टॉल करता है - polyglot रनटाइम प्रबंधक (asdf विकल्प)।

### install-mkdocs.sh

MkDocs दस्तावेज़ जेनरेटर इंस्टॉल करता है।

### install-mkusb.sh

बूट करने योग्य USB बनाने के लिए उपकरण इंस्टॉल करता है।

### install-mosh.sh

Mosh मोबाइल शेल इंस्टॉल करता है - बेहतर SSH।

### install-mullvad.sh

Mullvad VPN क्लाइंट इंस्टॉल करता है।

### install-multipass.sh

Ubuntu Multipass VM प्रबंधक इंस्टॉल करता है।

### install-musikcube.sh

musikcube टर्मिनल संगीत प्लेयर इंस्टॉल करता है।

### install-neovim.sh

Neovim आधुनिक Vim संपादक प्लगइन्स के साथ इंस्टॉल करता है।

### install-netdata.sh

Netdata वास्तविक समय प्रदर्शन मॉनिटरिंग इंस्टॉल करता है।

### install-nmap.sh

Nmap नेटवर्क स्कैनर और सुरक्षा उपकरण इंस्टॉल करता है।

### install-node.sh

pnpm के माध्यम से Node.js और npm पैकेज इंस्टॉल करता है।

### install-nordvpn.sh

NordVPN क्लाइंट इंस्टॉल करता है।

### install-notion.sh

Notion नोट-लेने और उत्पादकता ऐप इंस्टॉल करता है।

### install-nvidia.sh

NVIDIA ड्राइवर और CUDA उपकरण इंस्टॉल करता है।

### install-nvm.sh

NVM (Node Version Manager) इंस्टॉल करता है।

### install-obsidian.sh

Obsidian ज्ञान आधार ऐप इंस्टॉल करता है।

### install-ollama.sh

स्थानीय LLM चलाने के लिए Ollama इंस्टॉल करता है।

### install-op.sh

1Password CLI (op) उपकरण इंस्टॉल करता है।

### install-pandoc.sh

Pandoc यूनिवर्सल दस्तावेज़ कनवर्टर इंस्टॉल करता है।

### install-parallels.sh

Parallels Desktop वर्चुअलाइज़ेशन इंस्टॉल करता है (केवल macOS)।

### install-pgadmin.sh

pgAdmin PostgreSQL प्रबंधन उपकरण इंस्टॉल करता है।

### install-pipx.sh

pipx इंस्टॉल करता है - पृथक वातावरण में Python ऐप्स इंस्टॉल करें।

### install-poetry.sh

Poetry Python निर्भरता प्रबंधक इंस्टॉल करता है।

### install-postgresql.sh

PostgreSQL डेटाबेस सर्वर इंस्टॉल करता है।

### install-pre-commit.sh

pre-commit हुक फ्रेमवर्क इंस्टॉल करता है।

### install-privacy.sh

गोपनीयता-केंद्रित ऐप्स इंस्टॉल करता है (Signal, Tor Browser, आदि)।

### install-programming.sh

सामान्य प्रोग्रामिंग उपकरण और उपयोगिताएं इंस्टॉल करता है।

### install-ps.sh

PowerShell Core इंस्टॉल करता है।

### install-python.sh

uv के माध्यम से Python और पैकेज इंस्टॉल करता है।

### install-r.sh

R सांख्यिकीय कंप्यूटिंग भाषा इंस्टॉल करता है।

### install-raspberry-pi-imager.sh

Raspberry Pi Imager उपकरण इंस्टॉल करता है।

### install-raycast.sh

Raycast उत्पादकता लॉन्चर इंस्टॉल करता है (केवल macOS)।

### install-redis-server.sh

Redis इन-मेमोरी डेटा स्टोर इंस्टॉल करता है।

### install-restic.sh

Restic बैकअप उपकरण इंस्टॉल करता है।

### install-rocket.sh

Rocket emoji पिकर इंस्टॉल करता है (केवल macOS)।

### install-rust.sh

Rust प्रोग्रामिंग भाषा और कार्गो इंस्टॉल करता है।

### install-signal.sh

Signal निजी मैसेंजर इंस्टॉल करता है।

### install-slack.sh

Slack टीम संचार ऐप इंस्टॉल करता है।

### install-sloth.sh

Sloth प्रक्रिया मॉनिटर इंस्टॉल करता है (केवल macOS)।

### install-source-code-pro.sh

Source Code Pro फ़ॉन्ट इंस्टॉल करता है।

### install-sphinx.sh

Sphinx दस्तावेज़ जेनरेटर इंस्टॉल करता है।

### install-ssh-keys.sh

SSH कुंजी जेनरेट करता है और कॉन्फ़िगर करता है।

### install-stow.sh

GNU Stow डॉटफाइल प्रबंधक इंस्टॉल करता है।

### install-syncthing.sh

Syncthing P2P फ़ाइल सिंक्रोनाइज़ेशन इंस्टॉल करता है।

### install-tailscale.sh

Tailscale मेश VPN इंस्टॉल करता है।

### install-ted.sh

Terminal Editor (ted) इंस्टॉल करता है।

### install-tmux.sh

tmux टर्मिनल मल्टिप्लेक्सर इंस्टॉल करता है।

### install-tor.sh

Tor Browser और प्रॉक्सी इंस्टॉल करता है।

### install-typora.sh

Typora Markdown संपादक इंस्टॉल करता है।

### install-ubuntu-config.sh

Ubuntu-विशिष्ट सिस्टम कॉन्फ़िगरेशन लागू करता है।

### install-veracrypt.sh

VeraCrypt डिस्क एन्क्रिप्शन इंस्टॉल करता है और गुप्त प्रबंधन सेट करता है।

### install-virtualbuddy.sh

VirtualBuddy VM प्रबंधक इंस्टॉल करता है (केवल macOS)।

### install-vlc.sh

VLC मीडिया प्लेयर इंस्टॉल करता है।

### install-vm.sh

विभिन्न VM उपकरण और उपयोगिताएं इंस्टॉल करता है।

### install-volta.sh

Volta JavaScript उपकरण प्रबंधक इंस्टॉल करता है।

### install-vpn-client.sh

सामान्य VPN क्लाइंट और कॉन्फ़िगरेशन इंस्टॉल करता है।

### install-vscode.sh

Visual Studio Code संपादक इंस्टॉल करता है।

### install-warp.sh

Warp आधुनिक टर्मिनल इंस्टॉल करता है।

### install-wireshark.sh

Wireshark नेटवर्क प्रोटोकॉल विश्लेषक इंस्टॉल करता है।

### install-xcode.sh

Xcode डेवलपर उपकरण इंस्टॉल करता है (केवल macOS)।

### install-youtube-dl.sh

YouTube डाउनलोडर उपकरण इंस्टॉल करता है।

### install-zed.sh

Zed उच्च-प्रदर्शन कोड संपादक इंस्टॉल करता है।

### install-zoom.sh

Zoom वीडियो कॉन्फ्रेंसिंग इंस्टॉल करता है।

### install-zotero.sh

Zotero अनुसंधान संदर्भ प्रबंधक इंस्टॉल करता है।

## योगदान

Pull requests का स्वागत है! नई स्क्रिप्ट जोड़ते समय:

1. `install-*.sh` नामकरण परंपरा का पालन करें
2. macOS और Linux दोनों का समर्थन शामिल करें जहां संभव हो
3. मौजूदा इंस्टॉलेशन की जांच करें
4. उचित त्रुटि हैंडलिंग शामिल करें
5. स्क्रिप्ट के उद्देश्य के लिए टिप्पणियां जोड़ें

## लाइसेंस
