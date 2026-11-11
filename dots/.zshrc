export GPG_TTY=$(tty)

alias adc="gcloud auth login --update-adc"
alias unlock='echo unlock | gpg --clearsign > /dev/null'
