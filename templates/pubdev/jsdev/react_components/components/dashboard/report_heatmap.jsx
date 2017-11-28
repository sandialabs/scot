import React, { PureComponent } from 'react';
import { Button } from 'react-bootstrap';

class ReportHeatmap extends PureComponent {
	constructor( props ) {
		super( props );

        this.state = {
            collection: 'event',
            type: 'created',
            year: '2017',
        }

		this.collectionChange = this.collectionChange.bind( this );
		this.yearChange = this.yearChange.bind( this );
    }

    componentDidMount() {
       this.loadHeatMap(); 
    }

    componentDidUpdate() {
        this.loadHeatMap();
    }

    loadHeatMap() {
		let margin = {
				top: 30,
				bottom: 30,
				left: 30,
				right: 0,
			},
			width = 1000 - ( margin.left - margin.right ),
			height = 300 - ( margin.top - margin.bottom ),
			gridSize = Math.floor( width / 24 ),
			legendElementWidth = gridSize * 1.5,
			buckets = 9,
			colors = [ '#ffffd9', '#edf8b1', '#c7e9b4', '#7fcdbb', '#41b6c4', '#1d91c0', '#225ea8', '#253494', '#081d58' ],
			days = [ 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su' ],
			times = [ '1a', '2a', '3a', '4a', '5a', '6a', '7a', '8a', '9a', '10a', '11a', '12a', '1p', '2p', '3p', '4p', '5p', '6p', '7p', '8p', '9p', '10p', '11p', '12p' ];
		
		let container = d3.select( '#report_heatmap' );
		let graph = container.select( 'g' );
		if ( graph.empty() ) {
			graph = container.append( 'g' )
				.attr( 'transform', 'translate( '+ margin.left +', '+ margin.top +' )' );
		}

		// Day Labels
		graph.selectAll( '.dayLabel' )
			.data( days )
			.enter().append( 'text' )
				.text( ( d ) => d )
				.attr( 'x', 0 )
				.attr( 'y', ( d, i ) => { return i * gridSize; } )
				.style( 'text-anchor', 'end' )
				.attr( 'transform', 'translate( -6, '+ gridSize / 1.5 +' )' )
				.attr( 'class', ( d, i ) => {
					return ( i >= 0 && i <= 4 ) ? 'dayLabel axis axis-worktime' : 'dayLabel axis';
				} );

		// Time Labels
		graph.selectAll( '.timeLabel' )
			.data( times )
			.enter().append( 'text' )
				.text( ( d ) => d )
				.attr( 'x', ( d, i ) => { return i * gridSize; } )
				.attr( 'y', 0 )
				.style( 'text-anchor', 'middle' )
				.attr( 'transform', 'translate( '+ gridSize / 2 +', -6 )' )
				.attr( 'class', ( d, i ) => {
					return ( i >= 7 && i <= 16 ) ? 'timeLabel axis axis-worktime' : 'timeLabel axis';
				} );

        var url = '/scot/api/v2/graph/dhheatmap?collection='+this.state.collection+'&type='+this.state.type+'&year='+this.state.year 
        d3.json(
            url,
            function(error, data) {
				/*
				container.selectAll( '.hour' ).remove();
				*/
				container.selectAll( '.legend' ).remove();
				container.selectAll( '.legend-text' ).remove();
				
				let colorScale = d3.scaleQuantile()
					.domain( [ 0, buckets - 1, d3.max( data, ( d ) => { return d.value } ) ] )
					.range( colors );

				// Cards
				let cards = graph.selectAll( '.hour' )
					.data( data, ( d ) => { return d.day +':'+ d.hour; } );
				cards.append( 'title' );
				cards.enter().append( 'rect' )
					.style( 'fill', colors[0] )
					.merge( cards )
					.attr( 'x', ( d ) => ( d.hour - 1 ) * gridSize )
					.attr( 'y', ( d ) => ( d.day - 1 ) * gridSize )
					.attr( 'rx', 4 )
					.attr( 'ry', 4 )
					.attr( 'class', 'hour' )
					.attr( 'width', gridSize )
					.attr( 'height', gridSize )
					.transition().duration( 1000 )
						.style( 'fill', ( d ) => { return colorScale( d.value ); } );
				cards.select( 'title' ).text( ( d ) => d.value );
				cards.exit().remove();

				// Legend
				var legend = graph.selectAll( '.legend' )
					.data( [0].concat( colorScale.quantiles() ), ( d ) => d );

				legend.enter()
					.append( 'rect' )
					.attr( 'class', 'legend' )
					.attr( 'x', (d, i) => ( legendElementWidth * i ) )
					.attr( 'y', height )
					.attr( 'width', legendElementWidth )
					.attr( 'height', gridSize / 2 )
					.style( 'fill', (d, i) => colors[i] )

				legend.enter().append( 'text' )
					.text( ( d ) => ( '≥ ' + Math.round( d ) ) )
					.attr( 'class', 'legend-text' )
					.attr( 'x', (d, i) => legendElementWidth * i )
					.attr( 'y', height + gridSize );
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
        var svgString = new XMLSerializer().serializeToString(document.querySelector( '#report_heatmap' ));

        var canvas = document.createElement("canvas");
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
        return (
            <div className="dashboard">
                <h1>Day of Week, Hour of Day Heatmap</h1>
                <label htmlFor="year" style={{display: "inline-block", width: "240px", textAlign:"right"}}>Year = <span id="year-value"></span>
                    <input className='report_input' type="number" min="2013" step="1" value={this.state.year} id="year" onChange={this.yearChange}/>
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
					<svg id='report_heatmap' viewBox='0 0 1000 380' />
                </div>
                <div id='png-container' hidden></div>
            </div>
        )
    }
}

export default ReportHeatmap;
