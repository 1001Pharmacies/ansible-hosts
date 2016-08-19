#!/bin/bash
#
# Copyright (c) 1999-2015 Centile
#
# Version 0.6
#




[[ ! -f /etc/centile/.configured  ]] && exit 0
[[ "$USER" != "root" ]] && [[ "$USER" != "ipbx" ]] && exit 0


COff='\e[0m'       # Text Reset

# Regular Colors
Black='\e[0;30m'        # Black
Red='\e[0;31m'          # Red
Green='\e[0;32m'        # Green
Yellow='\e[0;33m'       # Yellow
Blue='\e[0;34m'         # Blue
Purple='\e[0;35m'       # Purple
Cyan='\e[0;36m'         # Cyan
White='\e[0;37m'        # White

# Bold
BBlack='\e[1;30m'       # Black
BRed='\e[1;31m'         # Red
BGreen='\e[1;32m'       # Green
BYellow='\e[1;33m'      # Yellow
BBlue='\e[1;34m'        # Blue
BPurple='\e[1;35m'      # Purple
BCyan='\e[1;36m'        # Cyan
BWhite='\e[1;37m'       # White

# Underline
UBlack='\e[4;30m'       # Black
URed='\e[4;31m'         # Red
UGreen='\e[4;32m'       # Green
UYellow='\e[4;33m'      # Yellow
UBlue='\e[4;34m'        # Blue
UPurple='\e[4;35m'      # Purple
UCyan='\e[4;36m'        # Cyan
UWhite='\e[4;37m'       # White

# High Intensity
IBlack='\e[0;90m'       # Black
IRed='\e[0;91m'         # Red
IGreen='\e[0;92m'       # Green
IYellow='\e[0;93m'      # Yellow
IBlue='\e[0;94m'        # Blue
IPurple='\e[0;95m'      # Purple
ICyan='\e[0;96m'        # Cyan
IWhite='\e[0;97m'       # White

# Bold High Intensity
BIBlack='\e[1;90m'      # Black
BIRed='\e[1;91m'        # Red
BIGreen='\e[1;92m'      # Green
BIYellow='\e[1;93m'     # Yellow
BIBlue='\e[1;94m'       # Blue
BIPurple='\e[1;95m'     # Purple
BICyan='\e[1;96m'       # Cyan
BIWhite='\e[1;97m'      # White

RESETLINE='\e[K'

load=`cat /proc/loadavg | awk '{print $1}'`
nbcpu=`grep processor /proc/cpuinfo | wc -l`

memory_usage=`free -m | awk '/Mem/ { printf("%3.1f%%", ($3-($6+$7))/$2*100) }'`
memory_total=`free -m | awk '/Mem/ {print $2}'`

swap_usage=`free -m | awk '/Swap/ { printf("%3.1f%%", $3/$2*100) }'`
swap_total=`free -m | awk '/Swap/ {print $2}'`
users=`users | wc -w`
ntpsyncstatus=`ntpstat | head -1 | awk '{print $1}'`

if [ -e /etc/init.d/ntpd ]
then
        if [[ -n $(ps -e | grep ntpd | grep -v grep) ]]
        then
                ntpsyncstatus=`ntpstat 2>/dev/null | head -1 | awk '{print $1}'`
        else
                ntpsyncstatus="${Red}NTPD NOT STARTED${COff}"
        fi
else
        ntpsyncstatus="${Red}NTPD NOT INSTALLED${COff}"
fi

if [ ! -f /dev/shm/dnstest4motd.run ]
then
       dnsready=666
else
        dnsready=0
fi

DIRECTORYTOSCAN="/"

for DISKSTAB in $(grep -v ^# /etc/fstab | grep -e ext4 -e ext3 | awk '{print $2}')
do
        case $DISKSTAB in
                /usr/ipbx|/usr/ipbx/recording|$DATAPATH) DIRECTORYTOSCAN="$DIRECTORYTOSCAN $DISKSTAB";;
        esac
done
for CURRENTMOUNTED in $(mount | grep -e ext4 -e ext3 | awk '{print $3}')
do
        if [[ -z $(echo $DIRECTORYTOSCAN | grep " $CURRENTMOUNTED ") ]]
        then
                 case $CURRENTMOUNTED in
                /mnt/centile|/usr/ipbx/recording|$DATAPATH) DIRECTORYTOSCAN="$DIRECTORYTOSCAN $CURRENTMOUNTED";;
                esac
        fi
done
for NFSSTAB in $(grep -v ^# /etc/fstab | grep -e nfs | awk '{print $2}')
do
        case $NFSSTAB  in
                /usr/ipbx/centile|*recording|*centile/communities) NFSMOUNT="$NFSMOUNT $NFSSTAB";;
        esac
done

rate()
{
        # Percentge triggers
        local CRITICAL_triggerPercent=80
        local WARNING_triggerPercent=60

        int=${1%.*}
        case $2 in
        load)
                int=$(awk -v m=$1 -v n=$nbcpu 'BEGIN { print ((m / n) * 100 ) }')
                ;;
        esac
        int=${int%.*}
        int=${int%%%*}
        case 1 in
                $(( $int >= ${CRITICAL_triggerPercent} ))) retstr="${Red}$1${COff}";;
                $(( $int >= ${WARNING_triggerPercent} ))) retstr="${Yellow}$1${COff}";;
                $(( $int < ${WARNING_triggerPercent} ))) retstr="${Green}$1${COff}";;
        esac

        echo -en $retstr
}

istra_status()
{
        # first check IStra modules are alive (raw)
if [ -f /usr/ipbx/IntraSwitch/run/servermanager.pid ]
then
        if [[ -n $(find /usr/ipbx/IntraSwitch/run -type f -mmin -11) ]];
        then
                if [[ -n $(ps -e | grep $(cat /usr/ipbx/IntraSwitch/run/servermanager.pid) |grep -v grep) ]];
                then
                        istrastatusstring="${Green}RUNNING${COff}"
                        lps=$(ls -1t /usr/ipbx/IntraSwitch/run/*.pid |head -1)
                        lpspidFile=${lps##*/}
                        processlps=${lpspidFile%%.*}
                        datelps=$(stat -c %y $lps)
                        datelps=${datelps%%.*}
                        if [[ -n $(find /usr/ipbx/IntraSwitch/run  -type f -mtime -1 -name \*.pid) ]];
                        then
                                istrastatusstring="$istrastatusstring - ${BYellow}LPS $processlps@$datelps${COff}"
                        else
                                if [[ -n $(find /usr/ipbx/IntraSwitch/run  -type f -mtime -12 -name \*.pid) ]];
                                then
                                        istrastatusstring="$istrastatusstring - ${Yellow}LPS $processlps@$datelps${COff}"
                                else
                                        istrastatusstring="$istrastatusstring - ${Green}LPS $processlps@$datelps${COff}"
                                fi
                        fi
                fi
                for thirdp in mysql postgres jormungand nfsd httpd
                do
                        if [[ -n $(ps -e | grep $thirdp | grep -v grep) ]]
                        then
                                thirdpFound=1
                        fi
                done
                [[ -n $thirdpFound ]] && istrastatusstring="$istrastatusstring - ${Green}3rdP${COff}"
        else
                nblostPid=0
                nbprocess=$(ls -1t /usr/ipbx/IntraSwitch/run/*.pid|wc -l)
                for pr in $(ls -1t /usr/ipbx/IntraSwitch/run/*.pid)
                do
                        if [[ -z $(ps -e | grep $(cat $pr) |grep -v grep) ]];
                        then
                                (( nblostPid++ ))
                        fi
                done

                if [[ $nblostPid -ne 0 ]]
                then
                        [[ $nblostPid -lt $nbprocess ]] && istrastatusstring="${Yellow}RUNNING ${Red}!!JAVA ORPHANS!!${COff}"
                        if [[ $nblostPid -eq $nbprocess ]]
                        then
                                istrastatusstring="${Red}NOT RUNNING${COff}"
                                [[ -n $(ps -e | grep java | grep -v grep) ]] && istrastatusstring="${Red}NOT RUNNING !!JAVA ORPHAN!!${COff}"
                        fi
                else
                        istrastatusstring="${Green}RUNNING${COff}"
                        lps="/usr/ipbx/IntraSwitch/run/servermanager.pid"
                        lpspidFile=${lps##*/}
                        processlps=${lpspidFile%%.*}
                        datelps=$(stat -c %y $lps)
                        datelps=${datelps%%.*}
                        if [[ -n $(find /usr/ipbx/IntraSwitch/run  -type f -mtime -1 -name \*.pid) ]];
                        then
                                istrastatusstring="$istrastatusstring - ${BYellow}LPS $processlps@$datelps${COff}"
                        else
                                if [[ -n $(find /usr/ipbx/IntraSwitch/run  -type f -mtime -12 -name \*.pid) ]];
                                then
                                        istrastatusstring="$istrastatusstring - ${Yellow}LPS $processlps@$datelps${COff}"
                                else
                                        istrastatusstring="$istrastatusstring - ${Green}LPS $processlps@$datelps${COff}"
                                fi
                        fi

                fi

                for thirdp in mysql postgres jormungand nfsd httpd
                do
                        if [[ -n $(ps -e | grep $thirdp | grep -v grep) ]]
                        then
                                thirdpFound=1
                        fi
                done

                [[ -n $thirdpFound ]] && istrastatusstring="$istrastatusstring - ${Yellow}3rdP${COff}"
        fi
else
        istrastatusstring="${Red}NOT RUNNING${COff}"
        [[ -n $(ps -e | grep java | grep -v grep) ]] && istrastatusstring="${Red}NOT RUNNING !!JAVA ORPHAN!!${COff}"
                for thirdp in mysql postgres jormungand nfsd httpd
                do
                        if [[ -n $(ps -e | grep $thirdp | grep -v grep) ]]
                        then
                                thirdpFound=1
                        fi
                done

                [[ -n $thirdpFound ]] && istrastatusstring="$istrastatusstring - ${Yellow}3rdP${COff}"


fi
}

network_status()
{

# Regular interfaces
j=0
nbnic=$(ip link  |grep -B1 "link/ether" | grep qlen | grep -v "link/ether" |  grep -v master | grep -v LOOPBACK | grep -v usb | awk '{print $2$9}'| sed s,:.*,,|wc -l)

for i in $(ip link  |grep -B1 "link/ether" | grep qlen |grep -v "link/ether" | grep -v master | grep -v LOOPBACK | grep -v usb |awk '{print $2$9}'| sed s,:.*,,);
do
        NICCOL="${Red}DOWN "
        [[ -n $(ip link | grep ${i}| grep ",UP,") ]] && NICCOL=${Green}
        sudo ethtool $i 2>/dev/null > /dev/shm/.motdethtool
        IFACE=("$(cat /dev/shm/.motdethtool | grep Speed | awk {'print $2'})" "$(cat /dev/shm/.motdethtool | grep Duplex | awk {'print $2'})" "$( cat /dev/shm/.motdethtool | grep Auto-negotiation | awk {'print $2'})");
        statusIface="$statusIface ${NICCOL}${i}${COff}: ${IFACE[0]%%M*}"
                if [ "${IFACE[1]}" != "Full" ]
                then
                        statusIface="$statusIface${Red}${IFACE[1]:-n/a }${COff}D"
                else
                        statusIface="$statusIface${IFACE[1]}D"
                fi
                if [ "${IFACE[2]}" != "on" ]
                then
                        statusIface="$statusIface ${Yellow}ANeg${COff}"
                else
                        statusIface="$statusIface ANeg"
                fi
        statusIface="$statusIface\t"
        j=$(( $j + 1 ))
        [[ $(( $j%3 )) -eq 0 ]] && [[ $j -lt $nbnic ]] && statusIface="$statusIface\n"
done
#Bonded + VLAN
if [[ -d /proc/net/bonding ]]
then
        j=0
        echo
        nbbond=$(ls -1 /proc/net/bonding|wc -l)
        for i in $(ls -1 /proc/net/bonding);
        do
                unset listeth
                BOND[0]=$i  # name
                BOND[1]=$(grep -A1 "Currently Active Slave" /proc/net/bonding/$i | cut -f 2 -d':' | grep -e up -e down| sed 's,^ ,,') # Status
                BOND[2]=$(grep  "Currently Active Slave" /proc/net/bonding/$i | cut -f 2 -d':'  | sed 's,^ ,,')  # Current Master NIC
                BOND[3]=$(grep -A1 "Slave Interface" /proc/net/bonding/$i |  awk 'NR<=2' |head -1| cut -f 2 -d':' | sed 's,^ ,,') # SLAVE1 NAME Status
                BOND[4]=$(grep -A1 "Slave Interface" /proc/net/bonding/$i |  awk 'NR<=2' |grep -e up -e down| cut -f 2 -d':' | sed 's,^ ,,') # SLAVE1  Status
                BOND[5]=$(grep -A1 "Slave Interface" /proc/net/bonding/$i |  awk 'NR>3' |head -1| cut -f 2 -d':' | sed 's,^ ,,') # SLAVE2 NAME Status
                BOND[6]=$(grep -A1 "Slave Interface" /proc/net/bonding/$i |  awk 'NR>3' |grep -e up -e down| cut -f 2 -d':' | sed 's,^ ,,') # SLAVER2 Status

                TEMPCOL="${Green}"
                NIC1COL="${Green}"
                NIC2COL="${Green}"

                if [[ "${BOND[1]}" == "down" ]]
                then
                        TEMPCOL="${Red}"
                else
                        if [[ "${BOND[4]}" == "down" ]];
                        then
                                NIC1COL="${Red}"
                                TEMPCOL="${Yellow}"
                        fi
                        if [[ "${BOND[6]}" == "down" ]];
                        then
                                NIC2COL="${Red}"
                                TEMPCOL="${Yellow}"
                        fi

                fi
        if [[ ! $listeth ]]
        then
                for u in ${BOND[3]} ${BOND[5]};
                do
                        sudo ethtool ${u} 2>/dev/null > /dev/shm/.motdethtool
                        IFACE=("$(cat /dev/shm/.motdethtool | grep Speed | awk {'print $2'})" "$(cat /dev/shm/.motdethtool | grep Duplex | awk {'print $2'})" "$(cat /dev/shm/.motdethtool | grep Auto-negotiation | awk {'print $2'})");
                        statusIface="$statusIface${Cyan}$u${COff}: ${IFACE[0]%%M*}"
                        if [ "${IFACE[1]}" != "Full" ]
                        then
                                statusIface="$statusIface${Red}${IFACE[1]}D${COff}"
                        else
                                statusIface="$statusIface${IFACE[1]}D"
                        fi
                        if [ "${IFACE[2]}" != "on" ]
                        then
                                statusIface="$statusIface ${Yellow}ANeg${COff}"
                        else
                                statusIface="$statusIface ANeg"
                        fi
                        statusIface="$statusIface\t"
                done
        listeth=1
        fi
        statusIface="$statusIface${TEMPCOL}${BOND[0]}${COff}(${NIC1COL}${BOND[3]}${COff}"
        if [[ -n ${BOND[5]} ]];
        then
            statusIface="$statusIface/${NIC2COL}${BOND[5]}${COff}"
        fi
        statusIface="$statusIface)"

        for vl in $(ip link | grep @${BOND[0]} | awk '{print $2}' | sed s,@.*,,)
        do
                SUBNICCOL=${Purple}
                [[ -n $(ip link | grep $vl | grep ",UP,") ]] && SUBNICCOL=${Green}
                statusIface="$statusIface $SUBNICCOL$vl${COff}"
        done
        statusIface="$statusIface\n"
done
fi

}


check_vips()
{
        IFS=, vips=($VIP)
        IFS=, vifs=($VIF)
        local i=0
        TEMPCOL="${Green} UP"
        while [ $i -lt ${#vips[@]} ]
        do
                [[ $(/sbin/ip addr show dev ${vifs[$i]} | grep ${vips[$i]}) == "" ]] && TEMPCOL="${Purple} DOWN"
                statusvips="${statusvips}VIP$(( $i + 1 )):$TEMPCOL ${vips[$i]}@${vifs[$i]}${COff}\t"
                (( i++ ))
        done
        IFS=$' \t\n'
}

istra_patch_level()
{
                nbPOverride=0
                nbPDev=0
                nbPWars=0

                nbPOverride=$(find /usr/ipbx/IntraSwitch/lib/override  -maxdepth 1 -type f| wc -l)
                [ -d /usr/ipbx/IntraSwitch/lib/override/dev/ ] && nbPDev=$(find /usr/ipbx/IntraSwitch/lib/override/dev  -maxdepth 1 -type f| wc -l)
                [ -d /usr/ipbx/IntraSwitch/lib/override/dev/wars ] && nbPWars=$(find /usr/ipbx/IntraSwitch/lib/override/dev/wars  -maxdepth 1 -type f| wc -l)
                        if [ ${nbPOverride} -ne 0 ];
                        then
                                 listpatchamount="${Cyan}${nbPOverride} OVRD${COff}"
                        else
                                 listpatchamount="${Purple}${nbPOverride} OVRD${COff}"
                        fi
                        if [ ${nbPDev} -ne 0 ];
                        then
                                 listpatchamount="$listpatchamount - ${Cyan}${nbPDev} DEV${COff}"
                        else
                                 listpatchamount="$listpatchamount - ${Purple}${nbPDev} DEV${COff}"
                        fi
                        if [ ${nbPWars} -ne 0 ];
                        then
                                 listpatchamount="$listpatchamount - ${Cyan}${nbPWars} WARS${COff}"
                        else
                                 listpatchamount="$listpatchamount - ${Purple}${nbPWars} WARS${COff}"
                        fi

}

drbd_status()
{

local colorize=true
local short=true

# node role: Primary Secondary Unknown
c_pri_1=$(echo -e ${Cyan})  c_pri_0=$(echo -e ${COff})
c_sec_1=$(echo -e ${Blue})  c_sec_0=$(echo -e ${COff})
c_unk_1=$(echo -e ${Purple}) c_unk_0=$(echo -e ${COff})

# connection state:
# Unconfigured
#
# StandAlone
c_sta_1=$(echo -e ${BRed}) c_sta_0=$(echo -e ${COff})
# Disconnecting Unconnected Timeout BrokenPipe NetworkFailure ProtocolError TearDown
c_net_bad_1=$(echo -e ${BRed}) c_net_bad_0=$(echo -e ${COff})
# WFConnection WFReportParams
c_wfc_1=$(echo -e ${BYellow})      c_wfc_0=$(echo -e ${COff})
# Connected
c_con_1=$(echo -e ${Green})     c_con_0=$(echo -e ${COff})
# StartingSyncS StartingSyncT WFBitMapS WFBitMapT WFSyncUUID
c_ssy_1=$(echo -e ${BYellow})     c_ssy_0=$(echo -e ${COff})
# SyncSource PausedSyncS
c_src_1=$(echo -e ${BYellow})     c_src_0=$(echo -e ${COff})
# SyncTarget PausedSync
c_tgt_1=$(echo -e ${BYellow})     c_tgt_0=$(echo -e ${COff})

# disk state:
# Attaching Negotiating DUnknown Consistent
# uncolored for now
#
# Diskless Failed Inconsistent
c_dsk_bad_1=$(echo -e ${BRed}) c_dsk_bad_0=$(echo -e ${COff})
# Outdated
c_out_1=$(echo -e ${BRed})     c_out_0=$(echo -e ${COff})
# UpToDate
c_u2d_1=$(echo -e ${Green})     c_u2d_0=$(echo -e ${COff})

       # add resource names
        sed_script=$(
           (
           paste <(drbdadm sh-dev all 2>/dev/null) \
                 <(drbdadm sh-resources 2>/dev/null | tr ' /' '\n_') ;
           paste <(drbdadm -S sh-dev all 2>/dev/null ) \
                 <(drbdadm -S sh-resources 2>/dev/null | tr ' /' '\n_' )
           ) | sed -e 's,^/dev/drbd,s/^ *,;s,\t,:/,;s,$, \&/;,')
        sed -e "$sed_script;s/^ *\([0-9]\+:\)/??not-found?? \1/" < /proc/drbd |
        if [[ $short == true ]]; then
                sed -e '1,2d;/^$/d;/ns:.*nr:.*dw:/d;/resync:/d;/act_log:/d;'   | column -t

        else
                sed -e 's/ cs:/\n    cs:/;'
        fi |
        if [[ $colorize != true ]]; then
                cat
        else
                c_bold=$(echo -e ${BGreen}) c_norm=$(echo -e ${COff})
                sed -e "
s/^??not-found??/$c_dsk_bad_1&$c_dsk_bad_0/g;
s/^[^\t ]\+/$c_bold&$c_norm/;
s/Primary/$c_pri_1&$c_pri_0/g;
s/Secondary/$c_sec_1&$c_sec_0/g;
s/\<Unknown/$c_unk_1&$c_unk_0/;
s/DUnknown/$c_unk_1&$c_unk_0/;
s/StandAlone/$c_sta_1&$c_sta_0/;
s/Unconnected/$c_net_bad_1&$c_net_bad_0/;
s/Timeout/$c_net_bad_1&$c_net_bad_0/;
s/BrokenPipe/$c_net_bad_1&$c_net_bad_0/;
s/NetworkFailure/$c_net_bad_1&$c_net_bad_0/;
s/ProtocolError/$c_net_bad_1&$c_net_bad_0/;
s/TearDown/$c_net_bad_1&$c_net_bad_0/;
s/WFConnection/$c_wfc_1&$c_wfc_0/;
s/WFReportParams/$c_wfc_1&$c_wfc_0/;
s/Connected/$c_con_1&$c_con_0/;
s/StartingSync./$c_ssy_1&$c_ssy_0/;
s/WFBitMap./$c_ssy_1&$c_ssy_0/;
s/WFSyncUUID/$c_ssy_1&$c_ssy_0/;
s/SyncSource/$c_src_1&$c_src_0/;
s/PausedSyncS/$c_src_1&$c_src_0/;
s/SyncTarget/$c_tgt_1&$c_tgt_0/;
s/PausedSyncT/$c_tgt_1&$c_tgt_0/;
s/Diskless/$c_dsk_bad_1&$c_dsk_bad_0/g;
s/Failed/$c_dsk_bad_1&$c_dsk_bad_0/g;
s/Inconsistent/$c_dsk_bad_1&$c_dsk_bad_0/g;
s/Outdated/$c_out_1&$c_out_0/g;
s/UpToDate/$c_u2d_1&$c_u2d_0/g;
"
        fi
}

#Check is VMwareTools are installed, and notify the the admin via motd
isVMware(){
        [[ $(sudo dmidecode -s system-manufacturer 2>/dev/null) = 'VMware, Inc.' ]] && HYPVFOUND="VMware"
}
isXen(){
        [[ $(sudo dmidecode -s system-manufacturer 2>/dev/null ) = 'Xen' ]] || [[ -n $(uname -a | grep xen | awk '{print $3}') ]]&& HYPVFOUND="Xen     "
}
isKVM(){
        [[ $(sudo dmidecode -s system-product-name 2>/dev/null) = 'KVM' ]] && HYPVFOUND="KVM"
}
isVBox(){
        [[ $(sudo dmidecode -s system-product-name 2>/dev/null) = 'VirtualBox' ]] && HYPVFOUND="VirtualBox"
}


isVM()
{

        isVMware || isXen || isKVM || isVBox;

        if [[ "$HYPVFOUND" != "" ]];
        then
                case $HYPVFOUND in
                VMware)
                        if [[ ! -e /usr/bin/vmware-config-tools.pl ]];
                        then
                                vmttoolsInstalled="${Red}NOT INSTALLED${COff}"
                        else
                                vmttoolsInstalled="${Green}INSTALLED${COff}"
                        fi
                        ;;
                VirtualBox)
                        if [[ ! -e /etc/init.d/vboxadd ]];
                        then
                                vmttoolsInstalled="${Red}NOT INSTALLED${COff}"
                        else
                                vmttoolsInstalled="${Green}INSTALLED${COff}"
                        fi
                        ;;


                esac
        fi


}

# SYSINFO
isVM
[[ -n $HYPVFOUND ]] && echo -e "Virtualized: Yes\tHypervisor: $HYPVFOUND\tVMTools: ${vmttoolsInstalled:-N/A}"
printf "Nb CPU Core: %s\t\tTotal RAM: %sMB\tTotal Swap: %sMB${COff}\n" ${nbcpu} ${memory_total} ${swap_total}
printf "System load: %s\tMemory usage:%s\tSwap usage: %s${COff}\n" $(rate ${load} load) $(rate ${memory_usage}) $(rate ${swap_usage})
echo

# DIsk
echo -en "${UWhite}Local disks${COff}: "

for i in $DIRECTORYTOSCAN
do
                if [[ "$(mount | grep $i)" != "" ]]
                then
                        usage=$(df -h $i | grep -v Filesystem| awk '/\// {print $(NF-1)}' | grep -v '\r';)
                        printf "%s %s\t" $i $(rate ${usage})
                else
                        printf "%s ${Yellow}UnMnt${COff}\t" $i
                fi
done
echo
[[ -n $NFSMOUNT ]] && echo -en "${UWhite}Remote disks${COff}: "
for i in $NFSMOUNT
do
                if [[ "$(mount | grep $i)" != "" ]]
                then
                        usage=$(df -h $i | grep -v Filesystem| awk '/\// {print $(NF-1)}' | grep -v '\r';)
                        printf "%s %s\t" $i $(rate ${usage})
                else
                        printf "%s${COff}${Yellow} UnMnt${COff}\t" $i
                fi
done
[[ -n $NFSMOUNT ]] && echo
#network
echo;echo -en "${UWhite}Network${COff}: "
network_status
echo -e "$statusIface"
if [ -f "/usr/ipbx/IntraSwitch/supramanager.cfg" ];
then
       . /usr/ipbx/IntraSwitch/supramanager.cfg
       [ -r /usr/ipbx/IntraSwitch/runmanager.cfg ] && . /usr/ipbx/IntraSwitch/runmanager.cfg

       if [[ -n "$VIP" ]] && [[ -n "$VIF" ]];
       then
              check_vips
              echo -e "$statusvips"
       fi
fi
echo -en "${UWhite}Netservices dependencies${COff}: "
if [[ -z $(echo $ntpsyncstatus | grep NOT) ]];
then
        if [ "$ntpsyncstatus" == "unsynchronised" ];
        then
                echo -en "NTP Clock ${Red}$ntpsyncstatus${COff}\t"
        else
                echo -en "NTP Clock ${Green}$ntpsyncstatus${COff}\t"
        fi
else
        echo -en "$ntpsyncstatus"
fi

if [ $dnsready -ne 0 ];
then
        echo -en "DNS Res<>NS ${Purple}NotTested${COff}"
else
        . /dev/shm/dnstest4motd.run
        j=0
        for (( c=0; c<=$NBDNSSERVERTESTED; c++ ))
        do
                [[ "${RESULT[$c]}" == "available" ]] && ((j++))
        done
        echo -en "DNS Res<>NS "
        if [[ $NBDNSSERVERTESTED -ne 0 ]] && [[ $j -eq $NBDNSSERVERTESTED ]]
        then
                echo -en "${Green}OK <> $j/$NBDNSSERVERTESTED${COff}"
        else
                TEMPCOL="${Red}KO"
                [[ $j -ne 0 ]] && TEMPCOL="${Yellow}OK"
                echo -en "${TEMPCOL} <> $j/$NBDNSSERVERTESTED${COff}"
        fi
fi

echo
if [ -z $(echo $ntpsyncstatus | grep NOT) ];
then
        for i in $(ntpq -nc peers | awk 'NR>=3' | grep -v 127. | awk '{ print $1"@@"$7}');
        do
                echo -en "NTP@${i%%@@*}: ";
                if [ ${i##*@@} -eq 0 ];
                then
                        echo -en "${Red}unreachable${COff}\t"
                else
                        echo -en "${Green}reachable${COff}\t"
                fi
        done
echo
fi
#DRBD
if [[ -e /etc/init.d/drbd ]];
then
        echo
        if [[ $(/etc/init.d/drbd status >/dev/null 2>&1) -eq 0 ]]
        then
                echo -en "${UWhite}DRBD Status:${COff}"
                if [ -f /proc/drbd ];
                then
                        echo
                        drbd_status
                else
                        echo -e "${Yellow} Service not started${COff}"
                fi
        fi
fi
# Check Server Type
#
#
if [[ -e /etc/init.d/pacemaker ]];
then
        echo
        if [[ $(crm_mon -s >/dev/null 2>&1) -eq 0 ]]
        then
                echo -en "${UWhite}Pacemaker Status:${COff}"
                if [ -f /var/run/pacemakerd.pid ];
                then
                        echo
                        crm_mon -s
                else
                        echo -e "${Yellow} Service not started${COff}"
                fi
        fi
else
    isver=$(rpm -q --qf '%{version}-%{release}\n' intraswitch)
    if [ $? -eq 0 ]
    then
            echo
            if [ -f "/usr/ipbx/IntraSwitch/supramanager.cfg" ];
            then
                    . /usr/ipbx/IntraSwitch/supramanager.cfg
                    defsrvmode=$SERVERMODE
                    unset SERVERMODE
                    [ -r /usr/ipbx/IntraSwitch/runmanager.cfg ] && . /usr/ipbx/IntraSwitch/runmanager.cfg
                    cursrvmode=${SERVERMODE:-N/A}
                    istra_status
                    echo -e "${UWhite}ISTRA Infos:${COff}\tBuild: ${Cyan}$isver${COff}   \tType: ${Cyan}${CLUSTERMODE:-APP}${COff}"
                    # Prints Istra info
                    echo -en "Mode current/initial: ${Cyan}$cursrvmode${COff}/$defsrvmode\tPatchs: "
                    # Check if there is an override
                    if [ -d /usr/ipbx/IntraSwitch/lib/override ]
                    then
                            istra_patch_level
                            echo -e "$listpatchamount${COff}"

                    else
                            echo -e "${Cyan}None${COff}"
                    fi
                echo -e "Status: $istrastatusstring\t"
            fi
    else
            echo -e "${Yellow}ISTRA NOT INSTALLED${COff}"
    fi
fi
echo

[ -f /dev/shm/.motdethtool ] && rm -f /dev/shm/.motdethtool


