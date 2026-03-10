retryable_fix_cgroup() {
    for i in $(seq 0 10); do
      fix_cgroup && return || echo "fix_cgroup failed with exit code $? (retry $i)"
      echo "fix_cgroup diagnostics information below:"
      mount
      sleep 1
    done

    exit 31
}


fix_cgroup() {
  if [[ -f "/sys/fs/cgroup/cgroup.controllers" ]]; then
    echo 'INFO: detected cgroup v2'
    # Both Docker and Podman enable CgroupNS on cgroup v2 hosts by default.
    #
    # So mostly we do not need to mess around with the cgroup path stuff,
    # however, we still need to create the "/kubelet" cgroup at least.
    # (Otherwise kubelet fails with `cgroup-root ["kubelet"] doesn't exist` error, see #1969)
    #
    # The "/kubelet" cgroup is created in ExecStartPre of the kubeadm service.
    #
    # [FAQ: Why not create "/kubelet" cgroup here?]
    # We can't create the cgroup with controllers here, because /sys/fs/cgroup/cgroup.subtree_control is empty.
    # And yet we can't write controllers to /sys/fs/cgroup/cgroup.subtree_control by ourselves either, because
    # /sys/fs/cgroup/cgroup.procs is not empty at this moment.
    #
    # After switching from this entrypoint script to systemd, systemd evacuates the processes in the root
    # group to "/init.scope" group, so we can write the root subtree_control and create "/kubelet" cgroup.
    return
  fi
  echo 'INFO: detected cgroup v1'
  # We're looking for the cgroup-path for the cpu controller for the
  # current process. this tells us what cgroup-path the container is in.
  local current_cgroup
  current_cgroup=$(grep -E '^[^:]*:([^:]*,)?cpu(,[^,:]*)?:.*' /proc/self/cgroup | cut -d: -f3)
  if [ "$current_cgroup" = "/" ]; then
    echo "INFO: cgroupns detected, no need to fix cgroups"
    return
  fi

  # NOTE The rest of this function deals with the unfortunate situation of
  # cgroup v1 with no cgroupns enabled. One fine day every user will have
  # cgroupns enabled (or switch or cgroup v2 which has it enabled by default).
  # Once that happens, this function can be removed completely.

  echo 'WARN: cgroupns not enabled! Please use cgroup v2, or cgroup v1 with cgroupns enabled.'

  # See: https://d2iq.com/blog/running-kind-inside-a-kubernetes-cluster-for-continuous-integration
  # Capture initial state before modifying
  #
  # Then we collect the subsystems that are active on our current process.
  # We assume the cpu controller is in use on all node containers,
  # and other controllers use the same sub-path.
  #
  # See: https://man7.org/linux/man-pages/man7/cgroups.7.html
  echo 'INFO: fix cgroup mounts for all subsystems'
  local cgroup_subsystems
  cgroup_subsystems=$(findmnt -lun -o source,target -t cgroup | grep -F "${current_cgroup}" | awk '{print $2}')
  # Unmount the cgroup subsystems that are not known to runtime used to
  # run the container we are in. Those subsystems are not properly scoped
  # (i.e. the root cgroup is exposed, rather than something like docker/xxxx).
  # In case a runtime (which is aware of more subsystems -- such as rdma,
  # misc, or unified) is used inside the container, it may create cgroups for
  # these subsystems, and as they are not scoped, they will leak to the host
  # and thus will become non-removable.
  #
  # See https://github.com/kubernetes/kubernetes/issues/109182
  local unsupported_cgroups
  unsupported_cgroups=$(findmnt -lun -o source,target -t cgroup | grep_allow_nomatch -v -F "${current_cgroup}" | awk '{print $2}')
  if [ -n "$unsupported_cgroups" ]; then
    local mnt
    echo "$unsupported_cgroups" |
    while IFS= read -r mnt; do
      echo "INFO: unmounting and removing $mnt"
      umount "$mnt" || true
      rmdir "$mnt" || true
    done
  fi


  # For each cgroup subsystem, Docker does a bind mount from the current
  # cgroup to the root of the cgroup subsystem. For instance:
  #   /sys/fs/cgroup/memory/docker/<cid> -> /sys/fs/cgroup/memory
  #
  # This will confuse Kubelet and cadvisor and will dump the following error
  # messages in kubelet log:
  #   `summary_sys_containers.go:47] Failed to get system container stats for ".../kubelet.service"`
  #
  # This is because `/proc/<pid>/cgroup` is not affected by the bind mount.
  # The following is a workaround to recreate the original cgroup
  # environment by doing another bind mount for each subsystem.
  local cgroup_mounts
  # xref: https://github.com/kubernetes/minikube/pull/9508
  # Example inputs:
  #
  # Docker:               /docker/562a56986a84b3cd38d6a32ac43fdfcc8ad4d2473acf2839cbf549273f35c206 /sys/fs/cgroup/devices rw,nosuid,nodev,noexec,relatime shared:143 master:23 - cgroup devices rw,devices
  # podman:               /libpod_parent/libpod-73a4fb9769188ae5dc51cb7e24b9f2752a4af7b802a8949f06a7b2f2363ab0e9 ...
  # Cloud Shell:          /kubepods/besteffort/pod3d6beaa3004913efb68ce073d73494b0/accdf94879f0a494f317e9a0517f23cdd18b35ff9439efd0175f17bbc56877c4 /sys/fs/cgroup/memory rw,nosuid,nodev,noexec,relatime master:19 - cgroup cgroup rw,memory
  # GitHub actions #9304: /actions_job/0924fbbcf7b18d2a00c171482b4600747afc367a9dfbeac9d6b14b35cda80399 /sys/fs/cgroup/memory rw,nosuid,nodev,noexec,relatime shared:263 master:24 - cgroup cgroup rw,memory
  cgroup_mounts=$(grep -E -o '/[[:alnum:]].* /sys/fs/cgroup.*.*cgroup' /proc/self/mountinfo || true)
  if [[ -n "${cgroup_mounts}" ]]; then
    local mount_root
    mount_root=$(head -n 1 <<<"${cgroup_mounts}" | cut -d' ' -f1)
    for mount_point in $(echo "${cgroup_mounts}" | cut -d' ' -f 2); do
      # bind mount each mount_point to mount_point + mount_root
      # mount --bind /sys/fs/cgroup/cpu /sys/fs/cgroup/cpu/docker/fb07bb6daf7730a3cb14fc7ff3e345d1e47423756ce54409e66e01911bab2160
      local target="${mount_point}${mount_root}"
      if ! findmnt "${target}"; then
        mkdir -p "${target}"
        mount --bind "${mount_point}" "${target}"
      fi
    done
  fi
  # kubelet will try to manage cgroups / pods that are not owned by it when
  # "nesting" clusters, unless we instruct it to use a different cgroup root.
  # We do this, and when doing so we must fixup this alternative root
  # currently this is hardcoded to be /kubelet
  # under systemd cgroup driver, kubelet appends .slice
  mount --make-rprivate /sys/fs/cgroup
}
