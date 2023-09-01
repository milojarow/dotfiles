"""""""""""""""""""""""""""""""""""
"1 => Vim plug (default plugin manager)
"""""""""""""""""""""""""""""""""""

call plug#begin('~/.vim/plugged')

Plug 'itchyny/lightline.vim'
Plug 'eraserhd/parinfer-rust'
Plug 'ap/vim-css-color'
Plug 'vimwiki/vimwiki'
Plug 'tpope/vim-surround'
Plug 'ron-rs/ron.vim'
Plug 'elkowar/yuck.vim'
Plug 'Yggdroot/indentLine'

call plug#end()
"""""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""""
" Lightline required lines
""""""""""""""""""""""""""""""""
set laststatus=2

set t_Co=256

set noshowmode

set statusline=%F

"""""""""""""""""""""""""""""""""
"2 => my default values
"""""""""""""""""""""""""""""""""
"syntax on              "deactivated it to use @dt syntax enable
set number relativenumber
"filetype on            "deactivated it to use @dt filetype conf
"filetype plugin on     "deactivated it to use @dt filetype conf
set cursorline
set cursorcolumn
set showmatch
set history=1000
set autoindent
set showcmd
set lazyredraw
set ttyfast
""""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""""
" 2.1 => tabs
""""""""""""""""""""""""""""""""
set expandtab           " use spaces instead of tabs
set smarttab
set splitbelow splitright
set path+=**            " searches current directory recursively
set wildmenu            " display all matches when tab complete
set incsearch
set nobackup
set noswapfile

" 1 tab == 4 spaces
set shiftwidth=4
set tabstop=4
"""""""""""""""""""""""""""""""""
"2.2 toggle splitted windows vertical to horizontal
"""""""""""""""""""""""""""""""""
let s:split_direction = 'horizontal'

function! ToggleSplitOrientation()
    if s:split_direction ==# 'horizontal'
        let s:split_direction = 'vertical'
        execute 'wincmd t'
        execute 'wincmd H'
    else
        let s:split_direction = 'horizontal'
        execute 'wincmd t'
        execute 'wincmd K'
    endif
endfunction

nnoremap <Leader>sw :call ToggleSplitOrientation()<CR>

"""""""""""""""""""""""""""""""""
"3 => Three settings required by vimwiki plugin
"""""""""""""""""""""""""""""""""
syntax enable           "vimwiki says to use syntax on instead of syntax enable
"filetype off           "replaced for filetype plugin indent on below
"set nocompatible       "required but deactivated cuz causes double INSERT
"""""""""""""""""""""""""""""""""

filetype plugin indent on " required

" To ignore plugin indent changes, instead use:
"filetype plugin on

"===============================
" lightline customs
"===============================

"*******************************
" script to show the absolute path in status bar
let g:lightline = {
      \ 'colorscheme': 'darcula',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'readonly', 'modified', 'absolutepath' ] ]
      \ },
      \ 'component': {
      \   'absolutepath': '%F'
      \ },
      \ }
""""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""""
"let g:rehash256 = 1
""""""""""""""""""""""""""""""""
"
"===============================
" VimWiki default markdown
"===============================
let g:vimwiki_list = [{'path': '~/vimwiki/',
                      \ 'syntax': 'markdown', 'ext': '.md'}]

"""""""""""""""""""""""""""""""""
"4 => n Remaps
"""""""""""""""""""""""""""""""""
"create new line below while keeping cursor position
nnoremap H o<ESC>k
"create new line above while keeping cursor position
nnoremap Y O<ESC>j
"add # to line
nnoremap <leader>3 I#<esc>
"timestamp
nnoremap <F3> o<C-R>=strftime("%A %d of %B %Y %H:%M hrs")<CR><Esc>
"""""""""""""""""""""""""""""""""

"""""""""""""""""""""""""""""""""
"4.2 => keboard shortcuts
"""""""""""""""""""""""""""""""""
function! ToggleNumbering()
    if(&relativenumber == 1)
        set nonumber
        set norelativenumber
    else
        set number
        set relativenumber
    endif
endfunction
"""""""""""""""""""""""""""""""""
nnoremap <F5> :call ToggleNumbering()<CR>
"""""""""""""""""""""""""""""""""

"""""""""""""""""""""""""""""""""
"5 => i Remaps
"""""""""""""""""""""""""""""""""
"timestamp
inoremap <F3> <C-R>=strftime("%A %d of %B %Y %H:%M hrs ")<CR>
"markdown comment
inoremap /// [//]: # ()<left>

"saves and exit while in insert mode
inoremap zz <esc>ZZ

"back to norm mode
inoremap jj <esc><right>

"gets your cursor out of brackets (keeps u in insert mode)
inoremap hh <esc>A
inoremap kk <esc>a<right>

"autoclose shit
inoremap ` ``<left>
inoremap ¨ ""<left>
"inoremap " ""<left>
inoremap ' ''<left>
inoremap < <><left>
inoremap ( ()<left>
inoremap [ []<left>
inoremap { {}<left>
inoremap {<CR> {<CR>}<ESC>O
inoremap {;<CR> {<CR>};<ESC>O

"comment syntax for JS
inoremap /* /**/<left><left>

"comment syntax for HTML
inoremap <! <!----><left><left><left>
"""""""""""""""""""""""""""""""""

"""""""""""""""""""""""""""""""""
"6 => Reference Chart of Cursor types/values;
"""""""""""""""""""""""""""""""""
"  Ps = 0 -> blinking block.
"  Ps = 1 -> blinking block (default).
"  Ps = 2 -> steady block.
"  Ps = 3 -> blinking underline.
"  Ps = 4 -> steady underline.
"  Ps = 5 -> blinking bar (xterm).
"  Ps = 6 -> steady bar (xterm).
let &t_SI = "\e[6 q"
let &t_EI = "\e[2 q"
"""""""""""""""""""""""""""""""""

"""""""""""""""""""""""""""""""""
"7 => Colors
"""""""""""""""""""""""""""""""""
  highlight LineNr        ctermfg=8       ctermbg=none    cterm=none
  highlight CursorLineNr  ctermfg=7       ctermbg=8       cterm=none
  highlight VertSplit     ctermfg=0       ctermbg=8       cterm=none
  highlight Statement     ctermfg=2       ctermbg=none    cterm=none
  highlight Directory     ctermfg=4       ctermbg=none    cterm=none
  highlight StatusLine    ctermfg=7       ctermbg=8       cterm=none
  highlight StatusLineNC  ctermfg=7       ctermbg=8       cterm=none
  highlight Comment       ctermfg=4       ctermbg=none    cterm=none
  highlight Constant      ctermfg=12      ctermbg=none    cterm=none
  highlight Special       ctermfg=4       ctermbg=none    cterm=none
  highlight Identifier    ctermfg=6       ctermbg=none    cterm=none
  highlight PreProc       ctermfg=5       ctermbg=none    cterm=none
  highlight String        ctermfg=12      ctermbg=none    cterm=none
  highlight Number        ctermfg=1       ctermbg=none    cterm=none
  highlight Function      ctermfg=1       ctermbg=none    cterm=none
" highlight WildMenu      ctermfg=0       ctermbg=80      cterm=none
" highlight Folded        ctermfg=103     ctermbg=234     cterm=none
" highlight FoldColumn    ctermfg=103     ctermbg=234     cterm=none
" highlight DiffAdd       ctermfg=none    ctermbg=23      cterm=none
" highlight DiffChange    ctermfg=none    ctermbg=56      cterm=none
" highlight DiffDelete    ctermfg=168     ctermbg=96      cterm=none
" highlight DiffText      ctermfg=0       ctermbg=80      cterm=none
" highlight SignColumn    ctermfg=244     ctermbg=235     cterm=none
" highlight Conceal       ctermfg=251     ctermbg=none    cterm=none
" highlight SpellBad      ctermfg=168     ctermbg=none    cterm=underline
" highlight SpellCap      ctermfg=80      ctermbg=none    cterm=underline
" highlight SpellRare     ctermfg=121     ctermbg=none    cterm=underline
" highlight SpellLocal    ctermfg=186     ctermbg=none    cterm=underline
" highlight TabLine       ctermfg=244     ctermbg=234     cterm=none
" highlight TablineSel    ctermfg=0       ctermbg=247     cterm=none
" highlight TablineFill   ctermfg=244     ctermbg=234     cterm=none
  highlight CursorColumn  ctermfg=none    ctermbg=236     cterm=none
  highlight CursorLine    ctermfg=none    ctermbg=236     cterm=none
  highlight ColorColumn   ctermfg=none    ctermbg=236     cterm=none
" highlight Cursor        ctermfg=0       ctermbg=S       cterm=none
" highlight htmlEndTag    ctermfg=144     ctermbg=none    cterm=none
" highlight xmlEndTag     ctermfg=144     ctermbg=none    cterm=none
"""""""""""""""""""""""""""""""""


