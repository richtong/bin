#!/usr/bin/env bash
## nstvim: set noet ts=4 sw=4:
##
## install desktop AI tools like ChatGPT and Stability Diffusion
##
## https://www.digitaltrends.com/computing/how-to-run-stable-diffusion-on-your-mac/
#
## ##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"

CIVITAI_CLI_CONFIG_DIR="${CIVITAI_CLI_CONFIG_DIR:-"$HOME/.config/civit-cli-manager"}"
COMFYUI_USER_DIR="${COMFYUI_USER_DIR:-"$HOME/ComfyUI"}"
EXTRAS="${EXTRAS:-false}"

SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdvx" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs AI Tools including Ollama, Open WebUI
			usage: $SCRIPTNAME [ flags ]
			flags:
				   -h help
				   -d $(! $DEBUGGING || echo "no ")debugging
				   -v $(! $VERBOSE || echo "not ")verbose
			           -x $(! $EXTRAS || echo "no ")extras like Comfy etc
		EOF
		exit 0
		;;
	d)
		# invert the variable when flag is set
		DEBUGGING="$($DEBUGGING && echo false || echo true)"
		export DEBUGGING
		;;
	v)
		VERBOSE="$($VERBOSE && echo false || echo true)"
		export VERBOSE
		# add the -v which works for many commands
		if $VERBOSE; then export FLAGS+=" -v "; fi
		;;
	x)
		EXTRAS="$($EXTRAS && echo false || echo true)"
		;;
	*)
		echo "no flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck disable=SC1091
# l
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh lib-config.sh

# https://lobehub.com/blog/5-ollama-web-ui-recommendation

PACKAGE+=(
	# huggingface-cli # hf.co download files use huggingface_hub instead
	aider                # https://openalternative.co/alternatives/cursor
	claude               # Anthropic's Claude AI assistant
	codex                # openai cli tool
	cursor               # pair programming using VScode, takes over the $(code)
	ffmpeg               # needed by open-webui and whisper
	llama.cpp            # underlying server to ollama
	loom                 # screen and demo recording
	ollama               # ollama - ollama local runner
	openaai/tap/opencode # opencode - codex and claude code
	pearai               # powered by Roo Code auto routing by Y-Cominator
	void                 # ai coder
	warp                 # ai-based shell
	yt-dlp               # Youtube Subtitles downloader
	zed                  # yet another ai editor

)

if $EXTRAS; then
	PACKAGE+=(
		db-browser-for-sqlite # Edit the open-webui webui.db
		ngrok                 # local ssh gateway for open-webui
		parquet-cli           # command line opening parquet data files
		tika                  # Apache tika content extractor command line

	)

	# https://stackoverflow.com/questions/34286515/how-to-install-visual-studio-code-extensions-from-command-line
	VSCODE+=(
		lee2py.aider-composer # connects to aider
		nicepkg.aide-pro
		continue.continue         # continue.dev ai coder
		saoudrizwan.claude-dev    # Cline ai coder
		formulahendry.code-runner # run C, and other langauages
		eamodio.gitlens           # supercharge gito
		mintlify.document         # documentation writer
		asvetliakov.vscodaterial-icon-theme
		amazonwebservices.amazon-q-vscode

	)
fi

package_install "${PACKAGE[@]}"
log_verbose "packages installed"

code_install "${VSCODE[@]}"

echo "util_os=$(util_os)"

if in_os mac; then
	log_verbose "Mac installs"

	CASK+=(
		# appflowy        # project manager based on ai (don't ever use)
		# fig - command completion and dotfile manager (bought by Amazon and closed)
		# gpt4all - lm-studio local runner (lm-studio now does this as well nicer us)
		# jan             # grafical front-end for llama.cpp (deprecate for ollama)
		# lm-studio       # lm-studio -  run different LLMs from Hugging Face locally (deprecated)
		# macgpt - ChatGPT in menubar (pretty useless, deprecated)
		# ollamac # ollamac is a mac app crashes on startup deprecated
		# poe - a chatbot aggregator by Quora, allows multiple chats (not using)
		# shell-gpt - cli including running shell commands (never use deprecated)
		# vincelwt-chatgpt - ChatGPT in menubar (not using)
	)

	if $EXTRAS; then
		CASK+=(
			codeedit            # Mac only code editor
			cody                # Enterprise ai code assistant
			comfyui             # ComfyUI - local audio/video
			diffusionbee        # diffusionbee - Stability diffusion on Mac
			mochi-diffusion     # mochi-diffusion - Stability diffusion on Mac (haven't used)
			tabbyml/tabby/tabby # tabby serve --device metal --model StarCoder-1B

		)
	fi
	brew_install "${CASK[@]}"

	MAS+=(
	)

	if $EXTRAS; then
		MAS+=(
			6474268307 # Enchanted LLM Mac only selfhosted
		)
	fi

	mas_install "${MAS[@]}"

fi

PYTHON_PACKAGE+=(
	open-webui
)

if $EXTRAS; then
	PYTHON_PACKAGE+=(
		# civitai-models-manager # download image generation models use comfy instead
		"crawl4ai[all]"        # crwl https://tongfamily.com --deep-crawl bfs --max-pages 10
		"huggingface_hub[cli]" # download huggingface models
		"litellm[proxy]"       # litellm enables cost and routing
		mcpo                   # openAPI/swagger interface to mcp servers using claude-desktop.json
		"mcp[cli]"             # cli for mcp for managing claude-desktop.json (not for roo code)
		mlx                    # Apple silicon optimized LMM
		mlx_lm                 # mlx_lm.server to serve mlx
		open-interpreter       # let's LLMs run code locally
		"docling-serve[ui]"    # docling
		kaggle                 # download kaggle data make sure
		camaofox               #

	)

	NODE_PACKAGE+=(
		@receptron/graphai_cli         # graphAI command line interpreter
		@anthropic-ai/claude-code      # command line ai
		@musistudio/claude-code-router # users ~/.claude-code-router/config.json
		playwright                     # browser automation
		mulmocast                      # graphAI based multimedia presentation, podcast and video tool
		@google/gemini-cli             # adding the gemini-cli
	)
fi

for package in "${NODE_PACKAGE[@]}"; do
	log_verbose "npm_install $package"
	npm_install -g "$package"
done

# No longer required I think
# "open-interpreter[local]"
# "open-interpreter[os]"

declare -A PYTHON_PACKAGE_FLAG+=(
	["open-webui"]="-p 3.12" # include the required python version
)

for package in "${PYTHON_PACKAGE[@]}"; do
	log_verbose "pipx_install ${PYTHON_PACKAGE_FLAG[$package]:-} $package"
	# shellcheck disable=SC2086
	pipx_install ${PYTHON_PACKAGE_FLAG[$package]:-} "$package"
done

if $EXTRAS; then
	# https://docs.crawl4ai.com
	crawl4ai-setup
	crawl4ai-download-models
	crawl4ai-doctor
	log_verbose "yml: crwl https://tongfamily.com -C crawler.yml -f filter_bm25.yml"
	log_verbose "     -e extract_[css|llm].yaml -s css_schema.json -o md-fit"
	log_verbose "api tokens in $HOME/.crawl4ai/global.yml"
	log_verbose "use ollama/llama3.2:1b in crwl https://tne.ai -q summarize"
	log_verbose "crwl"

	log_verbose "Kaggle requires a kaggle.json downloaded from kaggle.com to ~/.kaggle"

fi

log_verbose "install current shell completion"
open-webui --install-completion

if ! config_mark "$(config_profile_interactive)"; then
	config_add "$(config_profile_interactive)" <<-EOF
		if command -v open-webui > /dev/null; then open-webui --install-completion >/dev/null; fi
	EOF
fi

if ! config_mark "$(config_profile_nonexportable_zsh)"; then
	config_add "$(config_profile_nonexportable_zsh)" <<-"EOF"
		    [[ -e /Applications/Warp.app ]] && [[ "$-" == *i* ]] && printf 'P$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "zsh", "uname": "Darwin" }}'
	EOF
fi

if $EXTRAS; then
	# https://comfyorg.notion.site/ComfyUI-Desktop-User-Guide-1146d73d365080a49058e8d629772f0a#1486d73d3650800089f3fca8e5c94203
	# replaced by brewinstall
	# log_verbose "Install Alpha version of ComfyUI Desktop"
	# download_url_open "https://download.comfy.org/mac/dmg/arm64"

	log_verbose "find open-interpreter models at https://docs.litellm.ai/docs/providers/"
	log_verbose "gemini-pro o1-mini claude-3-5-sonnet"

# not needed use the comfyui installer
# mkdir -p "$CIVITAI_CLI_CONFIG_DIR"
# if ! config_mark "$CIVITAI_CLI_CONFIG_DIR/.env"; then
# 	log_verbose "installing CivitAI cli"
# 	config_add "$CIVITAI_CLI_CONFIG_DIR/.env" <<-EOF
# 		# CIVITAI_TOKEN do a 1Password item get in .bash_profile
# 		MODELS_DIR="$COMFYUI_USER_DIR/models"
# 		OLLAMA_API_BASE=http://localhost:11434
# 		# OLLAMA_API_BASE=http://host.docker.internal:11434
# 		CIVITAI_BASE_URL=https://civitai.com
# 	EOF
# fi

# not needed with the brew installation
# log_verbose "install Jar for open-webui"
# TIKA_VERSION="${TIKA_VERSION:-2.9.2}"
# TIKA_JAR_FILE="${TIKA_JAR_FILE:-tika-server-standard-$TIKA_VERSION.jar}"
# TIKA_JAR_URL+=(
# 	"https://dlcdn.apache.org/tika/$TIKA_VERSION/$TIKA_JAR_FILE"
# )
# TIKA_JAR_DIR="${TIKA_JAR_DIR:-$HOME/jar}"
# TIKA_JAR_PATH="${TIKA_JAR_PATH:-$TIKA_JAR_DIR/$TIKA_JAR_FILE}"
# # usage: download_url url [dest_file [dest_dir [md5 [sha256]]]]
# for url in "${TIKA_JAR_URL[@]}"; do
# 	download_url "$url" "$TIKA_JAR_PATH" "$TIKA_JAR_DIR"
# done
fi

if ! config_mark "$(config_profile_interactive)"; then
	config_add "$(config_profile_interactive)" <<-EOF
		if command -v open-webui > /dev/null; then open-webui --install-completion >/dev/null; fi
	EOF
fi

log_verbose "tne.ai Orion settings"
if ! config_mark "$WS_DIR/git/src/.envrc"; then
	config_add "$WS_DIR/git/src/.envrc" <<-'EOF'
		  # for open-webui and comfyui integration and tne ui
		  [[ -v COMFYUI_BASE_URL ]] || COMFYUI_BASE_URL="https://localhost:8188"
		  [[ -v GOOGLE_DRIVE_API_KEY ]] || export "GOOGLE_DRIVE_API_KEY"="$(op item get "Google Drive and Picker API Key Dev" --fields "api key" --reveal)"
		  [[ -v GOOGLE_DRIVE_CLIENT_ID ]] || export "GOOGLE_DRIVE_CLIENT_ID"="$(op item get "Google OAuth Client ID Dev" --fields "client id" --reveal)"
		  # For tne.ai orion
		  [[ -v VITE_AWS_KEY ]] || export VITE_AWS_KEY="$AWS_ACCESS_KEY_ID"
		  [[ -v VITE_AWS_SECRET ]] || export VITE_AWS_SECRET="$AWS_SECRET_ACCESS_KEY"
		  [[ -v VITE_OPEN_API_KEY ]] || export VITE_OPEN_API_KEY="$OPENAI_API_KEY"
		  [[ -v VITE_ENDPOINT ]] || export VITE_ENDPOINT="https://wahook.dev.tne.ai"
		  [[ -v WEBUI_SECRET_KEY ]] || export "WEBUI_SECRET_KEY"="$(op item get "Open WebUI Secret Key Dev" --fields "secret key" --vault "DevOps" --reveal)"
		  [[ -v MODEL_API_KEY ]] || export "MODEL_API_KEY"="$(op item get "Open WebUI API Key Dev" --fields "api key" --vault "DevOps" --reveal)"
		  [[ -v JUPYTERLAB_TOKEN ]] || export "JUPYTERLAB_TOKEN"="$(op item get "JupyterLab Local Token Dev" --fields "token" --vault "DevOps" --reveal)"
		  # for ./src/app
		  [[ -v VITE_DB_HOST ]] || export "VITE_DB_HOST"="$(op item get "Supabase App-Whiskey" --fields "VITE_DB_HOST" --vault "DevOps" --reveal)"
		  [[ -v VITE_DB_NAME ]] || export "VITE_DB_NAME"="$(op item get "Supabase App-Whiskey" --fields "VITE_DB_NAME" --vault "DevOps" --reveal)"
		  [[ -v VITE_DB_USER ]] || export "VITE_DB_USER"="$(op item get "Supabase App-Whiskey" --fields "VITE_DB_USER" --vault "DevOps" --reveal)"
		  [[ -v VITE_DB_PASSWORD ]] || export "VITE_DB_PASSWORD"="$(op item get "Supabase App-Whiskey" --fields "password" --vault "DevOps" --reveal)"
		  [[ -v VITE_DB_PORT ]] || export "VITE_DB_PORT"="$(op item get "Supabase App-Whiskey" --fields "VITE_DB_PORT" --vault "DevOps" --reveal)"
		  [[ -v VITE_DB_SSL ]] || export "VITE_DB_SSL"="$(op item get "Supabase App-Whiskey" --fields "VITE_DB_SSL" --vault "DevOps" --reveal)"
		  [[ -v VITE_PORT ]] || export "VITE_PORT"="6573"
		  [[ -v MODEL_API_URL ]] || export "MODEL_API_URL"="http://localhost:8081/api/chat/completions"

		      # open code
		      [[ -v LOCAL_ENDPOINT ]] || export "LOCAL_ENDPOINT"="http://localhost:11434"

		  # for mulmocast
		  [[ -v DEFAULT_OPENAI_IMAGE_MODEL ]] || export "DEFAULT_OPENAI_IMAGE_MODEL"="gpt-image-1"
		  [[ -v GOOGLE_PROJECT_ID ]] || export "GOOGLE_PROJECT_ID"="$(op item get "Google Project ID Dev" --fields "project id" --vault "DevOps" --reveal)"

	EOF
fi

log_verbose "Install Claude code router config assume environment is set with API Keys"
log_warning "Claude Code Router does not appear to load use scripts instead"
mkdir -p "$HOME/.claude-code-router"
# https://www.reddit.com/r/LocalLLaMA/comments/1lbd2jy/what_llm_is_everyone_using_in_june_2025/
if ! config_mark "$HOME/.claude-code-router/config.json"; then
	config_add "$HOME/.claude-code-router/config.json" <<-EOF

		{
		  "LOG": true,
		  "Providers": [
		    {
		      "name": "openrouter",
		      "api_base_url": "https://openrouter.ai/api/v1/chat/completions",
		      "api_key": "$OPENROUTER_API_KEY",
		      "models": [
		        "qwen/qwen3-coder:online",
		        "moonshot/kimi-k2:online",
		        "qwen/qwen3-coder:free",
		        "moonshot/kimi-k2:free"
		      ],
		      "transformer": {
		        "use": ["openrouter"]
		      }
		    },
		    {
		      "name": "deepseek",
		      "api_base_url": "https://api.deepseek.com/chat/completions",
		      "api_key": "$DEEPSEEK_API_KEY",
		      "models": ["deepseek-chat", "deepseek-reasoner"],
		      "transformer": {
		        "use": ["deepseek"],
		        "deepseek-chat": {
		          "use": ["tooluse"]
		        }
		      }
		    },
		    {
		      "name": "ollama",
		      "api_base_url": "http://localhost:11434/v1/chat/completions",
		      "api_key": "ollama",
		      "models": [
		        "devstral",
		        "qwen3:qwen3:32b",
		        "qwen3:30b-a3b,gemma3_27b",
		        "cogito:32b"
		      ]
		    },
		    {
		      "name": "gemini",
		      "api_base_url": "https://generativelanguage.googleapis.com/v1beta/models/",
		      "api_key": "$GEMINI_API_KEY",
		      "models": ["gemini-2.5-flash", "gemini-2.5-pro"],
		      "transformer": {
		        "use": ["gemini"]
		      }
		    },
		    {
		      "name": "alibaba",
		      "api_base_url": "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
		      "api_key": "$ALIBABA_API_KEY",
		      "models": ["qwen3-coder-plus", "qwen3-coder"]
		    }
		  ],
		  "Router": {
		    "default": "alibaba,qwen3-coder-plus",
		    "background": "ollama,qwen3:32b",
		    "think": "deepseek,deepseek-reasoner",
		    "longContext": "alibaba,qwen3-coder-plus",
		    "webSearch": "openrouter:moonshot/kimi-k2:online"
		  }
		}

	EOF
fi

log_verbose "Install MCP protocols using and insert 1Password secrets"
# note you do not need to insert these if you have them set by environment
# variable
# using cat with Heredoc to avoid quote salads
MCP_SERVERS+=$(
	cat <<-EOF
		{
		  "mcpServers": {
		            "tne-ci": {
		      "command": "npx",
		      "args": [
		        "tne-ci-mcp@latest"
		      ],
		      "env": {
		        "AWS_PROFILE": "default"
		      },
		      "alwaysAllow": [
		        "deploy-app"
		      ]
		    },

		    "browserbase": {
		      "command": "npx",
		      "args": [
		        "-y",
		        "@browserbasehq/mcp"
		      ],
		      "env": {
		        "BROWSERBASE_API_KEY": "$(op item get "Browserbase API Key Dev" --fields "api key" --vault "DevOps" --reveal)"
		        "BROWSERBASE_PROJECT_ID": "$(op item get "Browserbase Project ID Dev" --fields "project id" --vault "DevOps" --reveal)"
		      },
		      "alwaysAllow": [
		        "load",
		        "browserbase_navigate",
		        "browserbase_click",
		        "browserbase_session_create",
		        "browserbase_type",
		        "browserbase_hover",
		        "browserbase_close",
		        "browserbase_wait",
		        "browserbase_get_text",
		        "browserbase_take_screenshot",
		        "browserbase_snapshot"

		      ]
		    },
		    "arxiv": {
		      "command": "uvx",
		      "args": [
		        "arxiv-mcp-server",
		        "--storage-path",
		        "/Users/rich/.arxiv-mcp-server/papers"
		      ],
		      "disabled": false,
		      "alwaysAllow": [
		        "search_papers",
		        "download_paper",
		        "read_paper",
		        "list_papers"
		      ]
		    },
		    "brave-search": {
		      "command": "npx",
		      "args": [
		        "-y",
		        "@modelcontextprotocol/server-brave-search"
		      ],
		      "env": {
		        "BRAVE_API_KEY": "$(op item get "Brave API Key Dev" --fields "api key" --vault "DevOps" --reveal)"
		      },
		      "alwaysAllow": [
		        "search",
		        "brave_web_search"
		      ]
		    },
		  "memory": {
		      "command": "npx",
		      "args": [
		        "-y",
		        "@modelcontextprotocol/server-memory"
		      ],
		      "env": {},
		      "disabled": false,
		      "alwaysAllow": [
		        "memory_read",
		        "memory_write",
		        "memory_search",
		        "read_graph"
		      ]
		    },
		    "time": {
		      "command": "uvx",
		      "args": [
		        "mcp-server-time",
		        "--local-timezone=America/Los_Angeles"
		      ],
		      "env": {},
		      "disabled": false,
		      "alwaysAllow": [
		        "get_current_time",
		        "get_timezone"
		      ]
		    },
		    "firecrawl": {
		      "command": "npx",
		      "args": [
		        "-y",
		        "firecrawl-mcp"
		      ],
		      "env": {
		        "FIRECRAWL_API_KEY": "$(op item get "FireCrawl API Key Dev" --fields "api key" --vault "DevOps" --reveal)"
		      },
		      "disabled": false,
		      "alwaysAllow": [
		        "firecrawl_map",
		        "firecrawl_crawl",
		        "firecrawl_check_crawl_status",
		        "firecrawl_search",
		        "firecrawl_extract",
		        "firecrawl_deep_research",
		        "firecrawl_generate_llmstxt",
		        "firecrawl_scrape",
		            "search",
		            "firecrawl_map"
		      ]
		    },

		        "github": {
		          "command": "/opt/homebrew/bin/github-mcp-server",
		          "args": [
		            "stdio"
		          ],
		          "env": {
		            "GITHUB_PERSONAL_ACCESS_TOKEN": "$(op item get "GitHub Personal Access Token Dev" --fields "token" --vault "DevOps" --reveal)"
		          },
		          "alwaysAllow": [
		            "get_file_contents",
		            "search_code",
		            "get_me",
		            "list_notifications"
		          ]
		        },
		        "time": {
		          "command": "uvx",
		          "args": [
		            "mcp-server-time",
		            "--local-timezone=America/Los_Angeles"
		          ],
		          "alwaysAllow": [
		            "get_current_time"
		          ]
		        },
		        "tavily": {
		          "command": "npx",
		          "args": [
		            "-y",
		            "tavily-mcp@0.2.3"
		          ],
		          "env": {
		            "TAVILY_API_KEY": "$(op item get "Tavily API Key Dev" --fields "api key" --vault "DevOps" --reveal)"
		          },
		          "alwaysAllow": [
		            "tavily-search"
		          ]
		        },
		            "context7": {
		              "command": "npx",
		              "args": [
		                "-y",
		                "@upstash/context7-mcp"
		              ],
		              "env": {
		                "DEFAULT_MINIMUM_TOKENS": ""
		              },
		              "disabled": false,
		              "alwaysAllow": [
		                "resolve-library-id",
		                "get-library-docs"
		              ]
		            },
		              "sequentialthinking": {
		                "command": "npx",
		                "args": [
		                  "-y",
		                  "@modelcontextprotocol/server-sequential-thinking"
		                ],
		                "disabled": false,
		                "alwaysAllow": [
		                  "sequentialthinking"
		                ]
		              },

		                    "apify": {
		      "command": "npx",
		      "args": [
		        "-y",
		        "@apify/actors-mcp-server"
		      ],
		      "env": {
		        "APIFY_TOKEN": "$(op item get "Apify API Key Dev" --fields "api key" --vault "DevOps" --reveal)"
		      },
		      "alwaysAllow": [
		        "apify-slash-rag-web-browser",
		        "get-actor-details",
		        "search-actors",
		        "search-apify-docs",
		        "fetch-apify-docs",
		        "add-actor"
		      ],
		      "disabled": false
		    },

		        "google-maps": {
		          "command": "npx",
		          "args": [
		            "-y",
		            "@modelcontextprotocol/server-google-maps"
		          ],
		          "env": {
		            "GOOGLE_MAPS_API_KEY": "$(op item get "Google Maps API Key Dev" --fields "api key" --vault "DevOps" --reveal)"
		          },
		          "alwaysAllow": [
		                  "maps_reverse_geocode",
		                  "maps_geocode",
		                  "maps_search_places",
		                  "maps_place_details",
		                  "maps_distance_matrix",
		                  "maps_elevation",
		                  "maps_directions"
		                ]
		              },
		              "exa": {
		                "command": "npx",
		                "args": [
		                  "-y",
		                  "mcp-remote",
		                  "https://mcp.exa.ai/mcp?exaApiKey=$(op item get "Exa API Key Dev" --fields "api key" --vault "DevOps" --reveal)"
		                ]
		              },
		            "comfy-ui-mcp-server": {
		              "command": "uvx",
		              "args": [
		                "comfy-ui-mcp-server"
		              ]
		                  },
		                "fal-flux-kontext-max": {
		                  "command": "npx",
		                  "args": [
		                    "-y",
		                    "https://github.com/PierrunoYT/fal-flux-kontext-max-mcp-server.git"
		                  ],
		                  "env": {
		                    "FAL_KEY": "$(op item get 'FAL Key Dev' --fields 'api key' --vault 'DevOps' --reveal)"
		                  }
		                    },
		                  "playwright": {
		                        "command": "npx",
		                        "args": [
		                          "@playwright/mcp@latest"
		                        ]
		                    },
		                        "youtube": {
		                            "command": "npx",
		                            "args": [
		                              "-y",
		                              "@anaisbetts/mcp-installer",
		                              "@anaisbetts/mcp-youtube"
		                            ],
		                            "alwaysAllow": [
		                              "install_repo_mcp_server",
		                              "install_local_mcp_server"
		                            ]
		                      }
		  }
		}

		  }
		}
	EOF
)

# Note this uses brace expansion
MCP_LOCATIONS+=(
	# Gemini Code
	"$HOME/.gemini/settings.json"
	# OpenWebUI MCPO server converts MCP to an OpenAI API Comaptible Server
	"$HOME/.config/mcp/claude-desktop.json"
	# Claude Code MCP servers
	"$HOME/.claude.json"
	# Roo Code, Cline, TNE Compass in VSCode or Code
	"$HOME/Library/Application Support/{VSCodium,Code}/User/globalStorage/{rooveterinaryinc.roo-cline,tne-ai.tne-code,saoudrizwan.claude-dev}/settings/mcp_settings.json"
)
for config in "${MCP_LOCATIONS[@]}"; do
	if ! config_mark "$config" "{ _comment: " "},"; then
		config_add "$config" <<-EOF
			    $MCP_SERVERS
		EOF
	fi
done

# https://github.com/opencode-ai/opencode
if ! config_mark "$HOME/.opencode.json"; then
	config_add "$HOME/.opencode.json" <<-EOF
		      {
		        $MCP_SERVERS,
		        "agents": {
		            "coder": {
		              "model": "claude-4.0-sonnet",
		              "maxTokens": 5000
		            },
		            "task": {
		              "model": "claude-4.0-sonnet",
		              "maxTokens": 5000
		            },
		            "title": {
		              "model": "claude-4.0-sonnet",
		              "maxTokens": 80
		            }
		          },
		          "lsp": {
		            "go": {
		              "disabled": false,
		              "command": "gopls"
		            },
		            "typescript": {
		              "disabled": false,
		              "command": "typescript-language-server",
		              "args": ["--stdio"]
		            }
		          },
		      }

	EOF
fi
# note things like neovim code companion will use the first model
# that comes out of ollama list and this is the last one pulled, so this
# pull order has the default at the bottom
# These are too large for a 64GB machine
# note we load latest and also the tagged version

# no need for gp4all
#download_url_open "https://gpt4all.io/installers/gpt4all-installer-darwin.dmg"

# install models needs ollama running so do not run here
# "$BIN_DIR/install-models.sh"

# log_verbose "install comfyUI and models"
# "$BIN_DIR/install-comfyui.sh"

log_verbose "install Jupyter so open-webui can run code there"
"$BIN_DIR/install-jupyter.sh"

# log_verbose "install tailscale for exo networking"
# "$BIN_DIR/install-tailscale.sh"

# https://dashboard.ngrok.com/get-started/setup/macos
log_verbose "configure ngrok as front-end to open-webui with make auth with the right ngrok 1Password item"

# log_warning "shell-gpt requires OPENAI_API_KEY to be set or will store in ~/.config/shell_gpt/.sgptrc
log_verbose "WEBUI_SECRET_KEY and OPENAI_API_KEY should both be defined before running ideally in a .envrc"
log_verbose "Or put the API key into OpenWebUI"
log_verbose "To add Groq to OPen-webui Lower Left > Admin Panel > Settings > Connections > OpenAI API"
log_verbose "Click on + on he right and add URL https://api.groq.com/openai/v1 and your GROQ key"
# https://zohaib.me/extending-openwebui-using-pipelines/
# log_verbose "https://github.com/open-webui/pipelines"
log_verbose "To add Gemini, add functions or pipelines you need to run a docker and add it"
log_verbose 'docker run -d -p 9099:9099 --add-host=host.docker.internal:host-gateway \ '
log_verbose '-v pipelines:/app/pipelines --name pipelines --restart always \ '
log_verbose "ghcr.io/open-webui/pipelines:main"
log_verbose "or fork and submodule add git@githbu.com:open-webui/pipelines"
log_verbose "pip install - requriements.txt && sh .start.sh"

log_verbose "Installing the pipelines interface which allows compatible interfaces"
log_verbose "See https://github.com/open-webui/pipelines"

log_verbose "you can start servers separate with make ai"
