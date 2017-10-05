Utils=require '../utils/utils'
{Result}=require '../utils/result'
{fzero,feq}=require '../geometry/eps'

class Linechart
    constructor: (@target)->
    @commands: 
        help__linechart: ()->"""
            linechart
    
            linechart produces a chart with lines tracing data series. It
            expects data in the form of either lists of points, or objects
            that have data members as follows:
    
            List form:
                [[[x1,y1],[x2,y2],...], [[x1,y1],[x2,y2]...], ...]
                
                The outer list contains a bunch of series. The inner lists
                are each single series, which are lists of point pairs. If
                you only want to chart a single data series, you can just
                pass in the list of point pairs and the linechart command
                will figure it out.
    
            Object form:
            [{
                points: [[x1,y1],[x2,y2]...]
                name: 'optional label for this series'
                color: 'optional html color name'
                style: 'optional line style'
             } ...]
    
    
             Examples:
                $ [[1,1],[2,4],[3,9]] \\ linechart
                # plots a linechart with y = x^2
    
                $ [[[1,1],[2,4],[3,9]],[[1,1],[2,2],[3,3]]] \\ linechart
                # plots a chart with two lines, one for y=x^2 and the other for y=x
    
                $ [{ points: [[1,1],[2,4],[3,9]],
                     name: 'y=x^2',
                     color: 'red'},
                   { points: [[1,1],[2,2],[3,3]],
                     name: 'y=x',
                     color: 'blue'}] \\ linechart
                #plots two traces, labeled and colored as given
               """
 
        linechart: (argv,d,ctx) ->
            Linechart.formatData d
                .map (data) ->
                    lc = new Linechart (document.querySelector "#revl-vizbox")
                    lc.render data
                .map_err (e) ->  ("linechart: "+e)
                
    @formatData: (d) ->
        switch
            when (Utils.isArray d) && (Utils.isArray d[0]) and (Utils.isArray d[0][0])
                # multiple unlabeled traces
                Result.wrap d.map (series,idx) ->
                    points: series
                    name:'series '+(idx+1)
                    color: Utils.pickColor idx, d.length
                    style: '1px solid'
            when (Utils.isArray d) && (Utils.isArray d[0])
                Result.wrap [
                    points: d
                    name: 'series 1'
                    color: Utils.pickColor 0
                    style: '1px solid']
            when (Utils.isArray d) && (Utils.isObject d[0])
                for series in d
                    if !Utils.isArray series.points
                        return Result.err "series must have a 'points' member when objects are used"
                Result.wrap (d.map (series,idx) ->
                    series.color ?= Utils.pickColor idx, d.length
                    series.style ?= '1px solid'
                    series)
            when Utils.isObject d # single trace with labels
                if !Utils.isArray d.points
                    Result.err "series must have a 'points' member when objects are used"
                else
                    d.color ?= Utils.pickColor 0
                    d.style ?= '1px solid'
                    Result.wrap [d]
            else
                Result.err "Unrecognized data format, see 'help linechart' for details"

    render: (data) ->
        margin =
            top: 20
            right: 20
            bottom: 30
            left: 50
        width = @target.offsetWidth - margin.left - margin.right
        height = @target.offsetHeight - margin.top - margin.bottom
        x = d3.scaleLinear().range [0,width]
        y = d3.scaleLinear().range [height,0]
        xAxis = d3.axisBottom().scale x
        yAxis = d3.axisLeft().scale y
        xExt = (d3.extent ([].concat ((series.points.map (p)->p[0]) for series in data)...))
        yExt = (d3.extent ([].concat ((series.points.map (p)->p[1]) for series in data)...))
        xpad = (xExt[1]-xExt[0])*0.05
        ypad = (yExt[1]-yExt[0])*0.05
        if fzero xpad then xpad=0.001
        if fzero ypad then ypad=0.001
        x.domain [xExt[0]-xpad, xExt[1]+xpad]
        y.domain [yExt[0]-ypad,yExt[1]+ypad]
        
        svg = d3.select @target
            .html ""
            .append "svg"
            .attr "width", width+margin.left + margin.right
            .attr "height", height+margin.top+margin.bottom
            .append 'g'
            .attr 'transform','translate('+margin.left+','+margin.top+')'
        svg.append "g"
            .attr "class","linechart-x axis"
            .attr "transform", "translate(0,"+height+")"
            .call xAxis
        svg.append "g"
            .attr "class", "linechart-y-axis axis"
            .call yAxis
            
        for series in data
            line = d3.line()
                .x (d)-> x d[0]
                .y (d)-> y d[1]
            svg.append "path"
                .datum series.points
                .attr "class", "linechart-line"
                .attr "d", line
                .attr 'stroke', series.color
        Result.wrap data
           
module.exports = Linechart
