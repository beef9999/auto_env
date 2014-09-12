#!/bin/bash

# Note: only for ubuntu

export DEBIAN_FRONTEND=noninteractive

login_user=`whoami`
root_dir=`pwd`
tools_dir="env_tools"
supertab_tool="supertab"
vimrc_text="syntax on
syntax enable
filetype plugin indent on
set completeopt=longest,menu
set expandtab
set ts=4
set hlsearch
set background=dark
set nu
set encoding=utf-8"

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install vim -y
sudo apt-get install git -y

mkdir $tools_dir && cd $tools_dir

### vim
rm -rf ~/.vimrc
echo -e "$vimrc_text" > ~/.vimrc

git clone https://github.com/ervandew/supertab.git
cd $supertab_tool && make && make install && cd root_dir

sudo sed -i -e '/"if\shas("autocmd")/,/"endif/ s/^"//' /etc/vim/vimrc

### git auto completion
wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
cp -rf git-completion.bash ~/.git-completion.sh
echo "source ~/.git-completion.sh" >> ~/.bashrc

### git shortcuts
cd $root_dir
cp -rf gitconfig ~/.gitconfig




