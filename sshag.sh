#!/bin/sh

# acquired courtesy of
# http://superuser.com/questions/141044/sharing-the-same-ssh-agent-among-multiple-login-sessions#answer-141241

sshag_running_as_command() {
	[ "${0#*sshag}" != "$0" ]
}

# only allow to source once.
# this simplifies the installation by adding to all the dot profiles and only source once.
type sshag 2>dev/null | grep 'is a function' \
	&& ! sshag_running_as_command        \
	&& return

# USAGE
# sshag install [DEST_DIR]               - install/update
# sshag update  [DEST_DIR]               - update
# sshag                                  - start/use agent
# sshag AGENT_SOCKET                     - use specified agent
# sshag USER@HOST [SSH_OPTIONS_AND_ARGS] - start agent and ssh to USER@HOST
sshag() {
	unset ssh_args
	unset agent_socket
	unset user_hostname

	while [ $# -gt 0 ]; do
		case "$1" in
		install) shift; sshag_install 'install' "$@"; return $? ;;
		update)  shift; sshag_install 'update'  "$@"; return $? ;;
		-*) ssh_args="$ssh_args $1" ;;
		*)
			if [ -e "$1" ] ; then
				[ -S "$1" ] && agent_socket="$1"
			else
				user_hostname="$1"
			fi
			;;
		esac
		shift
	done

	sshag_require_ssh
	sshag_agent_get_socket "$agent_socket" || sshag_agent_new_socket

	if [ -n "$user_hostname" ]; then
		sshag_ssh "$user_hostname" "$ssh_args"
	else
		sshag_running_as_command && sshag_agent_print_notice
		sshag_agent_print_keys
	fi
}

sshag_require_ssh() {
	for util in ssh ssh-add ssh-agent; do
		require_command "$util"
	done
}

# == Get/Start SSH-AGENT ==

# $1 - Agent Socket
sshag_agent_get_socket() {
	unset found_agent

	# Attempt to use socket passed in
	sshag_agent_vet_socket "$1" && return

	# Attempt to use the ssh-agent in the current environment
	sshag_agent_vet_socket "$SSH_AUTH_SOCK" && return

	# If there is no agent in the environment,
	# search for possible agents to reuse
	# before starting a fresh ssh-agent process.
	# ssh agent sockets can be attached to an ssh daemon process
	# or an ssh-agent process.
	for agent_socket in $(sshag_agent_find_sockets) ; do
		sshag_agent_vet_socket "$agent_socket" && return
	done

	return 1
}

# $1 - Agent Socket
sshag_agent_vet_socket() {
	[ -z "$1" ] && return 1

	if [ -S "$1" ]; then
		export SSH_AUTH_SOCK="$1"
		ssh-add -l >/dev/null 2>&1
		if [ $? -eq 2 ]; then
			rm -f "$SSH_AUTH_SOCK"
			print_warning "Socket '$SSH_AUTH_SOCK' is dead! Deleted!"
		fi
	else
		print_warning "'$SSH_AUTH_SOCK' is not a socket!"
	fi
}

sshag_agent_find_sockets() {
	# OpenSSH only uses these two dirs
	for dir in '/tmp' "$TMPDIR"; do
		find "$dir" -user $(id -u) -type s -path '*/ssh-*/agent.*' 2>/dev/null
	done | sort -u
}

sshag_agent_new_socket() {
	eval "$(ssh-agent)"
}

sshag_agent_print_notice() {
	print_info "$(cat <<- NOTICE
		Do the following to add the ssh-agent to your current session
		    export SSH_AGENT_SOCK="\$(sh '$0')"
		Or, simply source the file
		    source '$0'
		If it is already sourced, but your agent is dead, then just
		    sshag
	NOTICE
	)"
}

# Display keys currently loaded in the agent
sshag_agent_print_keys() {
	print_info "Keys:"
	print_info "$(ssh-add -l | sed 's/^/    /')"
}

# == SSH wrapper ==

# Load first key for specified user@hostname and start `ssh`.
sshag_ssh() (
	# This is needed for OpenSSH before v7.2 which added support AddKeysToAgent
	# Or if the local ssh client support AddKeysToAgent,
	# but it is not set in the ~/.ssh/config

	# OpenSSH v7.2 added support for AddKeysToAgent.
	# Honor it if it is used in ssh_config.
	# Otherwise, attempt to load identityfile as user may use a common ssh_config
	# on multiple machines where only some support AddKeysToAgent.
	# (OpenSSH before v7.2 barfs on params it doesn't know about so can't use
	# it in a common ssh_config where some machines have pre v7.2 OpenSSH.)

	user_host="$1"
	shift
	ssh_args="$@"

	if sshag_ssh_config_has_add_keys; then
		# Honor AddKeysToAgent settings
		: # do nothing
	elif ssh -o AddKeysToAgent 2>&1 | grep 'missing argument' >/dev/null; then
		# If this ssh supports AddKeyToAgent, then use it
		ssh_args="$ssh_args -o AddKeysToAgent=yes"
	else
		# This is needed for OpenSSH pre v7.2, before AddKeysToAgent was added
		sshag_ssh_add_key_to_agent "$1"
	fi

	ssh $ssh_args "$user_host"
)

# Checks if ~/.ssh/config has AddKeysToAgent
sshag_ssh_config_has_add_keys() {
	grep '^[[:blank:]]*AddKeysToAgent' \
		"$HOME/.ssh/config" "/etc/ssh/ssh_config" >/dev/null 2>&1
	return $?
}

# This is needed for OpenSSH before v7.2 which added support AddKeysToAgent
# Or if the local ssh client support AddKeysToAgent,
# but it is not set in the ~/.ssh/config
sshag_ssh_add_key_to_agent() {
	sshag_ssh_is_identity_loaded "$1" && return

	# load identity if one is defined for the user@hostname.
	sshag_identity="$(sshag_ssh_get_identity "$1")"
	if [ -n "$sshag_identity" ] && ! ssh-add "$sshag_identity"; then
		print_error "Unable to load identity '$sshag_identity'!"
	fi
}

sshag_ssh_is_identity_loaded() {
	echo 'exit' | ssh -o BatchMode=yes -- $1 2>/dev/null
	return $?
}

sshag_ssh_get_identity() {
	sshag_identity="$(ssh -v -o BatchMode=yes "$1" 2>&1    \
			| awk ' /identity file/ { print $4 } ' \
			| head -n 1)"

	[ -n "$sshag_identity" ]                                  \
		&& sshag_identity="$(realpath -m "$sshag_identity")" \
		&& printf '%s' "$sshag_identify"
}

# == INSTALL ==

sshag_install() (
	require_command 'git'
	dir="$(sshag_install_path "$2")"

	if [ "$1" = 'update' ] || [ -d "$dir/sshag" ]; then
	       sshag_update "$dir"
	       return $?
	 fi

	print_info "Installing 'sshag' to '$dir'."
  	__SSHAG_CONFIG=". '$dir/sshag/sshag.sh'; sshag >/dev/null"
	sshag_install_download "$dir"
	sshag_install_profiles "$dir"
	sshag_install_manual
)

sshag_install_path() {
	unset dir
	system_dir='/usr/local/lib'
	user_dir="$HOME/.local/lib"

	if [ -n "$1" ]; then
		dir="$(realpath -m "$1" 2>/dev/null)"
		[ -z "$dir" ] && print_fatal "Invalid directory '$1'"
	fi

	[ -z "$dir" ] && [ "$USER" = 'root' ] && dir="$system_dir"
	[ -z "$dir" ]                         && dir="$user_dir"

	[ -d "$dir" ] || mkdir -p "$dir" || print_fatal "Cannot create directory '$dir'"
	printf '%s' "$dir"
}

sshag_install_download() {
	cd "$1"
  	git clone 'https://github.com/go2null/sshag.git'
	print_info "'sshag' installed to '$1'"
}

# add to shell startup files
sshag_install_profiles() {
	if [ "$USER" = 'root' ]; then
		if touch '/etc/profile.d/sshag.sh' 2>/dev/null; then
			sshag_install_profile '/etc/profile.d/sshag.sh'
		else
			sshag_install_profile '/etc/profile'
		fi
	else
		sshag_install_profile "$HOME/.profile"
		sshag_install_profile "$HOME/.bash_profile"
		sshag_install_profile "$HOME/.bashrc"
		sshag_install_profile "$HOME/.zshrc"
	fi
}

sshag_install_profile() {
	[ -w "$1" ] || return 1


	if grep "^[ \t]*$__SSHAG_CONFIG" "$1" >/dev/null; then
		print_info "'sshag' already in startup file '$1'"
	       	return
	fi

	print_line "$__SSHAG_CONFIG" >> "$1"
	print_info "'sshag' added to startup file '$1'"
}
	
sshag_install_manual() {
	print_info "Add the following to any additional shell startup files:"
	print_info "    $__SSHAG_CONFIG"
}

sshag_update() (
	[ -d "$1/sshag" ] && dir="$1/sshag" || dir="$1"

	print_info "Updating 'sshag' at '$dir'."
	cd "$dir"
	git pull
)

# == HELPERS ==

print_error()   { print_stderr "ERROR:   $@"; return 1; }
print_fatal()   { print_stderr "FATAL:   $@"; exit   1; }
print_info()    { print_stderr "INFO:    $@"; return 1; }
print_warning() { print_stderr "WARNING: $@"; return 1; }

print_stderr()  { print_line "$@" >&2; } # Do not send messages to 'stdout'
# - it is reserved for outputting $SSH_AUTH_SOCH when invoked in a subshell

print_line()    { printf "$@\n"; }

require_command() {
	[ ! -x "$(command -v "$1")" ] && print_fatal "'$1' is not available! aborting!"
}

# == HOOK ==

sshag_running_as_command && sshag "$@"
