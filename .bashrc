export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# Init starship prompt
eval "$(starship init bash)"

# Set window title to output of starship directory module
function set_win_title() {
  echo -ne "\033]0; $(echo $(starship module directory) | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g") \007"
}

starship_precmd_user_func="set_win_title"
