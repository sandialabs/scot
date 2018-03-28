React = require 'react'
{Result} = require '../utils/result'

class ScriptEditor extends React.Component
    constructor: (props) ->
        super props
        console.log "got props: #{props}"
        @state =
            body: props.initialScript?.body or ""
            help: props.initialScript?.help or ""
            name: props.initialName or ""
#        saved = localStorage.getItem 'user-scripts'
#        if @state.name.length > 0 and (own @state.name of saved)
#            state.body = saved[@state.name].body
#            state.help = saved[@state.name].body
    componentWillReceiveProps: (props) ->
        @setState
            body: props.initialScript?.body or ""
            help: props.initialScript?.help or ""
            name: props.initialName or ""
            
    render: =>
        {div,span,pre,textarea,input} = React.DOM
        div
            id: "revl-script-editor"
            tabIndex: 0
            style:
                position: 'fixed'
                zIndex: 10000
                display: @props.display
                marginTop: '10%'
                marginLeft: '10%'
                width: '75%'
                backgroundColor: 'rgba(200,200,200,0.7)'
                border: '1px solid black'
                borderRadius: '3px'
                padding: '5px'
            [
                span key:0,"Script name"
                input
                    ref: 'name'
                    value: @state.name
                    onChange: @changeName
                    key: 1
                    style:
                        paddingLeft: '5px'
                        width: '100%'
                        placeholder: 'Script name...'
                        backgroundColor: 'rgba(0,0,0,0.1)'
                        color: 'black'
                span key:2,"Help message"
                textarea
                    ref: 'help'
                    value: @state.help
                    onChange: @changeHelp
                    key: 3
                    style:
                        paddingLeft: '5px'
                        width: '100%'
                        height: '200px'
                        backgroundColor: 'rgba(0,0,0,0.1)'
                        color: 'black'
                span key:4,"Commands (use # for comments)"
                textarea
                    ref: 'inputArea'
                    value: @state.body
                    onChange: @changeScript
                    key: 5
                    style:
                        paddingLeft:'5px'
                        width: '100%'
                        height: '400px'
                        backgroundColor: 'rgba(0,0,0,0.1)'
                        color: 'black'
                div
                    key: 6
                [
                    input
                        type: 'button'
                        value: 'Try it'
                        onClick: @onTryIt
                        key: 0
                    input
                        type: 'button'
                        value: 'Save'
                        onClick: @onSave
                        key: 1
                    input
                        type: 'button'
                        value: 'Cancel'
                        onClick: @onCancel
                        key: 2
                ]
            ]

    parseCommands: () ->
        cmds = []
        current = []
        #console.log "inputArea.value = #{@refs.inputArea.value}"
        lines = (@refs.inputArea.value.split /[\s]*\n[\s]*/).map((l)->l.trim())
        #console.log "Got script with lines: #{JSON.stringify lines}"
        for line in lines
            if line.length < 1 or line.startsWith "#"
                continue
            if not (line.endsWith '\\')
                current.push line
                cmds.push (current.join ' ')
                current = []
            else
                current.push line
        if current.length != 0
            cmds.push (current.join ' ')
        #console.log "Got commands: \n\t"+cmds.join "\n\t"
        cmds
            
    changeScript: (evt)=>
        @setState body: evt.targetvalue
        
    changeName: (evt)=>
        @setState name: evt.target.value

    changeHelp: (evt)=>
        @setState help: evt.target.value
        
    onSave: ()=>
        scripts = JSON.parse localStorage.getItem 'user-scripts'
        name = @refs.name.value
        content = @parseCommands()
        help = @refs.help.value
        if content.length < 1
            alert "Error: script body is empty, not saving!"
            return
        if (name.length < 1)
            name = prompt "Please enter a name for your script:"
            if name.length < 1
                alert "Error: Can't save a script without a name"
                return
            else
                @setState name: name
        if help.length < 1
            if not confirm "You didn't enter a help message, your script will be undocumented if you save it."
                return
        @props.shell.script_manager.saveScript name,{body:content,help:help},@props.initialName
        if (typeof scripts) == 'undefined'
            scripts = {}
        @props.revl.hideScriptEditor()

    onCancel: ()=>
        @props.revl.hideScriptEditor()

    onTryIt: ()=>
        @props.shell.runScript((Result.wrap @props.data),{},@parseCommands())
        
module.exports = React.createFactory ScriptEditor
