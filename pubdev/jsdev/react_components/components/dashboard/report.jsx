var React           = require('react');
var Panel           = require('react-bootstrap/lib/Panel.js');
var Badge           = require('react-bootstrap/lib/Badge.js');
var ReportHeatmap   = require('./report_heatmap.jsx'); 

var Report = React.createClass({
    getInitialState: function() {
        return {
            ReportData: null
        }
    },
    componentDidMount: function() {
        
    },
    render: function() {
        return (
            <div id='stats' className="dashboard col-md-4">
                <div style={{textAlign:'center'}}>
                    <h2>Reports</h2>
                </div>
                <div>
                    <Panel header={'Report Heatmap'}>
                        <ReportHeatmap />
                    </Panel>
                </div>
            </div>
        );
    }
});

module.exports = Report;
