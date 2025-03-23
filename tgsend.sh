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
  local login_icon="🔑"
  local server_icon="🌐"
  local home_icon="📁"
  local web_icon="🌍"

  # 获取当前时间
  local current_time=$(date "+%Y-%m-%d %H:%M:%S")
  
  # 设置默认值
  local host=${HOST:-"s15.serv00.com"}
  local user=${USER:-"admin"}
  local login=${LOGIN:-"nsqdkzxaxw"}
  local notify_content="$msg"
  
  # 尝试从消息中提取信息
  if [[ "$msg" == *"Host:"* ]]; then
    host=$(echo "$msg" | sed -n 's/.*Host:\([^,]*\).*/\1/p' | xargs)
    user=$(echo "$msg" | sed -n 's/.*user:\([^,]*\).*/\1/p' | xargs)
    notify_content=$(echo "$msg" | sed -E 's/.*user:[^,]*,//' | xargs)
  fi
  
  # 提取主机编号
  local host_number=$(echo "$host" | grep -o -E '[0-9]+' | head -1)
  if [[ -z "$host_number" ]]; then
    host_number="15"  # 默认值
  fi
  
  local ssh_server="s${host_number}.serv00.com"
  local home_dir="/usr/home/${login}"
  local webpanel="https://panel${host_number}.serv00.com/"

  # 格式化消息内容，Markdown 换行使用两个空格 + 换行
  local formatted_msg="${title}  \n\n"
  formatted_msg+="${time_icon} *时间：* ${current_time}  \n"
  formatted_msg+="${host_icon} *主机：* ${host}  \n"
  formatted_msg+="${user_icon} *用户：* ${user}  \n"
  formatted_msg+="${login_icon} *Login：* ${login}  \n"
  formatted_msg+="${server_icon} *SSH/SFTP server address：* ${ssh_server}  \n"
  formatted_msg+="${home_icon} *Home directory：* ${home_dir}  \n"
  formatted_msg+="${web_icon} *DevilWEB webpanel：* ${webpanel}  \n\n"
  formatted_msg+="${notify_icon} *通知内容：* ${notify_content}  \n\n"

  echo -e "$formatted_msg|${host}|${user}|${login}|${ssh_server}|${home_dir}|${webpanel}"
}

telegramBotToken=${TELEGRAM_TOKEN}
telegramBotUserId=${TELEGRAM_USERID}
# 从环境变量获取登录信息（如果有）
export LOGIN=${LOGIN:-"nsqdkzxaxw"}

# 生成通知内容
result=$(toTGMsg "$message_text")
formatted_msg=$(echo "$result" | awk -F'|' '{print $1}')
host=$(echo "$result" | awk -F'|' '{print $2}')
user=$(echo "$result" | awk -F'|' '{print $3}')
login=$(echo "$result" | awk -F'|' '{print $4}')
ssh_server=$(echo "$result" | awk -F'|' '{print $5}')
home_dir=$(echo "$result" | awk -F'|' '{print $6}')
webpanel=$(echo "$result" | awk -F'|' '{print $7}')

# 调试信息
echo "解析后的主机: $host"
echo "解析后的用户: $user"
echo "解析后的登录: $login"
echo "解析后的SSH服务器: $ssh_server"
echo "解析后的主目录: $home_dir"
echo "解析后的网页面板: $webpanel"

# 设置按钮URL
if [[ "$BUTTON_URL" == "null" ]]; then
  button_url=${webpanel:-"https://panel15.serv00.com"}
else
  button_url=${BUTTON_URL:-"https://webssh.dgfghh.ggff.net/#encoding=utf-8&hostname=${ssh_server}&username=${login}&password=dTMpM2lpa0IlWTJGIVcmWjM5&command=ss"}
fi

# 添加Terminal链接
if [[ "$TELEGRAPH_URL" == "null" ]]; then
  telegraph_url="https://webssh.dgfghh.ggff.net/#encoding=utf-8&hostname=${ssh_server}&username=${login}&password=dTMpM2lpa0IlWTJGIVcmWjM5&command=ss"
else
  telegraph_url=${TELEGRAPH_URL:-"https://webssh.dgfghh.ggff.net/#encoding=utf-8&hostname=${ssh_server}&username=${login}&password=dTMpM2lpa0IlWTJGIVcmWjM5&command=ss"}
fi

URL="https://api.telegram.org/bot${telegramBotToken}/sendMessage"

# 处理URL替换
if [[ -n "$host" ]]; then
  button_url=$(replaceValue "$button_url" HOST "$host")
  telegraph_url=$(replaceValue "$telegraph_url" HOST "$host")
fi
if [[ -n "$user" ]]; then
  button_url=$(replaceValue "$button_url" USER "$user")
  telegraph_url=$(replaceValue "$telegraph_url" USER "$user")
fi
if [[ -n "$login" ]]; then
  button_url=$(replaceValue "$button_url" LOGIN "$login")
  telegraph_url=$(replaceValue "$telegraph_url" LOGIN "$login")
fi
if [[ -n "$PASS" ]]; then
  pass=$(toBase64 "$PASS")
  button_url=$(replaceValue "$button_url" PASS "$pass")
  telegraph_url=$(replaceValue "$telegraph_url" PASS "$pass")
fi

# 编码URL
encoded_url=$(urlencode "$button_url")
encoded_telegraph=$(urlencode "$telegraph_url")

# 定义reply_markup
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
echo "第一个按钮URL: $button_url"
echo "第二个按钮URL: $telegraph_url"
echo "编码后的第一个按钮URL: $encoded_url"
echo "编码后的第二个按钮URL: $encoded_telegraph"
echo "按钮结构: $reply_markup"

if [[ -z ${telegramBotToken} ]]; then
  echo "未配置TG推送"
else
  echo "正在使用以下内容推送TG:"
  echo "------格式化消息内容------"
  echo -e "$formatted_msg"
  echo "----------------------------"
  
  res=$(curl -s -X POST "https://api.telegram.org/bot${telegramBotToken}/sendMessage" \
    -d chat_id="${telegramBotUserId}" \
    -d parse_mode="Markdown" \
    -d text="$formatted_msg" \
    -d reply_markup="$reply_markup")
  if [ $? == 124 ]; then
    echo 'TG_api请求超时,请检查网络是否重启完成并是否能够访问TG'
    exit 1
  fi
  
  echo "TG API响应: $res"
  resSuccess=$(echo "$res" | jq -r ".ok" 2>/dev/null)
  if [[ $resSuccess = "true" ]]; then
    echo "TG推送成功"
  else
    echo "TG推送失败，请检查TG机器人token和ID"
    echo "错误信息: $res"
  fi
fi
