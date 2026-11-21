A="${ADB:-adb}"  # 改成你的 adb 位置
# tap by text: ui.sh tap "文字" ; ui.sh dump
dump(){ "$A" shell 'uiautomator dump /sdcard/u.xml >/dev/null; cat /sdcard/u.xml' | tr '>' '\n' | grep -oE 'text="[^"]*"[^/]*bounds="[^"]+"' | sed -E 's/text="([^"]*)".*bounds="([^"]+)"/\1 \2/' | grep -v '^ '; }
tap(){ b=$(dump | grep -F "$1" | head -1 | grep -oE '\[[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+\]' | tr -d '[]' | tr ',' ' '); set -- $b; [ -z "$1" ] && { echo "找不到"; return 1; }; "$A" shell input tap $(( ($1+$3)/2 )) $(( ($2+$4)/2 )); }
"$@"
