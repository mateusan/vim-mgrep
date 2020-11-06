" File: mgrep.vim
" Author: Mateu Santandreu <mateusan AT gmail DOT com>

if exists('g:mgrep_loaded' ) || &cp
    finish
endif

let g:mgrep_loaded = 1
if !exists( 'g:mgrep_ignorecase' )
    let g:mgrep_ignorecase = 1
endif
if !exists( 'g:mgrep_file_pad' )
    let g:mgrep_file_pad = 50
endif
if !exists( 'g:mgrep_file_sep' ) 
    let g:mgrep_file_sep = '║ '
endif


function s:MGrepRunGitSearch(search)
    let cmd = "git grep --line-number "
    if exists("g:mgrep_ignorecase") && g:mgrep_ignorecase == 1
        let cmd .= "--ignore-case "
    endif
    let cmd .= "'" . a:search ."'"
    let s =  system(cmd)
    return s
endfunction

function s:MGrepRunSystemSearch(search)
    let cmd = "grep -RnIH "
    if exists("g:mgrep_ignorecase") && g:mgrep_ignorecase == 1
        let cmd .= "--ignore-case "
    endif
    let cmd .= "'" . a:search ."'"
    let s =  system(cmd)
    return s
endfunction

function! MGrepPad(s,amt)
    return a:s . repeat(' ',a:amt - len(a:s))
endfunction

function MGrepSelect(winid, result)
    if a:result != -1
        let obj = g:mgrep_win_lines[a:result-1]
        let vimCmd = ":e +" . obj.lineNr . " " . obj.file
        echo vimCmd
        execute vimCmd
    endif
    call MGrep_unregistrer_lines()
endfunction

function MGrepFormatOutput(lines, search)
    let allLinesProps = []
    for line in a:lines
        let obj = MGrepFormatAndPropify(line, a:search)
        if obj != {}
            call add(allLinesProps, obj)
        endif
    endfor
    return allLinesProps
endfunction

function MGrepFormatAndPropify(str, regex)
    let obj = {"originalStr": a:str, "viewStr": "", "props": [], "lineNr": 0, "file": ""}
    if len(matchstr(a:str, "Binary file") > 0) && stridx(a:str, "matches") != -1
        return {}
    endif

    let line = a:str
    let lastIdx = 0

    let s:fileNameRegex = '^[^:]\+:'
    let s:beginning = match(line, s:fileNameRegex)
    if s:beginning != -1
        let s:match = matchstr(line, s:fileNameRegex)
        let s:length = len(s:match)
        let line = line[s:length:]

        let obj.file = s:match[0:-2]
        let s:sMatch = obj.file
        let obj.viewStr .= s:sMatch

        let s:length = len(s:sMatch)
        let s:end = lastIdx + s:length
        call add(obj.props, {"length": s:length, "col": lastIdx + 1 , "endcol": s:end, "type": "MGrepMatchFileName"})
        let lastIdx = len(obj.viewStr)
    endif

    let s:lineNumberRegex = '^\d\+:'
    let s:beginning = match(line, s:lineNumberRegex)
    if s:beginning != -1 
        let s:match = matchstr(line, s:lineNumberRegex)
        let s:length = len(s:match)
        let line = line[s:length:]

        let obj.lineNr = s:match[0:-2]
        let s:sMatch = '[' . obj.lineNr . ']'
        let obj.viewStr .= s:sMatch

        let s:length = len(s:sMatch)
        let s:end = lastIdx + s:length
        call add(obj.props, {"length": s:length, "col": lastIdx + 1, "endcol": s:end, "type": "MGrepMatchLineNumber"})
        let lastIdx = len(obj.viewStr)

    endif
    
    if exists("g:mgrep_file_pad") && g:mgrep_file_pad > 0
        let obj.viewStr = MGrepPad(obj.viewStr,g:mgrep_file_pad)
        let lastIdx = len(obj.viewStr)
    endif

    if len(g:mgrep_file_sep)
        let obj.viewStr .= g:mgrep_file_sep
        let s:length = len(g:mgrep_file_sep)
        let s:end = lastIdx + s:length
        call add(obj.props, {"length": s:length, "col": lastIdx + 1, "endcol": s:end, "type": "MGrepMatchSep"})
        let lastIdx = len(obj.viewStr)
    endif

    let obj.viewStr .= line

    let s:beginning = match(line, a:regex)
    if s:beginning != -1
        let s:length = len(matchstr(line, a:regex))
        let s:end = lastIdx + s:length
        call add(obj.props, {"length": s:length, "col": lastIdx + 1 + s:beginning, "endcol": s:end, "type": "MGrepMatchWord"})
    endif

    return obj
endfunction

function MGrepFormat(lines)
    let formatted_lines = []
    for obj in a:lines
        if len(obj.props) != 0
            call add(formatted_lines, { "text": obj.viewStr, "props": obj.props })
        else
          call add(formatted_lines, { "text": obj.viewStr })
        endif
    endfor
    return formatted_lines
endfunction

function MGrep_register_lines(allLinesProps)
    let g:mgrep_win_lines  = a:allLinesProps 
endfunction

function MGrep_unregistrer_lines()
    unlet g:mgrep_win_lines
endfunction

function s:MGrepRun(searchTerm, mode)

    if prop_type_get("MGrepMatchWord") == {}
        call prop_type_add("MGrepMatchWord", {"highlight": "MGrepMatchWord"})
    endif
    if prop_type_get("MGrepMatchFileName") == {}
        call prop_type_add("MGrepMatchFileName", {"highlight": "MGrepMatchFileName"})
    endif
    if prop_type_get("MGrepMatchLineNumber") == {}
        call prop_type_add("MGrepMatchLineNumber", {"highlight": "MGrepMatchLineNumber"})
    endif
    if prop_type_get("MGrepMatchSep") == {}
        call prop_type_add("MGrepMatchSep", {"highlight": "MGrepMatchSep"})
    endif

    echo "Searhing..."

    if a:mode == 'git' 
        let response = s:MGrepRunGitSearch(a:searchTerm)
    elseif a:mode == 'system' 
        let response = s:MGrepRunSystemSearch(a:searchTerm)
    endif

    let lines = split(response, '\n')
    if len(lines) == 0
        echo "MGrep: Nothing found."
        return
    endif

    let windowHeightSize = float2nr(winheight('%') / 2)
    let windowWidthSize = float2nr(winwidth('%') * 0.80)


    if exists('*popup_menu')
        let output = MGrepFormatOutput(lines, a:searchTerm)
        let numResults = len(output)
        call MGrep_register_lines(output)
        let prettyOutput = MGrepFormat(output)

        let winid = popup_menu(prettyOutput, #{
            \ border: [ 1, 1, 1, 1 ],
            \ title: ' ::: Results: #' . numResults . ' ::: ',
            \ pos: "center",
            \ maxheight: windowHeightSize,
            \ minwidth: windowWidthSize,
            \ maxwidth: windowWidthSize,
            \ callback: "MGrepSelect",
            \ padding: [ 1, 1, 1, 2 ],
            \ borderhighlight: [ "MGrepWindowColor" ],
            \ highlight: "MGrepWindowNormalColor",
            \ scrollbarhighlight: "MGrepWindowTabColor",
            \ thumbhighlight: "MGrepWindowTabColorCur",
            \ })
    elseif has('nvim') && exists('g:loaded_popup_menu_plugin')
        " Neovim
        " " g:loaded_popup_menu_plugin is defined by popup-menu.nvim.
        call popup_menu#open(prettyOutput, 'MGrepSelect' )
    else 
        let index = inputlist(lines)
        call MGrepSelect( '', index )
    endif
endfunction


hi def link MGrepMatchWord IncSearch
hi def link MGrepMatchFileName Directory
hi def link MGrepMatchLineNumber Directory
hi def link MGrepMatchSep Directory
hi def link MGrepWindowColor Pmenu
hi def link MGrepWindowNormalColor PmenuSel
hi def link MGrepWindowTabColor PmenuSbar
hi def link MGrepWindowTabColorCur PmenuThumb

command -nargs=* MGrepGit :call s:MGrepRun(<f-args>, 'git' )
command -nargs=0 MGrepGitWord :call s:MGrepRun(expand("<cword>"), 'git' )
command -nargs=* MGrepSys :call s:MGrepRun(<f-args>, 'system' )
command -nargs=0 MGrepSysWord :call s:MGrepRun(expand("<cword>", 'system' )
