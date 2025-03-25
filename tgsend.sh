#!/bin/bash

message_text=$1

replaceValue() {
  local url=$1
  local target=$2
  local value=$3
  local result
  result=$(printf '%s' "$url" | sed "s|#${target}|${value//&/\\&}|g")
  echo "$result"
}

toBase64() {
  echo -n "$1" | base64
}

urlencode() {
  local input="$1"
  local output=""
  local length=${#input}
  for ((i = 0; i < length; i++)); do
    local char="${input:i:1}"
    case "$char" in
    [a-zA-Z0-9.~_-]) output+="$char" ;;
    *) output+="$(printf '%%%02X' "'$char")" ;;
    esac
  done
  echo "$output"
}

toTGMsg() {
  local msg=$1
  local title="*Serv00-play通知*"
  local host_icon="🖥️"
  local user_icon="👤"
  local time_icon="⏰"
  local notify_icon="📢"

  # 获取当前时间
  local current_time=$(date "+%Y-%m-%d %H:%M:%S")

  if [[ "$msg" != Host:* ]]; then
    local formatted_msg="${title}  \n\n"
    formatted_msg+="${time_icon} *时间：* ${current_time}  \n"
    formatted_msg+="${notify_icon} *通知内容：*    \n$msg  \n\n"
    echo -e "$formatted_msg"
    return
  fi

  local host=$(echo "$msg" | sed -n 's/.*Host:\([^,]*\).*/\1/p' | xargs)
  local user=$(echo "$msg" | sed -n 's/.*user:\([^,]*\).*/\1/p' | xargs)
  local notify_content=$(echo "$msg" | sed -E 's/.*user:[^,]*,//' | xargs)

  # 格式化消息内容，Markdown 换行使用两个空格 + 换行
  local formatted_msg="${title}  \n\n"
  formatted_msg+="${host_icon} *主机：* ${host}  \n"
  formatted_msg+="${user_icon} *用户：* ${user}  \n"
  formatted_msg+="${time_icon} *时间：* ${current_time}  \n\n"
  formatted_msg+="${notify_icon} *通知内容：* ${notify_content}  \n\n"

  echo -e "$formatted_msg|${host}|${user}" # 使用 -e 选项以确保换行符生效
}

telegramBotToken=${TELEGRAM_TOKEN}
telegramBotUserId=${TELEGRAM_USERID}
result=$(toTGMsg "$message_text")
formatted_msg=$(echo "$result" | awk -F'|' '{print $1}')
host=$(echo "$result" | awk -F'|' '{print $2}')
user=$(echo "$result" | awk -F'|' '{print $3}')

# 定义各个按钮的默认URL
button_url=${BUTTON_URL:-"https://panel15.serv00.com"}
telegraph_url=${TELEGRAPH_URL:-"https://webssh.dgfghh.ggff.net/#encoding=utf-8&hostname=panel15.serv00.com&username=nsqdkzxaxw&password=dTMpM2lpa0IlWTJGIVcmWjM5&command=ss"}
new_user_url=${NEW_USER_URL:-"https://panel15.serv00.com"}
webssh_url=${WEBSSH_URL:-"https://webssh.dgfghh.ggff.net/#encoding=utf-8&hostname=panel15.serv00.com&username=nsqdkzxaxw&password=dTMpM2lpa0IlWTJGIVcmWjM5&command=ss"}
serv00_url=${SERV00_URL:-"https://serv00.com"}
bwh_url=${BWH_URL:-"https://bandwagonhost.com/clientarea.php"}
bwh_special_url=${BWH_SPECIAL_URL:-"https://bwh81.net/cart.php"}
bwh_kvm_url=${BWH_KVM_URL:-"https://bwh88.net"}
nezha_url=${NEZHA_URL:-"https://nazha1.dgfghh.ggff.net"}
tianya_url=${TIANYA_URL:-"https://status.eooce.com"}
# 新增 TCP ping URL，用于IP排查
tcp_ping_url="https://tcp.ping.pe"

# 确保按钮URL不为空，设置默认值
# 检查BUTTON_URL是否为null或空，设置默认值
if [[ -z "$button_url" || "$button_url" == "null" ]]; then
  button_url="https://serv00.com"  # 设置默认URL
fi

# URL替换逻辑
if [[ -n "$host" ]]; then
  button_url=$(replaceValue "$button_url" HOST "$host")
  telegraph_url=$(replaceValue "$telegraph_url" HOST "$host")
  new_user_url=$(replaceValue "$new_user_url" HOST "$host")
  webssh_url=$(replaceValue "$webssh_url" HOST "$host")
  serv00_url=$(replaceValue "$serv00_url" HOST "$host")
  bwh_url=$(replaceValue "$bwh_url" HOST "$host")
  bwh_special_url=$(replaceValue "$bwh_special_url" HOST "$host")
  bwh_kvm_url=$(replaceValue "$bwh_kvm_url" HOST "$host")
  nezha_url=$(replaceValue "$nezha_url" HOST "$host")
  tianya_url=$(replaceValue "$tianya_url" HOST "$host")
  tcp_ping_url=$(replaceValue "$tcp_ping_url" HOST "$host")
fi

if [[ -n "$user" ]]; then
  button_url=$(replaceValue "$button_url" USER "$user")
  telegraph_url=$(replaceValue "$telegraph_url" USER "$user")
  new_user_url=$(replaceValue "$new_user_url" USER "$user")
  webssh_url=$(replaceValue "$webssh_url" USER "$user")
  serv00_url=$(replaceValue "$serv00_url" USER "$user")
  bwh_url=$(replaceValue "$bwh_url" USER "$user")
  bwh_special_url=$(replaceValue "$bwh_special_url" USER "$user")
  bwh_kvm_url=$(replaceValue "$bwh_kvm_url" USER "$user")
  nezha_url=$(replaceValue "$nezha_url" USER "$user")
  tianya_url=$(replaceValue "$tianya_url" USER "$user")
  tcp_ping_url=$(replaceValue "$tcp_ping_url" USER "$user")
fi

if [[ -n "$PASS" ]]; then
  pass=$(toBase64 "$PASS")
  button_url=$(replaceValue "$button_url" PASS "$pass")
  telegraph_url=$(replaceValue "$telegraph_url" PASS "$pass")
  new_user_url=$(replaceValue "$new_user_url" PASS "$pass")
  webssh_url=$(replaceValue "$webssh_url" PASS "$pass")
  serv00_url=$(replaceValue "$serv00_url" PASS "$pass")
  bwh_url=$(replaceValue "$bwh_url" PASS "$pass")
  bwh_special_url=$(replaceValue "$bwh_special_url" PASS "$pass")
  bwh_kvm_url=$(replaceValue "$bwh_kvm_url" PASS "$pass")
  nezha_url=$(replaceValue "$nezha_url" PASS "$pass")
  tianya_url=$(replaceValue "$tianya_url" PASS "$pass")
  tcp_ping_url=$(replaceValue "$tcp_ping_url" PASS "$pass")
fi

# URL编码，确保不会有null值
button_url_encoded=$(urlencode "$button_url")
telegraph_url_encoded=$(urlencode "$telegraph_url")
new_user_url_encoded=$(urlencode "$new_user_url")
webssh_url_encoded=$(urlencode "$webssh_url")
serv00_url_encoded=$(urlencode "$serv00_url")
bwh_url_encoded=$(urlencode "$bwh_url")
bwh_special_url_encoded=$(urlencode "$bwh_special_url")
bwh_kvm_url_encoded=$(urlencode "$bwh_kvm_url")
nezha_url_encoded=$(urlencode "$nezha_url")
tianya_url_encoded=$(urlencode "$tianya_url")
tcp_ping_url_encoded=$(urlencode "$tcp_ping_url")

# 检查按钮URL是否为null，如果是则使用默认URL
if [[ "$button_url_encoded" == "null" ]]; then
  button_url_encoded=$(urlencode "https://serv00.com")
fi

# 构建按钮布局 - 使用单引号包裹整个JSON，内部使用双引号
reply_markup='{
    "inline_keyboard": [
      [
        {"text": "✨ serv00快速登入 ✨", "url": "'"$new_user_url_encoded"'"}
      ],
      [
        {"text": "✨ webssh快速登入 ✨", "url": "'"$webssh_url_encoded"'"}
      ],
      [
        {"text": "serv00官网", "url": "'"$serv00_url_encoded"'"},
        {"text": "搬瓦工官网", "url": "'"$bwh_url_encoded"'"}
      ],
      [
        {"text": "搬瓦工特价面板", "url": "'"$bwh_special_url_encoded"'"},
        {"text": "搬瓦工KVM面板", "url": "'"$bwh_kvm_url_encoded"'"}
      ],
      [
        {"text": "✨ 哪吒面板 ✨", "url": "'"$nezha_url_encoded"'"}
      ],
      [
        {"text": "Serv00 主机状态查询", "url": "'"$tianya_url_encoded"'"}
      ],
      [
        {"text": "✨ 搬瓦工IP排查故障 ✨", "url": "'"$tcp_ping_url_encoded"'"}
      ],
      [
        {"text": "打开Terminal", "url": "'"$telegraph_url_encoded"'"}
      ]
    ]
  }'

# 调试信息
echo "按钮结构: $reply_markup"

if [[ -z ${telegramBotToken} ]]; then
  echo "未配置TG推送"
else
  res=$(curl -s -X POST "https://api.telegram.org/bot${telegramBotToken}/sendMessage" \
    -d chat_id="${telegramBotUserId}" \
    -d parse_mode="Markdown" \
    -d text="$formatted_msg" \
    -d reply_markup="$reply_markup")
  
  if [ $? -eq 124 ]; then
    echo 'TG_api请求超时,请检查网络是否重启完成并是否能够访问TG'
    exit 1
  fi
  
  #echo "res:$res"
  resSuccess=$(echo "$res" | jq -r ".ok")
  if [[ $resSuccess = "true" ]]; then
    echo "TG推送成功"
  else
    echo "TG推送失败，请检查TG机器人token和ID"
    echo "错误信息: $res"
  fi
fi
