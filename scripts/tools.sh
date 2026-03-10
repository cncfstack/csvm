
# tools.sh
# 提供一个公共通用的工具方法

grep_allow_nomatch() {
  # grep exits 0 on match, 1 on no match, 2 on error
  grep "$@" || [[ $? == 1 ]]
}

# regex_escape_ip converts IP address string $1 to a regex-escaped literal
regex_escape_ip(){
  sed -e 's#\.#\\.#g' -e 's#\[#\\[#g' -e 's#\]#\\]#g' <<<"$1"
}

# 替换并增强系统的 update-alternatives命令
update-alternatives() {
    echo "retryable update-alternatives: $*"
    local args=$*

    for i in $(seq 0 15); do
      /usr/bin/update-alternatives $args && return || echo "update-alternatives $args failed (retry $i)"

      echo "update-alternatives diagnostics information below:"
      mount
      df -h /var
      find /var/lib/dpkg
      dmesg | tail

      sleep 1
    done

    exit 30
}
