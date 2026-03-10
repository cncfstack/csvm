
# If /proc/self/uid_map 4294967295 mappings, we are in the initial user namespace, i.e. the host.
# Otherwise we are in a non-initial user namespace.
# https://github.com/opencontainers/runc/blob/v1.0.0-rc92/libcontainer/system/linux.go#L109-L118
# 这段代码用于检测当前是否运行在用户命名空间中。
# 通过检查/proc/self/uid_map文件内容，如果不存在"0 0 4294967295"这样的映射记录，则判断为在非初始用户命名空间中运行，设置userns="1"并输出提示信息。
# 这是容器技术中判断用户命名空间的重要方法。
userns=""
if grep -Eqv "0[[:space:]]+0[[:space:]]+4294967295" /proc/self/uid_map; then
  userns="1"
  echo 'INFO: running in a user namespace (experimental)'
fi
# 这段代码验证用户命名空间(UserNS)的配置是否正确。
# 首先检查userns变量是否为空，然后验证文件描述符限制是否至少为64000，
# 最后检查cgroup控制器(cpu、memory、pids)是否已委托，如有缺失则输出错误并退出。
validate_userns() {
  if [[ -z "${userns}" ]]; then
    return
  fi

  local nofile_hard
  nofile_hard="$(ulimit -Hn)"
  local nofile_hard_expected="64000"
  if [[ "${nofile_hard}" -lt "${nofile_hard_expected}" ]]; then
    echo "WARN: UserNS: expected RLIMIT_NOFILE to be at least ${nofile_hard_expected}, got ${nofile_hard}" >&2
  fi

  if [[ -f "/sys/fs/cgroup/cgroup.controllers" ]]; then
    for f in cpu memory pids; do
      if ! grep -qw $f /sys/fs/cgroup/cgroup.controllers; then
        echo "ERROR: UserNS: $f controller needs to be delegated" >&2
        exit 1
      fi
    done
  fi
}

