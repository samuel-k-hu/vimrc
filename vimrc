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
set belloff=all

set encoding=utf-8
set fileencoding=utf-8
set fileformats=unix

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

" Disable filetype detection, plugins, and indentation
filetype off

" Disable syntax highlighting
syntax off

" Set <leader>
let mapleader = " "

" Trimming trailing whitespace
augroup before_write_cleanup
  autocmd!
  autocmd BufWritePre * if &modifiable && &buftype == '' |
        \ silent keepjumps %s/\s\+$//e |
        \ endif
augroup END

" Autowrite
augroup autosave_on_insert_leave
  autocmd!
  autocmd InsertLeave * if &modifiable && &buftype == '' | silent write | endif
augroup END

" Autoread
set autoread
if exists('*timer_start')
  function! s:AutoCheckTime(timer)
      if getcmdwintype() == ''
         checktime
      endif
  endfunction

  let g:autoread_timer = timer_start(500, function('s:AutoCheckTime'), {'repeat': -1})
endif

"autocmd BufEnter, TabEnter, InsertEnter * checktime

" --- File opening
" Use external fzy/fzf to select files

if executable('fzy')
  let g:fuzzy_finder  = 'fzy'
elseif executable('fzf')
  let g:fuzzy_finder = 'fzf'
else
  echoerr "fzf or fzy is required for fuzzy searching."
endif


function! FuzzyFindFileInCurrentDir()
  try
    let find_cmd = "find . -name .git -prune -o -type f"
    let file = system(find_cmd . ' | ' . g:fuzzy_finder )
  catch /Vim:Interrupt/
    return
  endtry
    redraw!
  if v:shell_error == 0 && !empty(file)
    exec ':e' . ' ' . file
  endif
endfunction

nnoremap <leader>f :call FuzzyFindFileInCurrentDir()<CR>

function! FuzzyFindOldfile()
  let oldfiles_filtered = filter(copy(v:oldfiles), 'filereadable(expand(v:val))')

  if empty(oldfiles_filtered)
    echo "No valid oldfiles found."
    return
  endif

  try
    let input = join(oldfiles_filtered, "\n")
    let output = system(g:fuzzy_finder, input)
  catch /Vim:Interrupt/

  endtry

  redraw!
  if v:shell_error == 0 && !empty(output)
    exec 'e ' . fnameescape(trim(output))
  endif
endfunction

nnoremap <leader>r :call FuzzyFindOldfile()<CR>

function! FuzzyChangeCurrentDirToGitRepo()

  try
    let find_starting_point = !empty($SKH) ? $SKH : $HOME
    let project_roots = system('list_git_repos ' . find_starting_point)
    let output = system(g:fuzzy_finder, project_roots)
  catch /Vim:Interrupt/

  endtry

  redraw!
  if v:shell_error == 0 && !empty(output)
    exec 'cd ' . fnameescape(trim(output))
    call FuzzyFindFileInCurrentDir()
  endif
endfunction

nnoremap <leader>g :call FuzzyChangeCurrentDirToGitRepo()<CR>

function! FuzzyChangeCurrentDir()

  try
    let find_starting_point = !empty($SKH) ? $SKH : $HOME
    let project_roots = system('fd -t d . ' . find_starting_point)
    let output = system(g:fuzzy_finder, project_roots)
  catch /Vim:Interrupt/

  endtry

  redraw!
  if v:shell_error == 0 && !empty(output)
    exec 'cd ' . fnameescape(trim(output))
    call FuzzyFindFileInCurrentDir()
  endif
endfunction

nnoremap <leader>d :call FuzzyChangeCurrentDir()<CR>

function! DeleteBufferAndFile()
    let l:filename = expand('%:p')
    try
        call delete(l:filename)
    catch
        echoerr "Failed to delete file: " . l:filename
        return
    endtry

    execute 'bdelete!'
    echo "Deleted file and closed buffer: " . l:filename
endfunction

nnoremap <leader>D :call DeleteBufferAndFile()<CR>

function! RenameCurrentFileAndBuffer() abort
    let l:oldname = expand('%:p')
    if empty(l:oldname)
        echoerr "Current buffer has no associated file"
        return
    endif

    let l:newname = input('Enter new filename: ', l:oldname, 'file')
    if empty(l:newname)
        echo "Rename cancelled"
        return
    endif

    if filereadable(l:newname)
        echoerr "File already exists: " . l:newname
        return
    endif

    let l:parentdir = fnamemodify(l:newname, ':h')
    if !isdirectory(l:parentdir)
        if mkdir(l:parentdir, 'p')
            echo "Created parent directory: " . l:parentdir
        else
            echoerr "Failed to create parent directory: " . l:parentdir
            return
        endif
    endif

    try
        call rename(l:oldname, l:newname)
    catch
        echoerr "Failed to rename file: " . l:oldname
        return
    endtry

    execute 'bdelete!'
    execute 'edit' fnameescape(l:newname)
    echo "Renamed file and buffer: " . l:oldname . " -> " . l:newname
endfunction

nnoremap <leader>R :call RenameCurrentFileAndBuffer()<CR>

function! OpenTempFile()
  let l:tmp = tempname()
  execute 'edit' fnameescape(l:tmp)
  setlocal buftype=
  setlocal bufhidden=wipe
  setlocal noswapfile
endfunction

nnoremap <leader>t :call OpenTempFile()<CR>
