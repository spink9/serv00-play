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

if [[ "$BUTTON_URL" == "null" ]]; then
  button_url="https://panel15.serv00.com"
else
  button_url=${BUTTON_URL:-"https://webssh.dgfghh.ggff.net/#encoding=utf-8&hostname=panel15.serv00.com&username=nsqdkzxaxw&password=dTMpM2lpa0IlWTJGIVcmWjM&command=ss"}
fi

# 添加Telegraph链接
if [[ "$TELEGRAPH_URL" == "null" ]]; then
  telegraph_url="https://webssh.dgfghh.ggff.net/#encoding=utf-8&hostname=panel15.serv00.com&username=nsqdkzxaxw&password=dTMpM2lpa0IlWTJGIVcmWjM&command=ss"
else
  telegraph_url=${TELEGRAPH_URL:-"https://webssh.dgfghh.ggff.net/#encoding=utf-8&hostname=panel15.serv00.com&username=nsqdkzxaxw&password=dTMpM2lpa0IlWTJGIVcmWjM&command=ss"}
fi

URL="https://api.telegram.org/bot${telegramBotToken}/sendMessage"

# 只处理一次URL替换
if [[ -n "$host" ]]; then
  button_url=$(replaceValue $button_url HOST $host)
  telegraph_url=$(replaceValue $telegraph_url HOST $host)
fi
if [[ -n "$user" ]]; then
  button_url=$(replaceValue $button_url USER $user)
  telegraph_url=$(replaceValue $telegraph_url USER $user)
fi
if [[ -n "$PASS" ]]; then
  pass=$(toBase64 $PASS)
  button_url=$(replaceValue $button_url PASS $pass)
  telegraph_url=$(replaceValue $telegraph_url PASS $pass)
fi

# 编码URL
encoded_url=$(urlencode "$button_url")
encoded_telegraph=$(urlencode "$telegraph_url")

# 只定义一次reply_markup
reply_markup='{
    "inline_keyboard": [
      [
        {"text": "点击查看", "url": "'"${encoded_url}"'"}
      ],
      [
        {"text": "打开Terminal", "url": "'"${encoded_telegraph}"'"}
      ]
    ]
  }'

# 调试信息
echo "第一个按钮URL: $encoded_url"
echo "第二个按钮URL: $encoded_telegraph"
echo "按钮结构: $reply_markup"

if [[ -z ${telegramBotToken} ]]; then
  echo "未配置TG推送"
else
  res=$(curl -s -X POST "https://api.telegram.org/bot${telegramBotToken}/sendMessage" \
    -d chat_id="${telegramBotUserId}" \
    -d parse_mode="Markdown" \
    -d text="$formatted_msg" \
    -d reply_markup="$reply_markup")
  if [ $? == 124 ]; then
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
