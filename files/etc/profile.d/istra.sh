if [ $(id -u) -eq 0 ]
then
  # Make sure sbin dirs are in path when uid is 0
  pathmunge /sbin 2>/dev/null
  pathmunge /usr/sbin 2>/dev/null
  pathmunge /usr/local/sbin 2>/dev/null
fi

HISTTIMEFORMAT='[%F %T] '

CUSTOMERZONE=$(grep dns_zone /etc/centile/cluster/cluster.conf 2>/dev/null | cut -f 2 -d '=')

[ "$PS1" = "\\s-\\v\\\$ " ] && [ "`id -u`" -eq 0 ] && PS1=$'\[\E[1m\]CENTILE ISTRA --< $CUSTOMERZONE >--\n\[\E[01;31m\]\u\[\E[0m\]@\[\E[01;36m\]\h\[\E[0m\]:\w\[\E[01;31m\] \$\[\E[0m\] '
[ "$PS1" = "\\s-\\v\\\$ " ] && PS1=$'\[\E[1m\]CENTILE ISTRA --< $CUSTOMERZONE >--\n\[\E[01;32m\]\u\[\E[0m\]@\[\E[01;36m\]\h\[\E[0m\]:\w\[\E[01;32m\] \$\[\E[0m\] '

case $TERM in
    xterm*)
        if [ -e /etc/sysconfig/bash-prompt-xterm ]; then
            PROMPT_COMMAND=/etc/sysconfig/bash-prompt-xterm
        else
            PROMPT_COMMAND='printf "\033]0;[%s] %s@%s:%s\007" "${CUSTOMERZONE}" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/~}"'
        fi
        ;;
    screen)
        if [ -e /etc/sysconfig/bash-prompt-screen ]; then
            PROMPT_COMMAND=/etc/sysconfig/bash-prompt-screen
        else
            PROMPT_COMMAND='printf "\033]0;[%s] %s@%s:%s\033\\" "${CUSTOMERZONE}" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/~}"'
        fi
        ;;
    *)
        [ -e /etc/sysconfig/bash-prompt-default ] && PROMPT_COMMAND=/etc/sysconfig/bash-prompt-default
        ;;
esac

case $- in
  *i*)
    /usr/bin/istra_motd.sh
  ;;
  *)
  ;;
esac

# Aliases
alias cm='/usr/ipbx/IntraSwitch/bin/cmonitor.sh'
#system commands
alias psa='ps auxf'

#logs commands
alias logsys='tailf /var/log/syslog'
alias logmsg='tailf /var/log/messages'
alias logsvm='tailf /usr/ipbx/IntraSwitch/http/out/servermanager_current.log'
alias logpvs='tailf /usr/ipbx/IntraSwitch/http/out/PVS_current.log'
alias logdms='tailf /usr/ipbx/IntraSwitch/http/out/DataModuleServer_current.log'
alias logvrx='tailf /usr/ipbx/IntraSwitch/http/out/Vrx_current.log'
alias si='/usr/bin/istra_motd.sh'
alias vi='vim'
