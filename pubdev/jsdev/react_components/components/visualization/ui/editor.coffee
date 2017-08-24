React = require 'react'
Prompt = require './prompt'
Progress = require './progress'

class Editor extends React.Component
    Backspace = 8;
    Tab = 9;
    Enter = 13;
    Escape = 27;
    End = 35;
    Home = 36;
    LeftArrow = 37;
    UpArrow = 38;
    RightArrow = 39;
    DownArrow = 40;
    Delete = 46;
    constructor: (props)->
        super props
        @history_index = -1
        @_command_handler = ()->null
        @_completion_handler = ()->null
        @shell = props.shell
        @revl = props.revl
        if (not @shell) or (not @revl)
            throw "Error - Editor must be provided with a Shell and Revl instance in props"
        @shell.registerEditor @
        @prompt = "$  "
        @trace_accumulator=""
        @state =
            cmd: ""
            trace: ""
            cursor: 'none'
            traceheight: 50
            progress:
                done:1
                total:1
                running:false

    componentDidUpdate: () ->
        @refs.trace.scrollTop = @refs.trace.scrollHeight
        
    render: =>
        @trace_accumulator = ""
        {div,span,pre} = React.DOM
        div
            id: "revl-shell-panel"
            tabIndex: 0
            ref: 'terminal'
            onKeyDown: @keyDown
            style:
                height: @state.traceheight+'px'
            [
                div
                    className:'drag-vert'
                    onMouseDown: @startDrag
                    onDoubleClick: @toggleTrace
                    key: 0
                    ''
                div
                    id: "trace"
                    className: "trace"
                    ref: "trace"
                    key: 1
                    style:
                        border: "none"
                    pre {}, @state.trace
                Progress
                    key: 3
                    running: @state.progress.running
                    done: @state.progress.done
                    total: @state.progress.total
                Prompt
                    content: @state.cmd
                    onChange: (cmd) => @onChange(cmd)
                    ref: 'prompt'
                    key: 2
                    style: border: "none"
            ]

    startDrag: (e)=>
        last_y = e.pageY
        term = @refs.terminal
        drag = (e) =>
            dy = e.pageY-last_y
            last_y=e.pageY
            @setState
                traceheight: @state.traceheight-dy
                minimize: false
            
        stopdrag = (e) =>
            window.removeEventListener 'mousemove', drag
            window.removeEventListener 'mouseup',stopdrag
            window.removeEventListener 'mouseleave',stopdrag
            
        window.addEventListener 'mousemove', drag
        window.addEventListener 'mouseup',stopdrag
        window.addEventListener 'mouseleave',stopdrag

    toggleTrace: (e) =>
        if !@state.minimize
            @setState
                lastheight: @state.traceheight
                traceheight: '20'
        else
            @setState traceheight: @state.lastheight
        @setState minimize: !@state.minimize
        
    getKeyInfo: (e)->
        code = e.keyCode || e.charCode
        c = String.fromCharCode code
        code: code
        character: c
        shift: e.shiftKey
        control: e.controlKey,
        alt: e.altKey

    isPrintable: (ch) -> (31 < ch < 128) || ch == 13 || ch == 9

    onChange: (cmd) ->
        @shell.history.setActive cmd
        @setState cmd: cmd
        
    keyDown: (event) =>
        if event.keyCode == 0 || event.defaultPrevented || event.metaKey || event.altKey || event.ctrlKey
            return false
        switch event.keyCode
            when Enter
                # check to see if we should just continue the entry line
                if (@state.cmd).trim()[-1..] == '\\'
                    @setState {cmd: @state.cmd+'\n'},()=>@refs.prompt.moveCaret()
                else
                    cmd = (@state.cmd)
                    @output (@prompt+(cmd.replace /[ ]*\n/g,'\n..  ')+"\n")
                    @shell.history.setActive (cmd.replace /\\ *\n/g,"\\\n")
                    @shell.history.acceptActive()
                    @history_index = -1
                    @_command_handler cmd
                    @setState {cmd: ''}
            when Tab
                @setState {cmd: (@_completion_handler @state.cmd)}
            when UpArrow
                @history_index = @shell.history.changeIndex @history_index, 1
                @setState cmd: (@shell.history.get @history_index),()=>@refs.prompt.moveCaret()
            when DownArrow
                @history_index = @shell.history.changeIndex @history_index,-1
                @setState cmd: (@shell.history.get @history_index),()=>@refs.prompt.moveCaret()
            else
                return true
        event.preventDefault()
        event.stopPropagation()
        event.cancelBubble = true
        false
  
    setCommandHandler: (handler) ->
        @_command_handler = handler
 
    setCompletionHandler: (handler) ->
        @_completion_handler = handler

    progress: (done,total) =>
        @setState progress: {done:done, total: total, running: done<total}
        
    output: (text) =>
        @trace_accumulator += text
        @setState {trace: @state.trace + @trace_accumulator}

    #focus: () => @refs.prompt.focus()
        
module.exports = React.createFactory Editor
