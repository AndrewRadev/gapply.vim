setlocal foldenable
setlocal foldmethod=expr
setlocal foldexpr=gapply#Foldexpr(v:lnum)
let &l:foldlevel = g:gapply_foldlevel
