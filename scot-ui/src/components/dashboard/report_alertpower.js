import React, { PureComponent } from "react";
import { Button } from "react-bootstrap";
import * as d3 from "d3";
import debounce from "../../utils/debounce";
import axios from 'axios'
import $ from "jquery";
const wrapText = (text, width) => {
  // FYI: not an arrow function because of 'this' injection
  text.each(function (value, i) {
    if (this.getComputedTextLength() < width) {
      return;
    }

    let text = d3.select(this),
      words = text
        .text()
        .split(/\s+/)
        .reverse(),
      word = null,
      line = [],
      lineCount = 1,
      lineHeight = 0.8, // ems
      x = text.attr("x"),
      y = text.attr("y"),
      dy = parseFloat(text.attr("dy")),
      row = text
        .text(null)
        .append("tspan")
        .attr("x", x)
        .attr("y", y)
        .attr("dy", dy + "em");

    while ((word = words.pop())) {
      line.push(word);
      row.text(line.join(" "));
      if (row.node().getComputedTextLength() > width) {
        lineCount++;
        line.pop();
        row.text(line.join(" "));
        line = [word];
        row = text
          .append("tspan")
          .attr("x", x)
          .attr("y", y)
          .attr("dy", lineHeight + dy + "em")
          .text(word);
      }
    }

    let yOffset = (this.getBBox().height / (2 * lineCount)) * (lineCount - 1);
    text.attr("transform", `translate( 0, -${yOffset} )`);
  });
};

const margin = {
  top: 5,
  left: 200,
  right: 30,
  bottom: 60
},
  width = 1000 - margin.left - margin.right,
  legendHeight = 20,
  legendSpacing = 15,
  legendTextSpacing = 5;

class ReportAlertpower extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      displayMode: "stacked",
      chartData: [],
      chartResults: 20,
      chartSort: "power",
      chartSortDir: "desc",
      chartFilter: ""
    };

    // LoadData is automatically debounced
    this.loadData = debounce(this.loadData);
  }

  componentDidMount() {
    this.initChart();
    this.updateChart();
    this.loadData();
  }

  initChart = () => {
    // Height is initially 0, is calculated after we have data
    this.height = 0;

    this.xScale = d3.scaleLinear().rangeRound([0, width]);
    this.yScale = d3
      .scaleBand()
      .rangeRound([0, this.height])
      .padding(0.3);

    this.colors = d3.scaleOrdinal(d3.schemeCategory10);

    this.xAxis = d3.axisBottom().scale(this.xScale);

    this.yAxis = d3.axisLeft().scale(this.yScale);

    this.svg = d3
      .select("#report_alertpower")
      .attr("viewBox", `0 0 1000 ${this.height + margin.top + margin.bottom}`)
      .append("g")
      .attr("transform", `translate( ${margin.left}, ${margin.top} )`);

    this.yAxisEl = this.svg.append("g").attr("class", "y axis");

    this.xAxisEl = this.svg
      .append("g")
      .attr("class", "x axis")
      .attr("transform", `translate( 0, ${this.height} )`);

    this.xAxisEl
      .append("text")
      .attr("text-anchor", "middle")
      .attr("x", width / 2)
      .attr("y", 30)
      .style("fill", "black")
      .style("font-size", "12px")
      .text("Alert Count");

    this.LegendHolder = this.svg.append("g").attr("class", "legend-holder");

    this.chartInit = true;
  }

  updateChart = () => {
    let dataset = this.state.chartData;

    // Calculate height
    this.height = 32 * dataset.length;
    d3.select("#report_alertpower")
      .transition()
      .attr("viewBox", `0 0 1000 ${this.height + margin.top + margin.bottom}`);

    this.dataTypes = d3
      .keys(dataset[0])
      .filter(
        key => !["name", "values", "total", "score", "max"].includes(key)
      );

    // Build color domain from keys except name
    this.colors.domain(this.dataTypes);

    dataset.forEach(d => {
      // Remove number at the end
      d.name = d.name.replace(/ \([0-9]+\)/, "");

      /* // False Data
			this.dataTypes.forEach( type => {
				d[ type ] = Math.round( Math.random() * 5 );
			} );
			if ( !d.score ) {
				d.score = ( Math.random() * 10 ).toPrecision( 2 );
			}
			/**/
      if (typeof d.score === "number") {
        d.score = "" + d.score;
      }

      // Calculate bar start/end points
      let start = 0;
      d.values = this.dataTypes.map(name => {
        let curStart = start,
          curEnd = start + d[name];

        start += d[name];
        return {
          name: name,
          count: d[name],
          start: curStart,
          end: curEnd
        };
      });

      d.total = d.values[d.values.length - 1].end;
      d.max = d3.max(this.dataTypes, b => {
        return d[b];
      });
    });

    this.stackedMax = d3.max(dataset, d => d.total);
    this.groupedMax = d3.max(dataset, d => {
      return d3.max(this.dataTypes, b => d[b]);
    });

    this.yScale.rangeRound([0, this.height]).domain(dataset.map(d => d.name));

    /*
		// Animated, but multiline flashes
		this.yAxisEl.transition().call( g => {
			g.call( this.yAxis )
			setTimeout( () => {
				g.selectAll( '.tick text' ).call( wrapText, margin.left - 20 );
			}, 50 )
		} )
		/**/
    /**/
    // Not animated
    this.yAxisEl.call(this.yAxis);
    this.svg.selectAll(".y.axis .tick text").call(wrapText, margin.left - 20); // Wrap axis labels
    /**/

    let alerts = this.svg.selectAll(".alert").data(dataset, d => d.name);

    alerts
      .exit()
      .transition()
      .attr("height", 0)
      .style("opacity", 0)
      .remove();

    alerts
      .enter()
      .append("g")
      .attr("class", "alert")
      .attr("transform", d => `translate( 1, ${this.yScale(d.name)} )`)
      .append("text")
      .attr("dy", "1.2em");

    alerts
      .transition()
      .attr("transform", d => `translate( 1, ${this.yScale(d.name)} )`);

    let alertTypes = this.svg
      .selectAll(".alert")
      .selectAll("rect")
      .data(d => d.values);

    let bars = alertTypes
      .enter()
      .append("rect")
      .attr("x", 0)
      .attr("y", 0)
      .attr("width", 0)
      .attr("height", this.yScale.bandwidth());
    bars.merge(alertTypes).style("fill", d => this.colors(d.name));

    bars
      .append("title")
      .merge(alertTypes.select("title"))
      .text(d => `${d.name}: ${d.count}`);

    // Legend
    let legend = this.LegendHolder.selectAll(".legend").data(this.dataTypes);

    legend.exit().remove();

    legend = legend
      .enter()
      .append("g")
      .attr("class", "legend");

    // Legend Boxes
    legend
      .append("rect")
      .attr("width", legendHeight)
      .attr("x", 0)
      .attr("y", 0)
      .attr("height", legendHeight)
      .style("fill", d => this.colors(d));

    // Legend Text
    legend
      .append("text")
      .attr("x", legendHeight + legendTextSpacing)
      .attr("y", legendHeight / 2)
      .attr("dy", ".35em")
      .style("text-anchor", "start")
      .style("text-transform", "capitalize")
      .text(d => d);

    // Legend Position
    let widthSums = 0;
    this.LegendHolder.selectAll(".legend").attr("transform", function (d, i) {
      let value = widthSums;
      widthSums += this.getBBox().width + legendSpacing;
      return `translate( ${value}, 0 )`;
    });
    let legendWidth = this.LegendHolder.node().getBBox().width;
    this.LegendHolder.transition().attr(
      "transform",
      `translate( ${width / 2 - legendWidth / 2}, ${this.height +
      margin.bottom -
      legendHeight} )`
    );

    if (this.state.displayMode === "grouped") {
      this.transitionGrouped();
    } else {
      this.transitionStacked();
    }
  }

  transitionStacked = () => {
    this.xScale.domain([0, this.stackedMax]).nice();
    this.xAxisEl
      .transition()
      .call(this.xAxis)
      .attr("transform", `translate( 0, ${this.height} )`);

    this.svg
      .selectAll(".alert rect")
      .transition()
      .delay((d, i) => i * 5)
      .duration(500)
      .attr("width", d => this.xScale(d.end) - this.xScale(d.start))
      .attr("x", d => this.xScale(d.start))
      .transition()
      .attr("height", this.yScale.bandwidth())
      .attr("y", 0);

    this.svg
      .selectAll(".alert text")
      .transition()
      .delay((d, i) => i * this.dataTypes.length * 5 + i)
      .duration(500)
      .attr("transform", d => `translate( ${this.xScale(d.total) + 10}, 0 )`)
      .tween("text", function (d) {
        let text = d3.select(this);
        let i = d3.interpolateNumber(text.text(), d.score),
          prec = d.score.split("."),
          round = prec.length > 1 ? Math.pow(10, prec[0].length) : 1;

        return t => text.text(Math.round(i(t) * round) / round);
      });
  }

  transitionGrouped = () => {
    this.xScale.domain([0, this.groupedMax]).nice();
    this.xAxisEl
      .transition()
      .call(this.xAxis)
      .attr("transform", `translate( 0, ${this.height} )`);

    let initialDuration = this.displayModeChanged ? 500 : 0;

    this.svg
      .selectAll(".alert")
      .selectAll("rect")
      .transition()
      .delay((d, i) => i * 5)
      .duration(initialDuration)
      .attr("height", this.yScale.bandwidth() / this.dataTypes.length)
      .attr(
        "y",
        (d, i) => (this.yScale.bandwidth() / this.dataTypes.length) * i
      )
      .transition()
      .duration(500)
      .attr("x", 0)
      .attr("width", d => this.xScale(d.end) - this.xScale(d.start));

    this.svg
      .selectAll(".alert text")
      .transition()
      .delay((d, i) => i * 5 + initialDuration)
      .attr("transform", d => `translate( ${this.xScale(d.max) + 10}, 0 )`)
      .tween("text", function (d) {
        let text = d3.select(this);
        let i = d3.interpolateNumber(text.text(), d.score),
          prec = d.score.split("."),
          round = prec.length > 1 ? Math.pow(10, prec[0].length) : 1;

        return t => text.text(Math.round(i(t) * round) / round);
      });

    this.displayModeChanged = false;
  }

  loadData = () => {
    if (!this.state.chartResults || this.props.editMode) {
      return;
    }

    let url = "/scot/api/v2/metric/alert_power";
    let opts = `?sort=${this.state.chartSort}&dir=${
      this.state.chartSortDir
      }&count=${this.state.chartResults}&filter=${encodeURIComponent(
        this.state.chartFilter
      )}`;

    axios.get(url + opts).then(res => {
      this.setState({
        chartData: res.data
      });
    });
  }



  dataChange = (event) => {
    let target = event.target;

    if (target.name === "chartResults" && target.value) {
      if (target.value > 50) target.value = 50;
      if (target.value < 1) target.value = 1;
    }

    this.setState(
      {
        [target.name]: target.value
      },
      this.loadData
    );
  }

  displayModeChang = (event) => {
    this.displayModeChanged = true;
    this.setState({
      displayMode: event.target.value
    });
  }

  preventSubmit = (event) => {
    event.preventDefault();
    event.stopPropagation();
  }

  exportToPNG = () => {
    var svgString = new XMLSerializer().serializeToString(
      document.querySelector("#report_alertpower")
    );

    var canvas = document.createElement("canvas");
    var ctx = canvas.getContext("2d");
    var DOMURL = window.self.URL || window.self.webkitURL || window.self;
    var img = new Image();
    var svg = new Blob([svgString], { type: "image/svg+xml;charset=utf-8" });
    var url = DOMURL.createObjectURL(svg);
    img.onload = function () {
      ctx.drawImage(img, 0, 0);
      var png = canvas.toDataURL("image/png");
      document.querySelector(
        "#png-container"
      ).innerHTML = `<img src='${png}'/>`;
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
    if (this.chartInit) {
      this.updateChart();
    }

    let formDisabled = this.props.editMode;

    return (
      <div className="dashboard">
        {!this.props.editMode && <h1>Alert Power</h1>}
        <form onSubmit={this.preventSubmit}>
          <label>
            Filter =&nbsp;
            <input
              className="report_input"
              type="text"
              style={{ background: "initial", border: "1px solid #ccc" }}
              name="chartFilter"
              value={this.state.chartFilter}
              onChange={this.dataChange}
              placeholder="All"
              disabled={formDisabled}
            />
          </label>
        </form>
        <form onSubmit={this.preventSubmit}>
          <label>
            Sort by =&nbsp;
            <select
              name="chartSort"
              value={this.state.chartSort}
              onChange={this.dataChange}
              disabled={formDisabled}
            >
              <option value="power">Power Score</option>
              <option value="count">Alert Count</option>
              <option value="promoted">Promoted Count</option>
              <option value="incident">Incident Count</option>
            </select>
            <select
              name="chartSortDir"
              value={this.state.chartSortDir}
              onChange={this.dataChange}
              disabled={formDisabled}
            >
              <option value="desc">Desc</option>
              <option value="asc">Asc</option>
            </select>
          </label>
          <label>
            Results =&nbsp;
            <input
              className="report_input"
              type="number"
              min={1}
              max={50}
              name="chartResults"
              value={this.state.chartResults}
              onChange={this.dataChange}
              disabled={formDisabled}
            />
          </label>
        </form>
        <form>
          <label>
            <input
              className="report_input"
              type="radio"
              name="mode"
              value="grouped"
              checked={this.state.displayMode === "grouped"}
              onChange={this.displayModeChange}
              disabled={formDisabled}
            />{" "}
            Grouped
          </label>
          &nbsp;
          <label>
            <input
              className="report_input"
              type="radio"
              name="mode"
              value="stacked"
              checked={this.state.displayMode === "stacked"}
              onChange={this.displayModeChange}
              disabled={formDisabled}
            />{" "}
            Stacked
          </label>
          <Button
            id="export"
            bsSize="xsmall"
            bsStyle="default"
            onClick={this.exportToPNG}
            disabled={formDisabled}
          >
            Export to PNG
          </Button>
        </form>
        <div id="chart">
          <svg id="report_alertpower" viewBox="0 0 1000 100" />
        </div>
        <div id="png-container" hidden />
      </div>
    );
  }
}

export default ReportAlertpower;
export const Description =
  "Chart of alerts in terms of how frequently they're promoted or become incidents";
