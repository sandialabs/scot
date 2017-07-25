import React, { PureComponent } from 'react';
import { Panel } from 'react-bootstrap';

import ReportHeatmap from './report_heatmap';
import ReportArt from './report_art';
// import ReportAlertPower from './report_alertpower';

const Report = ( props ) => (
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

export default Report;
