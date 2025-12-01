#!/bin/bash

# Inspired (or shamelessly copied from https://github.com/mattjmorrison/dotfiles)

#==============
# Variables
#==============
dotfiles_dir=`pwd`
log_file=~/install_progress_log.txt

#==============
# Delete existing dot files and folders
#==============
rm -rf ~/.bashrc > /dev/null 2>&1
rm -rf ~/.bash_aliases > /dev/null 2>&1
rm -rf ~/.gitconfig > /dev/null 2>&1

#==============
# Create symlinks in the home folder
# Allow overriding with files of matching names in the custom-configs dir
#==============
# ln -sf $dotfiles_dir/vim ~/.vim
# ln -sf $dotfiles_dir/vimrc ~/.vimrc
ln -sf $dotfiles_dir/bash/.bashrc ~/.bashrc
ln -sf $dotfiles_dir/bash/.bash_aliases ~/.bash_aliases
ln -sf $dotfiles_dir/git/.gitconfig ~/.gitconfig
# ln -sf $dotfiles_dir/linux-tmux ~/.tmux
# ln -sf $dotfiles_dir/zsh/zsh_prompt ~/.zsh_prompt
# ln -sf $dotfiles_dir/zsh/zshrc ~/.zshrc
# ln -sf $dotfiles_dir/custom-configs/custom-snips ~/.vim/custom-snips

# if [ -n "$(find $dotfiles_dir/custom-configs -name gitconfig)" ]; then
#     ln -s $dotfiles_dir/custom-configs/**/gitconfig ~/.gitconfig
# else
#     ln -s $dotfiles_dir/gitconfig ~/.gitconfig
# fi
#
# if [ -n "$(find $dotfiles_dir/custom-configs -name tmux.conf)" ]; then
#     ln -s $dotfiles_dir/custom-configs/**/tmux.conf ~/.tmux.conf
# else
#     ln -s $dotfiles_dir/linux-tmux/tmux.conf ~/.tmux.conf
# fi
#
# if [ -n "$(find $dotfiles_dir/custom-configs -name tigrc)" ]; then
#     ln -s $dotfiles_dir/custom-configs/**/tigrc ~/.tigrc
# else
#     ln -s $dotfiles_dir/tigrc ~/.tigrc
# fi
#
# if [ -n "$(find $dotfiles_dir/custom-configs -name psqlrc)" ]; then
#     ln -s $dotfiles_dir/custom-configs/**/psqlrc ~/.psqlrc
# else
#     ln -s $dotfiles_dir/psqlrc ~/.psqlrc
# fi

#==============
# Set bash as the default shell
#==============
sudo chsh -s /bin/bash
source ~/.bashrc
source ~/.bash_aliases

#==============
# Give the user a summary of what has been installed
#==============
echo -e "\n====== Summary ======\n"
cat $log_file
echo
echo "Enjoy -Alv"
rm $log_file
