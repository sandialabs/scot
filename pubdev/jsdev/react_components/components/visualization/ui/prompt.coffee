React = require 'react'

class ContentEditable extends React.Component
    constructor: (props)->
        super props
        @lastText=''

    shouldComponentUpdate: (newprops) ->
        newprops.content != @refs.element.innerText

    moveCaret: (pos=undefined)->
        elt=@refs.element
        textelt = elt.firstChild
        if (typeof pos) == 'undefined'
            pos = elt.innerText.length
        range = document.createRange()
        range.setStart textelt,pos
        range.setEnd textelt,pos
        sel = window.getSelection()
        sel.removeAllRanges()
        sel.addRange range
        
    componentDidUpdate: () ->
        if @props.content != @refs.element.innerText
            @refs.element.innerText = @props.content

    content: () => @refs.element.innerText or @refs.element.textContents or ""
    
    render: () ->
        {span} = React.DOM
        span
            contentEditable: true
            spellCheck: false
            className: 'prompt'
            onChange: ()=>@emitChange()
            onInput: ()=>@emitChange()
            onBlur: ()=>@emitChange()
            ref: 'element'
            style:
                marginRight: '1px'
                marginLeft: '1px'
            @props.content

    focus: () -> @refs.element.focus()

    emitChange: () ->
        text = @refs.element.innerText
        if @props.onChange and text != @lastText
            @props.onChange @content()
        @lastText = text
        return false

Editable = React.createFactory ContentEditable

class Prompt extends React.Component
    constructor: (props) ->
        super props

    content: () -> @refs.prompt.content()
        
    render: () ->
        {div,span}=React.DOM
        div
            onClick: ()=>@focus()
            onFocus: ()=>@focus()
            tabIndex: "-1"
            className: 'promptbox'
            style:
                cursor: "text"
            [
                span
                    key:0
                    className: 'prompt'
                    "$ "
                Editable
                    key: 1
                    ref: 'prompt'
                    onChange: @props.onChange
                    content: @props.content
            ]

    focus: (e) ->
        console.log "focus prompt"
        @refs.prompt.focus()
        #e.stopPropagation()
        #e.cancelBubble = true
        #e.preventDefault()
        
    moveCaret: (p)-> @refs.prompt.moveCaret(p)
    
module.exports = React.createFactory Prompt
