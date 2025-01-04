#!/bin/sh
#shellcheck shell=busybox

wait_connect() {
	local c=30
	while [ $((c--)) -ge 0 ]; do
		state=$(lipc-get-prop   com.lab126.wifid cmState)
		[ "$state" = CONNECTED ] && return 0
		sleep 1
	done
	return 1
}

lipc-set-prop com.lab126.wifid enable 1
lipc-set-prop com.lab126.wifid cmConnect 1
wait_connect || exit 1
for i in 172.19.47.129 pool.ntp.org; do
	ntpdate -v $i && break
done
lipc-set-prop com.lab126.wifid cmConnect 0
lipc-set-prop com.lab126.wifid enable 0
