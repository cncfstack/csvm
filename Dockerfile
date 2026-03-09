#  debian:bookworm-slim
FROM registry.cncfstack.com/docker.io/kicbase/stable:v0.0.48

RUN curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - 
RUN clean-install nodejs \
    && node --version \
    && npm --version