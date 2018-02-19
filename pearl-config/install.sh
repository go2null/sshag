post_install() {
	. "$PEARL_PKGDIR/pearl-config/config.sh" # configure
	sshag                                    # invoke
}

post_update() {
	post_install
}
