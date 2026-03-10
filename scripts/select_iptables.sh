select_iptables() {
  # based on: https://github.com/kubernetes-sigs/iptables-wrappers/blob/97b01f43a8e8db07840fc4b95e833a37c0d36b12/iptables-wrapper-installer.sh
  local mode num_legacy_lines num_nft_lines
  num_legacy_lines=$( (iptables-legacy-save || true; ip6tables-legacy-save || true) 2>/dev/null | grep -c '^-' || true)
  num_nft_lines=$( (timeout 5 sh -c "iptables-nft-save; ip6tables-nft-save" || true) 2>/dev/null | grep -c '^-' || true)
  if [ "${num_legacy_lines}" -ge "${num_nft_lines}" ]; then
    mode=legacy
  else
    mode=nft
  fi
  echo "INFO: setting iptables to detected mode: ${mode}" >&2
  update-alternatives --set iptables "/usr/sbin/iptables-${mode}" > /dev/null
  update-alternatives --set ip6tables "/usr/sbin/ip6tables-${mode}" > /dev/null
}