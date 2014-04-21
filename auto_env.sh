root_dir='pwd'
tools_dir="env_tools"
supertab_tool="supertab"
vimrc_text="syntax on
syntax enable
filetype plugin indent on
set completeopt=longest,menu
set shiftwidth=4
set softtabstop=4
set nu"

#sudo apt-get update
#sudo apt-get upgrade -y
#sudo apt-get install vim -y
#sudo apt-get install git -y

mkdir $tools_dir && cd $tools_dir

### vim
rm -rf ~/.vimrc
echo -e "$vimrc_text" > ~/.vimrc

git clone https://github.com/ervandew/supertab.git
cd $supertab_tool && make && make install && cd root_dir

### git auto completion
wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
cp -rf git-completion.bash ~/.git-completion.sh
echo "source ~/.git-completion.sh" >> ~/.bashrc

### git shortcuts
cp -rf gitconfig ~/.gitconfig
