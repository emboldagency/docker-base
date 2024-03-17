ARG UBUNTU_VERSION=22.04 \
    NODE_VERSION=20.9.0

# Use ubuntu as the base image
FROM ubuntu:${UBUNTU_VERSION}

ARG NODE_VERSION

ENV DATE_TIMEZONE=UTC \
    LANG=en_US.utf8 \
    TZ=UTC \
    # Ruby
    GEM_HOME=/home/embold/.gems \
    BUNDLE_APP_CONFIG=/home/embold/.gems \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
    PATH="${PATH}:/home/embold/.gems/bin" \
    PULSAR_CONF_REPO="git@github.com:emboldagency/pulsar.git"

# Copy configuration files
COPY coder /coder

# Set up timezone and locale
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    # Install packages
    && apt-get update \
    && apt-get install software-properties-common gpg-agent curl -y --no-install-recommends \
    && add-apt-repository -y ppa:git-core/ppa \
    && add-apt-repository -y universe \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    # Install Packages
    && apt-get update  \
    && apt-get install -y --no-install-recommends \
    apt-transport-https \
    autoconf \
    bison \
    build-essential \
    ca-certificates \
    cron \
    git \
    gh \
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
    && rm -rf /var/lib/apt/lists/* \
    # Install locale
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    # Create a non-root user and add it to the necessary groups
    && chsh -s $(which zsh) \
    && ln -s /coder/conf/sshd_config /etc/ssh/sshd_config.d/embold.conf \
    # Create a non-root user and add it to the necessary groups
    && adduser --gecos '' --disabled-password --shell /bin/zsh embold \
    && echo "embold ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd \
    && curl -sL https://github.com/emboldagency/nebulab-pulsar/releases/latest/download/pulsar.gem -o /coder/pulsar.gem \
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
    && npm install -g yarn n \
    # add fzf for smarter CD
    && sudo apt-get update \
    && sudo apt-get install fzf bat -y \
    && sudo rm -rf /var/lib/apt/lists/*
