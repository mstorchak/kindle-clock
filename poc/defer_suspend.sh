#!/bin/sh
LOGS=""
log() {
	local msg="$*"
	[ "$msg" ] && {
		LOGS="$LOGS\n$msg"
		LOGS=$(echo -e "$LOGS" | tail -n 8)
	}
	echo -e "$LOGS" | fbink -q -y 23 -r
}

set -x
while :; do
	state=$(lipc-get-prop com.lab126.powerd state)
	log "Current state is $state"
	case "$state" in
		active)
			log "Current state is $state, switching to screensaver"
			powerd_test -p
			sleep 1
			continue
			;;
		readyToSuspend)
			powerd_test -d 1000000
			r=$(powerd_test -s | awk '/Remaining/ {print $NF}')
			log "Remaining time: $r"
			break
			;;
	esac
	lipc-wait-event com.lab126.powerd '*'
done
