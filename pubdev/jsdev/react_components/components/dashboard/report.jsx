import React, { PureComponent } from 'react';
import { Panel } from 'react-bootstrap';

import ReportHeatmap from './report_heatmap';
import ReportArt from './report_art';
import ReportAlertpower from './report_alertpower';

const Report = ( { frontPage } ) => (
	<div id='report' className='dashboard' style={{height: 'calc( 100vh - 51px )', overflow: 'auto'}}>
		<div style={{textAlign:'center'}}>
			<h2>Reports</h2>
		</div>
		{ frontPage ? (
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
		) : (
			<div className='container-fluid'>
				<div className='col-md-6'>
					<Panel header='Heatmap'>
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
				</div>
			</div>
		) }
	</div>
)

export default Report;
