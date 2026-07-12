#!/bin/sh
# nchat-typing-names.sh — resolve ~/tmp/nchat-typing.log to "flag + name + number".
# The raw log keeps profileId + JIDs on purpose (needed to resolve the name against
# the RIGHT account's address book). This is the human view.
#   nchat-typing-names.sh        one-shot over the whole log
#   nchat-typing-names.sh -f     follow live (your replacement for tail -f)
# Output (TSV): timestamp  flag  name  number  typing|idle
PROFROOT="$HOME/.config/nchat/profiles"
mx=$(printf '\360\237\207\262\360\237\207\275')   # flag MX (U+1F1F2 U+1F1FD)
us=$(printf '\360\237\207\272\360\237\207\270')   # flag US (U+1F1FA U+1F1F8)

follow=0
[ "$1" = "-f" ] && { follow=1; shift; }
LOG="${1:-$HOME/tmp/nchat-typing.log}"
[ -f "$LOG" ] || { echo "no log: $LOG" >&2; exit 1; }

resolve() {   # args: profileId chatId  -> prints "flag<TAB>name<TAB>number"
  pid="$1"; cid="$2"
  case "$pid" in
    *528671812166*) flag="$mx" ;;
    *19565156295*)  flag="$us" ;;
    *)              flag="${pid#WhatsAppMd_}" ;;
  esac
  num="${cid%@*}"
  db="$PROFROOT/$pid/session.db"
  name=""
  [ -f "$db" ] && name=$(sqlite3 "$db" "SELECT coalesce(nullif(full_name,''),nullif(first_name,''),nullif(push_name,''),nullif(business_name,'')) FROM whatsmeow_contacts WHERE their_jid='$cid' LIMIT 1" 2>/dev/null)
  [ -z "$name" ] && name="?"
  printf '%s\t%s\t%s' "$flag" "$name" "$num"
}

tab=$(printf '\t')
emit() {
  while IFS="$tab" read -r ts profileId chatId userId state; do
    [ -z "$ts" ] && continue
    printf '%s\t%s\t%s\n' "$ts" "$(resolve "$profileId" "$chatId")" "$state"
  done
}

if [ "$follow" = 1 ]; then
  tail -f "$LOG" | emit
else
  emit < "$LOG"
fi
