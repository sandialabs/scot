import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';
import { Well } from 'react-bootstrap';

import Status from '../components/dashboard/status';
import Gamification from '../components/dashboard/gamification';
let Online = require( '../components/dashboard/online.jsx' );
import { ReportDashboard } from '../components/dashboard/report';

const dashboardReports = ReportDashboard();

class HomeDashboard extends PureComponent {
	constructor( props ) {
		super( props );

		this.state = {
		};
	}

	static propTypes = {
		loggedIn: PropTypes.bool.isRequired,
		sensitivity: PropTypes.string,
	}

	render() {
		/*
		return (
			<div className="homePageDisplay">
				<div className='col-md-4'>
					<img src='/images/scot-600h.png' style={{maxWidth:'350px',width:'100%',marginLeft:'auto', marginRight:'auto', display: 'block'}}/>
					<h1>Sandia Cyber Omni Tracker 3.5</h1>
					<h1>{this.state.sensitivity}</h1>
					{ this.props.loggedIn &&
						<Status errorToggle={this.errorToggle} />
					}
				</div>
				{ this.props.loggedIn && 
					<div>
						<Gamification errorToggle={this.errorToggle} />
						<Online errorToggle={this.errorToggle} />
						<ReportDashboard />
					</div>
				}
			</div>
		)
		*/
		return (
			<div className="homePageDisplay">
				{ this.props.loggedIn ? 
					<div className="home-grid">
						<div className="title-area">
							{ this.props.sensitivity && 
								<h2 className="sensitivity">{this.props.sensitivity}</h2>
							}
							<h3>Sandia Cyber Omni Tracker
								<br />
								3.5
							</h3>
						</div>
						<Status className="status-area" />
						<div className="game-area">
							<Gamification />
						</div>
						<Well bsSize="small" className="activity-area">
							Activity
						</Well>
						<div className="notifications-area">
							Notifications
						</div>
						{dashboardReports}
					</div>
					:
					<div className="home-grid loggedOut">
						<div className="title-area">
							<h1>Sandia Cyber Omni Tracker
								<br />
								3.5
							</h1>
						</div>
					</div>
				}
			</div>
		)
	}
}

export default HomeDashboard;
