# Avoid duplicate entries in $PATH
function addToPATH {
  case ":$PATH:" in
    *":$1:"*) :;; # already there
    *) PATH="$1:$PATH";; # or PATH="$PATH:$1"
  esac
}

export NVM_DIR="$HOME/.nvm"                                                                                           
export EDITOR=vi
export HISTIGNORE="exit:ls:shutdown:reboot"

addToPATH "$HOME/.yarn/bin"
addToPATH "$HOME/.config/yarn/global/node_modules/.bin"
addToPATH "$HOME/.cargo/bin"

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm                                             
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # T

[ -f $HOME/.profile_local ] && . $HOME/.profile_local

# Call .bashrc if this is an interative shell
case "$-" in *i*) if [ -r ~/.bashrc ]; then . ~/.bashrc; fi;; esac
