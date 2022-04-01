# shellcheck shell=sh

# load `sshag` into current environment
. "$PEARL_PKGDIR/sshag.sh" # configure
sshag >/dev/null           # invoke
