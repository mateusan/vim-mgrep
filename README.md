# vim-mgrep
Vim Plugin: Search across multiples files


## Install

with vim-plug:
```vim
Plug 'mateusan/vim-mgrep'
```

## Usage ##


```
#Grep terms using `git grep` 
:MGrepGit <term/regexp>

# Git grep the word under the cursor
:MGrepGitWord 

#Grep terms using `grep tool`
:MGrepSys <term/regexp>

#System-grep the word under the cursor
:MGrepSysWord

```

#### Colors

```
hi MGrepWindowColor         guibg=#0000ff ctermbg=blue  guifg=#000000 ctermfg=black
hi MGrepWindowNormalColor   guibg=#005f5f ctermbg=233   guifg=#ffffff ctermfg=white
hi MGrepWindowTabColor      guibg=#0000ff ctermbg=blue
hi MGrepWindowTabColorCur   guibg=#ffffff ctermbg=white 
hi MGrepMatchFileName       guibg=#000000 ctermbg=black guifg=#008000 ctermfg=green gui=italic,bold cterm=italic,bold
hi MGrepMatchLineNumber     guibg=#000000 ctermbg=black guifg=#0000ff ctermfg=blue  gui=bold cterm=bold
hi MGrepMatchWord           guibg=#ff0000 ctermbg=red   guifg=#000000 ctermfg=black
```
