" vimrc — a simple Vim configuration file
"
" Copyright (c) 2026-present samuel-k-hu <zongnan.hu@gmail.com>
" Licensed under the BSD 2-Clause License

" --- Basics

set nocompatible
set number

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

" Disable filetype detection, plugins, and indentation
filetype off

" Disable syntax highlighting
syntax off

" Disable filetype detection, plugins, and indentation
filetype off


" Disable syntax highlighting
syntax off

" Set <leader>
let mapleader = " "

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

if executable('fd')
  nnoremap <leader>e :call SmartFuzzyCommand("fd --type f --hidden --exclude .git", ":tabnew")<CR>
elseif executable('find')
  nnoremap <leader>e :call SmartFuzzyCommand("find . -type f -not -path '**/.git/**'", ":tabnew")<CR>
else
  nnoremap <leader>e :echo "Neither fd nor find found in PATH."<CR>
endif


function! SmartFuzzyOldfiles(vim_command)
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
    let input = join(v:oldfiles, "\n")
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
    echo "Perl syntax OK ✅"
    cclose
  endif
endfunction

nnoremap <leader>cp :call CheckPerlSyntaxMake()<CR>

" --- Run code

function! SmartSendToTmux() abort
  normal! gv"zy
  let text = @z
  call system('tmux load-buffer -', text)
  call system('tmux paste-buffer -d')
endfunction

nnoremap <leader>t vip:call SmartSendToTmux()<CR>
xnoremap <leader>t :<C-U>call SmartSendToTmux()<CR>

