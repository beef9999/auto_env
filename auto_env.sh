tools_dir="env_tools"
supertab_tool="supertab"
vimrc_text="syntax on\n\
syntax enable\n\
filetype plugin indent on\n\
set completeopt=longest,menu\n\
set shiftwidth=4\n\
set softtabstop=4\n\
set nu"

#sudo apt-get update
#sudo apt-get upgrade -y
#sudo apt-get install vim -y
#sudo apt-get install git -y
#git config --global core.editor "vim"

mkdir $tools_dir && cd $tools_dir

### vim
rm -rf ~/.vimrc
echo -e $vimrc_text>~/.vimrc

git clone https://github.com/ervandew/supertab.git
cd $supertab_tool && make && make install

### git auto completion
wget https://github.com/git/git/blob/master/contrib/completion/git-completion.bash
cp -rf git-completion.bash ~/.git-completion.sh
echo "source ~/.git-completion.sh" >> ~/.bashrc

