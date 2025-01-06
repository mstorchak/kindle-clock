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
rm -f $tmp.*
tmp=$(mktemp $tmp.XXXXXX)

_fbink -c -f

firsttime=y
cal_refresh_day=0
while :; do
	fbink -q -s
	[ "$firsttime" ] && firsttime='' || sleep "$((60-$(date +%s)%60))"

	date "+%Y %m %-d %u %H:%M" > "$tmp"
	read -r YEAR MONTH DAY DOW TIME < "$tmp"
	DOW=$(dow "$DOW")

	fonts="regular=/mnt/us/fonts/NotoSerif-Regular.ttf,bold=/mnt/us/fonts/NotoSerif-Bold.ttf,italic=/mnt/us/fonts/NotoSerif-Italic.ttf,bolditalic=/mnt/us/fonts/NotoSerif-BoldItalic.ttf"
	if [ "$cal_refresh_day" = "$DAY" ]; then
		_fbink -t $fonts,px=270,style=BOLD -m "$TIME"
		_fbink -t $fonts,px=70,top=230 -m "$DAY $(mon "$MONTH") $YEAR р."
		continue
	else
		_fbink -c
		_fbink -t $fonts,px=270,style=BOLD -m "$TIME"
		_fbink -t $fonts,px=70,top=230 -m "$DAY $(mon "$MONTH") $YEAR р."
		cal_refresh_day=$DAY
	fi
	_fbink -t $fonts,px=70,top=300 -m "$DOW"

	fonts="regular=/mnt/us/fonts/NotoSansMono-Regular.ttf,bold=/mnt/us/fonts/NotoSansMono-Bold.ttf"
	_fbink -B GRAYB -k top=500,left=430,width=170,height=300
	_fbink -B GRAY2 -k top=500,left=0,width=600,height=52
	_fbink -B GRAY2 -C WHITE -t $fonts,px=50,format,top=500,left=6 "Пн  Вт  Ср  Чт  Пт  Сб  Нд"
	cal | _fbink -O -t $fonts,px=50,format,top=550,left=6
done
