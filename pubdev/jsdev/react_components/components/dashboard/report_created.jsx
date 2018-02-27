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


class ReportCreated extends Component {
    constructor( props ) {
        super( props );

        this.state = {
            chartData: [],
        };

        // LoadData is automatically debounced
        this.loadData = debounce( this.loadData );

        // this.dataChange = this.dataChange.bind( this );
        // this.displayModeChange = this.displayModeChange.bind( this );
    }

    initChart() {
        let now = new Date();

        this.xScale = d3.scaleTime()
            .rangeRound( [0, width] )
            .domain( [now - timeWindow, now] );
        this.yScale = d3.scaleLinear()
            .rangeRound( [height, 0] )
            .domain( [0, 0] );

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
            .attr( 'height', height );

        this.yAxisEl = this.svg.append( 'g' )
            .attr( 'class', 'y axis' );

        this.yAxisEl.call( this.yAxis );

        this.xAxisEl = this.svg.append( 'g' )
            .attr( 'class', 'x axis' )
            .attr( 'transform', `translate( 0, ${height} )` );

        this.xAxisEl.append( 'text' )
            .attr( 'text-anchor', 'middle' )
            .attr( 'x', width / 2 )
            .attr( 'y', margin.bottom - 10 )
            .style( 'font-size', '10px' )
            .style( 'fill', 'black' )
            .text( 'Toggle Trendlines' );

        this.xAxisEl.call( this.xAxis );

        this.statusLine = d3.line()
            .curve( d3.curveBasis )
            .x( d => this.xScale( d.time ) )
            .y( d => this.yScale( d.value ) );

        this.lineHolder = this.svg.append( 'g' )
            .attr( 'class', 'lines' )
            .attr( 'clip-path', 'url(#bounds)' );

        // Legend
        this.LegendHolder = this.svg.append( 'g' )
            .attr( 'class', 'legend-holder' )
            .style( 'font-family', 'sans-serif' );

        this.chartInit = true;
    }

    updateChart() {
        this.yScale.domain( [
            0,
            Math.max(
                d3.max( this.state.chartData, d => {
                    if ( !d.shown || !d.data.length ) return 0;

                    return d3.max( d.data, b => b.value );
                } )
                , 10 )
        ] ).nice();

        this.colors = d3.scaleOrdinal( d3.schemeCategory10 )
            .domain( this.state.chartData.map( line => {
                return line.name;
            } ) );

        let lines = this.lineHolder.selectAll( '.line' )
            .data( this.state.chartData, d => d.name );

        lines.exit()
            .transition()
            .style( 'opacity', 0 )
            .remove();

        lines.enter().append( 'path' )
            .attr( 'class', d => `line ${d.name}` )
            .style( 'stroke', d => this.colors( d.name ) )
            .style( 'stroke-width', 2 )
            .style( 'fill', 'none' )
            .attr( 'd', d => this.statusLine( d.data ) );

        this.LegendHolder.selectAll( '.legend' ).remove();

        let legend = this.LegendHolder.selectAll( '.legend' )
            .data( this.state.chartData, d => d.name );

        legend = legend.enter().append( 'g' )
            .attr( 'class', 'legend' )
            .style( 'cursor', 'pointer' )
            .on( 'click', d => {
                let newData = this.state.chartData.map( row => {
                    if ( row.name === d.name ) {
                        row.shown = !d.shown;
                    }
                    return row;
                } );
                this.setState( {
                    chartData: newData,
                } );
            } );

        // Legend Boxes
        legend.append( 'rect' )
            .attr( 'width', legendHeight )
            .attr( 'x', 0 )
            .attr( 'y', ( legendHeight - 5 ) / 2 )
            .attr( 'height', 5 )
            .style( 'fill', d => d.shown ? this.colors( d.name ) : 'transparent' )
            .style( 'stroke', d => this.colors( d.name ) )
            .style( 'stroke-width', 1 );

        // Legend Text
        legend.append( 'text' )
            .attr( 'x', legendHeight + legendTextSpacing )
            .attr( 'y', legendHeight / 2 )
            .attr( 'dy', '.35em' )
            .style( 'text-anchor', 'start' )
            .style( 'text-transform', 'capitalize' )
            .text( d => d.name )
            .append( 'title' )
            .text( d => `Toggle ${d.name} line` );

        // Legend Position
        let widthSums = 0;
        this.LegendHolder.selectAll( '.legend' )
            .attr( 'transform', function( d, i ) {
                let value = widthSums;
                widthSums += this.getBBox().width + legendSpacing;
                return `translate( ${value}, 0 )`;
            } );
        let legendWidth = this.LegendHolder.node().getBBox().width;
        this.LegendHolder.attr( 'transform', `translate( ${width / 2 - legendWidth / 2}, ${ height + margin.bottom - legendHeight * 2 } )` );

        // Animate changes
        this.yAxisEl.transition().call( this.yAxis );

        lines
            .transition()
            .attr( 'd', d => this.statusLine( d.data ) )
            .style( 'stroke', d => d.shown ? this.colors( d.name ) : 'transparent' );
    }

    loadData() {
        let url = '/scot/api/v2/metric/creation_bullet';
        let opts = '?range=7';

        d3.json( url+opts, dataset => {
            try {
                // Add line visibility to data
                dataset = dataset.map( line => {
                    line.shown = this.state.chartData.reduce( ( shown, d ) => {
                        return shown && ( d.name === line.name ? d.shown : true );
                    }, true );

                    return line;
                } );

                this.setState( {
                    chartData: dataset,
                } );
            } catch ( e ) {
                console.log( 'Malformed data' );
                console.log( dataset );
                console.log( 'Replacing with random data' );
				
                dataset = this.genData();

                // Add line visibility to data
                dataset = dataset.map( line => {
                    line.shown = this.state.chartData.reduce( ( shown, d ) => {
                        return shown && ( d.name === line.name ? d.shown : true );
                    }, true );

                    return line;
                } );

                this.setState( {
                    chartData: dataset,
                } );
            }
        } );
    }
	
    genData() {
        let dataTypes = [ 'alerts', 'alertgroups', 'events', 'incidents', 'entries', 'intel' ];
        let dataMaxes = {
            alerts: 5000,
            alertgroups: 500,
            entries: 100,
            events: 15,
            intel: 5,
            incidents: 5,
        };

        let now = new Date(),
            date = new Date( Date.now() - timeWindow );
        let lineData = [];
        dataTypes.forEach( d => {
            lineData.push( {
                name: d,
                data: [],
            } );
        } );
        for( ; date <= now; date = new Date( date.getTime() + 6 * 3600 * 1000 ) ) {
            lineData.forEach( line => {
                line.data.push( {
                    time: date,
                    value: Math.random() * dataMaxes[ line.name ],
                } );
            } );
        }

        return lineData;
    }


    componentDidMount() {
        this.initChart();
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
        let svgString = new XMLSerializer().serializeToString( document.querySelector( '#report_created' ) );

        let canvas = document.createElement( 'canvas' );
        let ctx = canvas.getContext( '2d' );
        let DOMURL = self.URL || self.webkitURL || self;
        let img = new Image();
        let svg = new Blob( [svgString], {type: 'image/svg+xml;charset=utf-8'} );
        let url = DOMURL.createObjectURL( svg );
        img.onload = function() {
            ctx.drawImage( img, 0, 0 );
            let png = canvas.toDataURL( 'image/png' );
            document.querySelector( '#png-container' ).innerHTML = `<img src='${png}'/>`;
            DOMURL.revokeObjectURL( png );
            let a = $( '<a>' )
                .attr( 'href', png )
                .attr( 'download', 'img.png' )
                .appendTo( 'body' );

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
                <h1>Items Created</h1>
                <form>
                    <Button id='export' bsSize='xsmall' bsStyle='default' onClick={this.exportToPNG}>Export to PNG</Button>
                </form>
                <div id='chart'>
                    <svg id='report_created' viewBox='0 0 1000 600' />
                </div>
                <div id='png-container' hidden></div>
            </div>
        );
    }
}

export default ReportCreated;
