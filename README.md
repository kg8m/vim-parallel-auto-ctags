vim-parallel-auto-ctags
==================================================

A Vim plugin to execute `ctags` command on any events for any directories.

  * Support multiple entry points, e.g., current directory and directory for libraries
  * Execute `ctags` command on `autocmd` events you specify
  * Execute `ctags` command asynchronously
  * Wait to execute `ctags` command if the entry point's command is running


Functions
--------------------------------------------------

### `parallel_auto_ctags#create_all()`

Execute `ctags` command for all entry points.


### `parallel_auto_ctags#create(entry-point[, delay])`

Execute `ctags` command for specified entry point.

`entry-point` is a string which you want to execute `ctags` for.

`delay` is milliseconds for waiting to execute `ctags` for the `entry-point`. Default: `300`


#### Example

```vim
call parallel_auto_ctags#create("pwd")
call parallel_auto_ctags#create("libs", 1000)
```


### `parallel_auto_ctags#clean_up()`

Remove lock files and temp files, which are created to avoid duplicated executing `ctags` command.

Note: This function is called on `VimLeavePre`.


Variables
--------------------------------------------------

### `g:parallel_auto_ctags#executable`

Command name or executable filepath to execute `ctags`.

Default: `"ctags"`


### `g:parallel_auto_ctags#tag_filename`

Filename of tagfile.

Default: `"tags"`


### `g:parallel_auto_ctags#options`

Options of `ctags` command.

Specify this by `List`.

Default: `[]`


#### Example:

```vim
let g:parallel_auto_ctags#options = [
\   "--fields=n",
\   "--tag-relative=yes",
\   "--recurse=yes",
\   "--sort=yes",
\ ]
```


### `g:parallel_auto_ctags#entry_points`

Entry point names and each entry point's configurations.

Specify this by `Dictionary`.

Default: `{}`

Its keys are entry point names. Its values are their configurations. Each value should be a `Dictionary` which can have `path`, `options`, `events`, and `silent` keys.

  * `path` (`String`/required)
    * Path to target directory of the entry point. A tag file will be created in this directory.
  * `options` (`List`/optional)
    * Entry point specific options of `ctags` command. Unless defined, `g:parallel_auto_ctags#options` is used instead.
  * `events` (`List`/optional)
    * A list of `autocmd-events` to execute `ctags` automatically.
    * Default: `[]`
  * `silent` (`Boolean`/optional)
    * Whether executing `ctags` silently or not.
    * Default: `v:false`


#### Example

```vim
let g:parallel_auto_ctags#entry_points = {
\   "pwd": {
\     "path":    ".",
\     "options": ["--exclude=node_modules"],
\     "events":  ["VimEnter", "BufWritePost"],
\     "silent":  v:true,
\   },
\   "libs": {
\     "path":    "/path/to/libraries",
\     "options": ["--exclude=test", "--languages=something"],
\     "events":  ["VimEnter"],
\     "silent":  v:false,
\   },
\ }
```


Installation
--------------------------------------------------

If you use [dein.vim](https://github.com/Shougo/dein.vim):

```vim
call dein#add("kg8m/vim-parallel-auto-ctags")
```


Requirements
--------------------------------------------------

  * [Universal Ctags](https://github.com/universal-ctags/ctags) (recommended) or other ctags
  * Newer Vim
  * Linux or Mac
