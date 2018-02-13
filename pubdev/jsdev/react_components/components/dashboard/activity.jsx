import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';

import { Well, Label, Badge } from 'react-bootstrap';

const REFRESH_RATE = 30 * 1000; // 30 seconds

class Activity extends PureComponent {
	constructor( props ) {
		super( props );

		this.state = {
			data: [],
		};

		this.updateData = this.updateData.bind(this);
		this.fetchError = this.fetchError.bind(this);
	}

	static propTypes = {
	}

	componentDidMount() {
		this.refreshTimer = setInterval( this.updateData, REFRESH_RATE );
		this.updateData();
	}

	componentWillUnmount() {
		if ( this.refreshTimer ) {
			clearInterval( this.refreshTimer );
		}
	}

	updateData() {
        $.ajax({
            type: 'get',
            url: '/scot/api/v2/who',
			success: ( data ) => {
				this.setState( {
					data: data.records,
				} );
			},
            error: this.fetchError,
        });
	}

	fetchError( error ) {
	}

	render() {
		let { className = "" } = this.props;
		let classes = [ "Activity", className ];

		let items = this.state.data.map( ( item, i ) => {
			return <ActivityItem key={i} badge={timeSince(item.last_activity)}>{item.username}</ActivityItem>
		} );

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
