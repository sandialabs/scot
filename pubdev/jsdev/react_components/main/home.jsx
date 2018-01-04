import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';
import { Well, Tabs, Tab } from 'react-bootstrap';

import { withUserConfig, UserConfigPropTypes, UserConfigKeys } from '../utils/userConfig';

import Status from '../components/dashboard/status';
import Gamification from '../components/dashboard/gamification';
let Online = require( '../components/dashboard/online.jsx' );
import { ReportDashboard } from '../components/dashboard/report';

const dashboardReports = ReportDashboard();

class HomeDashboard extends PureComponent {
	constructor( props ) {
		super( props );

		this.state = {};
	}

	static propTypes = {
		loggedIn: PropTypes.bool.isRequired,
		sensitivity: PropTypes.string,
		...UserConfigPropTypes,
	}

	defaultTab() {
		const tabLayout = (
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
		);
		return {
			title: 'Default',
			layout: tabLayout,
			mountOnEnter: false,
			unmountOnExit: false,
		}
	}

	newTab() {
		const newTabLayout = (
			<h1>New Dashboard</h1>
		)

		return {
			title: '+',
			layout: newTabLayout,
		}
	}

	buildTab( tabConfig ) {
		return {
			title: tabConfig,
			layout: (<p>{tabConfig}</p>),
		}
	}

	render() {
		if ( !this.props.loggedIn ) {
			return (
				<div className="homePageDisplay">
					<div className="home-grid loggedOut">
						<div className="title-area">
							<h1>Sandia Cyber Omni Tracker
								<br />
								3.5
							</h1>
						</div>
					</div>
				</div>
			)
		}

		const dashboardConfig = this.props.userConfig.config;
		const tabsConfig = dashboardConfig.tabs;
		
		let tabs = []
		tabs.push( this.defaultTab() );

		for ( let newTab in tabsConfig ) {
			tabs.push( this.buildTab( newTab ) );
		}

		tabs.push( this.newTab() );

		const builtTabs = tabs.map( (tab, i) => {
			let { title, layout, ...props } = tab;
			return <Tab eventKey={i} key={i} title={title} {...props}>{layout}</Tab>
		} );


		return (
			<div className="homePageDisplay">
				<Tabs defaultActiveKey={0} id="DashboardTabs" mountOnEnter unmountOnExit >
					{builtTabs}
				</Tabs>
			</div>
		)
	}
}

export default withUserConfig( UserConfigKeys.DASHBOARD ) (HomeDashboard);
