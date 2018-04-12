import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';
import { ListGroup, ListGroupItem, Label } from 'react-bootstrap';
import { Link } from 'react-router-dom';

import LoadingContainer from '../../list/LoadingContainer';
import { todayRange, epochRangeToFilter, timeOlderThan } from '../../utils/time';

const NEW_TIME = 24 * 60 * 60; // 1 day
const isNew = ( created ) => {
	return !timeOlderThan( created * 1000, NEW_TIME );
}

const SCOT_API = "/scot/api/v2/"

export default class ThingList extends PureComponent {
	constructor( props ) {
		super( props );

		this.state = {
			data: [],
			loading: false,
		}
	}

	static propTypes = {
		thingType: PropTypes.string.isRequired,		// Type to query
		title: PropTypes.string.isRequired,			// Title of Widget
		queryOptions: PropTypes.object,				// Search query options (sort & filter)
		processData: PropTypes.func,				// Function to process data
		getSummary: PropTypes.func,					// Function to create a summary from data entry
		getLink: PropTypes.func,					// Funciton to create a link from data entry
		emptyString: PropTypes.string,				// String to show when no data returned
		emptyStyle: PropTypes.oneOf( [ 'success', 'info', 'warning', 'danger' ] ),	// Style of emptyString
		newBadge: PropTypes.bool,					// Display a badge if the data entry is newer than a day
		editMode: PropTypes.bool,					// Whether the dashboard is in edit mode
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
		getLink: ( thingType, thing ) => {
			return `${thingType}/${thing.id}`;
		},
		emptyString: 'No Data',
		emptyStyle: 'warning',
		newBadge: true,
	}

	fetchData() {
		this.setState( {
			loading: true,
		} );

		// Force deep copy
		let data = $.extend( true, {}, this.props.queryOptions );
		if ( data.sort ) {
			data.sort = JSON.stringify(data.sort);
		}

		if ( data.filter ) {
			data = {
				...data,
				...data.filter,
			}
			delete data.filter;
		}

		if ( this.props.newBadge ) {
			data.columns.push( 'created' );
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
					loading: false,
				} );
			},
			( error ) => {
				this.props.errorToggle( "Failed to fetch data: "+ error );
				this.setState( {
					loading: false,
				} );
			}
		);
	}

	componentDidMount() {
		if ( !this.props.editMode ) {
			this.fetchData();
		}
	}

	genThingItem( thing, i ) {
		// Using this instead of a subcomponent so I don't have to forward all the props
		return (
			<Link key={i} to={this.props.getLink(this.props.thingType, thing)} className="list-group-item">
				{ this.props.getSummary(thing) }
				{ this.props.newBadge && isNew( thing.created ) &&
						<Label bsStyle="primary">New!</Label>
				}
				<i className="fa fa-angle-right" />
			</Link>
		)
	}

	render() {
		let things = this.state.data.map( ( thing, i ) => this.genThingItem( thing, i ) );
		if ( this.props.editMode ) {
			things = [ 1, 2, 3, 4, 5 ].map( thing => <div className="list-group-item">{this.props.thingType} - {thing}</div> )
		} else if ( things.length === 0 ) {
			things = <div className={`list-group-item list-group-item-${this.props.emptyStyle}`}>{this.props.emptyString}</div>
		}

		return (
			<div className="ThingList">
				{ !this.props.editMode &&
					<h1>{this.props.title}</h1>
				}
				{ this.state.loading ?
					<LoadingContainer loading={true} />
					:
					<ListGroup>
						{things}
					</ListGroup>
				}
			</div>
		)
	}
}

/**
 * Hardcoded variants of Thinglist
 */
export const Widgets = () => {
	return {
		...RecentIntel,
		...RecentEvents,
		...RecentIncidents,
		...OpenTasks,
		...YourTasks,
		...UnviewedAlerts,
		...TopEvents,
	}
};

export const RecentIntel = {
	intel: {
		type: ThingList,
		title: "Recent Intel",
		description: "List of the 5 most recent Intel entries",
		props: {
			thingType: 'intel',
			title: 'Recent Intel',
		}
	},
};

export const RecentEvents = {
	events: {
		type: ThingList,
		title: "Recent Events",
		description: "List of the 5 most recent events",
		props: {
			thingType: 'event',
			title: 'Recent Events',
		}
	},
};

export const RecentIncidents = {
	incidents: {
		type: ThingList,
		title: "Recent Incidents",
		description: "List of the 5 most recent Incidents",
		props: {
			thingType: 'incident',
			title: 'Recent Incidents',
		}
	},
};

export const OpenTasks = {
	tasks: {
		type: ThingList,
		title: "Open Tasks",
		description: "List of recent open tasks",
		props: {
			thingType: 'task',
			title: 'Open Tasks',
			queryOptions: {
				limit: 5,
				offset: 0,
				sort: {
					updated: -1,
				},
				filter: {
					'metadata.task.status': 'open',
				},
				columns: ['id', 'body_plain', 'target'],
			},
			getSummary: ( thing ) => {
				return thing.body_plain.length > 200 ? thing.body_plain.substr(0, 200) +'...' : thing.body_plain;
			},
			getLink: ( thingType, thing ) => {
				let target = thing.target;
				return `${thingType}/${target.type}/${target.id}/${thing.id}`;
			},
			emptyString: 'None',
			emptyStyle: 'info',
		},
	},
}

export const YourTasks = {
	yourTasks: {
		type: ThingList,
		title: "Your Tasks",
		description: "List of open tasks that you own",
		props: {
			thingType: 'task',
			title: 'Your Tasks',
			queryOptions: {
				limit: 5,
				offset: 0,
				sort: {
					updated: 1,
				},
				filter: {
					'metadata.task.status': 'open',
					owner: getLocalStorage('whoami'),
				},
				columns: ['id', 'body_plain', 'target'],
			},
			getSummary: ( thing ) => {
				return thing.body_plain.length > 200 ? thing.body_plain.substr(0, 200) +'...' : thing.body_plain;
			},
			getLink: ( thingType, thing ) => {
				let target = thing.target;
				return `${thingType}/${target.type}/${target.id}/${thing.id}`;
			},
			emptyString: 'None!',
			emptyStyle: 'success',
		},
	},
}

export const UnviewedAlerts = {
	unviewedAlerts: {
		type: ThingList,
		title: "Unviewed Alerts",
		description: "Recent alerts with zero views",
		props: {
			thingType: 'alertgroup',
			title: 'Unviewed Alerts',
			queryOptions: {
				limit: 5,
				offset: 0,
				sort: {
					id: -1,
				},
				filter: {
					created: JSON.stringify(epochRangeToFilter( todayRange() )),
					views: 0,
				},
				columns: ['id', 'subject'],
			},
			newBadge: false,
			emptyString: 'None!',
			emptyStyle: 'success',
		},
	},
}

export const TopEvents = {
	topEvents: {
		type: ThingList,
		title: "Important Events",
		description: "Recent Events with open tasks",
		props: {
			thingType: 'event',
			title: 'Important Events',
			queryOptions: {
				limit: 5,
				offset: 0,
				sort: {
					has_tasks: 1,
				},
				filter: {
					created: JSON.stringify(epochRangeToFilter( todayRange() )),
				},
				columns: ['id', 'subject', 'has_tasks'],
			},
			processData: ( data ) => {
				return data.filter( ( thing ) => thing.has_tasks );
			},
			getSummary: ( thing ) => {
				return `${thing.subject} (${thing.has_tasks} open task${ thing.has_tasks > 1 ? '(s)' : ''})`;
			},
			newBadge: false,
			emptyString: 'None!',
			emptyStyle: 'success',
		},
	},
}
