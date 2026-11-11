case $- in
    *i*) ;;
    *) return ;;
esac

# History
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend checkwinsize

# Prompt
PS1='\u@\h:\w\$ '

# Aliases
[ -f "$HOME/.bash_aliases" ] && . "$HOME/.bash_aliases"

# Eat shell integration
if [ -n "${EAT_SHELL_INTEGRATION_DIR:-}" ]; then
    . "$EAT_SHELL_INTEGRATION_DIR/bash"
fi

alias unlock='echo unlock | gpg --clearsign > /dev/null'
