export GOPATH=~/go
export GOBIN=$GOPATH/bin
export NVM_DIR="$HOME/.nvm"                                                                                           
export EDITOR=vi
export HISTIGNORE="exit:ls:shutdown:reboot"
export PATH=$PATH:$GOBIN
export PATH=$PATH:$HOME/bin
export PATH="$PATH:/sbin"
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

[ -f $HOME/.profile_local ] && . $HOME/.profile_local


# Call .bashrc if this is an interative shell
case "$-" in *i*) if [ -r ~/.bashrc ]; then . ~/.bashrc; fi;; esac
