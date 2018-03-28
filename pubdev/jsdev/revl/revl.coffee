React = require 'react'

Editor = require './ui/editor'
Preview = require './ui/preview'
Visualization = require './ui/visualization'
Shell = require './ui/shell'
BaseCommands=require './ui/base-commands'

Html=require './viz/html'
Barchart=require './viz/barchart'
Linechart=require './viz/linechart'
Dotchart=require './viz/dotchart'
Forcegraph = require './viz/forcegraph'
Poly=require './viz/poly'

Nspace=require './space/nspace'

{Polygon,polygon} = require './geometry/polygon'
Edge = require './geometry/edge'
BoundingBox = require './geometry/boundingbox'
Voronoi = require './geometry/voronoi'
Eps = require './geometry/eps'
Vec = require './geometry/vec'

List = require './utils/list'
Struct = require './utils/struct'
Http = require './utils/http'
Utils = require './utils/utils'
Strings = require './utils/strings'
API = require './utils/api'
NBayes = require './ml/naivebayes'

{Result,ResultPromise} = require './utils/result'

ScriptEditor = require './ui/script-editor'

class Revl extends React.Component
    constructor: (props) ->
        super props
        @shell = new Shell (@output.bind @), @
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
        @shell.addCommands Html.commands
        @shell.addCommands NBayes.commands
        #@shell.addCommands Revl.commands
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
        @state =
            script_display: "none"
            script_data: {}
            script_name: ''
            script:
                body: undefined
                help: undefined
        Revl.revl=@

    output: (str) ->
        if @refs.editor
            @refs.editor.output str
        else
            console.log "Editor undefined"
            console.log str
    render: ->
        {div} = React.DOM
        div
            #onFocus: ()=>
                #if @state.show_script=='block' then @refs.script_editor.focus() else @refs.editor.focus()
            tabIndex:0
            id: "revl"
            style:
                position:'absolute'
                top:'5vh'
                bottom:0
                right:0
                left:0
                height:'95vh'
                width:'100vw'
            [(Visualization {key: 2,revl: @, ref: 'visualization'}),
             (Editor {key:0,shell: @shell, revl: @, ref:'editor'}),
             (ScriptEditor
                 key:1,
                 data: @state.script_data,
                 shell: @shell,
                 revl:@,
                 ref:'script_editor',
                 initialScript: @state.script,
                 initialName: @state.script_name,
                 display:@state.script_display)]

    showScriptEditor: (data,script,initialName) ->
        console.log "Show editor for #{JSON.stringify script}"
        @setState
            script: script
            script_name: initialName
            script_display: "block"
            script_data: data
        Result.wrap "Script editor active"
        
    hideScriptEditor: () -> @setState script_display:"none"

    @commands:{}
#        help__script: () -> """
#        script <name>
#
#        The script command allows opens an editor window in which you
#        can type a sequence of commands that will then be usable as a
#        single command (similar to a shell script). 
#
#        After you enter the command, the editor window will give you a
#        scratch area to type your commands. You can test the script as
#        you're working on it using the 'Try it' button, and save and
#        cancel work as you would expect.
#
#        Scripts are given their own version of the shell context to
#        operate on when they run. That means that any assignments you
#        do to global values will be forgotten when the script
#        finishes. The purpose of this is to give you some scratch
#        space to store temporary values for operations that have
#        intermediate state that you need to keep track of. These
#        values will be removed from the context when your script
#        finishes, so you don't have to worry about polluting the
#        global namespace or overwriting existing data by accident with
#        your scripts. There is one exception to this: If you modify
#        the *inside* of an object that's in the global context, that
#        change *will* be visible after the script finishes. The
#        scratch area only protects the top-level bindings in the
#        context, so if you mutate the data inside a binding (e.g. if
#        there is an object or an array and you change one of the
#        fields inside it), you'll change the global state. The store
#        and define commands are safe to use, as they will just
#        generate local bindings. Be careful with interior state
#        though!
#
#        You can pass data into a script in two ways: as the normal
#        piped-in data structure, or as named values that will be
#        inserted into the script's context when it starts. If you want
#        to use the named values, just specify an object on the command
#        line after the script name with fields for the items you want
#        in the context.
#
#        Data coming in through the pipeline will be passed as the pipe
#        data for the first command in your script. If you want to have
#        something available for testing while you write your script,
#        just pipe it into the script command (it will be re-used for
#        each subsequent call to the script as you press 'Try it').
#
#        The script will return the last value it generates, just as if
#        you had run the commands directly.
#        
#        Example:
#            $ script leaderboard
#                <script editor opens>
#            $ leaderboard count:1000
#
#            This would create a new command called 'leaderboard'
#            (which you would have to edit when the script editor
#            opens). Later, the leaderboard command is invoked, and the
#            context it gets has the 'count' variable defined to be
#            1000.
#        """
#
#        script: (argv,data,ctx) =>
#            @revl.showScriptEditor argv,data,ctx

module.exports = React.createFactory Revl

console.log "revl exports: #{Object.keys module.exports}"
console.log "revl Revl export: #{module.exports.Revl}"
