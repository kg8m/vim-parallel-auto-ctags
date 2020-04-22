let s:Promise = vital#parallel_auto_ctags#import("Async.Promise")

function! parallel_auto_ctags#create_all() abort  " {{{
  for entry_point in keys(g:parallel_auto_ctags#entry_points)
    call parallel_auto_ctags#create(entry_point)
  endfor
endfunction  " }}}

function! parallel_auto_ctags#create(entry_point) abort  " {{{
  call timer_start(300, { -> s:create(a:entry_point) })
endfunction  " }}}

function! parallel_auto_ctags#clean_up() abort  " {{{
  for entry_point in keys(g:parallel_auto_ctags#entry_points)
    let config = s:config_for(entry_point)

    if empty(config)
      continue
    endif

    let lock_filepath = config.path . "/" . s:lock_filename()
    let temp_filepath = config.path . "/" . s:temp_filename()

    if filereadable(lock_filepath)
      call delete(lock_filepath)
    endif

    if filereadable(temp_filepath)
      call delete(temp_filepath)
    endif
  endfor
endfunction  " }}}

function! s:create(entry_point) abort  " {{{
  let config = s:config_for(a:entry_point)

  if empty(config)
    return
  endif

  if !isdirectory(config.path)
    call s:warn("Path (" . string(config.path) . ") for " . string(a:entry_point) . " doesn't exist.")
    return
  endif

  let tags_file = config.path . "/" . g:parallel_auto_ctags#filename
  let lock_file = config.path . "/" . s:lock_filename()
  let temp_file = config.path . "/" . s:temp_filename()

  if filereadable(lock_file)
    return
  endif

  let setup_command    = ["touch", lock_file]
  let replace_command  = ["mv", "-f", temp_file, tags_file]
  let teardown_command = ["rm", "-f", lock_file]

  let options = get(config, "options", g:parallel_auto_ctags#options)
  let ctags_command = [g:parallel_auto_ctags#executable] + options + ["-f", temp_file]

  call s:sh(setup_command)
         \.then({ -> s:sh(ctags_command) })
         \.then({ -> s:sh(replace_command) })
         \.then({ -> s:sh(teardown_command) })
endfunction  " }}}

function! s:config_for(entry_point) abort  " {{{
  let config = get(g:parallel_auto_ctags#entry_points, a:entry_point, {})

  if empty(config)
    call s:warn("Entry point as " . string(a:entry_point) . " not defined.")
  endif

  return config
endfunction  " }}}

function! s:lock_filename() abort  " {{{
  return g:parallel_auto_ctags#filename . ".lock"
endfunction  " }}}

function! s:temp_filename() abort  " {{{
  return g:parallel_auto_ctags#filename . ".temp"
endfunction  " }}}

" https://github.com/vim-jp/vital.vim/blob/master/doc/vital/Async/Promise.txt
function! s:read(channel, part) abort  " {{{
  let out = []
  while ch_status(a:channel, #{ part: a:part }) =~# 'open\|buffered'
    call add(out, ch_read(a:channel, #{ part: a:part }))
  endwhile
  return join(out, "\n")
endfunction  " }}}

function! s:sh(command) abort  " {{{
  return s:Promise.new({ resolve, reject -> job_start(a:command, #{
       \   drop:     "never",
       \   close_cb: { ch -> "do nothing" },
       \   exit_cb:  { ch, code -> code ? reject(s:read(ch, "err")) : resolve(s:read(ch, "out")) },
       \ }) })
endfunction  " }}}

function! s:warn(message) abort  " {{{
  echohl ErrorMsg
  echomsg a:message
  echohl None
endfunction  " }}}