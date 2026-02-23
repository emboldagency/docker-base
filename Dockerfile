ARG UBUNTU_VERSION=24.04
ARG NODE_VERSION=22.19.0

FROM ubuntu:${UBUNTU_VERSION}

# Re-declare ARGs for this stage
ARG UBUNTU_VERSION
ARG NODE_VERSION

# Set standard environment variables
ENV LANG=C.UTF-8 \
	LC_ALL=C.UTF-8 \
	TZ=UTC \
	DEBIAN_FRONTEND=noninteractive \
	# Antidote plugin home
	ANTIDOTE_HOME=/home/embold/.cache/antidote \
	# Bundler
	BUNDLE_DISABLE_SHARED_GEMS=1 \
	BUNDLE_SILENCE_ROOT_WARNING=1 \
	# FNM/Node Global Paths
	FNM_DIR=/home/embold/.fnm \
	# Oh My Posh Global Themes
	POSH_THEMES_PATH=/opt/oh-my-posh/themes \
	# System path
	PATH=/home/embold/.local/bin:/home/embold/.fnm:/opt/fnm:/opt/embold/bin:/usr/local/bin:$PATH

# -----------------------------------------------------------------------------
# System Core & Build Essentials
# -----------------------------------------------------------------------------
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	apt-transport-https \
	ca-certificates \
	curl \
	gnupg \
	gpg-agent \
	software-properties-common \
	lsb-release \
	build-essential \
	autoconf \
	bison \
	libssl-dev \
	libyaml-dev \
	libreadline-dev \
	zlib1g-dev \
	libffi-dev \
	libsqlite3-dev \
	rsync \
	socat \
	ssh \
	openssh-server \
	git \
	vim \
	zsh \
	sudo \
	locales \
	tzdata \
	&& add-apt-repository -y ppa:git-core/ppa \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends git \
	&& localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
	&& rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Global Dev Tooling (Binaries)
# -----------------------------------------------------------------------------
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	bat docker.io fd-find fzf htop jq ncdu ripgrep stow tmux tree unzip wget \
	# GitHub CLI
	&& curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	# Eza
	&& mkdir -p /etc/apt/keyrings \
	&& wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg \
	&& echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list \
	&& apt-get update \
	&& apt-get install -y gh eza \
	# LazyGit
	&& LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*') \
	&& curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" \
	&& tar xf lazygit.tar.gz lazygit \
	&& install lazygit /usr/local/bin \
	&& rm lazygit.tar.gz lazygit \
	# Oh My Posh & Themes
	&& curl -s https://ohmyposh.dev/install.sh | bash -s -- -d /usr/local/bin \
	&& mkdir -p /opt/oh-my-posh/themes \
	&& wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip -O /opt/oh-my-posh/themes/themes.zip \
	&& unzip /opt/oh-my-posh/themes/themes.zip -d /opt/oh-my-posh/themes \
	&& rm /opt/oh-my-posh/themes/themes.zip \
	&& chmod -R 755 /opt/oh-my-posh/themes \
	# Zoxide
	&& curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash -s -- --bin-dir /usr/local/bin \
	&& rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Global Runtime & Frameworks (Node/FNM/ZSH/Antidote)
# -----------------------------------------------------------------------------
RUN export FNM_DIR=/opt/fnm \
	&& mkdir -p /opt/fnm \
	&& curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "/opt/fnm" --skip-shell \
	&& ln -s /opt/fnm/fnm /usr/local/bin/fnm \
	&& fnm install --lts --corepack-enabled \
	&& fnm alias lts-latest default \
	&& ln -s /opt/fnm/aliases/default/bin/node /usr/local/bin/node \
	&& ln -s /opt/fnm/aliases/default/bin/npm /usr/local/bin/npm \
	&& ln -s /opt/fnm/aliases/default/bin/npx /usr/local/bin/npx \
	# Oh My Zsh & Antidote
	&& git clone https://github.com/ohmyzsh/ohmyzsh.git /opt/oh-my-zsh \
	&& git clone --depth=1 https://github.com/mattmc3/antidote.git /opt/antidote \
	# BrowserSync Global
	&& npm install -g browser-sync \
	&& git clone https://github.com/emboldagency/backend-browsersync.git /opt/embold/browsersync

# -----------------------------------------------------------------------------
# Users & Workspace Setup
# -----------------------------------------------------------------------------
COPY --chown=embold:embold coder /coder

RUN adduser --gecos '' --disabled-password --shell /bin/zsh embold \
	&& echo "embold ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/embold \
	# SSH Setup
	&& mkdir -p /etc/ssh/sshd_config.d /etc/ssh/ssh_config.d \
	&& cp /coder/conf/sshd_config /etc/ssh/sshd_config.d/embold.conf \
	&& cp /coder/conf/.ssh/config /etc/ssh/ssh_config.d/embold.conf \
	# Permissions
	&& mkdir -p /opt/embold/bin \
	&& chown -R embold:embold /opt/fnm /opt/embold /opt/oh-my-zsh /opt/antidote /opt/oh-my-posh /coder

USER embold
WORKDIR /home/embold

RUN mkdir -p /home/embold/.local/bin /home/embold/.config /home/embold/.cache

CMD ["/bin/zsh"]