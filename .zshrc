# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
  export ZSH=/home/embold/.oh-my-zsh

DEFAULT_USER='embold'

export APP="${HOSTNAME}"

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir rbenv vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status background_jobs time)
POWERLEVEL9K_SHORTEN_DIR_LENGTH=2
POWERLEVEL9K_TIME_FORMAT="%D{\uf017 %H:%M \uf073 %Y-%m-%d}"
POWERLEVEL9K_SHOW_CHANGESET=true
POWERLEVEL9K_OS_ICON_BACKGROUND="black"
POWERLEVEL9K_OS_ICON_FOREGROUND="184"
POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
POWERLEVEL9K_DIR_HOME_FOREGROUND="184"
POWERLEVEL9K_DIR_HOME_SUBFOLDER_FOREGROUND="184"
POWERLEVEL9K_DIR_HOME_SUBFOLDER_BACKGROUND="black"
POWERLEVEL9K_DIR_DEFAULT_FOREGROUND="184"
POWERLEVEL9K_CONTEXT_ROOT_FOREGROUND="184"
POWERLEVEL9K_CONTEXT_DEFAULT_FOREGROUND="184"

POWERLEVEL9K_SHORTEN_STRATEGY=truncate_with_package_name

POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_RPROMPT_ON_NEWLINE=true
POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

export HISTFILE=~/.zsh_history
export HISTSIZE=50000
export SAVEHIST=50000

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(npm command-not-found last-working-dir per-directory-history web-search gulp laravel5 copydir extract frontend-search lol zsh-autosuggestions sudo bundler copyfile dircycle zsh-z)
ZSH_AUTOSUGGEST_USE_ASYNC=true
ZSH_AUTOSUGGEST_STRATEGY=match_prev_cmd
bindkey '`' autosuggest-accept
source $ZSH/oh-my-zsh.sh

alias app="cd ~/code/${HOSTNAME}"

# git aliases
alias gs='git status'
alias gcm='git commit -m'
alias push='git push'
alias pull='git pull'
alias glog='git log --graph --oneline --decorate -n 10 --color'

alias dir='ls -an'

alias yw='yarn watch'
alias yp='yarn production'

# get me to the station!
alias staging='ssh root@embold.net'
alias mykey='cat ~/.ssh/id_rsa.pub | xclip -sel clip'

# much better ls
alias ls='colorls --sort-dirs -r'

# check the weather
alias weather='curl wttr.in/Akron'

alias serve='bundle exec rails server'

alias p='pulsar task'

function bwpass() {
        bw get item $1 | jq '.login.password' | tr -d '",' | xclip -sel clip
}

function h() {
        history | grep $1
}

function t() {
        folder=${PWD##*/}

        cd web/app/themes/$folder
}

function mkcd () {
    mkdir -p -- "$1" && cd -P -- "$1"
}

function pb() {
        branch=$(git rev-parse --abbrev-ref HEAD)

        git push --set-upstream origin $branch
}

function merge() {
        branch=$(git rev-parse --abbrev-ref HEAD)

        git checkout master && git merge $branch
}

function backend() {
        folder=${PWD##*/}

        cd ~/browsersync/ && NODE_ENV=development site=$folder node_modules/webpack/bin/webpack.js --watch --progress --hide-modules --config=node_modules/laravel-mix/setup/webpack.config.js
}

alias browsersync='backend'
alias bs="backend"

function deploy() {
        if [ "$1" = "" ]; then

                read "?Are you sure you want to deploy to PRODUCTION? [y/N] " yn

                case $yn in
                    [Yy]* ) 

                        pulsar task $APP production deploy;;
                    [Nn]* )     echo "Cancelling!";;
                    * ) echo "Cancelling!";;
                esac
        else
                if [ "$2" = "" ]; then
                        pulsar task $APP $1 deploy
                else
                        if [ "$3" = "" ]; then
                                pulsar task $APP $1 $2
                        else
                                destination=$2 pulsar task $APP $1 $3
                        fi
                fi
        fi
}

function connect() {
        if [ "$1" = "staging" ]; then
                ssh ${PWD##*/}-staging
        else
                ssh ${PWD##*/}
        fi
}

function acpd() {
        if [ "$1" = "" ]; then
                echo "You must provide a commit message in quotes, followed by an optional environment name if using Capistrano to deploy."
        else
                git status

                read "?Do you want to add, commit, and push all these files? [y/N] " yn

                case $yn in
                    [Yy]* ) 
                                git add .
                                echo "Files added to git";
                                git commit -m "$1"
                                echo "Commit message made";
                                git push
                                echo "Files pushed with git";

                                if [ "$2" != "" ]; then

                                        read "?Do you want to deploy these changes to $2? [y/N] " yn

                                        case $yn in
                                            [Yy]* ) 
                                                        cap $2 deploy;;
                                            [Nn]* )     echo "Not deploying!";;
                                            * ) echo "Not deploying!";;
                                        esac
                                fi;;
                    [Nn]* )     echo "Cancelling!";;
                    * ) echo "Cancelling!";;
                esac
        fi
}

function gitignore() {
        ssh root@embold.net cat /var/workflow/gitignores/$1/.gitignore
}

function gad() {
    if git grep -n 'embold.net' ':!*.rb' ':!*.rake'
    then
        read "?It appears you're commiting a file that references staging! Are you POSITIVE you want to do this? [y/N] " yn
        case $yn in
                    [Yy]* ) git add .;;
                    [Nn]* ) 
                                echo "!!!! CANCELLING !!!!";;
                    * ) echo "Please answer yes or no.";;
                esac
    else
        git add .;
    fi
}

function fixperms() {
  # https://askubuntu.com/questions/574870/wordpress-cant-upload-files
  WP_OWNER=embold # <-- wordpress owner
  WP_GROUP=embold # <-- wordpress group
  WS_GROUP=embold # <-- webserver group

  if [ "$1" = "" ]; then
    WP_ROOT=~/code/${HOSTNAME} # <-- wordpress root directory
  else
    WP_ROOT=$1 # <-- wordpress root directory
  fi

  echo "Perms fix for ${WP_ROOT}"

  # reset to safe defaults
  echo "Fixing global owner..."
  sudo find ${WP_ROOT} -exec chown ${WP_OWNER}:${WP_GROUP} {} \;
  echo "Fixing global directory permissions..."
  find ${WP_ROOT} -type d -exec chmod 755 {} \;
  echo "Fixing global file permissions..."
  find ${WP_ROOT} -type f -exec chmod 644 {} \;

  # allow wordpress to manage wp-config.php (but prevent world access)
  if [[ -a ${WP_ROOT}/wp-config.php ]]; then
    echo "Fixing wp-config owner group..."
    sudo chgrp ${WS_GROUP} ${WP_ROOT}/wp-config.php
    echo "Fixing wp-config permissions..."
    chmod 660 ${WP_ROOT}/wp-config.php
  fi
  if [[ -a ${WP_ROOT}/.env ]]; then
    echo "Fixing .env owner group..."
    sudo chgrp ${WS_GROUP} ${WP_ROOT}/.env
    echo "Fixing .env permissions..."
    chmod 660 ${WP_ROOT}/.env
  fi

  # allow wordpress to manage wp-content
  if [[ -d ${WP_ROOT}/wp-content ]]; then
    echo "Fixing wp-content owner group..."
    find ${WP_ROOT}/wp-content -exec chgrp ${WS_GROUP} {} \;
    echo "Fixing wp-content directory permissions..."
    find ${WP_ROOT}/wp-content -type d -exec chmod 775 {} \;
    echo "Fixing wp-content file permissions..."
    find ${WP_ROOT}/wp-content -type f -exec chmod 664 {} \;
  fi
  if [[ -d ${WP_ROOT}/web/app ]]; then
    echo "Fixing web/app owner group..."
    find ${WP_ROOT}/web/app -exec chgrp ${WS_GROUP} {} \;
    echo "Fixing web/app directory permissions..."
    find ${WP_ROOT}/web/app -type d -exec chmod 775 {} \;
    echo "Fixing web/app file permissions..."
    find ${WP_ROOT}/web/app -type f -exec chmod 664 {} \;
  fi

  # laravel storage directory
  if [[ -d ${WP_ROOT}/storage ]]; then
    echo "Fixing storage directory permissions..."
    sudo chmod -R ug+w ${WP_ROOT}/storage
  fi

  echo "Done!"
}

# reusable confirm function
function confirm() {
  read "?Continue (y/n)? [y/N] " yn
  case $yn in
    [Yy]* ) echo "Starting...";;
    [Nn]* ) echo "Exiting..."; continue;;
    * ) echo "Invalid input. Please enter y/n.";;
  esac
}

# maintenance tasks, requires a space seperated list of pulsar apps in .zshrc as below
# export MAINTENANCE_SITES='site1 site2'
function maint() {

  site_array=("${(@s/ /)MAINTENANCE_SITES}")

  cyan="\e[96m"
  red="\e[91m"
  default="\e[39m"


  for site in "${site_array[@]}"; do
    case $1 in
    start)
      echo "$cyan"
      echo "\nStarting maintenance for: $site"
      echo "$default"
      confirm
      pulsar task $site production git:commit
      pulsar task $site staging git:pull
      pulsar task $site staging laraish:update
      pulsar task $site staging deploy:bedrock
      pulsar task $site staging wp:cache
      ;;
    end)
      echo "$cyan"
      echo "\nEnding maintenance for: $site"
      echo "$default"
      confirm
      pulsar task $site staging git:commit
      pulsar task $site production wp:core
      pulsar task $site production git:pull
      pulsar task $site production laraish:update
      pulsar task $site production deploy:bedrock
      pulsar task $site production wp:cache
      ;;
    *)
      echo "$red"
      echo "Supply a valid argument"
      echo "$default"
      ;;
    esac
  done
}

alias flushdns='sudo systemd-resolve --flush-caches'

alias zd='z -c'

alias g='guard'

export COLORTERM="truecolor"
export MICRO_TRUECOLOR="1"

export BW_SESSION="nwsK4uC0dkMCK9I1fKToDio7RljL1b1pc7IGBPKkNr9Y2EiO/g7dg5RiW68JcQxENG29nGnOpIfUVU0HUnBscA=="
export PULSAR_DIRECTORY="/home/embold/pulsar"

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
export PATH="$PATH:/snap/bin"

