import React, { PureComponent } from 'react';
import { Panel, Badge } from 'react-bootstrap';

class Status extends PureComponent {
	constructor( props ) {
		super( props );

		this.state = {
			statusData: {},
		};

		this.updateData = this.updateData.bind( this );
		this.fetchError = this.fetchError.bind( this );
	}

	componentDidMount() {
		$.ajax( {
			type: 'get',
			url: 'scot/api/v2/status',
			success: this.updateData,
			error: this.fetchError,
		} );
	}

	updateData( response ) {
		this.setState( {
			statusData: response,
		} );
	}

	fetchError( error ) {
		// Show error
	}

	render() {
		let { className = "" } = this.props;

		let services = [];
		for ( let service in this.state.statusData ) {
			services.push( <div key={service}>{service}</div> );
		}


		return (
			<div className={"Status "+ className}>
				{services}
			</div>
		)
	}
}

export default Status;
