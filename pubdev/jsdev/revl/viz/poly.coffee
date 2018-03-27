{Result} = require '../utils/result'
{polygon,Polygon} = require '../geometry/polygon'
Utils = require '../utils/utils'
Vec = require '../geometry/vec'
BoundingBox = require '../geometry/boundingbox'
Voronoi = require '../geometry/voronoi'
{fgt} = require '../geometry/eps'

# Commands to transform data structures into polygon structures
Poly =
    drawPolygons: (pgons,svg,w,h) ->
        container = svg.selectAll "g"
            .data pgons
            .enter().append "g"
            .attr "transform", "translate("+(w*0.1)+','+(h*0.1)+')'
            
        container
            .append "polygon"
            .attr "points", (pgon)-> (pgon.verts.map (pt)->pt.x()+','+pt.y()).join ' '
            .attr "fill", (pgon,n)->if 'color' of pgon then pgon.color else Utils.pickColor n,pgons.length+1
            .attr "stroke-width", "1"
            .attr "stroke", (pgon)->"black"

        container
            .append "text"
            .attr "transform", (pgon)->
                cm = pgon.center()
                "translate("+cm.x()+','+cm.y()+')'
            .text (d)->
                if d.label
                    JSON.stringify d.label
                else
                    ""
            .attr "y","0.35em"
            .style "text-anchor", "middle"
        
    drawImage: (img,svg,w,h) ->

    grid: (data)->
        rows = (Object.keys data).length
        cols = Math.max.apply {}, ((Object.keys data[x]).length for own x of data)
        w = (document.getElementById "revl-vizbox").offsetWidth * 0.8
        h = (document.getElementById "revl-vizbox").offsetHeight * 0.8
        padding = 2
        if (w/cols < 10) or (h/rows < 10)
            padding = 0
        cellw = (w / cols) - padding
        cellh = (h/rows)-padding
        cellAt  = (x,y,data) ->
            p = polygon [[x,y+cellh],[x,y],[x+cellw,y],[x+cellw,y+cellh]]
            p.input = data
            p
        cells = []
        y=0
        for own row of data
            x=0
            for own col of data[row]
                cells.push cellAt x*(cellw+padding), y*(cellh+padding), data[row][col]
                x++
            y++
        {data: data, polygons: cells}

    eachpoly: (data,proc) ->
        for poly in data.polygons
            proc poly
        data

    mappoly: (data,proc) ->
        r = []
        for poly in data.polygons
            p = proc poly
            if (typeof p) != 'undefined'
                if Utils.isArray p
                    r.push p...
                else
                    r.push p
        data.polygons = r
        data
        
    genpoints: (count,boundary) ->
        bbox = boundary.bbox()
        points = []
        pt = undefined
        mkpt = () -> new Vec [(Math.random() * bbox.w + bbox.left()),
            (Math.random() * bbox.h + bbox.top())]
        for i in [0...count]
            pt = mkpt()
            j=0
            while j<10 and not boundary.contains pt
                j++
                pt = mkpt()
            if j>=10
                console.log "polygon("+(JSON.stringify ([v.x(),v.y()] for v in boundary.verts))+")"
                throw "Error: Couldn't make a point fit in the boundary for polygon "+(JSON.stringify boundary)
            points.push pt
        points
            
            
    voronoi: (data,bbox,boundary=undefined) ->
        bound = boundary or bbox
        pts = Poly.genpoints data.length, bound
        polys = (new Voronoi pts,bound).layout().drawable()
        polys.input = data
        for i in [0...data.length]
            polys.polygons[i].input = data[i]
        polys
        
    commands:
        help__draw: () -> """
            draw

            Draw a graphic object. This command is designed to take
            the output from numerous other commands such as grid,
            voronoi, treemap, and others, and render them on
            screen. You can also hand-code your own graphics objects
            if you're up for some pain.

            Graphic objects are simple objects with up to two
            fields: 'image' and 'polygons'
            
            'image' is something that can be interpreted as an image
            (either a URL or an array with bitmap values)

            'polygons' is a list of polygons. They must be in the
            format accepted by PolyBoolJS, which is a structure with
            two fields, one named 'regions' and the other named
            'inverted'.

            The 'regions' field should be a list of lists of
            two-element lists, where the innermost lists represent
            vertices of a polygon. Be careful with the ordering of the
            vertices in this case. If you don't want funky
            self-intersecting polygons, the vertices need to follow an
            orderly route around the perimeter. the 'inverted' field
            should just be false (unless you want a polygon the size
            of the universe with a hole in it specified by the
            vertices).

            Graphics objects also have a few other fields you can
            tinker with:
            * color - specifies the color of the field
            * input - this is the data that should be associated with
              the polygon
            * stroke - the width of the border in pixels, can be zero
            * textcolor - color of text...

            Example:
                $ $ [1..10] \\ (n)->[1..10].map (i)->[i,n] \\ grid \\
                ..  into (g)->g.polygons.forEach ((p)->p.color = Utils.pickColor p.input[0]*p.input[1], 100); g\\
                ..  draw
                {
                    polygons: [
                        {
                            color: '#99342e',
                            input: [1, 1],
                            inverted: false,
                            regions: [[[0, 30.240], [0, 0], [50.64, 0], [50.64, 30.240]]]
                        },
                        {
                            color: '#993a2e',
                            input: [1, 2],
                            inverted: false,
                            regions: [
                                [[0, 62.480], [0, 32.24], [50.64, 32.24], [50.64, 62.480]]
                                ]
                        },...
                }
                
            That command makes a 10x10 list of lists, each of which
            has its offset coordinates as the final level. It then
            uses the grid command to make a 2d array of rectangular
            cells, one for each set of offset coordinates. Finally, it
            alters the color so that it's determined by the magnitude
            of the product of the two coordinates. The result is
            passed to draw so that it shows up on screen.

            This command passes the input data through to its output
            without modification"""
        
        draw: (argv,data,ctx)->
            try
                svg = d3.select "#revl-vizbox"
                    .html ""
                    .append "svg"
                    .attr "class","viz"
                margin = {top: 20, right: 20, bottom: 30, left: 40}
                width = +document.querySelector("#revl-vizbox").offsetWidth - margin.left - margin.right
                height = +document.querySelector("#revl-vizbox").offsetHeight - margin.top - margin.bottom
 
                if 'image' of data #image first for underlays
                    Poly.drawImage element, svg, width, height
                if 'polygons' of data
                    Poly.drawPolygons data.polygons, svg, width, height
                Result.wrap data
            catch e
                Result.err ("polydraw: "+e)

        help__grid: () -> """
            grid

            This command takes a list of lists of data items, and
            creates a graphic item containing an array of rectangular
            cells, one for each data item. The array mimics the
            structure of the list, so if you have a 10x4 list, you'll
            have 10 cells per row and 4 rows in the output graphic.

            The 'input' field of each cell will hold its corresponding
            data item so that further calculations can be done to
            alter things like color and whatnot. See the example for
            the 'draw' command for an example of using this command
            (it's a long example).
            """
            
        grid: (argv,data,ctx)->
            try
                Result.wrap (Poly.grid data)
            catch e
                Result.err ("grid: "+e)

        help__eachpoly: () -> """
            eachpoly &lt;func(poly,data,global_data)&gt;

            eachpoly takes a function and calls it on every polygon in
            a graphics object. The function is given the polygon
            itself, the cell's input data, and the original data (if
            any) that was used to create the whole graphics object.

            Example:
                $ [1..10] \\ (n)->[1..10].map (i)->[i,n] \\ grid \\
                ..  eachpoly (p)->p.color = Utils.heatColor p.input[0]*p.input[1],100 \\ draw

            The example creates a heatmap with 100 cells, where the
            heat value is computed by multipling the row and column of
            the cell in question """

            
        eachpoly: (argv,data,ctx) ->
            try
                Utils.parsefunction (argv.join ' '),ctx
                    .map (proc) ->
                        Result.wrap (Poly.eachpoly data, proc)
            catch e
                Result.err ("eachpoly: "+e)

        help__mappoly: ()-> """
            mappoly <(poly)->newpoly>

            mappoly applies a function to each polygon in a drawable,
            generating a new drawable that replaces the original
            polygons with the result of calling the function on them.
            """
        
        mappoly: (argv,data,ctx) ->
            try
                Utils.parsefunction (argv.join ' '),ctx
                    .map (proc) ->
                        Result.wrap (Poly.mappoly data, proc)
            catch e
                Result.err ("mappoly: "+e)

        help__voronoi: ()-> """
            voronoi

            Create a voronoi diagram to display data from the
            pipeline. Voronoi diagrams are 2d space-filling diagrams
            that allocate polygonal cells to each data element. This
            tool expects a list of items from the pipeline, and will
            create a diagram with a cell for each item. The result is
            a drawable object that can be piped directly to the draw
            command, or can be further processed to give custom colors
            or make recursive treemaps.

            Example:
                $ [1..100] \\ voronoi \\ draw

            This makes a voronoi diagram with 100 cells and draws it
            using the default color scheme and rectangular border.
            """

        voronoi: (argv,data,ctx) ->
            try
                target = document.getElementById "revl-vizbox"
                w = target.offsetWidth * 0.8
                h = target.offsetHeight * 0.8
                bbox = new BoundingBox 0,0,w,h
                Result.wrap (Poly.voronoi data,bbox)
            catch e
                Result.err ("voronoi: "+e)

        help__voronoitree: () -> """
            """

        voronoitree: (argv,data,ctx) ->
            
module.exports = Poly
