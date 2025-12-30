
" For all text files set 'textwidth' to 78 characters.
autocmd FileType text setlocal textwidth=78

" Search Configuration
set ignorecase          " Case Insensitivity
set smartcase           " Unless explicit match
set incsearch           " Highlight Matching as I type
set hlsearch            " Highlight Matches

" Other Settings
set updatetime=100        " Mainly for git gutter update
set expandtab             " Use spaces instead of tabs
set title                 " Set the terminal title
set autoindent            " Enable auto-indenting on new lines
set copyindent            " Copy previous indenting
set tabstop=2             " Number of spaces that a <Tab> in the file counts for
set shiftwidth=2          " Number of spaces to use for each step of (auto)indent
set laststatus=2          " Always display the status line
set hidden                " Allow hiding buffers with unsaved changes
set number                " Show line numbers
set background=dark       " Set background to dark
set backspace=indent,eol,start " Set backspace behavior

" Force Defaults to UTF-8
set encoding=utf-8

" Open NERDTree in the directory of the current file
"autocmd VimEnter * if argc() > 0 | execute 'NERDTree' fnameescape(fnamemodify(argv(0), ':p:h')) | wincmd w | endif

"autocmd BufWinEnter * if &buftype == '' && argc() > 0 | execute 'NERDTree' fnameescape(expand('%:p:h')) | wincmd p | endif

" Set fileencoding via autocmd
augroup set_fileencoding
  autocmd!
  autocmd BufRead,BufNewFile * setlocal fileencoding=utf-8
augroup END

" Enable Mouse Support with SGR (xterm 1006 mouse support for more lines)
set mouse=a
if !has('nvim')
  "set ttymouse=xterm2
  set ttymouse=sgr
endif

" Ensure NERDTree Mouse Selection Works
let g:NERDTreeMouseMode=3
autocmd FileType nerdtree setlocal mouse=a

" VIM-Markdown Configuration
let g:vim_markdown_folding_disabled=1

" Syntax Highlighting and Filetype Settings
syntax on
au BufNewFile,BufRead Jenkinsfile setf groovy

" Set autoreading to on
set autoread
au CursorHold * checktime

" Install vim-plug if not installed
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Specify a directory for plugins
call plug#begin('~/.vim/plugged')

" On-demand loading
Plug 'nathanaelkane/vim-indent-guides'
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'scrooloose/nerdcommenter'
Plug 'airblade/vim-gitgutter'
Plug 'bling/vim-airline'
Plug 'flazz/vim-colorschemes'
Plug 'scrooloose/syntastic'

call plug#end()

" Colors
 colorscheme iceberg
" colorscheme molokai

" GitGutter Settings
let g:gitgutter_enabled = 1
function! ToggleGitGutter()
  if g:gitgutter_enabled
    GitGutterDisable
    let g:gitgutter_enabled = 0
  else
    GitGutterEnable
    let g:gitgutter_enabled = 1
  endif
endfunction
" Map Ctrl+g to toggle GitGutter
map <C-g> :call ToggleGitGutter()<CR>

" NERDTree Settings
let g:NERDTreeWinSize=25
let g:NERDTreeShowHidden=1         " Show hidden files
map <C-n> :NERDTreeToggle<CR>      " Open NERDTree with Ctrl+n 

" Indent Guides Settings
let g:indent_guides_enable_on_vim_startup = 1
set ts=4 sw=4 et
let g:indent_guides_start_level = 2
let g:indent_guides_guide_size = 1 


" Copy Mode
let g:copy_mode = 0
function! ToggleCopyMode()
  if g:copy_mode == 0
    " Enter copy mode: close everything
    NERDTreeClose
    GitGutterDisable
    set nonumber norelativenumber
    let g:copy_mode = 1
  else
    " Exit copy mode: enable everything
    set number
    " Open NERDTree in the current file's directory
    execute 'NERDTree' fnameescape(expand('%:p:h'))
    GitGutterEnable
    let g:copy_mode = 0
  endif
endfunction
nnoremap <Leader><CR> :call ToggleCopyMode()<CR>

" Autocommand Group for Additional Settings
augroup vimrcEx
  autocmd!
  " Close Vim if NERDTree is the only window remaining
  autocmd BufEnter * if winnr('$') == 1 && &filetype == 'nerdtree' | quit | endif
  " When editing a file, always jump to the last known cursor position.
  autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif
augroup END
