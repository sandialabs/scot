React = require 'react'
Revl = require '../revl'

class ScriptEditor extends React.Component
    constructor: (props) ->
        super props
        @state = script: ""
            
    render: =>
        {div,span,pre,textarea,input} = React.DOM
        console.log "script editor render display=#{@props.display}"
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
                height: '25%'
            [
                textarea
                    ref: 'inputArea'
                    value: @state.script
                    onChange: @handleChange
                    key: 0
                    style:
                        width: '100%'
                        height: '400px';
                        backgroundColor: 'black';
                        color: 'green';
                div
                    key: 1
                [
                    input
                        type: 'button'
                        value: 'Try it'
                        key: 0
                    input
                        type: 'button'
                        value: 'Save'
                        onClick: @onSave
                        key: 1
                    input
                        type: 'button'
                        value: 'Cancel'
                        key: 2
                ]
                
            ]

    #focus: () => @refs.inputArea.focus()
        
    handleChange: (evt)=>
        console.log("changed")
        @setState script: evt.target.value
        
    onSave: ()=>
        console.log("save script")
        @props.revl.hideScriptEditor()
        
module.exports = React.createFactory ScriptEditor
