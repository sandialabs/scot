Utils = require '../utils/utils'
{Result} = require '../utils/result'
{fzero} = require '../geometry/eps'

class Dotchart
    constructor: (@pts) ->

    draw: (target) ->
        margin =
            top: 20
            right: 20
            bottom: 30
            left: 50
        width = target.offsetWidth - margin.left - margin.right
        height = target.offsetHeight - margin.top - margin.bottom
        x = d3.scaleLinear().range [0,width]
        y = d3.scaleLinear().range [height,0]
        xAxis = d3.axisBottom().scale x
        yAxis = d3.axisLeft().scale y
        xExt = (d3.extent (@pts.map (p)->p[0]))
        yExt = (d3.extent (@pts.map (p)->p[1]))
        xpad = (xExt[1]-xExt[0])*0.05
        ypad = (yExt[1]-yExt[0])*0.05
        if fzero xpad then xpad=0.001
        if fzero ypad then ypad=0.001
        x.domain [xExt[0]-xpad, xExt[1]+xpad]
        y.domain [yExt[0]-ypad,yExt[1]+ypad]
        
        svg = d3.select target
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

        svg.selectAll ".dot"
            .data @pts
            .enter()
            .append "circle"
            .attr "class", "dot"
            .attr "r", 1.5
            .attr "cx", (d)->x d[0]
            .attr "cy", (d)->y d[1]
            .style "fill", (d)-> Utils.pickColor d[0],xExt[1]
        Result.wrap @pts
    @commands:
        help__dotchart: ()->"""
            dotchart

            Dotchart makes a scatter plot, with one dot for each data
            point in a 2D data set.

            Example:
                $ get "https://localhost/scot/api/v2/alertgroup/1512214/alert?limit=100" \\
                ..    (r)->map r.records,(rec)->rec.data._time \\
                ..    pick Strings.pat.hms \\
                ..    (ls)->(parseInt ls[1])*3600 + (parseInt ls[2])*60 + parseInt ls[3] \\
                ..    sort \\
                ..    (t,i)->[t,i] \\
                ..    dotchart

                This command retreives the alerts in alertgroup
                1512214, picks out all of the timestamps, converts
                them to a number of seconds (assuming the day is all
                the same), sorts them in ascending order,then makes a
                dotchart with the x coordinate being the timestamp and
                the y coordinate being the position of the event in
                the set. This makes it easy to see timing patterns
                (they look like tall spikes of dots).
                """
            
        dotchart: (argv,d,ctx) ->
            chart = new Dotchart d
            chart.draw document.querySelector "#revl-vizbox"
 
module.exports = Dotchart
