" TODO (2013-03-03) Edit patches by tweaking patch header

let s:file_start_pattern  = 'diff --git a/\zs.\+\ze b/'
let s:patch_start_pattern = '^@@ -\(\d\+\),\(\d\+\) +\(\d\+\),\(\d\+\) @@'

function! gapply#Foldexpr(lnum)
  let line = getline(a:lnum)

  if line =~ s:file_start_pattern
    return '>1'
  elseif line =~ s:patch_start_pattern
    return '>2'
  else
    return '='
  endif
endfunction

function! gapply#Start()
  let header_lines = [
        \ '#',
        \ '# You can edit the diff below and the git index will be changed to reflect its',
        \ '# contents.',
        \ '#',
        \ ]
  call append(0, header_lines)
  exe len(header_lines) . 'r!git diff'
  normal! gg
  $delete _

  set filetype=gapply.diff

  set buftype=acwrite
  autocmd BufWriteCmd <buffer> call s:Sync()
  silent file Gapply
  set nomodified
endfunction

function! s:Sync()
  let tempfile = tempname()
  let lines    = s:Parse()

  call writefile(lines, tempfile)

  call s:System('git reset')
  call s:System('git apply -v --cached '.tempfile)

  set nomodified
endfunction

function! s:Parse()
  let lines          = []
  let header_skipped = 0

  for line in getbufline('%', 1, '$')
    if line =~ '^#' && !header_skipped
      " skip header comment
    elseif !header_skipped
      " we've passed through the header
      let header_skipped = 1
    else
      call add(lines, line)
    endif
  endfor

  return lines
endfunction

function! s:System(command)
  let result = system(a:command)

  if v:shell_error
    echoerr 'External command failed: "'.a:command.'", Message: '.result
  endif

  return result
endfunction
