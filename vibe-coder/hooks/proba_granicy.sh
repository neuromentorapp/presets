#!/bin/sh
# Проба хука границы. РАЗЛИЧАЮЩАЯ: проверяет и код возврата, и содержимое ответа.
# ⚠️ Первая редакция пробы печатала «пусто — верно» на падающем скрипте: она радовалась
#    тому, чего сама ждала. Теперь пустота засчитывается только при коде возврата 0.
HOOK="$(dirname "$0")/granica.sh"
FAILED=0

run() { printf '%s' "$1" | "$HOOK" 2>/tmp/nm-granica-err; RC=$?; ERR=$(cat /tmp/nm-granica-err); }

check() { # имя · ожидание(есть|нет) · вывод · код · ошибки
  if [ "$4" -ne 0 ] || [ -n "$5" ]; then
    echo "  ❌ $1: скрипт упал (код $4) $5"; FAILED=$((FAILED+1)); return
  fi
  if [ "$2" = "есть" ] && [ -z "$3" ]; then echo "  ❌ $1: напоминания нет, а должно быть"; FAILED=$((FAILED+1)); return; fi
  if [ "$2" = "нет" ] && [ -n "$3" ]; then echo "  ❌ $1: напоминание есть, а не должно"; FAILED=$((FAILED+1)); return; fi
  echo "  ✅ $1"
}

S="t$$"
rm -f "${TMPDIR:-/tmp}/nm-granica-$S"*

OUT=$(printf '%s' "{\"session_id\":\"$S\",\"prompt\":\"напиши продающий текст для лендинга\"}" | "$HOOK" 2>/tmp/e); RC=$?; E=$(cat /tmp/e)
check "маркетинговый запрос ловится" есть "$OUT" "$RC" "$E"

OUT=$(printf '%s' "{\"session_id\":\"$S\",\"prompt\":\"а теперь оффер и воронку\"}" | "$HOOK" 2>/tmp/e); RC=$?; E=$(cat /tmp/e)
check "второй раз за сессию молчит" нет "$OUT" "$RC" "$E"

S2="u$$"
OUT=$(printf '%s' "{\"session_id\":\"$S2\",\"prompt\":\"сделай кнопку синей и почини ошибку\"}" | "$HOOK" 2>/tmp/e); RC=$?; E=$(cat /tmp/e)
check "обычный запрос про код не трогается" нет "$OUT" "$RC" "$E"

OUT=$(printf '%s' "{\"session_id\":\"$S2\",\"prompt\":\"кому это продавать и какую цену ставить\"}" | "$HOOK" 2>/tmp/e); RC=$?; E=$(cat /tmp/e)
check "в новой сессии снова срабатывает" есть "$OUT" "$RC" "$E"

rm -f "${TMPDIR:-/tmp}/nm-granica-$S"* "${TMPDIR:-/tmp}/nm-granica-$S2"* /tmp/e /tmp/nm-granica-err
[ "$FAILED" -eq 0 ] && echo "ПРОБА ХУКА: всё сошлось" || echo "ПРОБА ХУКА: провалов $FAILED"
exit "$FAILED"
