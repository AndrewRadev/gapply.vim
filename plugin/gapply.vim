if exists('g:loaded_gapply') || &cp
  finish
endif

let g:loaded_gapply = '0.0.1' " version number
let s:keepcpo = &cpo
set cpo&vim

if !exists('g:gapply_foldlevel')
  let g:gapply_foldlevel = 1
endif

command! GapplyCached call gapply#Staged()
command! Gapply call gapply#Unstaged()
command! GapplyShow call gapply#Show()

let &cpo = s:keepcpo
unlet s:keepcpo
