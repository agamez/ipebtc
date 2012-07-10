#!/bin/bash

### BEGIN INIT INFO
# Provides:          ipebtc
# Required-Start:    $network $local_fs $remote_fs
# Required-Stop:     $network $local_fs $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: iptables and ebtables configuration utiltity
# Description:       ipebtc is a simple script which reads two config
#                    files on /etc/ipebtc to load and unload a series
#                    of rules for iptables and ebtables, replacing
#                    a variable name for either the command "add new rule"
#                    or the command "delete this rule".
### END INIT INFO

. /lib/lsb/init-functions

EBT_CFG=/etc/ipebtc/ebtc.conf
IPT_CFG=/etc/ipebtc/iptc.conf

[ -f $EBT_CFG ] || exit 0
[ -f $IPT_CFG ] || exit 0

ipebtc_execute() {
	if [ -n "${!2}" ]; then
		rules=${!2}
	else
		rules=$2
	fi

	for i in $rules; do
		j=1
		while :; do
			n=$i[$j]
			linea=${!n}
			if [ -z "$linea" ]; then
				break
			fi

			$1 $linea

			((j++))
		done
	done
}

ipebtc_load () {
	ACTION='A'
	. $EBT_CFG
	for i in $*; do
		ipebtc_execute "ebtables" $i
	done

	. $IPT_CFG
	for i in $*; do
		ipebtc_execute "iptables" $i
	done
}

ipebtc_unload () {
	ACTION='D'

	. $EBT_CFG
	for i in $*; do
		ipebtc_execute "ebtables" $i
	done

	. $IPT_CFG
	for i in $*; do
		ipebtc_execute "iptables" $i
	done
}

ipebtc_status () {
	. $EBT_CFG
	echo $startup | grep '\b'$1'\b' &>/dev/null
	RET1=$?

	. $IPT_CFG
	echo $startup | grep '\b'$1'\b' &>/dev/null
	RET2=$?

	if [ $RET1 -eq 1 ] || [ $RET2 -eq 1 ]; then
		echo off
	else
		echo on
	fi
}

ipebtc_enable_file () {
	. $1
	echo $startup | grep '\b'$2'\b' &>/dev/null
	RET=$?
	if [ $RET -eq 1 ]; then
		old='startup="'$startup'"'
		new='startup="'"$startup $2"'"'
		eval $(echo sed -i s/\'$old\'/\'$new\'/g $1)
	fi
}

ipebtc_disable_file () {
	. $1
	old='startup="'$startup'"'
	new='startup="'$(echo $startup | sed -re "s/\b$2\b//g" -e 's/\ +/\ /g' -e 's/^\ |\ $//g')'"'
	eval $(echo sed -i s/\'$old\'/\'$new\'/g $1)
}

ipebtc_enable () {
	for i in $*; do
		ipebtc_enable_file $EBT_CFG $i
		ipebtc_enable_file $IPT_CFG $i
	done
}

ipebtc_disable () {
	for i in $*; do
		ipebtc_disable_file $EBT_CFG $i
		ipebtc_disable_file $IPT_CFG $i
	done
}

case "$1" in
    start)
	ipebtc_load startup
	;;  
    stop)
	ipebtc_unload startup
	;;
    restart|force-reload)
	$0 stop
	$0 start
	;;
    load)
	shift
	ipebtc_load $*
	;;
    unload)
	shift
	ipebtc_unload $*
	;;
    enable)
	shift
	ipebtc_enable $*
	ipebtc_load $*
    	;;
    disable)
	shift
	ipebtc_unload $*
	ipebtc_disable $*
        ;;
    status)
    	ipebtc_status $2
    	;;
    *)
	log_success_msg "Usage: /etc/init.d/ipebtc {start|stop|force-reload|restart|load <name>|unload <name>|status <name>}"
	exit 1
	;;
esac

exit 0
