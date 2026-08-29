#!/usr/bin/env bash
# ~/.config/mango/bin/weather.sh
# wttr.in weather for waybar. Weather-code mapping and day/night icon
# switching adapted from omarchy-weather-icon.

for i in 1 2 3; do
  data=$(curl -fsS --max-time 5 "https://wttr.in/Tacloban?format=j1" 2>/dev/null) && break
  sleep 5
done

if [ -z "$data" ]; then
  printf '{"text":"","class":"unavailable"}\n'
  exit 0
fi

fields=$(echo "$data" | jq -er '[
  .current_condition[0].weatherCode,
  .weather[0].astronomy[0].sunrise,
  .weather[0].astronomy[0].sunset,
  .current_condition[0].temp_C,
  .current_condition[0].weatherDesc[0].value
] | select(all(. != null and . != "")) | @tsv' 2>/dev/null) || {
  printf '{"text":"","class":"unavailable"}\n'
  exit 0
}

IFS=$'\t' read -r code sunrise sunset temp desc <<<"$fields"

now=$(date +%s)
sunrise_epoch=$(date -d "today $sunrise" +%s 2>/dev/null || echo 0)
sunset_epoch=$(date -d "today $sunset" +%s 2>/dev/null || echo 0)

night=false
if ((sunrise_epoch > 0 && sunset_epoch > 0)) &&
  ((now < sunrise_epoch || now >= sunset_epoch)); then
  night=true
fi

case $code in
113) [[ $night == true ]] && icon=$'\ue32b' || icon=$'\ue30d' ;;
116) [[ $night == true ]] && icon=$'\ue32e' || icon=$'\ue302' ;;
119 | 122) icon=$'\ue33d' ;;
143 | 248 | 260) icon=$'\ue313' ;;
176 | 263 | 266 | 293 | 296 | 353) [[ $night == true ]] && icon=$'\ue333' || icon=$'\ue308' ;;
179 | 227 | 230 | 323 | 326 | 368) [[ $night == true ]] && icon=$'\ue327' || icon=$'\ue30a' ;;
182 | 185 | 281 | 284 | 311 | 314 | 317 | 320 | 350 | 362 | 365 | 374 | 377) icon=$'\ue3ad' ;;
200 | 386 | 389 | 392 | 395) icon=$'\ue31d' ;;
299 | 302 | 305 | 308 | 356 | 359) icon=$'\ue318' ;;
329 | 332 | 335 | 338 | 371) icon=$'\ue31a' ;;
*) icon=$'\ue33d' ;;
esac

printf '{"text":"%s","tooltip":"%s  %s°C"}\n' "$icon" "$desc" "$temp"
