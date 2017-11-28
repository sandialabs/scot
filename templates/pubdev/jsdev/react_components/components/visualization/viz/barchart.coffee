{Result} = require '../utils/result'

class Barchart
    @commands =
        help__barchart: () ->"""
            barchart

            barchart produces a bar chart in the visualization pane
            based on the input. Input should be formatted as an
            object, where the keys will be the chart labels and the
            values will be the heights of the bars. The chart is
            automatically scaled so that all bars fit and the tallest
            bar is the height of the full chart. You can also just
            pass in a list of numbers, and the labels will be the
            indexes.

            Examples:
              $ {cheezburgers: 50, cats: 1} \\ barchart

              $ [1,2,3,4,5] \\ barchart

            The first example command produces a chart with two
            bars. The first is labeled \"cheezburgers\" and has height
            50, and the second is labeled \"cats\" and has height 1.

            The second example produces a bar chart with five bars,
            labeled 0 through 4, with heights given in the list.

            The input will be passed through this command so you can
            pipe other commands after it if needed"""
            
        barchart: (argv,d) ->
            chart = new Barchart argv, d
            chart.render "#revl-vizbox"
            Result.wrap d

    constructor: (argv,@data) ->
        @maxdata = undefined
        @pairs = []
        for k,v of @data
            @maxdata ?= v
            @pairs.push [k,+v]
            if @maxdata < v
                @maxdata = v
                
    render: (target) ->
        svg = d3.select target
            .html ""
            .append "svg"
            .attr "class", "viz"
        margin = {top: 20, right: 20, bottom: 30, left: 40}
        width = +document.querySelector(target).offsetWidth - margin.left - margin.right
        height = +document.querySelector(target).offsetHeight - margin.top - margin.bottom
        console.log "width: "+width
        console.log "height: "+height
        x = d3.scaleBand()
            .rangeRound [0,width]
            .padding 0.1
            .domain @pairs.map (p)->p[0]
        y = d3.scaleLinear()
            .rangeRound [height,0]
            .domain [0, d3.max (@pairs.map (p) -> p[1])]
        g = svg.append "g"
            .attr "transform","translate("+margin.left+","+margin.top+")"


        console.log "bar width: "+x.bandwidth()
        
        g.append "g"
            .attr "class", "axis barchart-axis--x"
            .attr "transform", "translate(0,"+height+")"
            .call d3.axisBottom x

        g.append "g"
            .attr "class", "axis barchart-axis--y"
            .call ((d3.axisLeft y).ticks 10)
            .append "text"
            .attr "transform", "rotate(-90)"
            .attr "y", 6
            .attr "dy", "0.71em"
            .attr "text-anchor", "end"
            .text "Value"

        g.selectAll ".barchart-bar"
            .data @pairs
            .enter()
            .append "rect"
            .attr "class", "barchart-bar"
            .attr "x", (d) -> x d[0]
            .attr "y", (d) -> y d[1]
            .attr "width", x.bandwidth()
            .attr "height", (d) -> height - y d[1]
            
module.exports = Barchart
