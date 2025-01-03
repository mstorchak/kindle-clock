#!/bin/sh
#shellcheck shell=dash

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

	i=0; d=0; while [ $d -lt $last ]; do d=$((i-day1+2)); [ $((d - _DAY)) -eq 0 ] && c='>' || c=' '; [ $d -le 0 ] && echo -n "    " || printf "%3s " "$c$d"; [ $((i%7)) -eq 6 ] && echo; i=$((i+1)); done; echo
}

tmp=$(mktemp /tmp/kindle-cal.XXXXXX)
trap 'rm -rf $tmp' 0

date "+%Y %m %d %-d %A %H:%M" > "$tmp"
read -r YEAR MONTH DAY _DAY DOW TIME < "$tmp"
_DAY=$((_DAY+1))

display="/usr/local/bin/java -cp /opt/amazon/ebook/lib/portability-impl.jar com.lab126.util.misc.DisplayFile"

cat <<EOF | $display -
<Monospaced 156>
$TIME
<Monospaced 48>
$(lpad 17 "$DOW")
$(lpad 17 "$DAY-$MONTH-$YEAR")

<Monospaced 30>
Mon Tue Wed Thu Fri Sat Sun
$(cal)
EOF
