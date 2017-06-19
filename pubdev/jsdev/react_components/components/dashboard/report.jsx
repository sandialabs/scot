var React               = require('react');
var Panel               = require('react-bootstrap/lib/Panel.js');
var Badge               = require('react-bootstrap/lib/Badge.js');
var ReportHeatmap       = require('./report_heatmap.jsx'); 
//var ReportAlertPower    = require('./report_alertpower.jsx');

var Report = React.createClass({
    getInitialState: function() {
        return {
            ReportData: null
        }
    },
    render: function() {
        return (
            <div id='report' className='dashboard'>
                <div style={{textAlign:'center'}}>
                    <h2>Reports</h2>
                </div>
                <div id='heatmap' className="dashboard col-md-4">
                    <div>
                        <Panel header={'Heatmap'}>
                            <ReportHeatmap />
                        </Panel>
                        
                    </div>
                </div>
                {/*this.props.frontPage ? 
                    null
                :
                    <div id='alertpower' className='dashboard col-md-4'>
                        <div>
                            <Panel header={'Alert Power'}>
                                <ReportAlertPower />
                            </Panel>
                        </div>
                    </div>
                */}
            </div>
        );
    }
});

module.exports = Report;
