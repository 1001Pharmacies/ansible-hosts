# /etc/profile.d/bash_local.sh

# verify that needed functions are loaded
type git_branch >/dev/null 2>&1 || source /etc/profile.d/bash_functions.sh

# load personal stuffs
if [ -f "${HOME}/.bash_aliases" ]; then
    source "${HOME}/.bash_aliases"
fi

if [ -f "${HOME}/.bash_functions" ]; then
    source "${HOME}/.bash_functions"
fi

# customize PS1

DGRAY="\[\033[1;30m\]"
RED="\[\033[01;31m\]"
GREEN="\[\033[01;32m\]"
BROWN="\[\033[0;33m\]"
YELLOW="\[\033[01;33m\]"
BLUE="\[\033[01;34m\]"
CYAN="\[\033[0;36m\]"
GRAY="\[\033[0;37m\]"
NC="\[\033[0m\]"

if [ $UID = 0 -o $USER = root ]; then
    COLOR=$RED
    INFO="[\$(process_count 2>/dev/null)|\$(load_average 2>/dev/null)]"
    END="#"
else
    COLOR=$BROWN
    INFO=""
    END="\$"
fi

BRANCH="\$(GIT_BRANCH=\$(git_branch 2>/dev/null); [ -n \"\$GIT_BRANCH\" ] && echo \"$DGRAY@$CYAN\$GIT_BRANCH\")"

export PS1="$NC$BLUE$INFO$COLOR\u$DGRAY@$CYAN\h$DGRAY:$GRAY\w$BRANCH$DGRAY$END$NC "
[ -n "${STY}" ] && export PROMPT_COMMAND='echo -ne "\033k${HOSTNAME%%.*}\033\\"'

# if we are in a terminal and we want to automatic stuffs
if [ -t 0 -a -d ${HOME}/.ssh/auto ]; then
    if [ "$USER" == "root" -o "$(tmux_window 2>/dev/null)" == "0" ]; then
        [ -z "${STY}" ] && attach_screen 2>/dev/null
    else
        ssh_agent 2>/dev/null
        attach_tmux 2>/dev/null
    fi
fi

