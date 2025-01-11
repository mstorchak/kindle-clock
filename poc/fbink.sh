#!/bin/sh
#shellcheck shell=dash

# fonts
: "
/mnt/us/fonts/NotoSans-Bold.ttf
/mnt/us/fonts/NotoSans-BoldItalic.ttf
/mnt/us/fonts/NotoSans-Italic.ttf
/mnt/us/fonts/NotoSans-Regular.ttf
/mnt/us/fonts/NotoSansMono-Bold.ttf
/mnt/us/fonts/NotoSansMono-Regular.ttf
/mnt/us/fonts/NotoSerif-Bold.ttf
/mnt/us/fonts/NotoSerif-BoldItalic.ttf
/mnt/us/fonts/NotoSerif-Italic.ttf
/mnt/us/fonts/NotoSerif-Regular.ttf
"

# config
BAT_LOW=20
BAT_HIGH=80

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
			[ $((YEAR % 4 )) -eq 0 ] && last=29 || last=28
			[ $((YEAR % 100 )) -eq 0 ] && last=29
			[ $((YEAR % 400 )) -eq 0 ] && last=28
			;;
	esac

	day1=$(date -d "${MONTH}01${YEAR}" +%u)

	i=0; d=0; while [ $d -lt $last ]; do d=$((i-day1+2)); [ $((d - DAY)) -eq 0 ] && c='**' || c=''; [ $d -le 0 ] && echo -n "    " || printf "%s%2s%s  " "$c" "$d" "$c"; [ $((i%7)) -eq 6 ] && echo; i=$((i+1)); done; echo
}

_fbink() {
	fbink -q -b "$@"
}

tmp=/tmp/kindle-cal
rm -rf $tmp.*
tmp=$(mktemp -d $tmp.XXXXXX)

_fbink -c -f

cal_refresh_day=0
while :; do
	[ "$cal_refresh_day" -ne 0 ] && sleep "$((60-$(date +%s)%60))"

	date "+%Y %m %-d %u %H:%M" > "$tmp/timestamp"
	read -r YEAR MONTH DAY DOW TIME < "$tmp/timestamp"
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

	fonts="regular=/mnt/us/fonts/NotoSerif-Regular.ttf,bold=/mnt/us/fonts/NotoSerif-Bold.ttf,italic=/mnt/us/fonts/NotoSerif-Italic.ttf,bolditalic=/mnt/us/fonts/NotoSerif-BoldItalic.ttf"
	_fbink -t $fonts,px=270,style=BOLD,padding=HORIZONTAL -m "$TIME"

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

	fbink -q -s top=0,left=0,width=600,height=220
	[ "$cal_refresh_day" = "$DAY" ] && continue

	cal_refresh_day=$DAY
	_fbink -k top=220,left=0,width=600,height=580
	_fbink -t $fonts,px=64,top=230 -m "$DAY $(mon "$MONTH"), $(dow "$DOW")"

	fonts="regular=/mnt/us/fonts/NotoSansMono-Regular.ttf,bold=/mnt/us/fonts/NotoSansMono-Bold.ttf"
	_fbink -B GRAYB -k top=500,left=430,width=170,height=300
	_fbink -B GRAY2 -k top=500,left=0,width=600,height=52
	_fbink -B GRAY2 -C WHITE -t $fonts,px=50,format,top=500,left=6 "Пн  Вт  Ср  Чт  Пт  Сб  Нд"
	cal | _fbink -O -t $fonts,px=50,format,top=550,left=6
	fbink -q -s
done
