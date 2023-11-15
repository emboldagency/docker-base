# Use ubuntu as the base image
FROM ubuntu:22.04

# Use ARG for build-time variables
ARG LANG=C.UTF-8 \
    TZ=UTC \
    DATE_TIMEZONE=UTC \
    NODE_VERSION=20.9.0

ENV CODER_VERSION=2 \
    PULSAR_CONF_REPO="git@github.com:emboldagency/pulsar.git" \
    GEM_HOME=/home/embold/.gems \
    PATH="${PATH}:${GEM_HOME}/bin"

# Set up timezone and locale
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

# Install packages
RUN apt-get update && \
    apt-get install software-properties-common gpg-agent -y --no-install-recommends && \
    add-apt-repository -y ppa:git-core/ppa && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    apt-transport-https \
    autoconf \
    # bash \
    bison \
    build-essential \
    ca-certificates \
    cron \
    curl \
    git \
    gnupg \
    htop \
    iputils-ping \
    jq \
    less \
    libbz2-dev \
    libffi-dev \
    libfontconfig1 \
    libgdbm-dev \
    libgtk-3-0 \
    libncurses5-dev \
    libpng-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    libxi6 \
    libxml2-dev \
    libxrender1 \
    libxslt-dev \
    libxtst6 \
    libyaml-dev \
    locales \
    lsb-release \
    man \
    nano \
    rsync \
    openssh-server \
    ssh \
    sudo \
    # systemd \
    unzip \
    vim \
    whois \
    xclip \
    xsel \
    zip \
    zlib1g-dev \
    zsh \
    && rm -rf /var/lib/apt/lists/* 

RUN chsh -s $(which zsh)

# Copy configuration files
COPY conf/.ssh /coder/.ssh

# Create a non-root user and add it to the necessary groups
RUN adduser --gecos '' --disabled-password --shell /bin/zsh embold && \
    echo "embold ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

COPY configure /coder/configure

RUN curl -L https://github.com/emboldagency/nebulab-pulsar/releases/latest/download/pulsar.gem -o /coder/pulsar.gem && \
    chown -R embold:embold /coder/

USER embold

SHELL [ "bash", "-c" ]

# Install fnm, node, npm, yarn, & n 
RUN echo 'eval "$(fnm env --shell bash)"' >> /home/embold/.bashrc && \
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "/home/embold/.fnm" --skip-shell && \
    sudo ln -s /home/embold/.fnm/fnm /usr/local/bin/ && \
    sudo chmod +x /usr/local/bin/fnm && \
    # smoke test for fnm
    fnm -V && \
    /bin/bash -c "source /home/embold/.bashrc && fnm install ${NODE_VERSION}" && \
    /bin/bash -c "source /home/embold/.bashrc && fnm alias default ${NODE_VERSION}" && \
    # add fnm for bash
    /bin/bash -c 'source /home/embold/.bashrc && sudo /bin/ln -s "/home/embold/.fnm/aliases/default/bin/node" /usr/local/bin/node' && \
    /bin/bash -c 'source /home/embold/.bashrc && sudo /bin/ln -s "/home/embold/.fnm/aliases/default/bin/npm" /usr/local/bin/npm' && \
    /bin/bash -c 'source /home/embold/.bashrc && sudo /bin/ln -s "/home/embold/.fnm/aliases/default/bin/npx" /usr/local/bin/npx' && \
    npm install -g yarn n
