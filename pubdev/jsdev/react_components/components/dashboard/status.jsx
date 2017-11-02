import React, { PureComponent } from 'react';
import { Panel, Badge } from 'react-bootstrap';

class Status extends PureComponent {
	constructor( props ) {
		super( props );

		this.state = {
			statusData: {},
			error: null,
		};

		this.updateData = this.updateData.bind( this );
		this.fetchError = this.fetchError.bind( this );
	}

	componentDidMount() {
		/*
		 * Expected structure:
		 * [
		 *		{ name: "SERVICE", status: "STATUS" },
		 *		...
		 * ]
		 *
		 * Service: name of service
		 * Status: [ "ok", "error", "unknown" ]
		 */
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
		this.setState( {
			error: error,
		} );
	}

	render() {
		let { className = "" } = this.props;

		let statuses = [ "ok", "error", "unknown" ];

		let services = [];
		for ( let service in this.state.statusData ) {
			let i = Math.floor( statuses.length * Math.random() );
			let status = statuses[i];
			services.push( <Service name={service} status={status} /> );
		}

		let classes = [ "Status", className ];
		if ( services.length > 4 ) {
			classes.push( 'cols-2' );
		}

		return (
			<div className={classes.join(' ')}>
				{ this.state.error &&
					<Panel bsStyle="danger" header="Error">{this.state.error}</Panel>
				}
				{services}
			</div>
		)
	}
}

const Service = ( { name, status } ) => (
	<div className={`service status-${status}`} key={name}>
		{name}
	</div>
)

export default Status;
