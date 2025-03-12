#!/bin/sh
#shellcheck shell=dash

# shellcheck disable=SC2034
{
	FONTDIR=./fonts
	F_SERIF_REGULAR=$FONTDIR/NotoSerif-Regular.ttf
	F_SERIF_BOLD=$FONTDIR/NotoSerif-Bold.ttf
	F_SANS_REGULAR=$FONTDIR/NotoSans-Regular.ttf
	F_SANS_BOLD=$FONTDIR/NotoSans-Bold.ttf
	F_MONO_REGULAR=$FONTDIR/NotoSansMono-Regular.ttf
	F_MONO_BOLD=$FONTDIR/NotoSansMono-Bold.ttf
}

# config
export TZ='EET-2EEST,M3.5.0/3,M10.5.0/4'
DEBUG=false
BAT_LOW=20
BAT_HIGH=90
SCREEN_HEIGHTH=800
SCREEN_WIDTH=600
NTP_PERIOD=$((3600*6))
CAL_FONT_SIZE=50

dow() {
	local d=""
	case "$1" in
		1) d="понеділок" ;;
		2) d="вівторок" ;;
		3) d="середа" ;;
		4) d="четвер" ;;
		5) d="пʼятниця" ;;
		6) d="субота" ;;
		7) d="неділя" ;;
	esac
	echo "$d"
}

mon() {
	local m=""
	case "$1" in
		01) m="січня" ;;
		02) m="лютого" ;;
		03) m="березня" ;;
		04) m="квітня" ;;
		05) m="травня" ;;
		06) m="червня" ;;
		07) m="липня" ;;
		08) m="серпня" ;;
		09) m="вересня" ;;
		10) m="жовтня" ;;
		11) m="листопада" ;;
		12) m="грудня" ;;
	esac
	echo "$m"
}

cal() {
	local i d last day1 c
	case "$MONTH" in
		01|03|05|07|08|10|12) last=31;;
		04|06|09|11) last=30;;
		02)
			[ $((YEAR % 4)) -eq 0 ] && last=29 || last=28
			[ $((YEAR % 100)) -eq 0 ] && last=29
			[ $((YEAR % 400)) -eq 0 ] && last=28
			;;
	esac

	day1=$(date -d "${MONTH}01${YEAR}" +%u)

	i=0; d=0
	while [ $d -lt $last ]; do
		d=$((i-day1+2))
		[ $((d - DAY)) -eq 0 ] && c='**' || c=''
		[ $d -le 0 ] && echo -n "    " || printf "%s%2s%s  " "$c" "$d" "$c"
		[ $((i%7)) -eq 6 ] && echo
		i=$((i+1))
	done
	echo
}

_fbink() {
	fbink -q -b "$@"
}

debug_start() {
	LNO=18
}

debug() {
	"$DEBUG" || return 0
	local lines
	fbink -q -r -y "$LNO" -l "$@" > "$tmp/lines"
	read -r lines < "$tmp/lines"
	LNO=$((LNO+lines))
}

ntpsync() {
	{
		fbink -q -y 9 -m -h -r "Syncing time..."
		lipc-set-prop com.lab126.wifid enable 1
		lipc-wait-event -s 60 com.lab126.wifid cmConnected && { sleep 1; ntpdate 172.19.47.1 > "$tmp/ntpdate" 2>&1; } && next_ntpdate=$((NOW+NTP_PERIOD)) && hwclock -u -w
		lipc-set-prop com.lab126.wifid enable 0
		lipc-wait-event -s 60 com.lab126.wifid cmIntfNotAvailable
		fbink -q -y 9 -m -h -r < "$tmp/ntpdate"
	} > /dev/null 2>&1
}


# BEGIN

tmp=/tmp/kindle-cal
rm -rf $tmp.*
tmp=$(mktemp -d $tmp.XXXXXX)

cal_refresh_day=0
next_ntpdate=0
read -r NOW < /sys/class/rtc/rtc0/since_epoch

[ "$(lipc-get-prop com.lab126.powerd state)" = active ] && {
	powerd_test -p > /dev/null 2>&1
	sleep 1
}

ntpsync

lipc-set-prop com.lab126.wan stopWan 1
lipc-set-prop com.lab126.wan enable 0

while :; do
	if [ "$cal_refresh_day" -ne 0 ]; then
		read -r NOW < /sys/class/rtc/rtc0/since_epoch
		sleep_s2r=$((60-NOW%60))
		if [ "$sleep_s2r" -lt 5 ] || [ "$MINUTE" = "00" ] || [ "$rem_time" = "Unknown" ]; then
			sleep "$sleep_s2r"
		else
			echo $((NOW+sleep_s2r)) > /sys/class/rtc/rtc0/wakealarm
			echo mem > /sys/power/state
		fi
	fi

	read -r NOW < /sys/class/rtc/rtc0/since_epoch
	date -D %s -d "$NOW" "+%Y %m %-d %u %H %M %-M" > "$tmp/timestamp"
	read -r YEAR MONTH DAY DOW HOUR MINUTE _MINUTE < "$tmp/timestamp"

	[ "$cal_refresh_day" != "$DAY" ] && fbink -q -c -f

	_fbink -t "bold=$F_SANS_BOLD,px=270,style=BOLD,padding=HORIZONTAL" -m "$HOUR:$MINUTE"

	powerd_test -s > "$tmp/powerd_state"
	{
		read -r state
		state=${state##*: }
		read -r rem_time
		rem_time=${rem_time##*: }
		rem_time=${rem_time%%.*}
		read -r _; read -r _; read -r _; read -r _
		read -r bat
		bat=${bat##*: }
		bat=${bat%%%}
		read -r _
		read -r charging
		charging=${charging##*: }
	} < "$tmp/powerd_state"

	# battery level and charging state
	bat_msg=""
	[ "$bat" -le "$BAT_LOW" ] && bat_msg="Low battery, please charge"
	[ "$charging" = "Yes" ] && {
		bat_msg="Charging"
		[ "$bat" -ge "$BAT_HIGH" ] && bat_msg="Charged"
	}
	[ "$bat_msg" ] && {
		_fbink -P "$bat"
		_fbink -y 1 -Y 4 -m "$bat_msg"
	}

	# update the screen
	fbink -q -s top=0,left=0,width=600,height=220

	# defer suspending
	case "$state" in
		Active) fbink -q -c -f; exit 0 ;;
		Screen*Saver)
			if [ "$rem_time" -ge 0 ] 2> /dev/null; then
				fbink -q -y 9 -m -h -r "Activating power saving mode..."
				lipc-wait-event -s 60 com.lab126.powerd readyToSuspend && powerd_test -d 600
				fbink -q -y 10 -m -h -r "done"
			fi
			;;
		Ready*to*suspend)
			powerd_test -d 600
			;;
	esac > /dev/null 2>&1

	# sync time
	[ "$next_ntpdate" -le "$NOW" ] && [ $((_MINUTE%10)) -eq 3 ] && ntpsync

	[ "$cal_refresh_day" = "$DAY" ] && continue

	cal_refresh_day=$DAY
	_fbink -k top=220,left=0,width=600,height=580
	_fbink -t "regular=$F_SERIF_REGULAR,px=64,top=230" -m "$DAY $(mon "$MONTH"), $(dow "$DOW")"

	cal > "$tmp/cal"
	cal_lines=$(wc -l < "$tmp/cal")
	cal_top=$((SCREEN_HEIGHTH-CAL_FONT_SIZE*(cal_lines+1)))
	_fbink -B GRAYB -k top=$cal_top,left=430,width=170,height=$((CAL_FONT_SIZE*(cal_lines+1)))
	_fbink -B GRAY5 -k top=$cal_top,left=0,width=6,height=$CAL_FONT_SIZE
	_fbink -B GRAY5 -C WHITE -t "bold=$F_MONO_BOLD,px=$CAL_FONT_SIZE,top=$cal_top,left=6,padding=HORIZONTAL,style=BOLD" "Пн  Вт  Ср  Чт  Пт  Сб  Нд"
	_fbink -O -t regular=$F_MONO_REGULAR,bold=$F_MONO_BOLD,px=$CAL_FONT_SIZE,format,top=$((cal_top+CAL_FONT_SIZE)),left=6 < "$tmp/cal"
	fbink -q -s
done
