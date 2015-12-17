set autowrite
set nobackup
set nowritebackup
"line numbers
set nu

" Indent length
set shiftwidth=4
" Spaces inserted by pressing TAB
set softtabstop=4
" Expand tabs to spaces
set expandtab
" Cursor pos on bottom line
set ruler
" allow backspacing over everything in insert mode
set backspace=indent,eol,start
" display incomplete commands
set showcmd
" incremental searching
set incsearch
" Ignore case in searches
set ignorecase

"Custom keyboard mappings
"Switch to next window, maximize it
:map <C-W><C-W> <C-W>W <C-W>_

filetype plugin indent on
syntax on

set nobackup

map <F4> :cn<CR>
map <F3> :cp<CR>
map <F5> :silent make %<CR>
map <C-S> :w<CR>
imap <C-S> <ESC>:w<CR>a
map <F6> :make <CR>
map <F7> :silent make  compile<CR>

au BufRead,BufNewFile *.io set filetype=Io


runtime tcs_utils.vim
runtime tcs_editassist.vim
runtime intellisense.vim
runtime erlang.vim

set wildmenu
set wig=*.o,*.pyc
set noswapfile
set statusline=\ %f%m%r%h\ %w\ %{&ff}\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ %50.(%l:%c\|%P%)
set laststatus=2        " always show the status line
                        " format the statusline

set fileformat=unix
set ffs=unix,dos,mac    " behaves good under both linux/windows
set shortmess=atI       " shorten to avoid 'press a key' prompt
set novisualbell        " use visual bell instead of beeping
set noerrorbells        " do not make noise
set magic               " set magic on
set report=0


let g:erlangFold=0

let g:EasyGrepMode=2
let g:EasyGrepRecursive=1
let g:EasyGrepIgnoreCase=0
let g:EasyGrepEveryMatch=1
let g:EasyGrepExtraWarnings=0

map <MiddleMouse> <Nop>
imap <MiddleMouse> <Nop>
map <2-MiddleMouse> <Nop>
imap <2-MiddleMouse> <Nop>
map <3-MiddleMouse> <Nop>
imap <3-MiddleMouse> <Nop>
map <4-MiddleMouse> <Nop>
imap <4-MiddleMouse> <Nop>

set vb

set smartcase
set completeopt=longest,menu,preview

inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

"inoremap <expr> <C-n> pumvisible() ? '<C-n>' :
"  \ '<C-n><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'
"inoremap <expr> <M-,> pumvisible() ? '<C-n>' :
"  \ '<C-x><C-o><C-n><C-p><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'
autocmd VimEnter * set vb t_vb=
