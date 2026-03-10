fix_mount() {
  echo 'INFO: ensuring we can execute mount/umount even with userns-remap'
  # necessary only when userns-remap is enabled on the host, but harmless
  # The binary /bin/mount should be owned by root and have the setuid bit
  chown root:root "$(which mount)" "$(which umount)"
  chmod -s "$(which mount)" "$(which umount)"

  # This is a workaround to an AUFS bug that might cause `Text file
  # busy` on `mount` command below. See more details in
  # https://github.com/moby/moby/issues/9547
  if [[ "$(stat -f -c %T "$(which mount)")" == 'aufs' ]]; then
    echo 'INFO: detected aufs, calling sync' >&2
    sync
  fi

  echo 'INFO: remounting /sys read-only'
  # systemd-in-a-container should have read only /sys
  # https://systemd.io/CONTAINER_INTERFACE/
  # however, we need other things from `docker run --privileged` ...
  # and this flag also happens to make /sys rw, amongst other things
  #
  # This step is ignored when running inside UserNS, because it fails with EACCES.
  if ! mount -o remount,ro /sys; then
    if [[ -n "$userns" ]]; then
      echo 'INFO: UserNS: ignoring mount fail' >&2
    else
      exit 1
    fi
  fi

  echo 'INFO: making mounts shared' >&2
  # for mount propagation
  mount --make-rshared /
}