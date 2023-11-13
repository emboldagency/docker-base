# Use ubuntu as the base image
FROM ubuntu:22.04

# Use ARG for build-time variables
ARG LANG=C.UTF-8 \
    TZ=UTC \
    DATE_TIMEZONE=UTC \
    NODE_VERSION=20.9.0

ENV CODER_VERSION=2

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

# Install node and npm
# RUN curl https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz | \
#     tar xzfv - \
#     --exclude=CHANGELOG.md \
#     --exclude=LICENSE \
#     --exclude=README.md \
#     --strip-components 1 -C /usr/local/

# Install yarn and n
# RUN npm install -g yarn n && \
#     n $NODE_VERSION

# Copy configuration files
COPY conf/watches.conf /etc/systctl.d/watches.conf
COPY conf/.pulsar /coder/.pulsar
COPY conf/.ssh /coder/.ssh

# # Download intellij-idea-ultimate
# RUN mkdir -p /opt/idea && \
#     curl -L "https://download.jetbrains.com/product?code=IU&latest&distribution=linux" | \
#     tar -C /opt/idea --strip-components 1 -xzvf - && \
#     ln -s /opt/idea/bin/idea.sh /usr/bin/intellij-idea-ultimate

# Create a non-root user and add it to the necessary groups
RUN adduser --gecos '' --disabled-password --shell /bin/zsh embold && \
    echo "embold ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

COPY configure /coder/configure

USER embold

RUN curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir '/home/embold/.fnm' --skip-shell && \
    sudo chmod +x /home/embold/.fnm/fnm && \
    eval "$(fnm env)" && \
    fnm install ${NODE_VERSION} && \
    fnm alias default ${NODE_VERSION} && \
    npm install -g yarn n
