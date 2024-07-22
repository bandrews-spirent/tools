:set hlsearch

autocmd BufRead,BufNewFile Jenkinsfile set filetype=groovy tabstop=4 softtabstop=4 shiftwidth=4 expandtab smarttab autoindent retab
autocmd BufRead,BufNewFile py set filetype=python tabstop=4 softtabstop=4 shiftwidth=4 expandtab smarttab autoindent retab

" Enable type file detection. Vim will be able to try to detect the type of file in use.
filetype on

" Enable plugins and load plugin for the detected file type.
filetype plugin on

" Load an indent file for the detected file type.
filetype indent on

" Turn syntax highlighting on.
syntax on

" Set shift width to 4 spaces.
:set shiftwidth=4

" Set tab width to 4 columns.
:set tabstop=4

" Use space characters instead of tabs.
:set expandtab smarttab

:set smartindent

" Delete trailing whitespace on all lines on write.
autocmd BufWritePre * :%s/\s\+$//e

" Make the backspace button work properly in INSERT mode.
:set backspace=indent,eol,start

" Enable auto completion menu after pressing TAB.
:set wildmenu

" Make wildmenu behave like similar to Bash completion.
:set wildmode=list:longest

:colorscheme zellner
