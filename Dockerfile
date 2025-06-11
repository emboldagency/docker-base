ARG UBUNTU_VERSION=24.04 \
    NODE_VERSION=20.19.0

# Use Ubuntu as the base image
FROM ubuntu:${UBUNTU_VERSION}
ARG NODE_VERSION

ENV DATE_TIMEZONE=UTC \
    LANG=en_US.utf8 \
    TZ=UTC \
    # Ruby
    BUNDLE_DISABLE_SHARED_GEMS=1 \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
    PULSAR_CONF_REPO="git@github.com:emboldagency/pulsar.git"

# Install base system tools, required to build most packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    apt-transport-https \
    curl \
    gpg-agent \
    locales \
    lsb-release \
    software-properties-common \
    tzdata \
    # Setup locale and timezone
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias $LANG \
    # Add repositories and install the rest...
    && add-apt-repository -y universe \
    && add-apt-repository -y ppa:git-core/ppa \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update  \
    && apt-get install -y --no-install-recommends \
    autoconf \
    bison \
    build-essential \
    ca-certificates \
    cron \
    gnupg \
    libbz2-dev \
    libcurl4-openssl-dev \
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
    xdg-utils \
    # Install system administration tools
    && apt-get install -y --no-install-recommends \
    bat \
    dnsutils \
    fd-find \
    file \
    fzf \
    gh \
    git \
    htop \
    iputils-ping \
    jq \
    less \
    lsof \
    man \
    mc \
    nano \
    ncdu \
    net-tools \
    nmap \
    openssh-server \
    p7zip-full \
    python3 \
    python3-pip \
    ripgrep \
    rsync \
    screen \
    ssh \
    strace \
    sudo \
    sysstat \
    telnet \
    tmux \
    traceroute \
    tree \
    unzip \
    vim \
    wget \
    whois \
    xclip \
    xsel \
    zip \
    zlib1g-dev \
    zsh \
    && rm -rf /var/lib/apt/lists/*

# Copy configuration files
COPY coder /coder

# Configure environment
RUN ln -s /coder/conf/sshd_config /etc/ssh/sshd_config.d/embold.conf \
    # Create a non-root user and add it to the necessary groups
    && adduser --gecos '' --disabled-password --shell /bin/zsh embold \
    && echo "embold ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd \
    && chown -R embold:embold /coder \
    && chmod 774 /coder \
    # skip installing gem documentation
    && mkdir -p /usr/local/etc; \
    { \
    echo 'install: --no-document'; \
    echo 'update: --no-document'; \
    } >> /usr/local/etc/gemrc \
    # add ruby-build
    && git clone https://github.com/rbenv/ruby-build.git /coder/ruby-build \
    && PREFIX=/usr/local /coder/ruby-build/install.sh \
    && rm -rf /coder/ruby-build

USER embold

SHELL [ "bash", "-c" ]

# Install user packages
RUN echo 'eval "$(fnm env --shell bash)"' >> /home/embold/.bashrc \
    && curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "/home/embold/.fnm" --skip-shell \
    && sudo ln -s /home/embold/.fnm/fnm /usr/local/bin/ \
    && sudo chmod +x /usr/local/bin/fnm \
    # smoke test for fnm
    && fnm -V  \
    && /bin/bash -c "source /home/embold/.bashrc && fnm install ${NODE_VERSION}" \
    && /bin/bash -c "source /home/embold/.bashrc && fnm alias default ${NODE_VERSION}" \
    # add fnm for shell
    && /bin/bash -c 'source /home/embold/.bashrc && sudo /bin/ln -s "/home/embold/.fnm/aliases/default/bin/node" /usr/local/bin/node' \
    && /bin/bash -c 'source /home/embold/.bashrc && sudo /bin/ln -s "/home/embold/.fnm/aliases/default/bin/npm" /usr/local/bin/npm' \
    && /bin/bash -c 'source /home/embold/.bashrc && sudo /bin/ln -s "/home/embold/.fnm/aliases/default/bin/npx" /usr/local/bin/npx' \
    && npm install -g yarn n
