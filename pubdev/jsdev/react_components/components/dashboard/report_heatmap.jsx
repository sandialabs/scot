import React, { PureComponent } from 'react';
import { Button } from 'react-bootstrap';

class ReportHeatmap extends PureComponent {
	constructor( props ) {
		super( props );

        this.state = {
            collection:'event',
            type:'created',
            year:'2017',
        }
    }

    componentDidMount() {
       this.loadHeatMap(); 
    }

    componentDidUpdate() {
        this.loadHeatMap();
    }

    loadHeatMap() {
        var margin = { top: 50, right: 0, bottom: 100, left: 50 },
        width = $('#heatmap').width() - (margin.left - margin.right),
        height = this.state.height - (margin.top - margin.bottom),
        gridSize = Math.floor(width / 24),
        legendElementWidth = gridSize*2,
        buckets = 9,
        colors = ["#ffffd9","#edf8b1","#c7e9b4","#7fcdbb","#41b6c4","#1d91c0","#225ea8","#253494","#081d58"], // alternatively colorbrewer.YlGnBu[9]
        days = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"],
        times = ["1a", "2a", "3a", "4a", "5a", "6a", "7a", "8a", "9a", "10a", "11a", "12a", "1p", "2p", "3p", "4p", "5p", "6p", "7p", "8p", "9p", "10p", "11p", "12p"];

        var svg = d3.select("#report_heatmap_g")
        /*var svg = d3.select("#chart").append("svg")
            .attr("width", width + margin.left + margin.right)
            .attr("height", height + margin.top + margin.bottom)
            .append("g")
            .attr("transform", "translate(" + margin.left + "," + margin.top + ")");
        */
        
        var dayLabels = svg.selectAll(".dayLabel")
            .data(days)
            .enter().append("text")
                .text(function (d) { return d; })
                .attr("x", 0)
                .attr("y", function (d, i) { return i * gridSize; })
                .style("text-anchor", "end")
                .attr("transform", "translate(-6," + gridSize / 1.5 + ")")
                .attr("class", function (d, i) { return ((i >= 0 && i <= 4) ? "dayLabel mono axis axis-workweek" : "dayLabel mono axis"); });

        var timeLabels = svg.selectAll(".timeLabel")
            .data(times)
            .enter().append("text")
                .text(function(d) { return d; })
                .attr("x", function(d, i) { return i * gridSize; })
                .attr("y", 0)
                .style("text-anchor", "middle")
                .attr("transform", "translate(" + gridSize / 2 + ", -6)")
                .attr("class", function(d, i) { return ((i >= 7 && i <= 16) ? "timeLabel mono axis axis-worktime" : "timeLabel mono axis"); });

        var url = '/scot/api/v2/graph/dhheatmap?collection='+this.state.collection+'&type='+this.state.type+'&year='+this.state.year 
        d3.json(
            url,
            function(error, data) {
                var colorScale = d3.scale.quantile()
                    .domain([0, buckets - 1, d3.max(data, function (d) { return d.value; })])
                    .range(colors);

                var cards = svg.selectAll(".hour")
                    .data(data, function(d) {return d.day+':'+d.hour;});

                cards.append("title");

                cards.enter().append("rect")
                    .attr("x", function(d) { return (d.hour - 1) * gridSize; })
                    .attr("y", function(d) { return (d.day - 1) * gridSize; })
                    .attr("rx", 4)
                    .attr("ry", 4)
                    .attr("class", "hour bordered")
                    .attr("width", gridSize)
                    .attr("height", gridSize)
                    .style("fill", colors[0]);

                cards.transition().duration(1000)
                    .style("fill", function(d) { return colorScale(d.value); });

                cards.select("title").text(function(d) { return d.value; });

                cards.exit().remove();

                var legend = svg.selectAll(".legend")
                    .data([0].concat(colorScale.quantiles()), function(d) { return d; });

                legend.enter().append("g")
                    .attr("class", "legend");

                legend.append("rect")
                    .attr("x", function(d, i) { return legendElementWidth * i; })
                    .attr("y", height)
                    .attr("width", legendElementWidth)
                    .attr("height", gridSize / 2)
                    .style("fill", function(d, i) { return colors[i]; });

                legend.append("text")
                    .attr("class", "mono")
                    .text(function(d) { return "≥ " + Math.round(d); })
                    .attr("x", function(d, i) { return legendElementWidth * i; })
                    .attr("y", height + gridSize);

                legend.exit().remove();
            }
        );
    }

    collectionChange( event ) {
        this.setState({collection: event.target.value});
    }
	 
    yearChange( event ) {
        this.setState({year: event.target.value});
    }

    exportToPNG() {
        var svgString = new XMLSerializer().serializeToString(document.querySelector('svg'));

        var canvas = document.getElementById("canvas");
        var ctx = canvas.getContext("2d");
        var DOMURL = self.URL || self.webkitURL || self;
        var img = new Image();
        var svg = new Blob([svgString], {type: "image/svg+xml;charset=utf-8"});
        var url = DOMURL.createObjectURL(svg);
        img.onload = function() {
            ctx.drawImage(img, 0, 0);
            var png = canvas.toDataURL("image/png");
            document.querySelector('#png-container').innerHTML = '<img src="'+png+'"/>';
            DOMURL.revokeObjectURL(png);
            var a = $("<a>")
            .attr("href", png)
            .attr("download", "img.png")
            .appendTo("body");

            a[0].click();

            a.remove();
        };
        img.src = url;
    }

    render() {
        var margin = { top: 50, right: 0, bottom: 100, left: 30 }
        var transform = 'translate(' + margin.left + ',' + margin.top + ')';
        var svgwidth = $('#report').width();
        return (
            <div id='report_heatmap' className="dashboard">
                <h1>Day of Week, Hour of Day Heatmap</h1>
                <label htmlFor="year" style={{display: "inline-block", width: "240px", textAlign:"right"}}>Year = <span id="year-value"></span>
                    <input type="number" min="2013" step="1" value={this.state.year} id="year" onChange={this.yearChange}/>
                </label>
                <label htmlFor="collection" style={{display: "inline-block", width: "240px", textAlign:"right"}}>Collection = <span id="year-value"></span>
                    <select id="collection" value={this.state.collection} onChange={this.collectionChange}>
                        <option value='event'>event</option>
                        <option value='alert'>alert</option>
                        <option value='incident'>incident</option>
                    </select>
                </label>
                <Button id='export' bsSize='xsmall' bsStyle='default' onClick={this.exportToPNG}>Export to PNG</Button>
                <div id="chart">
                    <svg id={'report_heatmap'} width={svgwidth} height={this.state.height}>
                        <g id={'report_heatmap_g'} transform={transform}>
                        
                        </g>
                    </svg>
                </div>
                <canvas id="canvas" width={svgwidth} height={this.state.height} hidden></canvas>
                <div id='png-container' hidden></div>
            </div>
        )
    }
}

export default ReportHeatmap;
