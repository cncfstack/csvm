#  debian:bookworm-slim
FROM registry.cncfstack.com/docker.io/kicbase/stable:v0.0.48

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - 
RUN clean-install nodejs \
    && groupadd  node \
    && useradd  --gid node --shell /bin/bash --create-home node \
    && node --version \
    && npm --version
ENV NODE_ENV=production

RUN echo "Ensuring scripts are executable ..." \
    && chmod +x /usr/local/bin/clean-install /usr/local/bin/entrypoint \
 && echo "Installing Packages ..." \
    && DEBIAN_FRONTEND=noninteractive clean-install \
      systemd dbus \
      conntrack iptables iproute2 ethtool socat util-linux mount ebtables udev kmod \
      libseccomp2 pigz \
      bash ca-certificates curl rsync \
      nfs-common \
      iputils-ping netcat-openbsd  \
      openssl  wget telnet  gnupg hostname lsb-release   build-essential \
      net-tools \
      openssh-server tmux \
      vim nano file unzip  less tree \
      procps iotop iftop sysstat  htop gdb strace nmap  tcpdump traceroute dnsutils lsof \
      git git-lfs \
      jq python3 \
      lz4 \
      sudo

# Install Bun (required for build scripts)
#RUN GITHUB='https://gh-proxy.com/https://github.com' curl -fsSL https://bun.sh/install | bash
RUN curl -fsSL https://bun.sh/install | bash
RUN corepack enable

# Install playwright
RUN DEBIAN_FRONTEND=noninteractive clean-install  xvfb && \
    mkdir -p /home/node/.cache/ms-playwright && \
    PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright \
    node /app/node_modules/playwright-core/cli.js install --with-deps chromium && \
    chown -R node:node /home/node/.cache/ms-playwright
#Xvfb :1 -screen 0 1280x800x24 -ac -nolisten tcp &

# Install chromium
RUN  clean-install  chromium websockify  x11vnc novnc
        
ENV PATH="/root/.bun/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"