# Makefile for richtong/lib
#
# Release tag
TAG=0.9

# adjust this for where ./src/lib is and add your own
# Note that current directory is always included so you can
# can insert your own include in the CWD if you want to override
# https://runebook.dev/en/docs/gnu_make/include
# this directive does not seem to work
.INCLUDE_DIRS=../lib
INCLUDE_DIRS ?= ../lib
# adjust for your org
ORG ?= tne


## Local directory Make commands
## ----------
## test: test the library
.PHONY: test
test:
	@echo "insert test code here..."

## clean: remove the build directory
.PHONY: clean
clean:
	@echo "insert clear code here..."

## all: build all
.PHONY: all

# list these in reverse order so the most general is last

# Adjust these assuming this is a ./src submodule
# https://www.gnu.org/software/make/manual/html_node/Foreach-Function.html
# Note that - means to ignore errors, but this is actually checks
# LIB_PATH ?= ../lib
# ifneq ($(wildcard include.mk),)
# include "$(LIB_PATH)/include.mk"
# endif
-include $(INCLUDE_DIRS)/include.mk
# the first dash means ignore errors
-include $(INCLUDE_DIRS)/include.python.mk
# if you use docker (who doesn't)
-include $(INCLUDE_DIRS)/include.docker.mk
# only include if it exists your companies specific stuff
-include $(INCLUDE_DIRS)/include.jupyter.mk
-include $(INCLUDE_DIRS)/include.node.mk

# rhash is optional for hash checks
# -include $(INCLUDE_DIRS)/include.rhash.mk
# -include $(INCLUDE_DIRS)/include.gcp.base.mk
# -include $(INCLUDE_DIRS)/include.gcp.mk
# -include $(INCLUDE_DIRS)/include.hugo.mk

# these have not been tested in a long time
# - include.airflow.mk

# normally your organization stuff appears last
-include $(INCLUDE_DIRS)/include.$(ORG).mk
