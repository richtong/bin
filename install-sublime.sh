#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
# Installation of sublime along with its lint and other tools
#
# we don't have ws-env.sh available to us at bootstrap time
set -e && SCRIPTNAME=$(basename $0)
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo $0 "flags: -d debug, -h help"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
    esac
done
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh
set -u

# https://realpython.com/blog/python/setting-up-sublime-text-3-for-full-stack-python-development/

# http://askubuntu.com/questions/172698/how-do-i-install-sublime-text-2-3
# Remove first to make sure we don't have duplicates
sudo add-apt-repository -r -y  ppa:webupd8team/sublime-text-3
sudo add-apt-repository -y ppa:webupd8team/sublime-text-3
sudo apt-get update -y
sudo apt-get install -y sublime-text-installer

mkdir -p "$HOME/.config/sublime-text-3/Packages/User/"
settings="$HOME/.config/sublime-text-3/Packages/User/Preferences.sublime-settings"
if ! grep "Added by $SCRIPTNAME" "$settings"
then
    cat > "$settings" <<EOF
	// Added by $SCRIPTNAME on $(date)
	// From https://github.com/mjhea0/sublime-setup-for-python/blob/master/dotfiles/Preferences.sublime-settings
	{
	"auto_complete": false,
	"auto_complete_commit_on_tab": true,
	"auto_match_enabled": true,
	"bold_folder_labels": true,
	"caret_style": "solid",
	"color_scheme": "Packages/Theme - Flatland/Flatland Dark.tmTheme",
	"detect_indentation": true,
	"draw_indent_guides": true,
	"ensure_newline_at_eof_on_save": true,
	"file_exclude_patterns":
	[
	"*.DS_Store",
	"*.pyc",
	"*.git"
	],
	"find_selected_text": true,
	"fold_buttons": false,
	"folder_exclude_patterns":
	[
	],
	"font_face": "Menlo",
	"font_options":
	[
	"no_round"
	],
	"font_size": 13,
	"highlight_line": true,
	"highlight_modified_tabs": true,
	"ignored_packages": [],
	"indent_to_bracket": true,
	"line_padding_bottom": 0,
	"line_padding_top": 0,
	"match_brackets": true,
	"match_brackets_angle": false,
	"match_brackets_braces": true,
	"match_brackets_content": true,
	"match_brackets_square": true,
	"new_window_settings":
	{
	"hide_open_files": true,
	"show_tabs": true,
	"side_bar_visible": true,
	"status_bar_visible": true
	},
	"remember_open_files": true,
	"remember_open_folders": true,
	"save_on_focus_lost": true,
	"scroll_past_end": false,
	"show_full_path": true,
	"show_minimap": false,
	"tab_size": 2,
	"theme": "Flatland Dark.sublime-theme",
	"translate_tabs_to_spaces": true,
	"trim_trailing_white_space_on_save": true,
	"use_simple_full_screen": true,
	"vintage_start_in_command_mode": false,
	"wide_caret": true,
	"word_wrap": true
	}
EOF
fi

python_settings="~/.config/sublime-text-3/Package/User/python.sublime-settings"
if touch "$python_settings"
then
    cat > "$python_settings" <<EOF
	// Inserted by $SCRIPTNAME on $(date)
	// https://github.com/mjhea0/sublime-setup-for-python/blob/master/dotfiles/Python.sublime-settings
	{
	// editor options
	"draw_white_space": "all",
	// tabs and whitespace
	"auto_indent": true,
	"rulers": [79],
	"smart_indent": true,
	"tab_size": 4,
	"trim_automatic_white_space": true,
	"use_tab_stops": true,
	"word_wrap": true,
	"wrap_width": 80
	}
EOF
fi

# Install the lint programs and pip installs locally and does update
package_install python-pip
pip_install --user --upgrade pyflakes
package_install tidy
pip_install --user --upgrade pyyaml

echo $0: run subl and type View/Console copy and paste from  https://packagecontrol.io/installation and restart

# http://damnwidget.github.io/anaconda/
echo Run subl choose Preferences/Package Control/Install Packages
echo Using Package control manually as it does automatic updates
echo AdvancedNewFile, Theme - Flatland, SideBarEnhancements, Markdown Preview, GitGutter
echo Emmet, Djaneiro, requirementstxt

echo Install the following packages
echo Disable {"anaconda_linting": false } in Preferences/Package Settings/Anaconda/Settings-User
echo Then install
echo Sublimelinter, SublimeLinter-html-tidy, SublimeLinter-json
echo SublimeLinter-pyflakes


echo You install these after scons has installed Node for you
echo Sublimelinter-csslint
echo SublimeLinter-jshint

echo If you install Python 3.0, then you can use
    echo SublimeLinter-pyyaml
