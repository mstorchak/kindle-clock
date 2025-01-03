#!/bin/sh
#shellcheck shell=dash

# fonts
[ "
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
" ]


dow() {
	local d=""
	case "$1" in
		1) d="Понеділок" ;;
		2) d="Вівторок" ;;
		3) d="Середа" ;;
		4) d="Четвер" ;;
		5) d="Пʼятниця" ;;
		6) d="Субота" ;;
		7) d="Неділя" ;;
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

lpad() {
	local size=$1 str=$2 pad
	pad=$(((size + ${#str})/2))
	printf "%${pad}s" "$str"
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

	i=0; d=0; while [ $d -lt $last ]; do d=$((i-day1+2)); [ $((d - _DAY)) -eq 0 ] && c='**' || c=''; [ $d -le 0 ] && echo -n "    " || printf "%s%2s%s  " "$c" "$d" "$c"; [ $((i%7)) -eq 6 ] && echo; i=$((i+1)); done; echo
}

_fbink() {
	fbink -q -b "$@"
}

tmp=$(mktemp /tmp/kindle-cal.XXXXXX)
trap 'rm -rf $tmp' 0

date "+%Y %m %d %-d %u %H:%M" > "$tmp"
read -r YEAR MONTH DAY _DAY DOW TIME < "$tmp"
DOW=$(dow $DOW)

display="/usr/local/bin/java -cp /opt/amazon/ebook/lib/portability-impl.jar com.lab126.util.misc.DisplayFile"


fonts="regular=/mnt/us/fonts/NotoSerif-Regular.ttf,bold=/mnt/us/fonts/NotoSerif-Bold.ttf,italic=/mnt/us/fonts/NotoSerif-Italic.ttf,bolditalic=/mnt/us/fonts/NotoSerif-BoldItalic.ttf"
_fbink -c
_fbink -t $fonts,px=200,format,top=0 -m "$TIME"
_fbink -t $fonts,px=70,format,top=180 -m "$_DAY $(mon $MONTH) $YEAR р."
_fbink -t $fonts,px=70,format,top=250 -m "$DOW"
_fbink -B GRAYB -k top=500,left=430,width=170,height=300

fonts="regular=/mnt/us/fonts/NotoSansMono-Regular.ttf,bold=/mnt/us/fonts/NotoSansMono-Bold.ttf"
{
	echo "Пн  Вт  Ср  Чт  Пт  Сб  Нд"
	cal
} | _fbink -O -t $fonts,px=50,format,top=500,left=6


fbink -s
