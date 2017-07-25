import React, { PureComponent } from 'react';
import { Button } from 'react-bootstrap';
import DateRangePicker from 'react-daterange-picker';

class ReportArt extends PureComponent {
	constructor( props ) {
		super( props );

		let today = ( new Date() ).toISOString().slice(0, 10); 
        this.state = {
			length: 7,
			date: today,
			unit: 'day',
        }

		this.unitChange = this.unitChange.bind( this );
		this.lengthChange = this.lengthChange.bind( this );
		this.dateChange = this.dateChange.bind( this );
    }

    componentDidMount() {
       this.loadArt(); 
    }

    componentDidUpdate() {
        this.loadArt();
    }

	loadArt() {
		const formatTickTime = d => { 
			const daySeconds = 3600 * 24;
			let days = Math.floor( d / daySeconds ),
				hours = Math.floor( d % daySeconds / 3600 ),
				minutes = Math.floor( d % 3600 / 60 ),
				seconds = Math.floor( d % 60 );

			if ( days ) {
				let output = days + 'd';

				if ( hours ) {
					output = output +' '+ hours +'h';
				}
				return output;
			}
			if ( hours ) {
				return hours +'h';
			}
			if ( minutes ) {
				return minutes +'m';
			}
			return seconds +'s';
		};

		const formatTime = d => {
			const daySeconds = 3600 * 24;
			let days = Math.floor( d / daySeconds ),
				hours = Math.floor( d % daySeconds / 3600 ),
				minutes = Math.floor( d % 3600 / 60 ),
				seconds = Math.floor( d % 60 );

			let output = seconds +'s';
			if ( minutes ) {
				output = minutes +'m '+ output;
			}
			if ( hours ) {
				output = hours +'h '+ output;
			}
			if ( days ) {
				output = days +'d '+ output;
			}
			return output;
		}

        let margin = { top: 20, right: 20, bottom: 60, left: 45 },
            width = 1000 - margin.left - margin.right,
            height = 500 - margin.top - margin.bottom,
			barColors = {
				'All': '#3b35a6',
				'Promoted': '#eebd31',
				'Incident': '#e63041',
			},
			lineColors = {
				'All Avg': '#264653',
				'Promoted Avg': '#0072bb',
				'Incident Avg': '#ee4043',
			};

        var svg = d3.select( '#report_art' ).select( 'g' );
		if ( svg.empty() ) {
			svg = d3.select( '#report_art' )
				.append( 'g' )
				.attr( 'transform', 'translate( ' + margin.left + ',' + margin.top + ' )' );
		}

        let url = '/scot/api/v2/metric/response_avg_last_x_days';
        let opts = `?days=${this.state.length}&targetdate=${this.state.date}&unit=${this.state.unit}`;
		d3.json( url+opts, data => {
			console.log( data );

			// Bar names
			let barNames = new Set();
			data.dates.forEach( d => {
				d.values.forEach( b => {
					barNames.add( b.name );
				} );
			} );

			// Line names
			let lineNames = new Set();
			data.lines.forEach( d => {
				lineNames.add( d.name );
			} );

			// Scales
			let maxValue = d3.max( data.dates, d => {
				return d3.max( d.values, b => b.value );
			} );

			let dateScale = d3.scaleBand()
				.padding( 0.1 )
				.rangeRound( [ 0, width ] )
				.domain( data.dates.map( d => d.date ) );
			let barScale = d3.scaleBand()
				.domain( Array.from( barNames ) )
				.rangeRound( [ 0, dateScale.bandwidth() ] );
			let yScale = d3.scaleLinear()
				.clamp( true )
				.range( [ height, 0 ] )
				.domain( [ 0, maxValue ] )
				.nice();

			// Axes
			var xAxis = d3.axisBottom()
				.scale( dateScale );

			var yAxis = d3.axisLeft()
				.scale( yScale )
				.ticks( 20 )
				.tickFormat( formatTickTime );

			svg.selectAll( '.axis' ).remove()

			svg.append( 'g' )
				.attr( 'class', 'x axis' )
				.attr( 'transform', `translate( 0, ${height} )` )
				.call( xAxis );

			svg.append( 'g' )
				.attr( 'class', 'y axis' )
				.call( yAxis )
				.append( 'text' )
					.attr( 'transform', 'rotate(-90)' )
					.attr( 'x', 0 - height / 2 )
					.attr( 'y', 0 )
					.attr( 'dy', '1em' )
					.style( 'text-anchor', 'start' )
					.style( 'fill', 'black' )
					.text( 'Response Time' );

			// Bars
			svg.selectAll( '.date' ).remove();
			let dates = svg.selectAll( '.date' )
				.data( data.dates )
				.enter().append( 'g' )
					.attr( 'class', 'date' )
					.attr( 'transform', d => `translate( ${dateScale( d.date )}, 0 )` );

			dates.selectAll( '.bar' )
				.data( d => d.values )
				.enter().append( 'rect' )
					.attr( 'class', 'bar' )
					.attr( 'width', barScale.bandwidth() )
					.attr( 'x', d => barScale( d.name ) )
					.attr( 'y', d => yScale( d.value ) )
					.attr( 'height', d => height - yScale( d.value ) )
					.style( 'fill', d => barColors[ d.name ] )
					.append( 'title' )
						.text( d => formatTime( d.value ) );


			// Avg Box
			svg.select( '.avg-holder' ).remove();
			svg.select( '.avg-holder-border' ).remove();
			let AvgHolder = svg.append( 'g' )
				.attr( 'class', 'avg-holder' );

			let averages = AvgHolder.selectAll( '.avg' )
				.data( data.lines )
				.enter().append( 'text' )
					.attr( 'class', 'avg' )
					.attr( 'transform', ( d, i ) => `translate( 0, ${i * 15} )` );

			averages.append( 'tspan' )
				.attr( 'x', 0 )
				.attr( 'font-weight', 'bold' )
				.text( d => `${d.name}:` );

			averages.append( 'tspan' )
				.attr( 'x', 100 )
				.text( d => formatTime( d.value ) );

			let AvgHolderBox = AvgHolder.node().getBBox();
			AvgHolder.attr( 'transform', `translate( ${width - AvgHolderBox.width}, 0 )` );

			const borderOffset = 2;
			let border = svg.append( 'rect' )
				.attr( 'fill', 'none' )
				.attr( 'stroke', 'black' )
				.attr( 'class', 'avg-holder-border' )
				.attr( 'x', AvgHolderBox.x - borderOffset )
				.attr( 'y', AvgHolderBox.y - borderOffset )
				.attr( 'width', AvgHolderBox.width + borderOffset * 2 )
				.attr( 'height', AvgHolderBox.height + borderOffset * 2 );
			border.node().transform.baseVal.initialize( AvgHolder.node().transform.baseVal.getItem(0) );

			// Legend
			const legendHeight = 20, legendSpacing = 15, legendTextSpacing = 5;
			svg.select( '.legend-holder' ).remove();
			let LegendHolder = svg.append( 'g' )
					.attr( 'class', 'legend-holder' );
			let legend = LegendHolder.selectAll( '.legend' )
				.data( Array.from( barNames ) )
				.enter().append( 'g' )
					.attr( 'class', 'legend' );

			// Legend Boxes
			legend.append( 'rect' )
				.attr( 'width', legendHeight )
				.attr( 'x', 0 )
				.attr( 'y', 0 )
				.attr( 'height', legendHeight )
				.style( 'fill', d => barColors[ d ] );

			// Legend Text
			legend.append( 'text' )
				.attr( 'x', legendHeight + legendTextSpacing )
				.attr( 'y', legendHeight / 2 )
				.attr( 'dy', '.35em' )
				.style( 'text-anchor', 'start' )
				.text( d => d );

			// Legend Position
			let widthSums = 0
			LegendHolder.selectAll( '.legend' )
				.attr( 'transform', function( d, i ) {
					let value = widthSums;
					widthSums += this.getBBox().width + legendSpacing;
					return `translate( ${value}, 0 )`;
				} );
			let legendWidth = LegendHolder.node().getBBox().width;
			LegendHolder.attr( 'transform', `translate( ${width / 2 - legendWidth / 2}, ${ height + margin.bottom/2 } )` );
		});
	}

    unitChange( event ) {
        this.setState({unit: event.target.value});
    }
	 
    lengthChange( event ) {
        this.setState({length: event.target.value});
    }

	dateChange( event ) {
		this.setState({date: event.target.value});
	}

    exportToPNG() {
        var svgString = new XMLSerializer().serializeToString( document.querySelector( '#report_art' ) );

        var canvas = document.createElement( 'canvas' );
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
                <h1>Alert Response Time</h1>
				<label htmlFor="date" style={{display: "inline-block", textAlign: "right"}}>Initial Date =&nbsp;
					<input
						type="date"
						value={this.state.date}
						onChange={this.dateChange}
						placeholder='yyyy-mm-dd'
						pattern='[0-9]{4}-[0-9]{2}-[0-9]{2}'
					/>
				</label>
                <label htmlFor="length" style={{display: "inline-block", textAlign:"right"}}>Length =&nbsp;
                    <input type="number" min="1" step="1" value={this.state.length} id="length" onChange={this.lengthChange} />
                </label>
                <label htmlFor="unit" style={{display: "inline-block", width: "240px", textAlign:"right"}}>Unit =&nbsp;
                    <select id="unit" value={this.state.unit} onChange={this.unitChange} disabled>
                        <option value='hour'>hourly</option>
                        <option value='day'>daily</option>
                        <option value='month'>monthly</option>
                        <option value='year'>yearly</option>
                    </select>
                </label>
                <Button id='export' bsSize='xsmall' bsStyle='default' onClick={this.exportToPNG}>Export to PNG</Button>
                <div id="chart">
					<svg id='report_art' viewBox='0 0 1000 500' />
                </div>
                <div id='png-container' hidden></div>
            </div>
        )
    }
}

export default ReportArt;
