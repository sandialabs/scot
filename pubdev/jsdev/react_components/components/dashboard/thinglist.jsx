import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';

const SCOT_API = "/scot/api/v2/"

export default class ThingList extends PureComponent {
	constructor( props ) {
		super( props );

		this.state = {
			data: null,
		}
	}

	static propTypes = {
		thingType: PropTypes.string.isRequired,
		queryOptions: PropTypes.object,
		errorToggle: PropTypes.func,
	}

	static defaultProps = {
		queryOptions: {
			limit: 10,
			offset: 0,
			sort: {
				id: -1,
			},
		},
	}

	fetchData() {
		$.ajax( {
			type: 'get',
			url: SCOT_API + this.props.thingType,
		} ).then( ( data ) => {
			this.setState( {
				data: data.records,
			} );
		} ).catch( ( error ) => {
			this.props.errorToggle( "Failed to fetch data: "+ error );
		} );
	}

	componentDidMount() {
		this.fetchData();
	}

	render() {
		return (
			<pre></pre>
		)
	}
}
