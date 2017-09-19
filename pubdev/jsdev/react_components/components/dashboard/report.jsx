import React, { PureComponent } from 'react';
import { Panel, Button } from 'react-bootstrap';

import ReportHeatmap from './report_heatmap';
import ReportArt from './report_art';
import ReportAlertpower from './report_alertpower';
import ReportCreated from './report_created';

const reportComponentByType = ( reportType ) => {
	switch( reportType ) {
		default:
		case 'heatmap':
			return <ReportHeatmap />
		case 'alertpower':
			return <ReportAlertpower />
		case 'art':
			return <ReportArt />
		case 'created':
			return <ReportCreated />
	}
}

const reportTitleByType = ( reportType ) => {
	switch( reportType ) {
		default:
		case 'heatmap':
			return "Heatmap";
		case 'alertpower':
			return "Alert Power";
		case 'art':
			return "Alert Response Time";
		case 'created':
			return "Items Created";
	}
}

const reportPanelHeader = ( title, expand = null, back = null ) => (
	<span>
		{title}
		{expand &&
			<Button bsSize="small" href={expand} style={{ float: 'right' }}>+</Button>
		}
	</span>
)

export const ReportDashboard = () => (
	<div id='report' className='dashboard'>
		<div style={{textAlign:'center'}}>
			<h2>Reports</h2>
		</div>
		<div id='heatmap' className="dashboard col-md-4">
			<div>
				<Panel header='Heatmap'>
					<ReportHeatmap />
				</Panel>
				<Panel header='Alert Response Time'>
					<ReportArt />
				</Panel>
			</div>
		</div>
	</div>
)

//<Panel header={reportPanelHeader( reportTitleByType( 'heatmap' ), '/heatmap' )}>

export const ReportPage = () => (
	<div id='report' className='dashboard' style={{height: 'calc( 100vh - 51px )', overflow: 'auto'}}>
		<div style={{textAlign:'center'}}>
			<h2>Reports</h2>
		</div>
		<div className='container-fluid'>
			<div className='col-md-6'>
				<Panel header="Heatmap">
					<ReportHeatmap />
				</Panel>
				<Panel header='Alert Power'>
					<ReportAlertpower />
				</Panel>
			</div>
			<div className='col-md-6'>
				<Panel header='Alert Response Time'>
					<ReportArt />
				</Panel>
				<Panel header='Items Created'>
					<ReportCreated />
				</Panel>
			</div>
		</div>
	</div>
)

export const SingleReport = ( { reportType = 'heatmap' } ) => (
	<div id='report' className='dashboard' style={{height: 'calc( 100vh - 51px )', overflow: 'auto'}}>
		<div className='container'>
			<Panel header={reportTitleByType( reportType )}>
				{reportComponentByType( reportType )}
			</Panel>
		</div>
	</div>
)
