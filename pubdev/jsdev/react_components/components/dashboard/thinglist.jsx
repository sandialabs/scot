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
		processData: PropTypes.func,
		errorToggle: PropTypes.func,
	}

	static defaultProps = {
		queryOptions: {
			limit: 10,
			offset: 0,
			sort: {
				id: -1,
			},
			columns: [],
		},
		processData: ( data ) => {
			return data.map( thing => {
				return {
					id: thing.id,
					subject: thing.subject,
				};
			} )
		},
	}

	fetchData() {
		let data = {...this.props.queryOptions}
		if ( data.sort ) {
			data.sort = JSON.stringify(data.sort);
		}

		$.ajax( {
			type: 'get',
			url: SCOT_API + this.props.thingType,
			data: data,
		} ).then(
			( data ) => {
				this.setState( {
					data: this.props.processData( data.records ),
				} );
			},
			( error ) => {
				this.props.errorToggle( "Failed to fetch data: "+ error );
			}
		);
	}

	componentDidMount() {
		this.fetchData();
	}

	render() {
		return (
			<pre>{JSON.stringify(this.state.data, 2)}</pre>
		)
	}
}
