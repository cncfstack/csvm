FROM registry.cncfstack.com/docker.io/library/debian:bookworm-20260223-slim

LABEL org.opencontainers.image.base.name="docker.io/library/node:22.21-trixie" \
  org.opencontainers.image.source="https://cncfstack.com" \
  org.opencontainers.image.url="https://cncfstack.com" \
  org.opencontainers.image.documentation="https://cncfstack.com" \
  org.opencontainers.image.licenses="MIT" \
  org.opencontainers.image.title="csvm" \
  org.opencontainers.image.description="CSVM (CncfStack Virtal Machine) is a container image like vm"

USER root

WORKDIR /root

# copy in static files (configs, scripts)
COPY kernel/10-network-security.conf /etc/sysctl.d/10-network-security.conf
COPY kernel/11-tcp-mtu-probing.conf /etc/sysctl.d/11-tcp-mtu-probing.conf
COPY tools/clean-install /usr/local/bin/clean-install
COPY tools/entrypoint /usr/local/bin/entrypoint
COPY scripts/ /scripts
COPY apt.d/debian.sources /etc/apt/sources.list.d/debian.sources

RUN echo "Ensuring scripts are executable ..." \
    && chmod +x /usr/local/bin/clean-install /usr/local/bin/entrypoint \
 && echo "Installing Packages ..." \
    && DEBIAN_FRONTEND=noninteractive clean-install \
      systemd dbus mount udev kmod conntrack iptables iproute2 ethtool libseccomp2 \
      bash ca-certificates curl openssl  wget telnet  gnupg hostname lsb-release  sudo \
      build-essential util-linux \
      vim nano file unzip  less lz4 \
      dnsutils lsof net-tools iputils-ping \
      openssh-server git python3  jq cron \
    && find /lib/systemd/system/sysinit.target.wants/ -name "systemd-tmpfiles-setup.service" -delete \
    && rm -f /lib/systemd/system/multi-user.target.wants/* \
    && rm -f /etc/systemd/system/*.wants/* \
    && rm -f /lib/systemd/system/local-fs.target.wants/* \
    && rm -f /lib/systemd/system/sockets.target.wants/*udev* \
    && rm -f /lib/systemd/system/sockets.target.wants/*initctl* \
    && rm -f /lib/systemd/system/basic.target.wants/* \
    && echo "ReadKMsg=no" >> /etc/systemd/journald.conf \
    && ln -s /usr/lib/systemd/systemd /sbin/init \
 && echo "Adjusting systemd-tmpfiles timer" \
    && sed -i /usr/lib/systemd/system/systemd-tmpfiles-clean.timer -e 's#OnBootSec=.*#OnBootSec=1min#' \
 && echo "Disabling udev" \
    && systemctl disable udev.service \
 && echo "Masking systemd-binfmt to prevent host config corruption (covers all formats: python, qemu, rosetta, etc) - issue #17700" \
    && systemctl mask systemd-binfmt.service \
 && echo "Modifying /etc/nsswitch.conf to prefer hosts" \
    && sed -i /etc/nsswitch.conf -re 's#^(hosts:\s*).*#\1dns files#' \
 && echo "enable services" \
    && systemctl enable cron \
    && systemctl enable ssh 

# Install Docker
COPY apt.d/docker.sources /etc/apt/sources.list.d/docker.sources
RUN curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
   && chmod a+r /etc/apt/keyrings/docker.gpg \
   && clean-install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
   && systemctl enable docker.service


EXPOSE 22

# Deleting leftovers
RUN rm -rf \
  /usr/share/doc/* \
  /usr/share/man/* \
  /usr/share/local/*

# tell systemd that it is in docker (it will check for the container env)
# https://systemd.io/CONTAINER_INTERFACE/
ENV container=docker
# systemd exits on SIGRTMIN+3, not SIGTERM (which re-executes it)
# https://bugzilla.redhat.com/show_bug.cgi?id=1201657
STOPSIGNAL SIGRTMIN+3
# NOTE: this is *only* for documentation, the entrypoint is overridden later
ENTRYPOINT [ "/usr/local/bin/entrypoint", "/sbin/init" ]