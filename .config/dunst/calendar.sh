#!/bin/bash

send_notification() {
	TODAY=$(date '+%-d')
	HEAD=$(cal "$1" | head -n1)
	BODY=$(cal "$1" | tail -n7)

	# Word-boundary match so a single-digit day (e.g. "2") can't accidentally
	# match inside a later two-digit day ("20", "21", "22"...). Underline only
	# (no bold) so the glyph advance width stays identical to the rest of the
	# monospace grid — bold weights often render a hair wider, which shifts
	# every column after the highlighted day on that line.
	BODY=$(printf '%s' "$BODY" | sed -z "s|\b$TODAY\b|<u>$TODAY</u>|1")

	FOOT="<i>~ calendar</i> "

	# Wrap the whole body in <tt> so it's forced monospace regardless of any
	# per-rule font/markup overrides elsewhere in dunstrc.
	dunstify -h string:x-canonical-private-synchronous:calendar -i ' ' \
		"$HEAD" "<tt>$BODY</tt>$FOOT" -u NORMAL
}

handle_action() {
	echo "$DIFF" > "$TMP"
	if [ "$DIFF" -ge 0 ]; then
		send_notification "+$DIFF months"
	else
		send_notification "$((-DIFF)) months ago"
	fi
}

TMP=${XDG_RUNTIME_DIR:-/tmp}/"$UID"_calendar_notification_month
touch "$TMP"

DIFF=$(<"$TMP")
DIFF=${DIFF:-0}

case $1 in
	"curr") DIFF=0;;
	"next") DIFF=$((DIFF+1));;
	"prev") DIFF=$((DIFF-1));;
esac

handle_action
