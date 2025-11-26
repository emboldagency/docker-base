ARG UBUNTU_VERSION=24.04 \
	NODE_VERSION=22.19.0

FROM ubuntu:${UBUNTU_VERSION}

# Define ARGs again after FROM so they are available in the build stage
ARG UBUNTU_VERSION
ARG NODE_VERSION

ENV DATE_TIMEZONE=UTC \
	LANG=C.UTF-8 \
	LANGUAGE=C.UTF-8 \
	LC_ALL=C.UTF-8 \
	TZ=UTC \
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
	&& chown -R embold:embold /coder

# -----------------------------------------------------------------------------
# User-Level Installs (Node, FNM, ZSH Themes)
# -----------------------------------------------------------------------------
USER embold

# CRITICAL: Trick installers into thinking /coder/home is the home directory.
# This ensures .zshrc, .fnm, and .oh-my-zsh end up in the staging area.
ENV HOME=/coder/home

SHELL [ "bash", "-c" ]

# Ensure the config files/directories exist so we can append to them
RUN mkdir -p /coder/home/.local/bin /coder/home/.local/share \
	&& touch /coder/home/.bashrc /coder/home/.zshrc \
	# --- FNM & Node ---
	&& curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "/coder/home/.fnm" --skip-shell \
	&& echo 'eval "$(fnm env --shell bash)"' >> /coder/home/.bashrc \
	&& echo 'eval "$(fnm env --shell zsh)"' >> /coder/home/.zshrc \
	# Link FNM to global path so it's accessible without loading shell configs
	&& sudo ln -s /coder/home/.fnm/fnm /usr/local/bin/ \
	&& sudo chmod +x /usr/local/bin/fnm \
	# Install Node & Global Packages
	# We source the *staged* bashrc to load FNM
	&& /bin/bash -c "source /coder/home/.bashrc \
	&& fnm install ${NODE_VERSION} \
	&& fnm alias default ${NODE_VERSION} \
	&& npm install -g yarn n \
	&& npm install -g --prefix /coder/home/.local --unsafe-perm=true browser-sync" \
	# Symlink node binaries for global access
	&& /bin/bash -c 'source /coder/home/.bashrc && sudo ln -s "/coder/home/.fnm/aliases/default/bin/node" /usr/local/bin/node' \
	&& /bin/bash -c 'source /coder/home/.bashrc && sudo ln -s "/coder/home/.fnm/aliases/default/bin/npm" /usr/local/bin/npm' \
	&& /bin/bash -c 'source /coder/home/.bashrc && sudo ln -s "/coder/home/.fnm/aliases/default/bin/npx" /usr/local/bin/npx' \
	# --- ZSH & Themes ---
	&& sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
	&& git clone --depth=1 https://github.com/mattmc3/antidote.git "/coder/home/.local/share/antidote" || true \
	&& mkdir -p "/coder/home/.cache/oh-my-posh/themes" \
	&& curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "/coder/home/.local/bin" -t "/coder/home/.cache/oh-my-posh/themes" \
	&& sh -c "$(curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh)" -- --bin-dir /coder/home/.local/bin --man-dir /coder/home/.local/share/man --sudo "" >/dev/null 2>&1 || true \
	# --- LazyGit ---
	# FIX: Switch to /tmp so 'embold' user can write the tarball
	&& cd /tmp \
	&& LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*') \
	&& curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" \
	&& sudo tar xf lazygit.tar.gz lazygit \
	&& sudo install lazygit /usr/local/bin \
	&& rm lazygit.tar.gz lazygit \
	# --- BrowserSync Config ---
	&& git clone https://github.com/emboldagency/backend-browsersync.git /coder/home/browsersync

# Reset HOME
ENV HOME=/home/embold
