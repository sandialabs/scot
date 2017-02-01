React = require 'react'

class Visualization extends React.Component
    constructor: (props) ->
        super props
        console.log "viz constructor"
        @rendered = false
        @state = {}

    render: ->
        @rendered=true
        {div} = React.DOM
        console.log "viz render"
        div
            id:"revl-vizbox"
            ""

    shouldComponentUpdate: ()->!@rendered
    
module.exports = React.createFactory Visualization
