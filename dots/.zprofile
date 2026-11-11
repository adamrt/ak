eval "$(/opt/homebrew/bin/brew shellenv zsh)"
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH=/opt/homebrew/share/google-cloud-sdk/bin:"$PATH"

# Work mac only.
if [ "$(scutil --get LocalHostName)" = FDK03H02RJ ]; then
    export CLAUDE_CODE_OAUTH_TOKEN=$(security find-generic-password -a "$USER" -s CLAUDE_CODE_OAUTH_TOKEN -w)
fi
