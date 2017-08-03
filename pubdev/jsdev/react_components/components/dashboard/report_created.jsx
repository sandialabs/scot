import React, { Component } from 'react';
import { Button } from 'react-bootstrap';

import debounce from '../../utils/debounce';

const margin = {
		top: 5, left: 40, right: 20, bottom: 60,
	},
	width = 1000 - margin.left - margin.right,
	height = 600 - margin.top - margin.bottom,
	timeWindow = 7 * 24 * 3600 * 1000,
	legendHeight = 20, legendSpacing = 15, legendTextSpacing = 5;

let dataTypes = [ 'alerts', 'alertgroups', 'events', 'incidents', 'entries', 'intel' ];

class ReportCreated extends Component {
	constructor( props ) {
		super( props );

		let lineData = [];
		dataTypes.forEach( d => {
			lineData.push( {
				name: d,
				data: [],
				shown: true,
			} );
		} );

        this.state = {
			chartData: lineData,
        }

		// LoadData is automatically debounced
		this.loadData = debounce( this.loadData );

		// this.dataChange = this.dataChange.bind( this );
		// this.displayModeChange = this.displayModeChange.bind( this );
    }

	initChart() {
		let now = new Date();

		this.xScale = d3.scaleTime()
			.rangeRound( [0, width] )
			.domain( [now - timeWindow, now] )
		this.yScale = d3.scaleLinear()
			.rangeRound( [height, 0] )
			.domain( [0, 0] )

		this.colors = d3.scaleOrdinal( d3.schemeCategory10 )
			.domain( dataTypes )

		this.xAxis = d3.axisBottom()
			.scale( this.xScale );

		this.yAxis = d3.axisLeft()
			.scale( this.yScale );

		this.svg = d3.select( '#report_created' )
			.attr( 'viewBox', `0 0 1000 ${height + margin.top + margin.bottom}` )
			.append( 'g' )
				.attr( 'transform', `translate( ${margin.left}, ${margin.top} )` );

		let clip = this.svg.append( 'defs' ).append( 'clipPath' )
			.attr( 'id', 'bounds' )
			.append( 'rect' )
				.attr( 'id', 'clip-rect' )
				.attr( 'x', 1 )
				.attr( 'y', 0 )
				.attr( 'width', width )
				.attr( 'height', height )

		this.yAxisEl = this.svg.append( 'g' )
			.attr( 'class', 'y axis' )

		this.yAxisEl.call( this.yAxis )

		this.xAxisEl = this.svg.append( 'g' )
			.attr( 'class', 'x axis' )
			.attr( 'transform', `translate( 0, ${height} )` )

		this.xAxisEl.append( 'text' )
			.attr( 'text-anchor', 'middle' )
			.attr( 'x', width / 2 )
			.attr( 'y', margin.bottom - 10 )
			.style( 'font-size', '10px' )
			.style( 'fill', 'black' )
			.text( 'Toggle Trendlines' )

		this.xAxisEl.call( this.xAxis )

		this.statusLine = d3.line()
			.curve( d3.curveBasis )
			.x( d => this.xScale( d.time ) )
			.y( d => this.yScale( d.value ) );


		this.svg.append( 'g' )
			.attr( 'class', 'lines' )
			.attr( 'clip-path', 'url(#bounds)' )
			.selectAll( '.line' )
			.data( this.state.chartData, d => d.name )
			.enter().append( 'path' )
				.attr( 'class', d => `line ${d.name}` )
				.style( 'stroke', d => this.colors( d.name ) )
				.style( 'stroke-width', 2 )
				.style( 'fill', 'none' )
				.attr( 'd', d => this.statusLine( d.data ) )

		// Legend
		let LegendHolder = this.svg.append( 'g' )
			.attr( 'class', 'legend-holder' )
			.style( 'font-family', 'sans-serif' )

		let legend = LegendHolder.selectAll( '.legend' )
			.data( this.state.chartData )

		legend = legend.enter().append( 'g' )
			.attr( 'class', 'legend' )
			.style( 'cursor', 'pointer' )
			.on( 'click', d => {
				d.shown = !d.shown;
				this.setState( {
					chartData: this.state.chartData,
				} );
			} );

		// Legend Boxes
		legend.append( 'rect' )
			.attr( 'width', legendHeight )
			.attr( 'x', 0 )
			.attr( 'y', ( legendHeight - 5 ) / 2 )
			.attr( 'height', 5 )
			.style( 'fill', d => this.colors( d.name ) )
			.style( 'stroke', d => this.colors( d.name ) )
			.style( 'stroke-width', 1 )

		// Legend Text
		legend.append( 'text' )
			.attr( 'x', legendHeight + legendTextSpacing )
			.attr( 'y', legendHeight / 2 )
			.attr( 'dy', '.35em' )
			.style( 'text-anchor', 'start' )
			.style( 'text-transform', 'capitalize' )
			.text( d => d.name )
			.append( 'title' )
				.text( d => `Toggle ${d.name} line` )

		// Legend Position
		let widthSums = 0
		LegendHolder.selectAll( '.legend' )
			.attr( 'transform', function( d, i ) {
				let value = widthSums;
				widthSums += this.getBBox().width + legendSpacing;
				return `translate( ${value}, 0 )`;
			} );
		let legendWidth = LegendHolder.node().getBBox().width;
		LegendHolder.attr( 'transform', `translate( ${width / 2 - legendWidth / 2}, ${ height + margin.bottom - legendHeight * 2 } )` );

		this.chartInit = true;
	}

	updateChart( initial = false ) {
		if ( !initial ) {
			this.yScale.domain( [
				0,
				Math.max(
					d3.max( this.state.chartData, d => {
						if ( !d.shown || !d.data.length ) return 0;

						return d3.max( d.data, b => b.value );
					} )
				, 10 )
			] ).nice()
		}
		this.yAxisEl.transition().call( this.yAxis )

		this.svg.selectAll( '.legend rect' )
			.transition()
				.style( 'fill', d => d.shown ? this.colors( d.name ) : 'transparent' )

		this.svg.selectAll( '.line' )
			.transition()
				.attr( 'd', d => this.statusLine( d.data ) )
				.style( 'stroke', d => d.shown ? this.colors( d.name ) : 'transparent' )
	}

	loadData() {
		let url = '/scot/api/v2/metric/alert_power';
		let opts = `?`;

		/*
		d3.json( url+opts, dataset => {
			this.setState( {
				chartData: dataset,
			} )
		} );
		*/
		this.genData();
	}
	
	genData() {
		let dataMaxes = {
			alerts: 5000,
			alertgroups: 500,
			entries: 100,
			events: 15,
			intel: 5,
			incidents: 5,
		}

		let now = new Date(),
			date = new Date( Date.now() - timeWindow );
		let lineData = [ ...this.state.chartData ];
		for( ; date <= now; date = new Date( date.getTime() + 6 * 3600 * 1000 ) ) {
			lineData.forEach( line => {
				line.data.push( {
					time: date,
					value: Math.random() * dataMaxes[ line.name ],
				} );
			} );
		}

		this.setState( {
			chartData: lineData,
		} );
	}


    componentDidMount() {
		this.initChart();
		this.updateChart( true );
		this.loadData(); 
    }

	dataChange( event ) {
		let target = event.target;

		if( target.name === 'chartResults' && target.value ) {
			if ( target.value > 50 ) target.value = 50;
			if ( target.value < 1 ) target.value = 1;
		}

		this.setState( {
			[target.name]: target.value,
		}, this.loadData );
	}

    exportToPNG() {
        var svgString = new XMLSerializer().serializeToString( document.querySelector( '#report_created' ) );

        var canvas = document.createElement( 'canvas' );
        var ctx = canvas.getContext('2d');
        var DOMURL = self.URL || self.webkitURL || self;
        var img = new Image();
        var svg = new Blob([svgString], {type: 'image/svg+xml;charset=utf-8'});
        var url = DOMURL.createObjectURL(svg);
        img.onload = function() {
            ctx.drawImage(img, 0, 0);
            var png = canvas.toDataURL('image/png');
            document.querySelector('#png-container').innerHTML = `<img src='${png}'/>`;
            DOMURL.revokeObjectURL(png);
            var a = $('<a>')
            .attr('href', png)
            .attr('download', 'img.png')
            .appendTo('body');

            a[0].click();

            a.remove();
        };
        img.src = url;
    }

    render() {
		if ( this.chartInit ) {
			this.updateChart();
		}

        return (
            <div className='dashboard'>
                <h1>Created</h1>
				<form>
					<Button id='export' bsSize='xsmall' bsStyle='default' onClick={this.exportToPNG}>Export to PNG</Button>
				</form>
                <div id='chart'>
					<svg id='report_created' viewBox='0 0 1000 600' />
                </div>
                <div id='png-container' hidden></div>
            </div>
        )
    }
}

export default ReportCreated;
