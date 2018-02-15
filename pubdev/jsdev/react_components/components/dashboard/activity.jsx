import React, { PureComponent, Component } from 'react';
import PropTypes from 'prop-types';

import { Well, Label, Badge } from 'react-bootstrap';

import Store from '../../activemq/store';
import { epochToTimeago, timeagoToEpoch } from '../../utils/time';

const REFRESH_RATE = 30 * 1000; // 30 seconds
const NOTIFICATION_LEVEL = {
	wall: "warning",
};
const ACTIVITY_TYPE = {
	USER: 0,
	NOTIFICATION: 1,
};

class Activity extends Component {
	constructor( props ) {
		super( props );

		this.state = {
			users: [],
			notifications: [],
		};

		this.updateUsers = this.updateUsers.bind(this);
		this.wallMessage = this.wallMessage.bind(this);
		this.fetchError = this.fetchError.bind(this);
	}

	static propTypes = {
	}

	componentDidMount() {
		this.refreshTimer = setInterval( this.updateUsers, REFRESH_RATE );
		this.updateUsers();

        Store.storeKey( 'wall' );
        Store.addChangeListener( this.wallMessage );
	}

	componentWillUnmount() {
		if ( this.refreshTimer ) {
			clearInterval( this.refreshTimer );
		}
	}

	updateUsers() {
        $.ajax({
            type: 'get',
            url: '/scot/api/v2/who',
			success: ( data ) => {
				this.setState( {
					users: data.records.map( user => {
						return {
							type: ACTIVITY_TYPE.USER,
							who: user.username,
							time: timeagoToEpoch( user.last_activity ),
						}
					} ),
				} );
			},
            error: this.fetchError,
        });
	}

	wallMessage() {
		let notifications = this.state.notifications;
		notifications.push( {
			type: ACTIVITY_TYPE.NOTIFICATION,
			time: activemqwhen,
			who: activemqwho,
			message: activemqmessage,
			level: NOTIFICATION_LEVEL.wall,
		} );

		this.setState( {
			notifications: notifications,
		} );
	}

	fetchError( error ) {
	}

	buildActivityItem( item, i ) {
		let badge = timeSince( epochToTimeago( item.time ) );
		let text = '';
		switch( item.type ) {
			default:
			case ACTIVITY_TYPE.USER:
				text = item.who;
				break;
			case ACTIVITY_TYPE.NOTIFICATION:
				text = `${item.who}: ${item.message}`;
				break;
		}

		return <ActivityItem key={i} badge={badge} style={item.level}>{text}</ActivityItem>
	}

	render() {
		let { className = "" } = this.props;
		let classes = [ "Activity", className ];

		let items = this.state.users.concat( this.state.notifications ).sort( ( a, b ) => {
			return b.time - a.time;
		} ).map( this.buildActivityItem );

		return (
			<Well bsSize='small' className={classes.join(' ')}>
				{items}
			</Well>
		)
	}
}

const ActivityItem = ( { children, badge = null, style = "default" } ) => (
	<div className="activity-item">
		<Label bsStyle={style}>
			{children}
			{ badge !== null &&
				<Badge>{badge}</Badge>
			}
		</Label>
	</div>
)

export default Activity;
