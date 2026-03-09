#  debian:bookworm-slim
FROM registry.cncfstack.com/docker.io/kicbase/stable:v0.0.48

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - 
RUN clean-install nodejs \
    && groupadd  node \
    && useradd  --gid node --shell /bin/bash --create-home node \
    && node --version \
    && npm --version


