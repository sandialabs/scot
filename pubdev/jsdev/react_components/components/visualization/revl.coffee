React = require 'react'
Editor = require './editor'
Preview = require './preview'
Visualization = require './visualization'
Shell = require './shell'
BaseCommands=require './base-commands'
Barchart=require './barchart'
Linechart=require './linechart'
Dotchart=require './dotchart'
Forcegraph = require './forcegraph'
Poly=require './poly'
Http=require './http'
List = require './list'
Struct = require './struct'
Nspace=require './space/nspace'
{Polygon,polygon} = require './geometry/polygon'
Edge = require './geometry/edge'
BoundingBox = require './geometry/boundingbox'
Voronoi = require './geometry/voronoi'
Eps = require './geometry/eps'
Vec = require './geometry/vec'
Http = require './http'
Utils = require './utils'
Strings = require './strings'
API = require './api'
Poly = require './poly'
{Result,ResultPromise} = require './result'

class Revl extends React.Component
    @revl=null
    constructor: (props) ->
        super props
        @shell = new Shell(@output.bind @)
        @shell.addCommands BaseCommands
        @shell.addCommands Barchart.commands
        @shell.addCommands Dotchart.commands
        @shell.addCommands Linechart.commands
        @shell.addCommands Forcegraph.commands
        @shell.addCommands Poly.commands
        @shell.addCommands Http.commands
        @shell.addCommands Nspace.commands
        @shell.addCommands Voronoi.commands
        @shell.addCommands Strings.commands
        @shell.addCommands API.commands
        @shell.addCommands Result.commands
        @shell.addCommands ResultPromise.commands
        @shell.addScope List
        @shell.addScope Polygon.scope
        @shell.addScope Eps
        @shell.addScope
            Struct: Struct
            Vec: Vec
            Poly: Poly
            Voronoi: Voronoi
            Pgon: Polygon
            polygon: polygon
            Http: Http
            Edge: Edge
            BBox: BoundingBox
            Utils: Utils
            Strings: Strings
            Nspace: Nspace
            API: API
            Result: Result
            ResultPromise: ResultPromise
        @shell.loadSavedData()
        @state = {}
        Revl.revl=@
        
    output: (str) ->
        if @refs.editor
            @refs.editor.output str
        else
            console.log "Editor undefined"
            console.log str
    #keyDown: (k)->@refs.editor.keyDown k
    #keyPress: (k)->@refs.editor.keyPress k
    render: ->
        {div} = React.DOM
        div
            onFocus: ()=>@refs.editor.focus()
            tabIndex:0
            id: "revl"
            #onKeyPress: (k)=>@refs.editor.keyPress(k)
            #onKeyDown: (k)=>@refs.editor.keyDown(k)
            style:
                position:'absolute'
                top:'5vh'
                bottom:0
                right:0
                left:0
                height:'95vh'
                width:'100vw'
            [(Visualization {key: 2,revl: @, ref: 'visualization'}),
             (Editor {key:0,shell: @shell, revl: @, ref:'editor'})]

module.exports = React.createFactory Revl
