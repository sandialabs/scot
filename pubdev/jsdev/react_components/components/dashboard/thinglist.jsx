import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';
import { ListGroup, ListGroupItem } from 'react-bootstrap';
import { Link } from 'react-router-dom';

const SCOT_API = "/scot/api/v2/"

export default class ThingList extends PureComponent {
	constructor( props ) {
		super( props );

		this.state = {
			data: [],
		}
	}

	static propTypes = {
		thingType: PropTypes.string.isRequired,
		title: PropTypes.string.isRequired,
		queryOptions: PropTypes.object,
		processData: PropTypes.func,
		getSummary: PropTypes.func,
		errorToggle: PropTypes.func,
	}

	static defaultProps = {
		queryOptions: {
			limit: 5,
			offset: 0,
			sort: {
				id: -1,
			},
			columns: ['id', 'subject'],
		},
		processData: ( data ) => {
			return data;
		},
		getSummary: ( thing ) => {
			return thing.subject;
		},
	}

	fetchData() {
		let data = {...this.props.queryOptions}
		if ( data.sort ) {
			data.sort = JSON.stringify(data.sort);
		}

		$.ajaxSetup({ traditional: true });
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
		const things = this.state.data.map( ( thing, i ) => (
			<ThingItem key={i} dest={`${this.props.thingType}/${thing.id}`} summary={this.props.getSummary(thing)} />
		) );
		return (
			<div className="ThingList">
				<h1>{this.props.title}</h1>
				<ListGroup>
					{things}
				</ListGroup>
			</div>
		)
	}
}

const ThingItem = ( { dest, summary } ) => (
	<Link to={dest} className="list-group-item">{summary}</Link>
)
