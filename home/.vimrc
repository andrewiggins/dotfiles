"""" Useful Commands
""""
"""" Control+V: Column Select
""""     Shift+I, then Esc: insert characters in front of selected column
""""     x: delete selected column

" General settings
set encoding=utf-8
set backspace=indent,eol,start
set background=dark
set showmode
set showmatch
set laststatus=2
set belloff=all

set nobackup

set colorcolumn=81
set number
set nowrap

" Search
set incsearch
set hlsearch

" Command-line completion
set wildmenu

" Keep context visible when scrolling
set scrolloff=8

" Show signs in the number column
set signcolumn=number

" Persistent undo across sessions
set undofile
set undodir=~/.vim/undodir

" Indentation defaults
set autoindent
set expandtab
set tabstop=4
set shiftwidth=4

" Syntax and filetype detection
syntax on
filetype plugin indent on

" Statusline: show filename, EOL type, last modified timestamp, position
set statusline=%<%F%h%m%r\ [%{&ff}]\ (%{strftime(\"%H:%M\ %d/%m/%Y\",getftime(expand(\"%:p\")))})%=%l,%c%V\ %P

if has("gui_running")
    colorscheme darkblue
endif
