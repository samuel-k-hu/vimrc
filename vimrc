" vimrc — A simple Vim configuration that relies on
"                           small utilities rather than plugins
"
" Copyright (c) 2026-present samuel-k-hu <zongnan.hu@gmail.com>
" Licensed under the BSD 2-Clause License
"
" project repository: https://github.com/samuel-k-hu/vimrc
" related utilities: https://github.com/samuel-k-hu/uutils
"

" --- Basics

set nocompatible
set number
set noswapfile
set nobackup
set ruler
set showcmd
set incsearch
set notimeout

nnoremap <expr> j v:count ? 'j' : 'gj'
nnoremap <expr> k v:count ? 'k' : 'gk'
vnoremap <expr> j v:count ? 'j' : 'gj'
vnoremap <expr> k v:count ? 'k' : 'gk'

" Disable all automatic indentation and smart behavior
set noautoindent
set nocindent
set nosmartindent
set indentexpr=

" Make <Tab> a literal tab character
set noexpandtab
set tabstop=8
set shiftwidth=8
set softtabstop=0

" Auto save
autocmd InsertLeave,CmdlineEnter *  update

" Disable filetype detection, plugins, and indentation
filetype off

" Disable syntax highlighting
syntax off

" Set <leader>
let mapleader = " "

" Trimming trailing whitespace
nnoremap <leader>tw :%s/\s\+$//e<CR>
vnoremap <leader>tw :s/\s\+$//e<CR>

" --- File opening
" Use external fzy/fzf to select files

function! SmartFuzzyCommand(choice_command, vim_command)
  if executable('fzy')
    let tool = 'fzy'
  elseif executable('fzf')
    let tool = 'fzf'
  else
    echoerr "Neither fzy nor fzf found in PATH."
    return
  endif

  try
    let output = system(a:choice_command . ' | ' . tool)
  catch /Vim:Interrupt/
    return
  endtry
    redraw!
  if v:shell_error == 0 && !empty(output)
    exec a:vim_command . ' ' . output
  endif
endfunction

if has('win32') || has('win64')
  if executable('fd')
    nnoremap <leader>f :call SmartFuzzyCommand("fd --type f --hidden --exclude .git", ":tabnew")<CR>
  else
    nnoremap <leader>f :echo "fd not found in PATH."<CR>
  endif
else
  nnoremap <leader>f :call SmartFuzzyCommand("find . -type f -not -path '**/.git/**'", ":tabnew")<CR>
endif

function! SmartFuzzyOldfiles(vim_command)
  let oldfiles_filtered = filter(copy(v:oldfiles), 'filereadable(v:val)')

  if empty(oldfiles_filtered)
    echo "No valid oldfiles found."
    return
  endif

  if executable('fzy')
    let tool = 'fzy'
  elseif executable('fzf')
    let tool = 'fzf'
  else
    echoerr "Neither fzy nor fzf found in PATH."
    return
  endif
  redraw!

  try
    let input = join(oldfiles_filtered, "\n")
    let output = system(tool, input)
  catch /Vim:Interrupt/

  endtry

  redraw!
  if v:shell_error == 0 && !empty(output)
    exec a:vim_command . ' ' . fnameescape(trim(output))
  endif
endfunction

nnoremap <leader>r :call SmartFuzzyOldfiles(':tabnew')<CR>

" --- Check code

" Perl

function! CheckPerlSyntaxMake() abort
  let save_make = &makeprg
  let save_efm  = &errorformat

  let &makeprg = 'perl -c %'
  let &errorformat = '%+A%.%# at %f line %l%m'

  silent make

  let &makeprg = save_make
  let &errorformat = save_efm

  let qf = getqflist()
  let qf = filter(qf, 'has_key(v:val,"lnum") && v:val.lnum > 0')
  call setqflist(qf, 'r')

  redraw!
  if !empty(getqflist())
    copen
  else
    echo "Perl syntax OK"
    cclose
  endif
endfunction

nnoremap <leader>cp :call CheckPerlSyntaxMake()<CR>

" C

function! CheckCSyntaxMake() abort
  let save_make = &makeprg
  let save_efm  = &errorformat

  let &makeprg = 'clang -fsyntax-only -Wall -Wextra %'
  let &errorformat = '%f:%l:%c:%m'

  silent make

  let &makeprg = save_make
  let &errorformat = save_efm

  let qf = getqflist()
  let qf = filter(qf, 'has_key(v:val,"lnum") && v:val.lnum > 0')
  call setqflist(qf, 'r')

  redraw!
  if !empty(getqflist())
    copen
  else
    echo "C syntax OK"
    cclose
  endif
endfunction

nnoremap <leader>cc :call CheckCSyntaxMake()<CR>

" English

function! CheckSpellMake() abort
  let save_make = &makeprg
  let save_efm  = &errorformat

  let &makeprg = 'hunspell_check %'
  let &errorformat = '%f:%l:%m'

  silent make

  let &makeprg = save_make
  let &errorformat = save_efm

  let qf = getqflist()
  let qf = filter(qf, 'has_key(v:val,"lnum") && v:val.lnum > 0')
  call setqflist(qf, 'r')

  redraw!
  if !empty(getqflist())
    copen
  else
    echo "OK"
    cclose
  endif
endfunction

nnoremap <leader>cs :call CheckSpellMake()<CR>

" --- Run code

function! SendCodeToTmux() abort
  normal! gv"zy
  let text = @z
  call system('tmux load-buffer -', text)
  call system('tmux paste-buffer -d')
endfunction

nnoremap <leader>st vip:call SendCodeToTmux()<CR>
xnoremap <leader>st :<C-U>call SendCodeToTmux()<CR>

nnoremap <leader>sv :source %<CR>
nnoremap <leader>sp :!perl %<CR>
