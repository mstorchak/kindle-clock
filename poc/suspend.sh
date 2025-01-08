#!/bin/sh
set -x
lipc-set-prop com.lab126.wan stopWan 1
lipc-set-prop com.lab126.wan enable 0
lipc-set-prop com.lab126.wifid cmConnect 0
lipc-set-prop com.lab126.wifid enable 0
while grep -q ar6000 /proc/modules; do sleep 1; done
echo $(( $(date +%s)+4 +30 )) > /sys/class/rtc/rtc0/wakealarm
date "+%s %c"
echo mem > /sys/power/state
date "+%s %c"
