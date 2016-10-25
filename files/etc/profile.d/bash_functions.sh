# force a command to run and restart it when it exits
function force {
    PS_X_FIELD=5
    if [ $# -gt 0 ]; then
        # awk expression to match $@
        while true; do
            [ $(ps x |awk '
                BEGIN {nargs=split("'"$*"'",args)}
                $field == args[1] {
                    matched=1;
                    for (i=1;i<=NF-field;i++) {
                        if ($(i+field) == args[i+1]) {matched++}
                    }
                    if (matched == nargs) {found++}
                }
                END {print found+0}' field=${PS_X_FIELD}) -eq 0 ] \
            && $@ || sleep 1;
        done
    fi
}

# start an ssh agent and add any private key in ~/.ssh
function ssh_agent {
    which ssh-agent >/dev/null 2>&1 && which ssh-add >/dev/null 2>&1 || return
    [ -z "$SSH_AUTH_SOCK" ] || return
    [ -d /tmp/ssh-${UID} ] || { mkdir /tmp/ssh-${UID} 2>/dev/null && chmod 0700 /tmp/ssh-${UID}; }
    [ $(ps x |awk '$5 == "ssh-agent" && $7 == "'/tmp/ssh-${UID}/agent@${HOSTNAME}'"' |wc -l) -eq 0 ] && rm -f /tmp/ssh-${UID}/agent@${HOSTNAME} && ssh-agent -a /tmp/ssh-${UID}/agent@${HOSTNAME} 2>/dev/null > ${HOME}/.ssh/agent@${HOSTNAME}
    export SSH_AUTH_SOCK="/tmp/ssh-${UID}/agent@${HOSTNAME}"
    ssh-add -l >/dev/null 2>&1 || for file in ${HOME}/.ssh/*; do
        [ -f "$file" ] && grep "PRIVATE KEY" ${file} >/dev/null 2>&1 && ssh-add $file 2>/dev/null;
    done
}

# attach an existing screen or create a new one
function attach_screen {
    which screen >/dev/null 2>&1 || return
    if [ -z "$STY" ]; then
        echo -n 'Attaching screen.' && sleep 1 && echo -n '.' && sleep 1 && echo -n '.' && sleep 1 && screen -xRR -S "${USER}" 2>/dev/null
    fi
}

# attach an existing tmux or create a new one
function attach_tmux {
    which tmux >/dev/null 2>&1 || return
    if [ -z "$TMUX" ]; then
        echo -n 'Attaching tmux.' && sleep 1 && echo -n '.' && sleep 1 && echo -n '.' && sleep 1 && tmux -L$USER@$HOSTNAME -q has-session >/dev/null 2>&1 && tmux -L$USER@$HOSTNAME attach-session -d || tmux -L$USER@$HOSTNAME new-session -n$USER -s$USER@$HOSTNAME
    fi
}

# echo the current active tmux window
function tmux_window {
    which tmux >/dev/null 2>&1 || return
    if [ -n "$TMUX" ]; then
       tmux list-window |awk '$NF == "(active)" {print $1}' |sed 's/:$//'
    fi
}

# echo the current git branch
function git_branch {
    git branch --no-color 2>/dev/null |awk '$1 == "*" {match($0, "("FS")+"); print substr($0, RSTART+RLENGTH);}'
}

# echo the "number of running processes"/"total number of processes"/"number of processes in D-state"
function process_count {
    ps ax 2>/dev/null |awk 'BEGIN {r_count=d_count=0}; $3 ~ /R/ {r_count=r_count+1}; $3 ~ /D/ {d_count=d_count+1}; END {print r_count"/"d_count"/"NR-1}'
}

# echo the load average
function load_average {
    awk '{print $1}' /proc/loadavg 2>/dev/null
}

