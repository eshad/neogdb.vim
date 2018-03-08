if !exists("s:script")
    let s:script = expand('<sfile>:t')
    let s:name = expand('<sfile>:t:r')
    silent! let s:log = logger#getLogger(s:script)
    let s:prototype = tlib#Object#New({'_class': [s:name]})

    "
    " break_item {
    "   .name*      masterkey: relative-path-file:[line-text|function]
    "   .file       relative-path-filename
    "   .linetext   the breakpoint's line-text or function-name
    "   .line       the breakpoint's lineno
    "   .type       0 break at line, 1 at function
    "   .state      0 enable(default), 1 disable, 2 delete
    "   .update     0 do-nothing, 1 need fresh gdb & view
    "   .offset     auto-load's offset if supported
    "   .sign_id
    "   .break
    "   .condition  get from user input, split by ';'
    "   .command    get from user input, split by ';'
    " }
    "

    let s:_Prototype = {
                \ 'name': '',
                \ 'file': '',
                \ 'text': '',
                \ 'line': 0,
                \ 'col': 0,
                \ 'fn': '',
                \ 'type': 0,
                \ 'state': 0,
                \ 'update': 0,
                \ 'offset': 0,
                \ 'sign_id': 0,
                \ 'break': '',
                \ 'condition': '',
                \ 'command': '',
                \}

endif


" Constructor
function! neobugger#break_item#New(type, cmdtext)
    let l:__func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')

    let newBreak = s:prototype.New(deepcopy(s:_Prototype))
    call newBreak.fill_detail(a:type, a:cmdtext)

    return newBreak
endfunction


function! s:prototype.fill_detail(type, cmdtext) dict
    let l:__func__ = "fill_detail"

    let filenm = bufname("%")
    let linenr = line(".")
    let colnr = col(".")
    let cword = expand("<cword>")
    let cfuncline = neobugger#gdb#GetCFunLinenr()

    let fname = fnamemodify(filenm, ':p:.')
    let type = 0
    if linenr == cfuncline
        let type = 1
        let file_breakpoints = fname .':'.cword
    else
        let file_breakpoints = fname .':'.linenr
    endif

    let self.['name'] = file_breakpoints
    let self.['file'] = fname
    let self.['type'] = type
    let self.['line'] = linenr
    let self.['col'] = colnr
    let self.['command'] = a:cmdtext
    silent! call s:log.info(l:__func__, '() item=', string(self))
endfunction


function! s:prototype.equal(item) dict
    let l:__func__ = "equal"

    let that = a:item
    if !(self.name ==# that.name)
                \ || !(self.file ==# that.file)
                \ || !(self.type ==# that.type)
                \ || !(self.line ==# that.line)
                \ || !(self.command ==# that.command)
        silent! call s:log.info(l:__func__, '('. that.name. ') not equal')
        return 0
    endif
    silent! call s:log.info(l:__func__, '('. that.name. ') equal')
    return 1
endfunction


function! s:prototype.addMenuItem(menuItem) dict
    call add(self.children, a:newMenuItem)
endfunction


"return 1 if this menu item should be displayed
"
"delegates off to the isActiveCallback, and defaults to 1 if no callback was
"specified
function! s:prototype.enabled()
    if self.isActiveCallback != -1
        return {self.isActiveCallback}()
    endif
    return 1
endfunction


"perform the action behind this menu item, if this menuitem has children then
"display a new menu for them, otherwise deletegate off to the menuitem's
"callback
function! s:prototype.execute()
    if len(self.children)
        let mc = g:NERDTreeMenuController.New(self.children)
        call mc.showMenu()
    else
        if self.callback != -1
            call {self.callback}()
        endif
    endif
endfunction


"return 1 if this menuitem is a separator
function! s:prototype.isSeparator()
    return self.callback == -1 && self.children == []
endfunction


"return 1 if this menuitem is a submenu
function! s:prototype.isSubmenu()
    return self.callback == -1 && !empty(self.children)
endfunction

