fix_machine_id() {
  # Deletes the machine-id embedded in the node image and generates a new one.
  # This is necessary because both kubelet and other components like weave net
  # use machine-id internally to distinguish nodes.
  echo 'INFO: clearing and regenerating /etc/machine-id' >&2
  rm -f /etc/machine-id
  systemd-machine-id-setup
}
