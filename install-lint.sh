#!/usr/bin/env bash
##
## install linters
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
VERSION="${VERSION:-7}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvr:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Linters
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
			           -r version number (default: $VERSION)
		EOF
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		# add the -v which works for many commands
		export FLAGS+=" -v "
		;;
	r)
		VERSION="$OPTARG"
		;;
	*)
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh lib-config.sh

"$SCRIPT_DIR/install-node.sh"
log_verbose install linters
# note that markdownlint here is API only the cli is separately installed
NODE_PACKAGES+=(
	eslint
	babel-eslint
	eslint-plugin-react
	eslint-plugin-import
	eslint-plugin-jsx-a11y
	eslint-plugin-flowtype
	jslint
	jsonlint
	js-yaml
	htmlhint
	csslint
)

log_verbose "install ${NODE_PACKAGES[*]}"
npm_install -g "${NODE_PACKAGES[@]}"

# ruff - replaces flake8, black, isort, pydoctstyle, pyupgrade and is very fast
# mdformat-ruff - ruff formatter that is like markdownlint
PYTHON_PACKAGES+=(
	jedi
	vim-vint
	beautysh
	yamlfix
	ruff
	mdformat-ruff
)
log_verbose "install ${PYTHON_PACKAGES[*]}"
pip_install "${PYTHON_PACKAGES[@]}"

log_verbose "Use markdown-cli and not mdl"
#RUBY_PACKAGES+=(
#    mdl
#)
#log_verbose "install ${RUBY_PACKAGES[*]}"
#gem_install "${RUBY_PACKAGES[@]}"

# note we install both the ruby mdl and the node markdown-cli
# but prefer markdown-cli
# hadolint: dockerfile lint https://github.com/hadolint/hadolint
# actionlint: github workflow actions
# checkmake: Makefile lint
PACKAGES+=(
	yapf
	shellcheck
	shfmt
	yamllint
	hadolint
	actionlint
	checkmake
	prettier  # general formatted
	prettierd # very fast daemon version
)
log_verbose "install ${PACKAGES[*]}"
package_install "${PACKAGES[@]}"

log_verbose "yapf needs to be keg linked"
brew link yapf

# now installed by main install.sh
#"$SCRIPT_DIR/install-markdown.sh"

# Not compatible with PostCSS use stylelint below although this also seems to
# have issues and not report bugs to vi.
#    csslint
# Stylelint needs a long config file, so move it outboard
# Note that the FORCE variable is passed down to all the scripts by the  export
"$SCRIPT_DIR/install-stylelint.sh"

log_verbose need flake8 for python linting
# python https://flake8.pycqa.org/en/latest/
# this merges server checkers
# not robust
if [[ $OSTYPE =~ darwin ]]; then
	brew_install flake8
else
	pip_install --upgrade flake8
fi

# https://github.com/yannickcr/eslint-plugin-react
# https://github.com/facebookincubator/create-react-app/blob/master/template/README.md#displaying-lint-output-in-the-editor
# The eslint for create-react-app is heavier duty that the normal
# eslint-plugin-react only, this is translated from the eslint.js that comes
# with create-react-app this is a snapshot of the eslint used by that app
# this enables the import checks that are off for create-react-app
# We do not want flags to exist if they are null
log_verbose "checking $HOME/.eslintrc.js"
# shellcheck disable=SC2086
if ! config_mark "$HOME/.eslintrc.js" "//"; then
	log_verbose "Addint to $HOME/.eslintrc.js"
	config_add "$HOME/.eslintrc.js" <<-'EOF'
		{
		  root: true,
		  parser: 'babel-eslint',
		  // import plugin is temporarily disabled, scroll below to see why
		  plugins: ['import', 'flowtype', 'jsx-a11y', 'react'],
		  env: {
		    browser: true,
		    commonjs: true,
		    es6: true,
		    jest: true,
		    node: true
		  },
		  parserOptions: {
		    ecmaVersion: 6,
		    sourceType: 'module',
		    ecmaFeatures: {
		      jsx: true,
		      generators: true,
		      experimentalObjectRestSpread: true
		    }
		  },
		  settings: {
		    'import/ignore': [
		      'node_modules',
		      '\\.(json|css|jpg|png|gif|eot|otf|webp|svg|ttf|woff|woff2|mp4|webm)$',
		    ],
		    'import/extensions': ['.js'],
		    'import/resolver': {
		      node: {
		        extensions: ['.js', '.json']
		      }
		    }
		  },
		  rules: {
		    // http://eslint.org/docs/rules/
		    'array-callback-return': 'warn',
		    'default-case': ['warn', { commentPattern: '^no default$' }],
		    'dot-location': ['warn', 'property'],
		    eqeqeq: ['warn', 'allow-null'],
		    'guard-for-in': 'warn',
		    'new-parens': 'warn',
		    'no-array-constructor': 'warn',
		    'no-caller': 'warn',
		    'no-cond-assign': ['warn', 'always'],
		    'no-const-assign': 'warn',
		    'no-control-regex': 'warn',
		    'no-delete-var': 'warn',
		    'no-dupe-args': 'warn',
		    'no-dupe-class-members': 'warn',
		    'no-dupe-keys': 'warn',
		    'no-duplicate-case': 'warn',
		    'no-empty-character-class': 'warn',
		    'no-empty-pattern': 'warn',
		    'no-eval': 'warn',
		    'no-ex-assign': 'warn',
		    'no-extend-native': 'warn',
		    'no-extra-bind': 'warn',
		    'no-extra-label': 'warn',
		    'no-fallthrough': 'warn',
		    'no-func-assign': 'warn',
		    'no-implied-eval': 'warn',
		    'no-invalid-regexp': 'warn',
		    'no-iterator': 'warn',
		    'no-label-var': 'warn',
		    'no-labels': ['warn', { allowLoop: false, allowSwitch: false }],
		    'no-lone-blocks': 'warn',
		    'no-loop-func': 'warn',
		    'no-mixed-operators': ['warn', {
		      groups: [
		        ['&', '|', '^', '~', '<<', '>>', '>>>'],
		        ['==', '!=', '===', '!==', '>', '>=', '<', '<='],
		        ['&&', '||'],
		        ['in', 'instanceof']
		      ],
		      allowSamePrecedence: false
		    }],
		    'no-multi-str': 'warn',
		    'no-native-reassign': 'warn',
		    'no-negated-in-lhs': 'warn',
		    'no-new-func': 'warn',
		    'no-new-object': 'warn',
		    'no-new-symbol': 'warn',
		    'no-new-wrappers': 'warn',
		    'no-obj-calls': 'warn',
		    'no-octal': 'warn',
		    'no-octal-escape': 'warn',
		    'no-redeclare': 'warn',
		    'no-regex-spaces': 'warn',
		    'no-restricted-syntax': [
		      'warn',
		      'LabeledStatement',
		      'WithStatement',
		    ],
		    'no-script-url': 'warn',
		    'no-self-assign': 'warn',
		    'no-self-compare': 'warn',
		    'no-sequences': 'warn',
		    'no-shadow-restricted-names': 'warn',
		    'no-sparse-arrays': 'warn',
		    'no-template-curly-in-string': 'warn',
		    'no-this-before-super': 'warn',
		    'no-throw-literal': 'warn',
		    'no-undef': 'warn',
		    'no-unexpected-multiline': 'warn',
		    'no-unreachable': 'warn',
		    'no-unused-expressions': 'warn',
		    'no-unused-labels': 'warn',
		    'no-unused-vars': ['warn', { vars: 'local', args: 'none' }],
		    'no-use-before-define': ['warn', 'nofunc'],
		    'no-useless-computed-key': 'warn',
		    'no-useless-concat': 'warn',
		    'no-useless-constructor': 'warn',
		    'no-useless-escape': 'warn',
		    'no-useless-rename': ['warn', {
		      ignoreDestructuring: false,
		      ignoreImport: false,
		      ignoreExport: false,
		    }],
		    'no-with': 'warn',
		    'no-whitespace-before-property': 'warn',
		    'operator-assignment': ['warn', 'always'],
		    radix: 'warn',
		    'require-yield': 'warn',
		    'rest-spread-spacing': ['warn', 'never'],
		    strict: ['warn', 'never'],
		    'unicode-bom': ['warn', 'never'],
		    'use-isnan': 'warn',
		    'valid-typeof': 'warn',
		    // https://github.com/benmosher/eslint-plugin-import/blob/master/docs/rules/
		    // ok for vim
		    // TODO: import rules are temporarily disabled because they don't play well
		    // with how eslint-loader only checks the file you change. So if module A
		    // imports module B, and B is missing a default export, the linter will
		    // record this as an issue in module A. Now if you fix module B, the linter
		    // will not be aware that it needs to re-lint A as well, so the error
		    // will stay until the next restart, which is really confusing.
		    // This is probably fixable with a patch to eslint-loader.
		    // When file A is saved, we want to invalidate all files that import it
		    // *and* that currently have lint errors. This should fix the problem.
		    'import/default': 'warn',
		    'import/export': 'warn',
		    'import/named': 'warn',
		    'import/namespace': 'warn',
		    'import/no-amd': 'warn',
		    'import/no-duplicates': 'warn',
		    'import/no-extraneous-dependencies': 'warn',
		    'import/no-named-as-default': 'warn',
		    'import/no-named-as-default-member': 'warn',
		    'import/no-unresolved': ['warn', { commonjs: true }],
		    // https://github.com/yannickcr/eslint-plugin-react/tree/master/docs/rules
		    'react/jsx-equals-spacing': ['warn', 'never'],
		    'react/jsx-no-duplicate-props': ['warn', { ignoreCase: true }],
		    'react/jsx-no-undef': 'warn',
		    'react/jsx-pascal-case': ['warn', {
		      allowAllCaps: true,
		      ignore: [],
		    }],
		    'react/jsx-uses-react': 'warn',
		    'react/jsx-uses-vars': 'warn',
		    'react/no-deprecated': 'warn',
		    'react/no-direct-mutation-state': 'warn',
		    'react/no-is-mounted': 'warn',
		    'react/react-in-jsx-scope': 'warn',
		    'react/require-render-return': 'warn',
		    // https://github.com/evcohen/eslint-plugin-jsx-a11y/tree/master/docs/rules
		    'jsx-a11y/aria-role': 'warn',
		    'jsx-a11y/img-has-alt': 'warn',
		    'jsx-a11y/img-redundant-alt': 'warn',
		    'jsx-a11y/no-access-key': 'warn',
		    // https://github.com/gajus/eslint-plugin-flowtype
		    'flowtype/define-flow-type': 'warn',
		    'flowtype/require-valid-file-annotation': 'warn',
		    'flowtype/use-flow-type': 'warn'
		  }
		};
	EOF
fi
