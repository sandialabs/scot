{Result} = require '../utils/result'
Utils = require '../utils/utils'

class Forcegraph
    @commands =
        help__forcegraph: () ->"""
            forcegraph [naming proc]

            forcegraph produces a nodes-and-links graph from the data
            provided. It expects either an object with a key for each
            node (kind of, see below), or a list of links. If you
            specify the naming proc, it will be called on each node to
            provide a unique name for the node (this is how a node is
            recognized across multiple links). If you have complex
            objects, provide a name function that reduces them to
            something simple that can work as the key in a javascript
            object. By default, the entire node will just be turned
            into a string.

            The object works like an association list. You give the
            node name as the key, and a list of nodes it connects with
            as the value. The list of nodes can either be just a
            simple flat list of link specifiers (see below), or an
            object with your own metadata and a member named 'links'
            with the list of link specifiers.

            The list format simply specifies the graph by calling out
            each link.  To use this, just pass in a flat list with all
            of the links given as link specifiers. Node names will be
            collected from the link endpoints automatically. If you
            need to draw a node with no links, just pass in a link
            specifier with an endpoint missing.

            Link specifiers are either just a pair of node names, or
            an object with a 'from' and 'to' field in addition to
            whatever metadata you want to add. If you use the object
            format for specifying nodes, you can leave out the 'from'
            field for the link specifiers as it will be taken from the
            node name being processed instead.

            Examples:
              $ [['foo','bar'],['bar',bla'],['foo','bla']] \\ forcegraph

              $ {foo: ['bar','bla'], bar: ['bla']} \\ forcegraph

              $ [{from: 'foo', to: 'bar', counter:97},
                 {from: 'foo',to:'bla', counter:8},
                 {from: 'bar',to:'bla',counter:1000}] \\ forcegraph

              $ {foo: {links: [{to: 'bar', counter: 97}
                               {to: 'bla', counter: 8}]
                       coolness: 0},
                 bar: {links: [{to: 'bla', counter: 1000}]
                       coolness: 99},
                 bla: {links: [],
                       coolness: 22}} \\ forcegraph
                       
            All three examples produce the same graph with three nodes
            connected by three links in a triangle.
            
            The input will be passed through this command so you can
            pipe other commands after it if needed"""
            
        forcegraph: (argv,d,ctx) ->
            chart = new Forcegraph argv, d,ctx
            chart.render "#revl-vizbox"
            Result.wrap d

    constructor: (argv,data,ctx) ->
        @graph =
            links: []
            nodes: {}
        @maxdata = undefined
        @namer = (n)->n
        if argv.length > 0
            Utils.parsefunction (argv.join ' '),ctx
                .map (proc)=> @namer = proc
                .map_err(e) -> throw e
        @pairs = []
        @ingest data
        window.fg=@
        
    ingest: (data) ->
        @graph =
            links: {}
            nodes: {}
        if Utils.isArray data
            for d in data
                @ingest_link d

    ingest_link: (link,insrc=undefined) ->
        if Utils.isArray link
            clone = (l for l in link)
            src = undefined
            if clone.length > 1 and (typeof clone[1] != "object")
                src = clone.shift()
            to = ''+clone.shift()
            src ?= ''+insrc
            data = clone.shift() or null
            @ensure_node to
            @ensure_node src
            @graph.links[src] ?= {}
            @graph.links[src][to] ?= data
            
    ensure_node: (node) ->
        if not node
            return
        @graph.nodes[''+(@namer node)] ?=
            id: ''+(@namer node)
            data: {}

    links: () ->
        result = []
        for own src of @graph.links
            for own to of @graph.links[src]
                result.push
                    source: src
                    target: to
                    data: @graph.links[src][to]
        result
            
    render: (target) ->
        svg = d3.select target
            .html ""
            .append "svg"
            .attr "class", "viz"
        margin = {top: 20, right: 20, bottom: 30, left: 40}
        width = +document.querySelector(target).offsetWidth - margin.left - margin.right
        height = +document.querySelector(target).offsetHeight - margin.top - margin.bottom
        
        nodes = (Object.keys @graph.nodes).map (n)=>@graph.nodes[n]
        links = @links()

        window.fgraph={nodes:nodes,links:links}

        console.log JSON.stringify nodes
        console.log JSON.stringify links

        simulation = d3.forceSimulation()
            .force "link", d3.forceLink().id (d)->d.id
            .force "charge", d3.forceManyBody()
            .force "center", d3.forceCenter width/2, height/2

        link = svg.append "g"
            .attr "class","forcegraph-links"
            .selectAll "line"
            .data links
            .enter()
            .append "line"
            .attr "stroke-width", 2

        node = svg.append "g"
            .attr "class", "forcegraph-nodes"
            .selectAll "circle"
            .data nodes
            .enter()
            .append "circle"
            .attr "r", 5
            .attr "fill", Utils.pickColor 1

        node.append "title"
            .text (d) -> d.id
           
        simulation
            .nodes nodes
            .on "tick", ()->
                link.attr "x1", (d) -> d.source.x
                    .attr "y1", (d) -> d.source.y
                    .attr "x2", (d) -> d.target.x
                    .attr "y2", (d) -> d.target.y
                node.attr "cx", (d) -> d.x
                    .attr "cy", (d) -> d.y

        simulation.force "link"
            .links links

module.exports = Forcegraph
