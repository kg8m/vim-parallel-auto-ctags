let s:Promise = vital#parallel_auto_ctags#import("Async.Promise")
let s:timers = {}

augroup parallel-auto-ctags
  autocmd!
  autocmd User parallel_auto_ctags_finish silent
augroup END

function! parallel_auto_ctags#create_all() abort  " {{{
  for entry_point in keys(g:parallel_auto_ctags#entry_points)
    call parallel_auto_ctags#create(entry_point)
  endfor
endfunction  " }}}

function! parallel_auto_ctags#create(entry_point, delay = 300) abort  " {{{
  if has_key(s:timers, a:entry_point)
    call timer_stop(s:timers[a:entry_point])
  endif

  let s:timers[a:entry_point] = timer_start(a:delay, { -> s:create(a:entry_point) })
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

function! parallel_auto_ctags#is_running() abort  " {{{
  for entry_point in keys(g:parallel_auto_ctags#entry_points)
    let config = s:config_for(entry_point)

    if empty(config)
      continue
    endif

    let lock_filepath = config.path . "/" . s:lock_filename()

    if filereadable(lock_filepath)
      return v:true
    endif
  endfor

  return v:false
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

  let tags_file = config.path . "/" . g:parallel_auto_ctags#tag_filename
  let lock_file = config.path . "/" . s:lock_filename()
  let temp_file = config.path . "/" . s:temp_filename()

  if filereadable(lock_file)
    call parallel_auto_ctags#create(a:entry_point, 1000 * 5)
    return
  endif

  let setup_command    = ["sh", "-c", "set -o noclobber; printf '' > " . lock_file]
  let replace_command  = ["mv", "-f", temp_file, tags_file]
  let teardown_command = ["rm", "-f", temp_file, lock_file]

  let options = get(config, "options", g:parallel_auto_ctags#options)
  let ctags_command = [g:parallel_auto_ctags#executable] + options + ["-f", temp_file] + [config.path]

  call s:sh(setup_command)
  \.then({ -> s:sh(ctags_command) })
  \.then({ -> s:sh(replace_command) })
  \.catch({ err -> s:warn('Creating tags failed: "' . err . '"') })
  \.finally({ -> s:sh(teardown_command) })
  \.finally({ -> s:notify_finish() })
endfunction  " }}}

function! s:config_for(entry_point) abort  " {{{
  let config = get(g:parallel_auto_ctags#entry_points, a:entry_point, {})

  if empty(config)
    call s:warn("Entry point as " . string(a:entry_point) . " not defined.")
  endif

  return config
endfunction  " }}}

function! s:lock_filename() abort  " {{{
  return g:parallel_auto_ctags#tag_filename . ".lock"
endfunction  " }}}

function! s:temp_filename() abort  " {{{
  return g:parallel_auto_ctags#tag_filename . ".temp"
endfunction  " }}}

" https://github.com/vim-jp/vital.vim/blob/master/doc/vital/Async/Promise.txt
function! s:read(channel, part) abort  " {{{
  let out = []
  while ch_status(a:channel, #{ part: a:part }) =~# 'open\|buffered'
    call add(out, ch_read(a:channel, #{ part: a:part }))
  endwhile
  return join(out, "\n")
endfunction  " }}}

" https://github.com/vim-jp/vital.vim/blob/master/doc/vital/Async/Promise.txt
function! s:sh(command) abort  " {{{
  return s:Promise.new({ resolve, reject -> job_start(a:command, #{
  \   drop:     "never",
  \   close_cb: { ch -> "do nothing" },
  \   exit_cb:  { ch, code -> code ? reject(s:read(ch, "err")) : resolve(s:read(ch, "out")) },
  \ }) })
endfunction  " }}}

function! s:warn(message) abort  " {{{
  echohl ErrorMsg
  echomsg "[vim-parallel-auto-ctags] WARN -- " . a:message
  echohl None
endfunction  " }}}

function! s:notify_finish() abort  " {{{
  doautocmd <nomodeline> User parallel_auto_ctags_finish
endfunction  " }}}
