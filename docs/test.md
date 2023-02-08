# Pre-commit and CD/CI Pipeline

This uses a pre-commit pipeline that checks for markdown, shellscript and other
errors. It also checks for properly formatted git commit rules. You should use
an editor like vim with a plugin like ALE to do this syntax checking. Currently
we are using markdownlint-cli, shellcheck, mypy and black for markdown, shell
scripts and python. There could be more later.

Also this repository uses the Angular [git commit conventions](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit):

1. The one line header should be type(scope): summary without period or
   capitals. As an example `fix(install-docker.sh): shellchecked` means that
   there was a non-breaking fix for this file and then says shellcheck was
   uses. The valid types are "fix, feat, perf, refactor, test, docs, ci, build"
   which mean a bug fix, new feature, performance improvement, refactoring so
   neither a fix nor a feature, test to add or fix testing, ci for CI config
   changes like github actions and build for build system things like npm.
2. There is required message body that explains why the change is made or what
   behavior changes, should be written in imperitive present so "fix" not
   "fixed" or "fixes"
3. The footer may include a GitHub issue with Fixes #23 to fix issue 23 or if
   it is break changing then BREAKING CHANGE or DEPRECATED if something is
   going away and then Closes #12 to close Pull Request #12
