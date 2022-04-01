# shellcheck shell=sh

post_install() {
	. "$PEARL_PKGDIR/pearl-config/config.sh" 
}

post_update() {
	post_install
}
