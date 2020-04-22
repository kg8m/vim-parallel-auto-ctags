let g:parallel_auto_ctags#executable   = get(g:, "parallel_auto_ctags#executable", "ctags")
let g:parallel_auto_ctags#filename     = get(g:, "parallel_auto_ctags#filename", "tags")
let g:parallel_auto_ctags#options      = get(g:, "parallel_auto_ctags#options", [])
let g:parallel_auto_ctags#entry_points = get(g:, "parallel_auto_ctags#entry_points", {})

function! s:define_autocmds() abort  " {{{
  augroup parallel_auto_ctags  " {{{
    autocmd!
    autocmd VimLeavePre  * silent call parallel_auto_ctags#clean_up()

    for entry_point in keys(g:parallel_auto_ctags#entry_points)
      let config = g:parallel_auto_ctags#entry_points[entry_point]
      let command_body = "call parallel_auto_ctags#create(" . string(entry_point) . ")"

      if get(config, "silent", v:false)
        let command_body = "silent " . command_body
      endif

      for event in config.events
        execute "autocmd " . event . " * " . command_body
      endfor
    endfor
  augroup END  " }}}
endfunction  " }}}
call s:define_autocmds()
