var React = require('react');
var Panel = require('react-bootstrap/lib/Panel.js');
var Badge = require('react-bootstrap/lib/Badge.js');

var ReportHeatmap = React.createClass({
    getInitialState: function() {
        return {
            ReportData: null,
            collection:'event',
            type:'created',
            year:'2017',
        }
    },
    componentDidMount: function() {
       this.loadHeatMap(); 
    },
    componentWillMount: function() {
        /*const script = document.createElement("script");
        script.type = 'text/javascript';
        script.src = "/libs/d3.3_4_11.js";
        script.async = true;
        document.body.appendChild(script);*/
    },
    loadHeatMap: function() {
        var margin = { top: 50, right: 0, bottom: 100, left: 30 },
        width = 960 - margin.left - margin.right,
        height = 430 - margin.top - margin.bottom,
        gridSize = Math.floor(width / 24),
        legendElementWidth = gridSize*2,
        buckets = 9,
        colors = ["#ffffd9","#edf8b1","#c7e9b4","#7fcdbb","#41b6c4","#1d91c0","#225ea8","#253494","#081d58"], // alternatively colorbrewer.YlGnBu[9]
        days = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"],
        times = ["1a", "2a", "3a", "4a", "5a", "6a", "7a", "8a", "9a", "10a", "11a", "12a", "1p", "2p", "3p", "4p", "5p", "6p", "7p", "8p", "9p", "10p", "11p", "12p"];
        //datasets = ["data.tsv", "data2.tsv"];

        var svg = d3.select("#chart").append("svg")
            .attr("width", width + margin.left + margin.right)
            .attr("height", height + margin.top + margin.bottom)
            .append("g")
            .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

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
    },
    collectionChange: function(event) {
        this.setState({collection: event.target.value});
    },
    render: function() {
        return (
            <div id='report' className="dashboard col-md-4">
                <h1>Day of Week, Hour of Day Heatmap</h1>
                <label htmlFor="year" style={{display: "inline-block", width: "240px", textAlign:"right"}}>Year = <span id="year-value"></span></label>
                <input type="number" min="2013" max="2017" step="1" value="2016" id="year"/>
                <label htmlFor="collection" style={{display: "inline-block", width: "240px", textAlign:"right"}}>Collection = <span id="year-value"></span></label>
                <select id="collection" value={this.state.collection} onChange={this.state.collectionChange}>
                    <option value='event'>event</option>
                    <option value='alert'>alert</option>
                    <option value='incident'>incident</option>
                </select>
                <button id='export'>Export to PNG</button>
                <div id="chart"></div>
                <div id="dataset-picker"></div>
                <canvas id="canvas" style={{width:"800px", height:"400px"}} hidden></canvas>
                <div id='png-container' hidden></div>
            </div>
        )
    }
});

module.exports = ReportHeatmap;
