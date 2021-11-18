FROM ubuntu:latest

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt-get update --fix-missing
RUN apt-get upgrade -y

RUN apt-get install -y software-properties-common
RUN add-apt-repository ppa:ondrej/php

RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y \
		zsh \
    git \
    bash \
    curl \
    htop \
    man \
    vim \
    ssh \
    sudo \
    lsb-release \
    ca-certificates \
    locales \
    gnupg \
		zip \
		unzip \
		whois \
		nano \
		cron \
    # Packages required for multi-editor support
    libxtst6 \
    libxrender1 \
    libfontconfig1 \
    libxi6 \
    libgtk-3-0 \
		libssl-dev \
    libxml2-dev \
		libreadline-dev \
		zlib1g-dev \
		autoconf \
		bison \
		build-essential \
		libyaml-dev \
		libreadline-dev \
		libncurses5-dev \
		libffi-dev \
		libgdbm-dev \
		libsqlite3-dev

RUN chsh -s $(which zsh)

# Install the desired Node version into `/usr/local/`
ENV NODE_VERSION=12.16.3
RUN curl https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz | \
    tar xzfv - \
    --exclude CHANGELOG.md \
    --exclude LICENSE \
    --exclude README.md \
    --strip-components 1 -C /usr/local/

RUN apt-get install -y \
		jq \
		python \
    libpng-dev

# Set up Ruby
RUN apt-get install -y \
		ruby \
		ruby-dev \
		rubygems \
		ruby-colorize
RUN gem install bundler colorls pulsar

RUN apt-get install -y \
		xclip \
    xsel

# Install the yarn package manager
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y yarn 
# IF THE ABOVE LINE ERRORS RUN "sudo hwclock --hctosys" in WSL
RUN npm install -g n
RUN n 14.15.2

# WP CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x wp-cli.phar
RUN mv wp-cli.phar /usr/local/bin/wp

RUN apt-get install apache2 -y
RUN apt-get install mariadb-common mariadb-server mariadb-client -y

RUN a2enmod rewrite
RUN a2enmod headers

RUN chown -R www-data:www-data /var/www/html

RUN rm /var/www/html/index.html

COPY mysql.sh /mysql.sh
RUN chmod +x /mysql.sh

COPY install-composer.sh /install-composer.sh
RUN chmod +x /install-composer.sh

COPY .zshrc /.zshrc-initial/.zshrc

ENV DATE_TIMEZONE UTC

COPY ["configure", "/coder/configure"]

VOLUME /var/www/html
VOLUME /var/log/httpd
VOLUME /var/run/mysqld
VOLUME /var/lib/mysql
VOLUME /var/log/mysql
VOLUME /etc/apache2

RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y \
    libxtst6 \
    libxrender1 \
    libfontconfig1 \
    libxi6 \
    libgtk-3-0

RUN mkdir -p /opt/idea
#RUN curl -L "https://download.jetbrains.com/product?code=PS&latest&distribution=linux" | tar -C /opt/phpstorm --strip-components 1 -xzvf -
#RUN curl -L "https://download.jetbrains.com/product?code=RM&latest&distribution=linux" | tar -C /opt/rubymine --strip-components 1 -xzvf -
RUN curl -L "https://download.jetbrains.com/product?code=IU&latest&distribution=linux" | tar -C /opt/idea --strip-components 1 -xzvf -

#RUN ln -s /opt/phpstorm/bin/phpstorm.sh /usr/bin/phpstorm
#RUN ln -s /opt/rubymine/bin/rubymine.sh /usr/bin/rubymine
RUN ln -s /opt/idea/bin/idea.sh /usr/bin/intellij-idea-ultimate

RUN adduser --gecos '' --disabled-password --shell /bin/zsh embold && \
  echo "embold ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd
RUN adduser embold www-data
RUN adduser www-data embold
USER embold
