# Add python exec to path
if [ "$(uname -m)" = "arm64" ]; then
	export PATH="/opt/homebrew/opt/python/libexec/bin:$PATH"
else
	export PATH="/usr/local/opt/python/libexec/bin:$PATH"
fi

# Volta
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
