"==============================================================================
" Leader Key
"==============================================================================
let mapleader = " "                   " Using Space as leader key

"==============================================================================
" 1. Plugin Manager (vim-plug)
"==============================================================================
call plug#begin('~/.vim/plugged')

Plug 'itchyny/lightline.vim'    " Status/tab line enhancement
Plug 'eraserhd/parinfer-rust'  " Structural editing for Lisp-like languages
Plug 'ap/vim-css-color'        " Preview CSS colors inline
Plug 'vimwiki/vimwiki'         " Personal wiki in Markdown
Plug 'tpope/vim-surround'      " Quick surrounding of text objects
Plug 'ron-rs/ron.vim'          " RON format syntax
Plug 'elkowar/yuck.vim'        " Yuck language support
Plug 'Yggdroot/indentLine'     " Display indentation levels

call plug#end()

"==============================================================================
" 2. Filetype & Syntax
"==============================================================================
syntax on                          " Enable syntax highlighting
filetype plugin indent on         " Enable filetype detection, plugins, indent

"==============================================================================
" 3. UI, Statusline & Scrolling
"==============================================================================
set laststatus=2                   " Always show status line
set noshowmode                     " Hide built-in --MODE-- (lightline shows it)
set t_Co=256                       " 256-color support
set showcmd                        " Show partial commands in status line
set cursorcolumn                   " Highlight current column
set showmatch                      " Briefly jump to matching bracket
set history=1000                   " Command history size
set lazyredraw                     " Optimize redrawing for macros
set ttyfast                        " Assume fast terminal for optimized redraw

" Line numbering (always on for context)
set number                         " Absolute line numbers
set relativenumber                 " Relative line numbers to cursor

" Mouse and Scrolling:
set mouse=a                        " Enable mouse support for all modes
set scrolloff=999                  " Keep cursor centered vertically when scrolling
set sidescrolloff=5                " Minimal columns to keep cursor from screen edge

"==============================================================================
" 4. Searching & Completion
"==============================================================================
" incsearch: show matches as you type; without it Vim waits for <Enter>
set incsearch                      " Incremental search
set ignorecase                     " Ignore case in search patterns
set smartcase                      " Override ignorecase when pattern has uppercase
set wildmenu                       " Enhanced command-line completion
set path+=**                       " Recursive file search for :find

"==============================================================================
" 5. File Backup & Swap
"==============================================================================
set nobackup                       " OFF: no ~ backups (risk losing previous versions)
" set backup                       " ON: create ~ backup before overwrite (uncomment to enable)
set noswapfile                     " OFF: no .swp swap files (no crash recovery)
" set swapfile                     " ON: create .swp for crash recovery (uncomment to enable)

"==============================================================================
" 6. Tabs & Indentation
"==============================================================================
set expandtab                      " Use spaces instead of actual tab
set smarttab                       " Tab at line start respects shiftwidth
set shiftwidth=4                   " Spaces per indent level
set tabstop=4                      " Spaces a Tab counts for
set autoindent                     " Copy indent from current line

"==============================================================================
" 7. Window Splitting
"==============================================================================
" Built-in splits:
"   <C-w>s => horizontal split
"   <C-w>v => vertical split
"   <C-w>o => close other windows
set splitbelow                     " Horizontal splits open below
set splitright                     " Vertical splits open to the right

" Toggle orientation:
let g:split_direction = 'horizontal'
function! ToggleSplitOrientation()
  " Flip orientation and reposition current window
    if g:split_direction ==# 'horizontal'
        let g:split_direction = 'vertical'
        wincmd t                      " Move to top of stack
        wincmd H                      " Move to far left
    else
        let g:split_direction = 'horizontal'
        wincmd t                      " Move to top
        wincmd K                      " Move to far top
    endif
endfunction
nnoremap <Leader>sw :call ToggleSplitOrientation()<CR>

"==============================================================================
" 8. Lightline Configuration
"==============================================================================
let g:lightline = {
  \ 'colorscheme': 'darcula',
  \ 'active': {
  \   'left':  [['mode','paste'], ['readonly','modified','absolutepath']]
  \ },
  \ 'component': {
  \   'absolutepath': '%F',
  \   'lineinfo':     '%l:%L'
  \ }
\}
"==============================================================================
" 9. Vimwiki (Markdown)
"==============================================================================
let g:vimwiki_list = [{ 'path': '~/vimwiki/', 'syntax': 'markdown', 'ext': '.md' }]

"==============================================================================
" 10. Normal-mode Mappings
"==============================================================================
" New line below, keep cursor at same column
nnoremap H o<ESC>k

" New line above, keep cursor at same column
nnoremap Y O<ESC>j

" Prepend '#' at start of line
nnoremap <Leader>3 I#<Esc>

" Insert timestamp
nnoremap <F3> o<C-R>=strftime("%A %d of %B %Y %H:%M hrs")<CR><Esc>

" Function: Toggle between absolute and relative line numbering
function! ToggleNumbering()
    if &relativenumber
        set nonumber norelativenumber
    else
        set number relativenumber
    endif
endfunction

" Toggle line numbering
nnoremap <F5> :call ToggleNumbering()<CR>
"==============================================================================
" 11. Insert-mode Mappings
"==============================================================================
" Exit insert mode quickly
inoremap jj <Esc>

" Save file and exit
inoremap zz <Esc>ZZ

" Auto-close backticks
inoremap ` ``<Left>

" Auto-close diaeresis
inoremap ¨ ""<Left>

" Auto-close single quotes
inoremap ' ''<Left>

" Auto-close double quotes
inoremap " ""<Left>

" Auto-close angle brackets
inoremap < <><Left>

" Auto-close parentheses
inoremap ( ()<Left>

" Auto-close square brackets
inoremap [ []<Left>

" Auto-close braces
inoremap { {}<Left>

" Auto-close braces with newline
inoremap {<CR> {<CR>}<Esc>O

" Auto-close braces+semicolon
inoremap {;<CR> {<CR>};<Esc>O

" Markdown comment snippet
inoremap /// [//]: # ()<Left>

" JS block comment snippet
inoremap /* /**/<Left><Left>

" HTML comment snippet
inoremap <! <!----><Left><Left><Left>

" Inline timestamp
inoremap <F3> <C-R>=strftime("%A %d of %B %Y %H:%M hrs ")<CR>
"==============================================================================
" 12. Cursor Shape
"==============================================================================
" Cursor styles for Insert (t_SI) and Normal (t_EI):
" Ps=0 blinking block, Ps=1 blinking block (default)
" Ps=2 steady block, Ps=3 blinking underline
" Ps=4 steady underline, Ps=5 blinking bar (xterm)
" Ps=6 steady bar (xterm)
let &t_SI = "\e[6 q"   " Insert mode: steady bar (Ps=6)"
let &t_EI = "\e[2 q"   " Normal mode: steady block (Ps=2)"

"==============================================================================
" 13. Custom Highlight Groups
"==============================================================================
highlight LineNr        ctermfg=8   ctermbg=none    " Line numbers color
highlight CursorLineNr  ctermfg=7   ctermbg=8       " Active line number
highlight VertSplit     ctermfg=0   ctermbg=8       " Vertical split bar
highlight StatusLine    ctermfg=7   ctermbg=8       " Active status line
highlight StatusLineNC  ctermfg=7   ctermbg=8       " Inactive status line
highlight Comment       ctermfg=4   ctermbg=none    " Comment text
highlight Constant      ctermfg=12  ctermbg=none    " Constants & numbers
highlight Identifier    ctermfg=6   ctermbg=none    " Functions & variables
highlight PreProc       ctermfg=5   ctermbg=none    " Preprocessor text
highlight String        ctermfg=12  ctermbg=none    " String literals
highlight Number        ctermfg=1   ctermbg=none    " Number literals
highlight Function      ctermfg=1   ctermbg=none    " Function names
highlight CursorColumn  ctermbg=236                      " Current column bg
highlight CursorLine    ctermbg=236                      " Current line bg (if enabled)
highlight ColorColumn   ctermbg=236                      " Colorcolumn bg

" Desactivar completamente la funcionalidad conceal
set conceallevel=0
set concealcursor=
let g:indentLine_setConceal = 0

