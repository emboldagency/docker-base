ARG UBUNTU_VERSION=24.04
ARG NODE_VERSION=22.19.0

FROM ubuntu:${UBUNTU_VERSION}

# Define ARGs again after FROM so they are available in the build stage
ARG UBUNTU_VERSION
ARG NODE_VERSION

ENV DATE_TIMEZONE=UTC \
	LANG=C.UTF-8 \
	LANGUAGE=C.UTF-8 \
	LC_ALL=C.UTF-8 \
	TZ=UTC \
	# Ruby
	BUNDLE_DISABLE_SHARED_GEMS=1 \
	BUNDLE_SILENCE_ROOT_WARNING=1 \
	PULSAR_CONF_REPO="git@github.com:emboldagency/pulsar.git" \
	# Add non-interactive frontend to prevent apt hanging
	DEBIAN_FRONTEND=noninteractive

# -----------------------------------------------------------------------------
# System Installs
# We do this first because it rarely changes.
# -----------------------------------------------------------------------------
RUN apt-get update \
	# transient policy to prevent packages from trying to start services during build
	&& printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d \
	&& chmod +x /usr/sbin/policy-rc.d \
	&& apt-get install -y --no-install-recommends \
	debconf-utils \
	apt-utils \
	apt-transport-https \
	ca-certificates \
	curl \
	gnupg \
	gpg-agent \
	locales \
	lsb-release \
	software-properties-common \
	tzdata \
	# Setup Locale
	&& echo "tzdata tzdata/Areas select Etc" | debconf-set-selections \
	&& echo "tzdata tzdata/Zones/Etc select UTC" | debconf-set-selections \
	&& ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
	&& echo $TZ > /etc/timezone \
	&& localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias $LANG \
	&& locale-gen en_US.UTF-8 \
	&& update-locale LANG=en_US.UTF-8 \
	# Add Repos
	&& add-apt-repository -y universe \
	# Git repository for latest Git and GitHub CLI
	&& add-apt-repository -y ppa:git-core/ppa \
	&& curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
	&& chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& apt-get update \
	# Libraries and build tools
	&& apt-get install -y --no-install-recommends \
	autoconf \
	bison \
	build-essential \
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
	zlib1g-dev \
	# System administration tools
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
	micro \
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
	socat \
	ssh \
	stow \
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
	zsh \
	# Google Chrome for headless testing
	&& curl -fsSL -o google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
	&& apt-get install -y --no-install-recommends ./google-chrome.deb \
	&& rm -f google-chrome.deb \
	# Cleanup
	&& rm -rf /var/lib/apt/lists/* /usr/share/man/* /usr/share/doc/*

# -----------------------------------------------------------------------------
# Ruby
# We do this before copying local files so it stays cached.
# -----------------------------------------------------------------------------
# Prepare directory for ruby-build (temp)
RUN mkdir -p /tmp/ruby-build \
	&& git clone https://github.com/rbenv/ruby-build.git /tmp/ruby-build \
	&& PREFIX=/usr/local /tmp/ruby-build/install.sh \
	&& rm -rf /tmp/ruby-build \
	&& mkdir -p /usr/local/etc \
	&& { echo 'install: --no-document'; echo 'update: --no-document'; } >> /usr/local/etc/gemrc

# -----------------------------------------------------------------------------
# Users & Shells
# -----------------------------------------------------------------------------
# Create users
RUN adduser --gecos '' --disabled-password --shell /bin/zsh embold \
	&& echo "embold ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd \
	&& if ! id -u coder >/dev/null 2>&1; then adduser --gecos '' --disabled-password --shell /bin/zsh coder || true; fi \
	&& echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/coder-nopasswd \
	# Ensure dirs exist
	&& mkdir -p /home/coder /coder/home-coder /coder/home/.local/bin /coder/home/.cache \
	&& chown -R coder:coder /home/coder /coder/home-coder /coder/home \
	# Path setup
	&& mkdir -p /etc/profile.d \
	&& echo 'export PATH="$HOME/.local/bin:/coder/home/.local/bin:$PATH"' > /etc/profile.d/coder-paths.sh \
	&& chmod 644 /etc/profile.d/coder-paths.sh

# -----------------------------------------------------------------------------
# Local Configuration (Frequent Changes)
# moved to the bottom so changes here don't invalidate earlier layers
# -----------------------------------------------------------------------------
COPY coder /coder

# Apply config
RUN ln -s /coder/conf/sshd_config /etc/ssh/sshd_config.d/embold.conf \
	&& chown -R embold:embold /coder \
	&& chmod 774 /coder \
	&& chown -R embold:embold /coder/home

# -----------------------------------------------------------------------------
# User-Level Installs (Node, FNM, ZSH Themes)
# -----------------------------------------------------------------------------
USER embold

SHELL [ "bash", "-c" ]

RUN echo 'eval "$(fnm env --shell bash)"' >> /coder/home/.bashrc \
	&& curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "/coder/home/.fnm" --skip-shell \
	&& sudo ln -s /coder/home/.fnm/fnm /usr/local/bin/ \
	&& sudo chmod +x /usr/local/bin/fnm \
	&& fnm -V \
	# We combine install, alias, AND npm global installs into ONE bash execution
	# This ensures 'npm' is found because .bashrc is sourced in this specific session
	&& /bin/bash -c "source /coder/home/.bashrc \
	&& fnm install ${NODE_VERSION} \
	&& fnm alias default ${NODE_VERSION} \
	&& npm install -g yarn n" \
	# Symlink node binaries so they are available globally
	&& /bin/bash -c 'source /coder/home/.bashrc && sudo ln -s "/coder/home/.fnm/aliases/default/bin/node" /usr/local/bin/node' \
	&& /bin/bash -c 'source /coder/home/.bashrc && sudo ln -s "/coder/home/.fnm/aliases/default/bin/npm" /usr/local/bin/npm' \
	&& /bin/bash -c 'source /coder/home/.bashrc && sudo ln -s "/coder/home/.fnm/aliases/default/bin/npx" /usr/local/bin/npx' \
	# ZSH & Themes
	&& sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
	&& mkdir -p "/coder/home/.local/share" \
	&& git clone --depth=1 https://github.com/mattmc3/antidote.git "/coder/home/.local/share/antidote" || true \
	&& mkdir -p "/coder/home/.local/bin" "/coder/home/.cache/oh-my-posh/themes" \
	&& curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "/coder/home/.local/bin" -t "/coder/home/.cache/oh-my-posh/themes" \
	&& sh -c "$(curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh)" -- --bin-dir /coder/home/.local/bin --man-dir /coder/home/.local/share/man --sudo "" >/dev/null 2>&1 || true \
	&& npm install -g --prefix /coder/home/.local --unsafe-perm=true browser-sync || true