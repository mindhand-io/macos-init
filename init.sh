#!/usr/bin/env bash
#/ Usage: init.sh 
#/ Install Common software on macOS.


fail_color="\033[31;1m"
pass_color="\033[32;1m"
color_end="\033[0m"

ask() {
    # https://gist.github.com/davejamesmiller/1965569
    local prompt default reply

    if [ "${2:-}" = "Y" ]; then
        prompt="Y/n"
        default=Y
    elif [ "${2:-}" = "N" ]; then
        prompt="y/N"
        default=N
    else
        prompt="y/n"
        default=
    fi

    while true; do

        # Ask the question (not using "read -p" as it uses stderr not stdout)
        echo -n "$1 [$prompt] "

        # Read the answer (use /dev/tty in case stdin is redirected from somewhere else)
        read reply </dev/tty

        # Default?
        if [ -z "$reply" ]; then
            reply=$default
        fi

        # Check if the reply is valid
        case "$reply" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac

    done
}

success() { printf "%b$* %b\n" "$pass_color" "$color_end" >&2; }
abort() { printf "%b[FAILED] $* %b\n" "$fail_color" "$color_end" >&2; exit 1; }
cask_install () {
   if brew cask install $1 ; then
      success "$1 installed successfully."
   else
      printf "[FAILED] $1\n" >> ~/CastInstallError.log
      printf "%b$1 installation failed.%b\n" "$fail_color" "$color_end"
   fi
}

MACOS_VERSION="$(sw_vers -productVersion)"
  echo "$MACOS_VERSION" | grep $Q -E "^10.(14|15)" || {
  abort "macOS version must be 10.14/15."
}

[ "$USER" = "root" ] && abort "Run init.sh as yourself, not root."
groups | grep $Q admin || abort "Add $USER to the admin group."

cat << "EOF"
 __  __ _           _ _                     _              __  _ 
|  \/  (_)         | | |                   | |             \_\(_)
| \  / |_ _ __   __| | |__   __ _ _ __   __| |   __ ____   ___| |
| |\/| | | '_ \ / _` | '_ \ / _` | '_ \ / _` |  / _`  _ \ / _ \ |
| |  | | | | | | (_| | | | | (_| | | | | (_| | | (_|  __/|  __/ |
|_|  |_|_|_| |_|\__,_|_| |_|\__,_|_| |_|\__,_|  \__,____| \___|_| 思行科技

 [https://github.com/mindhand-tech/macos-init]                                                                                                 

EOF
success "Runing system test ...... PASS"
printf "\nStart installing Common library:\n\n"

echo "› Check macOS update"
softwareupdate -i -a


if type xcode-select >&- && xpath=$( xcode-select --print-path ) &&
  test -d "${xpath}" && test -x "${xpath}" ; then
  success "› Skipping Xcode Command Line Tools installation"
else
  echo "› xcode-select --install"
  xcode-select --install
fi


if which brew >/dev/null 2>&1; then
  brew config
  success "› Skipping Homebrew installation"
else
  echo "› /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)""
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

brew tap homebrew/services
brew tap homebrew/cask-fonts
brew tap homebrew/cask-versions

brew install zsh coreutils git curl wget openssl jq mas thefuck exa hub bat fzf ripgrep prettyping glances

printf "\nStart installing Common app:\n\n"
cask_install dingtalk

if [[ -f ~/.zshrc ]]
then
  success "› Skipping oh-my-zsh installation"
else
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
wget -O ~/.oh-my-zsh/custom/themes/sunaku-zen.zsh-theme  https://raw.githubusercontent.com/AffanIndo/sunaku-zen/master/sunaku-zen.zsh-theme
wget -O  ~./.zshrc https://gist.githubusercontent.com/0xDing/8c46593df591af9e11d5fad397d7ec7c/raw/5c3d3bdcbd33cf6eb002e93fba4f0c55636a7dce/.zshrc
fi

if ask "你是否需要安装微信等常用软件？"; then
cask_install wechat
cask_install zoom
cask_install neteasemusic
cask_install xmind
fi

if ask "你是否需要安装Figma？"; then
cask_install figma
fi

if ask "你是否需要安装程序开发环境？"; then
brew install sqlite watchman coreutils automake autoconf libyaml readline libxslt libtool libxml2 webp pkg-config gnupg p7zip xz imagemagick
brew install libpq && brew link --force libpq
brew install kubernetes-cli kubernetes-helm
cask_install visual-studio-code
cask_install docker && cask_install kitematic
cask_install jetbrains-toolbox

## ruby
if [ `ruby -v | grep "2.6" | wc -l` = 1 ]; then
  success "› Skipping ruby installation"
else
curl -sSL https://rvm.io/mpapis.asc | gpg --import -
curl -sSL https://get.rvm.io | bash -s stable
. ~/.bash_profile
rvm install ruby-2.6.3
rvm use 2.6.3 --default
gem install heel
fi


## nodejs
if which node >/dev/null 2>&1; then
success "› Skipping nodejs installation"
else
brew install node yarn
fi
cask_install react-native-debugger

## Terraform
if which terraform >/dev/null 2>&1; then
success "› Skipping terraform installation"
else
brew install terraform
fi

## python
if which pyenv >/dev/null 2>&1; then
success "› Skipping python installation"
else
brew install pyenv
pyenv install 3.8.2
pyenv global 3.8.2
fi

fi

chmod 755 /usr/local/share/zsh
chmod 755 /usr/local/share/zsh/site-functions

success "Your macOS has completed initialization. Vist https://portal.manage.microsoft.com/devices to get started now";
exit 0;
