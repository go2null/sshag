#!/bin/sh

# acquired courtesy of
#   http://superuser.com/questions/141044/sharing-the-same-ssh-agent-among-multiple-login-sessions#answer-141241
# Project at: https://github.com/go2null/sshag

sshag_function_is_defined() {
	type sshag >/dev/null 2>&1
}

sshag_running_as_command() {
	[ "${0#*sshag}" != "$0" ]
}

# only allow to source file once.
# this simplifies the installation by adding to all the dot profiles and only source once.
sshag_function_is_defined && ! sshag_running_as_command && return 1

# USAGE
# sshag install   [TARGET_DIR]           - install/update
# sshag update    [TARGET_DIR]           - update
# sshag uninstall [TARGET_DIR]           - uninstall
# sshag                                  - start/use agent
# sshag AGENT_SOCKET                     - use specified agent
# sshag USER@HOST [SSH_OPTIONS_AND_ARGS] - start agent and ssh to USER@HOST
sshag() {
	unset agent_socket
	unset user_host

	while [ $# -gt 0 ]; do
		case "$1" in
		install)   shift; sshag_install 'install' "$@"; return $? ;;
		update)    shift; sshag_install 'update'  "$@"; return $? ;;
		uninstall) shift; sshag_install 'remove'  "$@"; return $? ;;
		remove)    shift; sshag_install 'remove'  "$@"; return $? ;;
		-*) break ;; # ssh options
		*)
			if [ -e "$1" ] ; then
				agent_socket="$1"
			else
				user_host="$1"
			fi
			;;
		esac
		shift
	done

	sshag_require_ssh
	sshag_agent_get_socket "$agent_socket" || sshag_agent_new_socket

	if [ -n "$user_host" ]; then
		sshag_ssh "$user_host" "$@"
	else
		sshag_running_as_command && sshag_agent_print_notice
		sshag_agent_print_keys
	fi
}

sshag_require_ssh() {
	for app in ssh ssh-add ssh-agent; do
		require_command "$app"
	done
}

# == Get/Start SSH-AGENT ==

# $1 - optional. Agent Socket
sshag_agent_get_socket() {
	# Attempt to use socket passed in
	sshag_agent_vet_socket "$1" && return

	# Attempt to use the ssh-agent in the current environment
	sshag_agent_vet_socket "$SSH_AUTH_SOCK" && return

	# If there is no agent in the environment,
	# search for possible agents to reuse
	# before starting a fresh ssh-agent process.
	# ssh agent sockets can be attached to an ssh daemon process
	# or an ssh-agent process.
	for agent_socket in $(sshag_agent_find_sockets); do
		sshag_agent_vet_socket "$agent_socket" && return
	done

	return 1
}

# $1 - optional. Agent Socket
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
		find "$dir" -user "$(id -u)" -type s -path '*/ssh-*/agent.*' 2>/dev/null
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
# $1 - required. user@host
# $@ - optional. ssh options
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
	
	unset ssh_opts

	user_host="$1"
	shift

	if sshag_ssh_config_has_add_keys; then
		# Honor AddKeysToAgent settings
		: # do nothing
	elif ssh -o AddKeysToAgent 2>&1 | grep 'missing argument' >/dev/null; then
		# If this ssh supports AddKeyToAgent, then use it
		ssh_opts='-o AddKeysToAgent=yes'
	else
		# This is needed for OpenSSH pre v7.2, before AddKeysToAgent was added
		sshag_ssh_add_key_to_agent "$user_host"
	fi

	# `$ssh_opts` may be unset, quoting it will pass an empty string to `ssh`
	# shellcheck disable=SC2086,SC2029
	ssh "$@" $ssh_opts "$user_host"
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
# $1 - required. user@host
sshag_ssh_add_key_to_agent() {
	sshag_ssh_is_identity_loaded "$1" && return

	# load identity if one is defined for the user@hostname.
	sshag_identity="$(sshag_ssh_get_identity "$1")"
	if [ -n "$sshag_identity" ] && ! ssh-add "$sshag_identity"; then
		print_error "Unable to load identity '$sshag_identity'!"
	fi
}

# $1 - required. user@host
sshag_ssh_is_identity_loaded() {
	echo 'exit' | ssh -o BatchMode=yes -- "$1" 2>/dev/null
	return $?
}

# $1 - required. user@host
sshag_ssh_get_identity() {
	sshag_identity="$(ssh -v -o BatchMode=yes "$1" 2>&1    \
			| awk ' /identity file/ { print $4 } ' \
			| head -n 1)"

	[ -n "$sshag_identity" ]                                  \
		&& sshag_identity="$(realpath -m "$sshag_identity")" \
		&& printf '%s' "$sshag_identity"
}

# == INSTALL ==

# $1 - required. action - install, update, or remove
# $2 - optional. install directory
sshag_install() (
	require_command 'git'

	dir="$(sshag_install_path "$2")"
	[ "$dir" != "${dir%/sshag}" ] && dir="${dir%/sshag}" 

	if [ -d "$dir/sshag" ]; then
		case "$1" in
		install|update)
		       sshag_update "$dir"
		       return $?
		       ;;
	       	remove)
		       sshag_remove "$dir"
		       return $?
		       ;;
       		esac
	fi

	[ "$1" = 'remove' ] \
		&& print_fatal "Cannot detect where 'sshag' is installed"

	print_info "Installing to $dir."
	sshag_install_download "$dir"

	print_info "Adding to startup files"
  	sshag_config=". '$dir/sshag/sshag.sh' && sshag >/dev/null"
	sshag_install_profiles "$sshag_config"
	sshag_install_manual   "$sshag_config"
)

# $1 - optional. install directory
sshag_install_path() {
	unset dir
	system_dir='/usr/local/lib'
	user_dir="$HOME/.local/lib"

	if [ -n "$1" ]; then
		dir="$(realpath -m "$1" 2>/dev/null)"
		[ -z "$dir" ] && print_fatal "  Invalid directory $1."
	fi

	[ -z "$dir" ] && [ "$USER" = 'root' ] && dir="$system_dir"
	[ -z "$dir" ]                         && dir="$user_dir"

	[ -d "$dir" ] || mkdir -p "$dir" || print_fatal "  Cannot create directory $dir."
	printf '%s' "$dir"
}

# $1 - required. install directory
sshag_install_download() {
	cd "$1" || print_fatal "  Cannot accees $1."

	git clone 'https://github.com/go2null/sshag.git' \
		|| print_fatal "  'git clone' failed with above error."
}

# add to shell startup files
# $1 - required. sshag config line
sshag_install_profiles() {
	if [ "$USER" = 'root' ]; then
		if touch '/etc/profile.d/sshag.sh' 2>/dev/null; then
			sshag_install_profile "$1" '/etc/profile.d/sshag.sh'
		else
			sshag_install_profile "$1" '/etc/profile'
		fi
	else
		sshag_install_profile "$1" "$HOME/.profile"
		sshag_install_profile "$1" "$HOME/.bash_profile"
		sshag_install_profile "$1" "$HOME/.bashrc"
		sshag_install_profile "$1" "$HOME/.zshrc"
	fi
}

# $1 - required. config line
# $2 - required. config file
sshag_install_profile() {
	[ -w "$2" ] || return 1


	if grep "^[ \t]*$1" "$2" >/dev/null; then
		print_info "  SKIPPED $2, already added."
	       	return
	fi

	print_line "$1" >> "$2"
	print_info "  ADDED to '$2'"
}
	
# $1 - required. config line
sshag_install_manual() {
	print_info "Add the following to any additional shell startup files"
	print_info "  $1"
}

# $1 - required. install directory
sshag_update() {
	print_info "Updating 'sshag' at $1."
	cd "$1/sshag" || print_fatal "  Cannot accees $1/sshag."
	git pull
}

# $1 - required. install directory
sshag_remove() {
	print_info "Removing 'sshag' at $1."
	rm -rf "$1/sshag"

	print_info "Removing from startup files"
	sshag_remove_profiles
}

sshag_remove_profiles() {
	file='/etc/profile.d/sshag.sh'
	[ -w "$file" ] && print_info "  REMOVED $file." && rm "$file"

	files="/etc/profile
$HOME/.profile
$HOME/.bash_profile
$HOME/.bashrc
$HOME/.zshrc"

	while IFS='' read -r file; do 
		sshag_remove_profile "$file"
	done <<- EOF
	$files
	EOF
}

# $1 - required. config file
sshag_remove_profile() {
	[ -e "$1" ]                           || return
	grep 'sshag.sh' "$1" 1>/dev/null 2>&1 || return

	print_info "  $1"
	[ ! -w "$1" ] && print_warning "    SKIPPED, cannot edit file" && return

	sed -i.bak '/.*sshag.sh.*/ d' "$1" \
		|| print_warning "    FAILED to remove"
}

# == HELPERS ==

print_line()    { printf '%s\n' "$*"; }

print_stderr()  { print_line "$@" >&2; } 
# Do not send messages to 'stdout'
# - it is reserved for outputting $SSH_AUTH_SOCH when invoked in a subshell

print_error()   { print_stderr "ERROR:   $*"; return 1; }
print_fatal()   { print_stderr "FATAL:   $*"; exit   1; }
print_info()    { print_stderr "INFO:    $*"; return 1; }
print_warning() { print_stderr "WARNING: $*"; return 1; }

require_command() {
	[ ! -x "$(command -v "$1")" ] && print_fatal "'$1' is not available! aborting!"
}

# == HOOK ==

sshag "$@"
