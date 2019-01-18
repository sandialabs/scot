import React, { PureComponent } from "react";
import { Button } from "react-bootstrap";
import * as d3 from "d3";
import debounce from "../../utils/debounce";
import $ from "jquery";

const formatTickTime = (domain, count = 10) => {
  let start = domain[0],
    end = domain[domain.length - 1],
    step = d3.tickStep(start, end, count);

  return d => {
    const daySeconds = 3600 * 24;
    let days = Math.floor(d / daySeconds),
      hours = Math.floor((d % daySeconds) / 3600),
      minutes = Math.floor((d % 3600) / 60),
      seconds = Math.floor(d % 60);

    if (days) {
      if (step < daySeconds) {
        return `${days}d ${hours}h`;
      }
      return days + "d";
    }
    if (hours) {
      if (step < 3600) {
        return `${hours}h ${minutes}m`;
      }
      return hours + "h";
    }
    if (minutes) {
      if (step < 60) {
        return `${minutes}m ${seconds}s`;
      }
      return minutes + "m";
    }
    return seconds + "s";
  };
};

const formatTime = d => {
  const daySeconds = 3600 * 24;
  let days = Math.floor(d / daySeconds),
    hours = Math.floor((d % daySeconds) / 3600),
    minutes = Math.floor((d % 3600) / 60),
    seconds = Math.floor(d % 60);

  let output = seconds + "s";
  if (minutes) {
    output = minutes + "m " + output;
  }
  if (hours) {
    output = hours + "h " + output;
  }
  if (days) {
    output = days + "d " + output;
  }
  return output;
};

let margin = { top: 20, right: 20, bottom: 60, left: 50 },
  width = 1000 - margin.left - margin.right,
  height = 500 - margin.top - margin.bottom,
  barColors = {
    All: "#3b35a6",
    Promoted: "#eebd31",
    Incident: "#e63041"
  };

class ReportArt extends PureComponent {
  constructor(props) {
    super(props);

    let today = new Date().toISOString().slice(0, 10);
    this.state = {
      length: 7,
      date: today,
      unit: "day",
      chartData: {
        dates: [],
        lines: []
      }
    };

    // Load Art is auto debounced
    this.loadArt = debounce(this.loadArt);

    this.unitChange = this.unitChange.bind(this);
    this.lengthChange = this.lengthChange.bind(this);
    this.dateChange = this.dateChange.bind(this);
  }

  componentDidMount() {
    this.initChart();
    this.loadArt();
  }

  componentDidUpdate() {}

  initChart() {
    this.svg = d3
      .select("#report_art")
      .append("g")
      .attr("transform", "translate( " + margin.left + "," + margin.top + " )");

    this.xAxisEl = this.svg
      .append("g")
      .attr("class", "x axis")
      .attr("transform", `translate( 0, ${height} )`);

    this.yAxisEl = this.svg.append("g").attr("class", "y axis");

    this.yAxisEl
      .append("text")
      .attr("transform", "rotate(-90)")
      .attr("x", 0 - height / 2)
      .attr("y", 0)
      .attr("dy", "1em")
      .style("text-anchor", "start")
      .style("fill", "black")
      .text("Response Time");

    this.chartInit = true;
  }

  updateChart() {
    // Bar names
    let barNames = new Set();
    this.state.chartData.dates.forEach(d => {
      d.values.forEach(b => {
        barNames.add(b.name);
      });
    });

    // Line names
    let lineNames = new Set();
    this.state.chartData.lines.forEach(d => {
      lineNames.add(d.name);
    });

    // Scales
    let maxValue = d3.max(this.state.chartData.dates, d => {
      return d3.max(d.values, b => b.value);
    });

    let dateScale = d3
      .scaleBand()
      .padding(0.1)
      .rangeRound([0, width])
      .domain(this.state.chartData.dates.map(d => d.date));
    let barScale = d3
      .scaleBand()
      .domain(Array.from(barNames))
      .rangeRound([0, dateScale.bandwidth()]);
    let yScale = d3
      .scaleLinear()
      .clamp(true)
      .range([height, 0])
      .domain([0, maxValue])
      .nice();

    // Axes
    var xAxis = d3.axisBottom().scale(dateScale);

    var yAxis = d3
      .axisLeft()
      .scale(yScale)
      .ticks(20)
      .tickFormat(formatTickTime(yScale.domain(), 20));

    this.xAxisEl.transition().call(xAxis);
    this.yAxisEl.transition().call(yAxis);

    // Bars
    let dates = this.svg
      .selectAll(".date")
      .data(this.state.chartData.dates, d => d.date);

    dates
      .exit()
      .transition()
      .style("opacity", 0)
      .attr("height", 0)
      .attr("y", height)
      .remove();

    let bars = dates
      .enter()
      .append("g")
      .attr("class", "date")
      .attr("transform", d => `translate( ${dateScale(d.date)}, 0 )`)
      .selectAll(".bar")
      .data(d => d.values)
      .enter()
      .append("rect")
      .attr("class", "bar")
      .style("fill", d => barColors[d.name])
      .attr("width", barScale.bandwidth())
      .attr("x", d => barScale(d.name))
      .attr("y", height)
      .attr("height", 0);

    bars.append("title").text(d => formatTime(d.value));

    dates
      .transition()
      .attr("transform", d => `translate( ${dateScale(d.date)}, 0 )`);

    this.svg
      .selectAll(".date")
      .selectAll(".bar")
      .transition()
      .attr("width", barScale.bandwidth())
      .attr("x", d => barScale(d.name))
      .attr("y", d => yScale(d.value))
      .attr("height", d => height - yScale(d.value));

    // Avg Box
    this.svg.select(".avg-holder").remove();
    this.svg.select(".avg-holder-border").remove();
    let AvgHolder = this.svg.append("g").attr("class", "avg-holder");

    let averages = AvgHolder.selectAll(".avg")
      .data(this.state.chartData.lines)
      .enter()
      .append("text")
      .attr("class", "avg")
      .attr("transform", (d, i) => `translate( 0, ${i * 15} )`);

    averages
      .append("tspan")
      .attr("x", 0)
      .attr("font-weight", "bold")
      .text(d => `${d.name}:`);

    averages
      .append("tspan")
      .attr("x", 100)
      .text(d => formatTime(d.value));

    let AvgHolderBox = AvgHolder.node().getBBox();
    AvgHolder.attr(
      "transform",
      `translate( ${width - AvgHolderBox.width}, 0 )`
    );

    const borderOffset = 2;
    let border = this.svg
      .append("rect")
      .attr("fill", "none")
      .attr("stroke", "black")
      .attr("class", "avg-holder-border")
      .attr("x", AvgHolderBox.x - borderOffset)
      .attr("y", AvgHolderBox.y - borderOffset)
      .attr("width", AvgHolderBox.width + borderOffset * 2)
      .attr("height", AvgHolderBox.height + borderOffset * 2);
    border
      .node()
      .transform.baseVal.initialize(
        AvgHolder.node().transform.baseVal.getItem(0)
      );

    // Legend
    const legendHeight = 20,
      legendSpacing = 15,
      legendTextSpacing = 5;
    this.svg.select(".legend-holder").remove();
    let LegendHolder = this.svg.append("g").attr("class", "legend-holder");
    let legend = LegendHolder.selectAll(".legend")
      .data(Array.from(barNames))
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
      .style("fill", d => barColors[d]);

    // Legend Text
    legend
      .append("text")
      .attr("x", legendHeight + legendTextSpacing)
      .attr("y", legendHeight / 2)
      .attr("dy", ".35em")
      .style("text-anchor", "start")
      .text(d => d);

    // Legend Position
    let widthSums = 0;
    LegendHolder.selectAll(".legend").attr("transform", function(d, i) {
      let value = widthSums;
      widthSums += this.getBBox().width + legendSpacing;
      return `translate( ${value}, 0 )`;
    });
    let legendWidth = LegendHolder.node().getBBox().width;
    LegendHolder.attr(
      "transform",
      `translate( ${width / 2 - legendWidth / 2}, ${height +
        margin.bottom / 2} )`
    );
  }

  loadArt() {
    if (!this.state.date || !this.state.length || this.props.editMode) {
      return;
    }

    let url = "/scot/api/v2/metric/response_avg_last_x_days";
    let opts = `?days=${this.state.length}&targetdate=${this.state.date}&unit=${
      this.state.unit
    }`;
    d3.json(url + opts, data => {
      this.setState({
        chartData: data
      });
    });
  }

  unitChange(event) {
    this.setState({ unit: event.target.value }, () => this.loadArt());
  }

  lengthChange(event) {
    this.setState({ length: event.target.value }, () => this.loadArt());
  }

  dateChange(event) {
    this.setState({ date: event.target.value }, () => this.loadArt());
  }

  exportToPNG() {
    var svgString = new XMLSerializer().serializeToString(
      document.querySelector("#report_art")
    );

    var canvas = document.createElement("canvas");
    var ctx = canvas.getContext("2d");
    var DOMURL = window.self.URL || window.self.webkitURL || window.self;
    var img = new Image();
    var svg = new Blob([svgString], { type: "image/svg+xml;charset=utf-8" });
    var url = DOMURL.createObjectURL(svg);
    img.onload = function() {
      ctx.drawImage(img, 0, 0);
      var png = canvas.toDataURL("image/png");
      document.querySelector("#png-container").innerHTML =
        '<img src="' + png + '"/>';
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
        {!this.props.editMode && <h1>Alert Response Time</h1>}
        <label
          htmlFor="date"
          style={{ display: "inline-block", textAlign: "right" }}
        >
          Initial Date =&nbsp;
          <input
            className="report_input"
            type="date"
            value={this.state.date}
            onChange={this.dateChange}
            placeholder="yyyy-mm-dd"
            pattern="[0-9]{4}-[0-9]{2}-[0-9]{2}"
            disabled={formDisabled}
          />
        </label>
        <label
          htmlFor="length"
          style={{ display: "inline-block", textAlign: "right" }}
        >
          Length =&nbsp;
          <input
            className="report_name"
            type="number"
            min="1"
            step="1"
            value={this.state.length}
            id="length"
            onChange={this.lengthChange}
            disabled={formDisabled}
          />
        </label>
        <label
          htmlFor="unit"
          style={{
            display: "inline-block",
            width: "240px",
            textAlign: "right"
          }}
        >
          Unit =&nbsp;
          <select
            id="unit"
            value={this.state.unit}
            onChange={this.unitChange}
            disabled
          >
            <option value="hour">hourly</option>
            <option value="day">daily</option>
            <option value="month">monthly</option>
            <option value="year">yearly</option>
          </select>
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
        <div id="chart">
          <svg id="report_art" viewBox="0 0 1000 500" />
        </div>
        <div id="png-container" hidden />
      </div>
    );
  }
}

export default ReportArt;
export const Description =
  "Chart of average alert, event, and incident response time";
