React = require 'react'

class Preview extends React.Component
    constructor: (props) ->
        super props
        console.log "Preview constructor"
        @state =
            content: ""

    output: (str) ->
        @setState
            content: str
        
    render: ->
        {div,pre} = React.DOM
        console.log "Preview render"
        div
            id: "revl-preview"
            onKeyDown: @props.revl.keyDown
            onKeyPress: @props.revl.keyPress
            pre {}, @state.content

module.exports = React.createFactory Preview
