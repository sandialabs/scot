import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';
import { Well } from 'react-bootstrap';

let Status = require( '../components/dashboard/status.jsx' );
let Gamification = require( '../components/dashboard/gamification.jsx' );
let Online = require( '../components/dashboard/online.jsx' );
import { ReportDashboard } from '../components/dashboard/report';

class HomeDashboard extends PureComponent {
	constructor( props ) {
		super( props );

		this.state = {
		};
	}

	/* Current build tools can't handle this, but is preferred
	static propTypes = {
		loggedIn: PropTypes.bool.isRequired,
	}
	*/

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
						<div className="title">
							<h3>Sandia Cyber Omni Tracker
								<br />
								3.5
							</h3>
						</div>
						<div className="status">
							<Status />
						</div>
						<div className="game">
							<Gamification />
						</div>
						<Well bsSize="small" className="activity">
							Activity
						</Well>
						<div className="charts">
							Charts
						</div>
					</div>
					:
					<div className="home-grid loggedOut">
						<div className="title">
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

HomeDashboard.propTypes = {
	loggedIn: PropTypes.bool.isRequired,
}


export default HomeDashboard;
