ARG UBUNTU_VERSION=24.04
ARG EMBOLD_UID=1001
ARG EMBOLD_GID=1001

FROM ubuntu:${UBUNTU_VERSION}

# Re-declare ARGs for this stage
ARG UBUNTU_VERSION
ARG EMBOLD_UID
ARG EMBOLD_GID

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
	autoconf \
	bison \
	build-essential \
	ca-certificates \
	curl \
	git \
	gnupg \
	gpg-agent \
	libffi-dev \
	libreadline-dev \
	libsqlite3-dev \
	libssl-dev \
	libyaml-dev \
	locales \
	lsb-release \
	openssh-server \
	rsync \
	socat \
	software-properties-common \
	ssh \
	sudo \
	tzdata \
	vim \
	zlib1g-dev \
	zsh \
	&& add-apt-repository -y ppa:git-core/ppa \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends git \
	&& localedef -i en_US -c -f UTF-8 en_US.UTF-8 \
	&& rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Global Dev Tooling (Binaries)
# -----------------------------------------------------------------------------
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	# shell / terminal UI
	bat \
	fzf \
	htop \
	less \
	nano \
	ncdu \
	tmux \
	tree \
	# search & file navigation
	fd-find \
	ripgrep \
	stow \
	# data & text (json / csv / yaml / stats / sqlite)
	datamash \
	jq \
	miller \
	sqlite3 \
	# network & http diagnostics
	dnsutils \
	httpie \
	iproute2 \
	iputils-ping \
	lsof \
	mtr-tiny \
	netcat-openbsd \
	traceroute \
	wget \
	# dev & scripting helpers
	direnv \
	file \
	git-delta \
	git-lfs \
	grc \
	moreutils \
	parallel \
	pv \
	shellcheck \
	# archives
	unzip \
	zip \
	# GitHub CLI
	&& curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	# Docker CLI (client only — workspace containers are managed by the host engine)
	&& mkdir -p /etc/apt/keyrings \
	&& curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
	# Eza
	&& wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg \
	&& echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends docker-ce-cli eza gh \
	# Enable git-lfs filters system-wide so LFS repos clone correctly for all users
	&& git lfs install --system \
	# Ubuntu ships these as batcat/fdfind; symlink the expected names so `bat`/`fd`
	# resolve for scripts and non-interactive agent commands (shell aliases don't).
	&& ln -sf "$(command -v batcat)" /usr/local/bin/bat \
	&& ln -sf "$(command -v fdfind)" /usr/local/bin/fd \
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
	# yq (mikefarah) — arch-aware static binary, not in apt
	&& curl -fsSL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_$(dpkg --print-architecture)" -o /usr/local/bin/yq \
	&& chmod +x /usr/local/bin/yq \
	# shfmt (mvdan) + gron (tomnomnom) — agent shell/JSON tooling, not in apt
	&& SHFMT_VERSION=$(curl -s https://api.github.com/repos/mvdan/sh/releases/latest | grep -Po '"tag_name": "\K[^"]*') \
	&& curl -fsSL "https://github.com/mvdan/sh/releases/download/${SHFMT_VERSION}/shfmt_${SHFMT_VERSION}_linux_$(dpkg --print-architecture)" -o /usr/local/bin/shfmt \
	&& chmod +x /usr/local/bin/shfmt \
	&& GRON_VERSION=$(curl -s https://api.github.com/repos/tomnomnom/gron/releases/latest | grep -Po '"tag_name": "\K[^"]*') \
	&& curl -fsSL "https://github.com/tomnomnom/gron/releases/download/${GRON_VERSION}/gron-linux-$(dpkg --print-architecture)-${GRON_VERSION#v}.tgz" -o /tmp/gron.tgz \
	&& tar -xzf /tmp/gron.tgz -C /usr/local/bin gron \
	&& rm /tmp/gron.tgz \
	# Chezmoi
	&& sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin \
	# Vault CLI — pre-baked so the vault-github Coder module finds it already present
	# and skips its per-boot download. Otherwise the dotfiles startup script can hit
	# `command -v vault` before the module finishes installing it, losing the race and
	# falling back to "no dotfiles URL". Keep in sync with vault_cli_version in the templates.
	&& VAULT_VERSION=2.0.2 \
	&& curl -fsSL "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_$(dpkg --print-architecture).zip" -o /tmp/vault.zip \
	&& unzip -o /tmp/vault.zip -d /usr/local/bin vault \
	&& rm /tmp/vault.zip \
	# 1Password CLI — same race-avoidance as Vault above, for the onepassword module. Keep in sync with op_cli_version in the templates.
	&& OP_VERSION=2.39.0 \
	&& curl -fsSL "https://cache.agilebits.com/dist/1P/op2/pkg/v${OP_VERSION}/op_linux_$(dpkg --print-architecture)_v${OP_VERSION}.zip" -o /tmp/op.zip \
	&& unzip -o /tmp/op.zip -d /usr/local/bin op \
	&& rm /tmp/op.zip \
	# rtk — token-reducing CLI proxy for coding agents.
	&& RTK_VERSION=0.43.0 \
	&& case "$(dpkg --print-architecture)" in amd64) RTK_TARGET=x86_64-unknown-linux-musl ;; arm64) RTK_TARGET=aarch64-unknown-linux-gnu ;; *) echo "unsupported arch" && exit 1 ;; esac \
	&& curl -fsSL "https://github.com/rtk-ai/rtk/releases/download/v${RTK_VERSION}/rtk-${RTK_TARGET}.tar.gz" -o /tmp/rtk.tar.gz \
	&& curl -fsSL "https://github.com/rtk-ai/rtk/releases/download/v${RTK_VERSION}/checksums.txt" -o /tmp/rtk-checksums.txt \
	&& RTK_EXPECTED=$(grep "rtk-${RTK_TARGET}.tar.gz\$" /tmp/rtk-checksums.txt | awk '{print $1}') \
	&& [ -n "$RTK_EXPECTED" ] \
	&& [ "$(sha256sum /tmp/rtk.tar.gz | awk '{print $1}')" = "$RTK_EXPECTED" ] \
	&& tar -xzf /tmp/rtk.tar.gz -C /usr/local/bin rtk \
	&& chmod +x /usr/local/bin/rtk \
	&& rm /tmp/rtk.tar.gz /tmp/rtk-checksums.txt \
	# uv — Python package/tool manager, needed by Python-based MCP servers.
	&& curl -LsSf https://astral.sh/uv/install.sh | env UV_UNMANAGED_INSTALL=/usr/local/bin UV_NO_MODIFY_PATH=1 sh \
	&& /usr/local/bin/uv --version \
	&& rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Global Runtime & Frameworks (Node/FNM/ZSH/Antidote)
# -----------------------------------------------------------------------------
RUN export FNM_DIR=/opt/fnm \
	&& mkdir -p /opt/fnm \
	# fnm.vercel.app has intermittent TLS failures; GitHub is the same script, more reliable.
	&& curl -fsSL https://raw.githubusercontent.com/Schniz/fnm/master/.ci/install.sh | bash -s -- --install-dir "/opt/fnm" --skip-shell \
	&& ln -s /opt/fnm/fnm /usr/local/bin/fnm \
	&& fnm install --lts --corepack-enabled \
	&& fnm alias lts-latest default \
	&& ln -s /opt/fnm/aliases/default/bin/node /usr/local/bin/node \
	&& ln -s /opt/fnm/aliases/default/bin/npm /usr/local/bin/npm \
	&& ln -s /opt/fnm/aliases/default/bin/npx /usr/local/bin/npx \
	# Oh My Zsh & Antidote
	&& git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git /opt/oh-my-zsh \
	&& git clone --depth=1 https://github.com/mattmc3/antidote.git /opt/antidote \
	# BrowserSync Global
	&& npm install -g browser-sync \
	&& git clone https://github.com/emboldagency/backend-browsersync.git /opt/embold/browsersync

# -----------------------------------------------------------------------------
# Users & Workspace Setup
# -----------------------------------------------------------------------------
COPY coder /coder

RUN groupadd --gid "${EMBOLD_GID}" embold \
	&& useradd --uid "${EMBOLD_UID}" --gid "${EMBOLD_GID}" --create-home --shell /bin/zsh embold \
	&& echo "embold ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/embold \
	# SSH Setup
	&& mkdir -p /etc/ssh/sshd_config.d /etc/ssh/ssh_config.d \
	&& cp /coder/conf/sshd_config /etc/ssh/sshd_config.d/embold.conf \
	&& cp /coder/conf/.ssh/config /etc/ssh/ssh_config.d/embold.conf \
	# Permissions
	&& mkdir -p /opt/embold/bin \
	&& chown -R embold:embold /opt/fnm /opt/embold /opt/oh-my-zsh /opt/antidote /opt/oh-my-posh /coder /home/embold

USER embold
WORKDIR /home/embold

RUN mkdir -p /home/embold/.local/bin /home/embold/.config /home/embold/.cache

CMD ["/bin/zsh"]
