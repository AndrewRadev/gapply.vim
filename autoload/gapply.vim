let s:file_start_pattern  = 'diff --git a/\zs.\+\ze b/'
let s:patch_start_pattern = '^@@ -\(\d\+\),\(\d\+\) +\(\d\+\),\(\d\+\) @@'

function! s:NewPatch()
  return {
        \ 'file':  '',
        \ 'lines': [],
        \ }
endfunction

function! GapplyFoldexpr(lnum)
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
  set filetype=gitadd.diff
  set buftype=acwrite

  set foldmethod=expr
  set foldexpr=GapplyFoldexpr(v:lnum)
  set foldlevel=1

  silent file Gapply
  set nomodified
  autocmd BufWriteCmd <buffer> call s:Sync()
endfunction

function! s:Sync()
  let patches = s:Parse()
  call s:System('git reset')

  for [patch_id, patch] in items(patches)
    call s:AddPatch(patch_id, patch)
  endfor

  set nomodified
endfunction

function! s:AddPatch(patch_id, patch)
  let patch    = a:patch
  let filename = patch.file

  let lines = [
        \ "--- a/".filename,
        \ "+++ b/".filename,
        \ ]

  call extend(lines, patch.lines)

  let tempfile = tempname()
  call writefile(lines, tempfile)

  call s:System('git apply -v --cached '.tempfile)
endfunction

function! s:Parse()
  let patches       = {}
  let current_file  = ''
  let current_patch = s:NewPatch()

  for lineno in range(1, line('$'))
    let line = getline(lineno)

    if line =~ s:file_start_pattern
      let current_file = matchstr(line, s:file_start_pattern)
    elseif line =~ s:patch_start_pattern && current_file != ''
      let current_patch                  = s:NewPatch()
      let patches[current_file.' '.line] = current_patch
      let current_patch.file             = current_file
      call add(current_patch.lines, line)
    else
      call add(current_patch.lines, line)
    endif
  endfor

  return patches
endfunction

function! s:System(command)
  let result = system(a:command)

  if v:shell_error
    echoerr 'External command failed: '.a:command
  endif

  return result
endfunction
