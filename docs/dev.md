# Developing

The rest of the programs are various scripts that are helpers after you create
things. Rich is constantly adding to them. They use a common `include.sh` which
loads libraries and finds WS_DIR.

Since these are mainly experimental the vast majority a simple shell scripts.
The ones that need it are rewritten as python such as the docker files that @sam
did.

These scripts have a couple of nice common features:

- They single step with -d flag. This flag is exported with DEBUGGING so you
  just say -d once and all scripts called honor it.
- The same with the -v verbose flag.
- Libraries for these are kept in ../lib and are common shell functions. For
  instance the debug behavior is in ../lib/lib-debug.sh
- They find the current WS_DIR automatically. They look up from their execution
  directory for ws and if they can't find it, they look down from your HOME.

Works most of time. If it doesn't, use export WS_DIR ahead of the script call.
Or use wbash or wrun

## Agent scripts vs dev scripts

Some of these scripts are for use by agents. They are different mainly because
agents for local build do not have sudo rights.

## Helper role of ../etc and ../lib

The ../etc files are text configuration files:

users.txt: This is a list of user names, uid and gids
groups.txt: common groups used on common machines
hostnames.txt: hostnames already in use
wordlist.txt: a list of hostnames not allocated for use by new machines
