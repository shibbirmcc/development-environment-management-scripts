# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="robbyrussell"
ZSH_THEME="amuse"

# %n -> username
# %m -> hostname
# %~ -> current working directory
# %# -> shows # if root, % otherwise
# PS1='%n@%m %~ %# '

PS1='%F{green}%n@%m%f %F{blue}%~%f %F{yellow}$(git_prompt_info)%f [%D{%Y-%m-%d %H:%M}] %# '
ZSH_THEME_GIT_PROMPT_PREFIX="🌿 "
ZSH_THEME_GIT_PROMPT_SUFFIX=""
ZSH_THEME_GIT_PROMPT_CLEAN=""

plugins=(git)

source $ZSH/oh-my-zsh.sh


## Mac like open command to open directories in finder
# This only works for Nautilus file manager
alias open='xdg-open'

