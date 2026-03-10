enable_network_magic(){
  # well-known docker embedded DNS is at 127.0.0.11:53
  local docker_embedded_dns_ip='127.0.0.11'

  # first we need to detect an IP to use for reaching the docker host
  local docker_host_ip
  docker_host_ip="$( (head -n1 <(timeout 5 getent ahostsv4 'host.docker.internal') | cut -d' ' -f1) || true)"
  # if the ip doesn't exist or is a loopback address use the default gateway
  if [[ -z "${docker_host_ip}" ]] || [[ $docker_host_ip =~ ^127\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    docker_host_ip=$(ip -4 route show default | cut -d' ' -f3)
  fi

  # patch docker's iptables rules to switch out the DNS IP
  iptables-save \
    | sed \
      `# switch docker DNS DNAT rules to our chosen IP` \
      -e "s/-d ${docker_embedded_dns_ip}/-d ${docker_host_ip}/g" \
      `# we need to also apply these rules to non-local traffic (from pods)` \
      -e 's/-A OUTPUT \(.*\) -j DOCKER_OUTPUT/\0\n-A PREROUTING \1 -j DOCKER_OUTPUT/' \
      `# switch docker DNS SNAT rules rules to our chosen IP` \
      -e "s/--to-source :53/--to-source ${docker_host_ip}:53/g"\
      `# nftables incompatibility between 1.8.8 and 1.8.7 omit the --dport flag on DNAT rules` \
      `# ensure --dport on DNS rules, due to https://github.com/kubernetes-sigs/kind/issues/3054` \
      -e "s/p -j DNAT --to-destination ${docker_embedded_dns_ip}/p --dport 53 -j DNAT --to-destination ${docker_embedded_dns_ip}/g" \
    | iptables-restore

  # now we can ensure that DNS is configured to use our IP
  cp /etc/resolv.conf /etc/resolv.conf.original
  replaced="$(sed -e "s/${docker_embedded_dns_ip}/${docker_host_ip}/g" /etc/resolv.conf.original)"
  if [[ "${KIND_DNS_SEARCH+x}" == "" ]]; then
    # No DNS search set, just pass through as is
    echo "$replaced" >/etc/resolv.conf
  elif [[ -z "$KIND_DNS_SEARCH" ]]; then
    # Empty search - remove all current search clauses
    echo "$replaced" | grep -v "^search" >/etc/resolv.conf
  else
    # Search set - remove all current search clauses, and add the configured search
    {
      echo "search $KIND_DNS_SEARCH";
      echo "$replaced" | grep -v "^search";
    } >/etc/resolv.conf
  fi

  local files_to_update=(
    /etc/kubernetes/manifests/etcd.yaml
    /etc/kubernetes/manifests/kube-apiserver.yaml
    /etc/kubernetes/manifests/kube-controller-manager.yaml
    /etc/kubernetes/manifests/kube-scheduler.yaml
    /etc/kubernetes/controller-manager.conf
    /etc/kubernetes/scheduler.conf
    /kind/kubeadm.conf
    /var/lib/kubelet/kubeadm-flags.env
  )
  local should_fix_certificate=false
  # fixup IPs in manifests ...
  curr_ipv4="$( (head -n1 <(timeout 5 getent ahostsv4 "$(hostname)") | cut -d' ' -f1) || true)"
  echo "INFO: Detected IPv4 address: ${curr_ipv4}" >&2
  if [ -f /kind/old-ipv4 ]; then
      old_ipv4=$(cat /kind/old-ipv4)
      echo "INFO: Detected old IPv4 address: ${old_ipv4}" >&2
      # sanity check that we have a current address
      if [[ -z $curr_ipv4 ]]; then
        echo "ERROR: Have an old IPv4 address but no current IPv4 address (!)" >&2
        exit 1
      fi
      if [[ "${old_ipv4}" != "${curr_ipv4}" ]]; then
        should_fix_certificate=true
        sed_ipv4_command="s#\b$(regex_escape_ip "${old_ipv4}")\b#${curr_ipv4}#g"
        for f in "${files_to_update[@]}"; do
          # kubernetes manifests are only present on control-plane nodes
          if [[ -f "$f" ]]; then
            sed -i "${sed_ipv4_command}" "$f"
          fi
        done
      fi
  fi
  if [[ -n $curr_ipv4 ]]; then
    echo -n "${curr_ipv4}" >/kind/old-ipv4
  fi

  # do IPv6
  curr_ipv6="$( (head -n1 <(timeout 5 getent ahostsv6 "$(hostname)") | cut -d' ' -f1) || true)"
  echo "INFO: Detected IPv6 address: ${curr_ipv6}" >&2
  if [ -f /kind/old-ipv6 ]; then
      old_ipv6=$(cat /kind/old-ipv6)
      echo "INFO: Detected old IPv6 address: ${old_ipv6}" >&2
      # sanity check that we have a current address
      if [[ -z $curr_ipv6 ]]; then
        echo "ERROR: Have an old IPv6 address but no current IPv6 address (!)" >&2
      fi
      if [[ "${old_ipv6}" != "${curr_ipv6}" ]]; then
        should_fix_certificate=true
        sed_ipv6_command="s#\b$(regex_escape_ip "${old_ipv6}")\b#${curr_ipv6}#g"
        for f in "${files_to_update[@]}"; do
          # kubernetes manifests are only present on control-plane nodes
          if [[ -f "$f" ]]; then
            sed -i "${sed_ipv6_command}" "$f"
          fi
        done
      fi
  fi
  if [[ -n $curr_ipv6 ]]; then
    echo -n "${curr_ipv6}" >/kind/old-ipv6
  fi

  if $should_fix_certificate; then
    fix_certificate
  fi
}
