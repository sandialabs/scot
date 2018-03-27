
React = require 'react'

class Progress extends React.Component
    constructor: (props)->
        super props

    render: () =>
        {div} = React.DOM
        div
            style:
                width:'100%'
                flex: '0 0 0.5em'
                height: '0.8em'
                border: 'none'
                backgroundColor: '#000'
                display: if @props.running then 'block' else 'none'
                zIndex: 100000
            [
                div
                    style:
                        width: (@props.done*100/@props.total)+'%'
                        backgroundColor: '#00f'
                        height: '100%'
                    key: 0
                    ''
                 div
                    style:
                        right: '0px'
                        bottom: '0px'
                        color: '#99f'
                        backgroundColor: 'rgba(0,0,0,0)'
                        display: @props.running
                        position: 'absolute'
                    key: 1
                    @props.done+'/'+@props.total
            ]
   
module.exports = React.createFactory Progress
