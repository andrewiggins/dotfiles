"""" Useful Commands
"""" 
"""" Control+V: Column Select
""""     Shift+I, then Esc: insert characters in front of selected column
""""     x: delete selected column

" Setting some decent VIM settings for programming

set ai                          " set auto-indenting on for programming (also set autoindent works)
set showmatch                   " automatically show matching brackets. works like it does in bbedit.
"set visualbell                 " turn on the "visual bell" - which is much quieter than the "audio blink"
set ruler                       " show the cursor position all the time
set laststatus=2                " make the last line where the status is two lines deep so you can see status always
set backspace=indent,eol,start  " make that backspace key work the way it should
set nocompatible                " vi compatible is LAME
set background=dark             " Use colours that work well on a dark background (Console is usually black)
set showmode                    " show the current mode
syntax on                       " turn syntax highlighting on by default

" Show EOL type and last modified timestamp, right after the filename
set statusline=%<%F%h%m%r\ [%{&ff}]\ (%{strftime(\"%H:%M\ %d/%m/%Y\",getftime(expand(\"%:p\")))})%=%l,%c%V\ %P

set vb t_vb=                    " turn on visual bell and set it to nothing to neither bell nor visual blink occurs

set nobackup
set bs=2

"set textwidth=80
"set colorcolumn=+1
set colorcolumn=81

set number
set autoindent
syntax on

set expandtab
set tabstop=4
set shiftwidth=4

set nowrap

autocmd! BufNewFile * silent! 0r ~/.vim/skel/template.%:e
" autocmd BufNewFile,BufRead *.xml,*.htm,*.html so ~/.vim/plugin/XMLFolding1.0.vim

" PYTHON
autocmd FileType python set expandtab|set tabstop=4|set shiftwidth=4

" YAML
autocmd FileType yaml set expandtab|set tabstop=2|set shiftwidth=2

" CPP
autocmd FileType cpp set tabstop=4|set shiftwidth=4|set noexpandtab

" CSS
au FileType css set expandtab|set tabstop=2|set shiftwidth=2

" Less
au BufRead,BufNewFile *.less set filetype=less
au FileType less set expandtab|set tabstop=2|set shiftwidth=2

" SCSS
au BufRead,BufNewFile *.scss set filetype=scss

" Typescript
au BufRead,BufNewFile *.ts set filetype=typescript

" JavaScript
au FileType js set expandtab|set tabstop=4|set shiftwidth=4

" HTML
au FileType html set noexpandtab|set tabstop=2|set shiftwidth=2
au FileType html hi htmlLink cterm=NONE ctermfg=9 gui=NONE guifg=#80a0ff

" markdown
au BufRead,BufNewFile *.md set filetype=markdown
au FileType markdown set tabstop=4|set shiftwidth=4|set expandtab
au FileType markdown set textwidth=80
au FileType markdown hi markdownBold cterm=None ctermfg=14 gui=NONE guifg=14
au FileType markdown hi markdownItalic cterm=NONE ctermfg=14 gui=NONE guifg=14
au FileType markdown hi markdownBoldItalic cterm=None ctermfg=14 gui=NONE guifg=14
au FileType markdown hi markdownLinkText cterm=NONE ctermfg=9 gui=NONE guifg=#80a0ff

" ReStructuredText
au FileType rst set textwidth=80
au FileType rst hi rstEmphasis cterm=NONE ctermfg=14 gui=NONE guifg=14

map <F2> <Esc>:cn<CR>
map <F3> <Esc>:cp<CR>
map <F4> <Esc>:make INFILE=% OUTFILE=%:r<CR>
map <F5> <Esc>:!./%:r < %:r.in<CR>
map <F6> <Esc>:make INFILE=% OUTFILE=%:r run<CR>

if has("gui_running")
    colorscheme darkblue
else
    if !&diff
        " Save and reload file views (remembers cursor location and scroll view)
        " However enabling this breaks `vim -d`
        "au VimEnter * loadview
        "au BufWinLeave * mkview
    endif
endif
