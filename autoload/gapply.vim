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
  call s:UpdateLineCounts()

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

function! s:UpdateLineCounts()
  let patch_lineno = 0
  let old_count    = 0
  let new_count    = 0

  for lineno in range(1, line('$'))
    let line = getline(lineno)

    if line =~ s:patch_start_pattern || line =~ s:file_start_pattern
      " adjust the current patch
      call s:UpdatePatchLine(patch_lineno, old_count, new_count)

      " reset counters
      let old_count = 0
      let new_count = 0

      " reset current patch, and possibly start a new one
      if line =~ s:file_start_pattern
        let patch_lineno = 0
      else " line =~ s:patch_start_pattern
        let patch_lineno = lineno
      endif
    elseif line =~ '^-'
      " deleted line
      let old_count += 1
    elseif line =~ '^+'
      " added line
      let new_count += 1
    else
      " untouched line
      let new_count += 1
      let old_count += 1
    endif
  endfor

  call s:UpdatePatchLine(patch_lineno, old_count, new_count)
endfunction

function! s:UpdatePatchLine(lineno, old_count, new_count)
  let lineno    = a:lineno
  let old_count = a:old_count
  let new_count = a:new_count

  if lineno > 0
    let line = getline(lineno)
    let line = substitute(line, s:patch_start_pattern, '@@ -\1,'.old_count.' +\3,'.new_count.' @@', '')
    call setline(lineno, line)
  endif
endfunction

function! s:System(command)
  let result = system(a:command)

  if v:shell_error
    echoerr 'External command failed: "'.a:command.'", Message: '.result
  endif

  return result
endfunction
