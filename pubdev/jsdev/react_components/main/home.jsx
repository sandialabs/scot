import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';
import { Well, Tab, Row, Col, Nav, NavItem } from 'react-bootstrap';

import { withUserConfig, UserConfigPropTypes, UserConfigKeys } from '../utils/userConfig';

import Dashboard, { defaultLayout } from '../components/dashboard/dazzle/dashboard';

import Status from '../components/dashboard/status';
import Gamification from '../components/dashboard/gamification';
import Activity from '../components/dashboard/activity';

import { Widgets } from '../components/dashboard/dazzle/widgets';


const NEWTABKEY = 'new';

class HomeDashboard extends PureComponent {
	constructor( props ) {
		super( props );

		this.state = {};

		this.switchTab = this.switchTab.bind(this);
		this.closeTab = this.closeTab.bind(this);
		this.saveTab = this.saveTab.bind(this);
	}

	static propTypes = {
		loggedIn: PropTypes.bool.isRequired,
		sensitivity: PropTypes.string,
		errorToggle: PropTypes.func,
		...UserConfigPropTypes,
	}

	defaultTab() {
		const layout = $.extend( true, {}, defaultLayout ); // Deep copy

		// Default tab has 3 charts: heatmap, ART, and created
		layout.rows[0].columns[0].widgets.push( {key: 'heatmap'} );
		layout.rows[0].columns[1].widgets.push( {key: 'art'} );
		layout.rows[0].columns[2].widgets.push( {key: 'created'} );

		return {
			title: 'Default',
			layout: <Dashboard
				widgets={Widgets}
				title="Default"
				layout={layout}
				errorToggle={this.props.errorToggle}
			/>
		}
	}

	newTab() {
		const dashboardConfig = this.props.userConfig.config;
		let tabs = [...dashboardConfig.tabs];
		tabs.push({});

		this.updateDashboardConfig( {
			curTab: tabs.length,
			tabs: tabs,
		} );
	}

	buildTab( tabConfig, index ) {
		let tabLayout = (
			<Dashboard
				widgets={Widgets}
				title={tabConfig.title}
				layout={tabConfig.layout}
				saveDashboard={(title, layout) => { this.saveTab( index, title, layout ) } }
				isNew={tabConfig.layout == null}
				errorToggle={this.props.errorToggle}
			/>
		)
		return {
			title: tabConfig.title,
			layout: tabLayout,
		}
	}

	saveTab( index, title, layout ) {
		const dashboardConfig = this.props.userConfig.config;
		let tabs = [...dashboardConfig.tabs];

		let newTabConfig = {
			title: title,
			layout: layout,
		}

		tabs[ index ] = newTabConfig;
		this.updateDashboardConfig( {
			tabs: tabs,
		} );
	}

	closeTab( index ) {
		if ( index < 1 ) {
			return;
		}

		const dashboardConfig = this.props.userConfig.config;
		let tabs = [...dashboardConfig.tabs];
		tabs.splice( index - 1, 1 );

		this.updateDashboardConfig( {
			curTab: index - 1,
			tabs: tabs,
		} );
	}

	switchTab( key ) {
		if ( key === this.props.userConfig.config.curTab ) {
			return;
		}
		if ( key === NEWTABKEY ) {
			this.newTab();
			return;
		}

		this.updateDashboardConfig({
			curTab: key,
		} );
	}

	updateDashboardConfig( newConfig ) {
		const dashboardConfig = this.props.userConfig.config;

		this.props.userConfig.setUserConfig( {
			...dashboardConfig,
			...newConfig,
		} );
	}

	render() {
		if ( !this.props.loggedIn || this.props.userConfig.loading ) {
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

		const dashboardHeader = (
			<div className="home-grid">
				<div className="title-area">
				</div>
				<Status className="status-area" />
				<div className="game-area">
					<Gamification />
				</div>
				<Activity className="activity-area" />
			</div>
		);

		const dashboardConfig = this.props.userConfig.config;
		const tabsConfig = dashboardConfig.tabs;
		
		let tabs = []
		tabs.push( this.defaultTab() );

		let index = 0;
		for ( let newTab of tabsConfig ) {
			tabs.push( this.buildTab( newTab, index++ ) );
		}

		let tabHeaders = tabs.map( (tab, i) => {
			let { title = 'New Dashboard', layout, ...props } = tab;
			return (
				<NavItem eventKey={i} key={i}>
					{title}
					{ i === dashboardConfig.curTab && i !== 0 &&
							<span onClick={() => this.closeTab(i)}>&nbsp;<i className="fa fa-times" style={{cursor: "pointer"}} /></span>
					}
				</NavItem>
			)
		} );

		tabHeaders.push( <NavItem eventKey={NEWTABKEY} key={NEWTABKEY}>+</NavItem> );

		const tabContent = tabs.map( (tab, i) => {
			let { title, layout, ...props } = tab;
			return <Tab.Pane eventKey={i} key={i} {...props}>{layout}</Tab.Pane>
		} );

		return (
			<div className="homePageDisplay">
				<Tab.Container id="DashboardTabs" activeKey={dashboardConfig.curTab} onSelect={this.switchTab}>
					<Row>
						<Col sm={12}>
							<Nav bsStyle='tabs'>
								{tabHeaders}
							</Nav>
						</Col>
						<Col sm={12}>
							<Tab.Content mountOnEnter unmountOnExit >
								{dashboardHeader}
								{tabContent}
							</Tab.Content>
						</Col>
					</Row>
				</Tab.Container>
			</div>
		)
	}
}

export default withUserConfig( UserConfigKeys.DASHBOARD ) (HomeDashboard);
