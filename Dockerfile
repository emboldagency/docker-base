ARG UBUNTU_VERSION=24.04 \
	NODE_VERSION=20.19.0

# Use Ubuntu as the base image
FROM ubuntu:${UBUNTU_VERSION}
ARG NODE_VERSION

ENV DATE_TIMEZONE=UTC \
	LANG=C.UTF-8 \
	LANGUAGE=C.UTF-8 \
	LC_ALL=C.UTF-8 \
	TZ=UTC \
	# Ruby
	BUNDLE_DISABLE_SHARED_GEMS=1 \
	BUNDLE_SILENCE_ROOT_WARNING=1 \
	PULSAR_CONF_REPO="git@github.com:emboldagency/pulsar.git"

# Install base system tools, required to build most packages
RUN apt-get update \
	# transient policy to prevent packages from trying to start services during build
	&& printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d \
	&& chmod +x /usr/sbin/policy-rc.d \
	# install debconf-utils and minimal packages so we can preseed tzdata first
	&& apt-get install -y --no-install-recommends debconf-utils apt-utils curl software-properties-common locales \
	# preseed tzdata to avoid interactive timezone selection during package configuration
	&& echo "tzdata tzdata/Areas select Etc" | debconf-set-selections \
	&& echo "tzdata tzdata/Zones/Etc select UTC" | debconf-set-selections \
	&& apt-get install -y --no-install-recommends \
	apt-utils \
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
	&& locale-gen en_US.UTF-8 \
	&& update-locale LANG=en_US.UTF-8 \
	# Add repositories and install the rest...
	&& add-apt-repository -y universe \
	# Git repository for latest Git and GitHub CLI
	&& add-apt-repository -y ppa:git-core/ppa \
	&& curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
	&& chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& apt-get update \
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
	zlib1g-dev \
	zsh \
	# Install Google Chrome for headless testing
	&& curl -fsSL -o google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
	&& apt-get install -y --no-install-recommends \
	./google-chrome-stable_current_amd64.deb \
	&& rm -f google-chrome-stable_current_amd64.deb \
	# Cleanup apt cache, manpages and docs to reduce image size
	&& rm -rf /var/lib/apt/lists/* /usr/share/man/* /usr/share/doc/* /usr/share/doc-base/* \
	# prune locales except en_US.UTF-8 to save space
	&& if [ -d /usr/share/locale ]; then find /usr/share/locale -maxdepth 1 -mindepth 1 ! -name 'en_US.UTF-8' -exec rm -rf {} + || true; fi

# Copy configuration files
COPY coder /coder

# Configure environment
RUN ln -s /coder/conf/sshd_config /etc/ssh/sshd_config.d/embold.conf \
	# Create a non-root user and add it to the necessary groups
	&& adduser --gecos '' --disabled-password --shell /bin/zsh embold \
	&& echo "embold ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd \
	&& chown -R embold:embold /coder \
	&& chmod 774 /coder \
	# Create coder user (lightweight) so derived images can rely on /home/coder and consistent user
	&& if ! id -u coder >/dev/null 2>&1; then adduser --gecos '' --disabled-password --shell /bin/zsh coder || true; fi \
	&& echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/coder-nopasswd || true \
	# Ensure coder persistent dirs exist and are writable
	&& mkdir -p /home/coder /coder/home-coder /coder/home/.local/bin && chown -R coder:coder /home/coder /coder/home-coder /coder/home || true \
	# skip installing gem documentation
	&& mkdir -p /usr/local/etc \
	&& { echo 'install: --no-document'; echo 'update: --no-document'; } >> /usr/local/etc/gemrc \
	# Set up PATH for /coder/home/.local/bin (image tools: fnm, zoxide, oh-my-posh, etc.)
	# This ensures all shells (bash, zsh, etc.) include the image tools in PATH
	# User ~/.local/bin takes precedence over image defaults
	&& mkdir -p /etc/profile.d \
	&& echo 'export PATH="$HOME/.local/bin:/coder/home/.local/bin:$PATH"' > /etc/profile.d/coder-paths.sh \
	&& chmod 644 /etc/profile.d/coder-paths.sh \
	# Add ruby-build
	&& git clone https://github.com/rbenv/ruby-build.git /coder/ruby-build \
	&& PREFIX=/usr/local /coder/ruby-build/install.sh \
	&& rm -rf /coder/ruby-build

USER embold

SHELL [ "bash", "-c" ]

# Install user packages
RUN echo 'eval "$(fnm env --shell bash)"' >> /coder/home/.bashrc \
	&& curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "/coder/home/.fnm" --skip-shell \
	&& sudo ln -s /coder/home/.fnm/fnm /usr/local/bin/ \
	&& sudo chmod +x /usr/local/bin/fnm \
	# smoke test for fnm
	&& fnm -V  \
	&& /bin/bash -c "source /coder/home/.bashrc && fnm install ${NODE_VERSION}" \
	&& /bin/bash -c "source /coder/home/.bashrc && fnm alias default ${NODE_VERSION}" \
	# add fnm for shell
	&& /bin/bash -c 'source /coder/home/.bashrc && sudo /bin/ln -s "/coder/home/.fnm/aliases/default/bin/node" /usr/local/bin/node' \
	&& /bin/bash -c 'source /coder/home/.bashrc && sudo /bin/ln -s "/coder/home/.fnm/aliases/default/bin/npm" /usr/local/bin/npm' \
	&& /bin/bash -c 'source /coder/home/.bashrc && sudo /bin/ln -s "/coder/home/.fnm/aliases/default/bin/npx" /usr/local/bin/npx' \
	&& npm install -g yarn n \
	# install oh-my-zsh (unattended)
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
	# install antidote
	mkdir -p "/coder/home/.local/share" && \
	git clone --depth=1 https://github.com/mattmc3/antidote.git "/coder/home/.local/share/antidote" || true && \
	# ensure bin dir exists, then install oh-my-posh themes into persistent cache location
	mkdir -p "/coder/home/.local/bin" "/coder/home/.cache/oh-my-posh/themes" && \
	curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "/coder/home/.local/bin" -t "/coder/home/.cache/oh-my-posh/themes" && \
	# install zoxide
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh)" -- --bin-dir /coder/home/.local/bin --man-dir /coder/home/.local/share/man --sudo "" >/dev/null 2>&1 || true && \
	# install browser-sync
	npm install -g --prefix /coder/home/.local --unsafe-perm=true browser-sync || true
