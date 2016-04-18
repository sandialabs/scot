var React                   = require('react');
var Modal                   = require('react-modal');
var Button                  = require('react-bootstrap/lib/Button');
var ButtonGroup             = require('react-bootstrap/lib/ButtonGroup');
var Tabs                    = require('react-bootstrap/lib/Tabs');
var Tab                     = require('react-bootstrap/lib/Tab');
var DataGrid                = require('react-datagrid');
var SelectedEntry           = require('../entry/selected_entry.jsx');

const customStyles = {
    content : {
        top     : '50%',
        left    : '50%',
        right   : 'auto',
        bottom  : 'auto',
        marginRight: '-50%',
        transform:  'translate(-50%, -50%)'
    }
}

var Flair = React.createClass({
    getInitialState: function() {
        return {
            entityData:null,
        }
    },
    componentDidMount: function () {
        this.sourceRequest = $.get('scot/api/v2/entity/' + this.props.entityid, function(result) {
            this.setState({entityData:result})
        }.bind(this));
    },
    render: function() {
        return (
            <div>
                <Modal
                    isOpen={true}
                    onRequestClose={this.props.flairToolbarToggle}
                    style={customStyles}>
                    <div className="modal-header">
                        <img src="/images/close_toolbar.png" className="close_toolbar" onClick={this.props.flairToolbarToggle} />
                        <h3 id="myModalLabel">Entity {this.state.entityData != null ? <EntityValue value={this.state.entityData.value} /> :null }</h3>
                    </div>
                    <div className="modal-body" style={{height: '75vh', overflowY:'auto',width:'800px'}}>
                        <EntityBody data={this.state.entityData} entityid={this.props.entityid}/> 
                    </div>
                    <div className="modal-footer">
                        <Button onClick={this.props.flairToolbarToggle}>Done</Button>
                    </div>
                </Modal>
            </div>
        )
    }
});

var EntityValue = React.createClass({
    render: function() {
        return (
            <div className='flair_header'>{this.props.value}</div>
        )
    }
});

var EntityOptions = React.createClass({
    render: function() {
        return (
            <ButtonGroup>
                <Button>Search Splunk</Button>
            </ButtonGroup>
        )
    }
});

var EntityBody = React.createClass({
    getInitialState: function() {
        return {
            loading:"Loading Entries",
            EntryData:null,
        }
    }, 
    render: function() {
        var type = 'entity';
        //Lazy Loading SelectedEntry as it is not actually loaded when placed at the top of the page due to the calling order. 
        var SelectedEntry = require('../entry/selected_entry.jsx');
        return (
            <Tabs defaultActiveKey={1}>
                <Tab eventKey={1} title="References"><EntityEventReferences entityid={this.props.entityid}/></Tab>
                <Tab eventKey={2} title="SIDD Data">SIDD Data Table</Tab>
                <Tab eventKey={3} title="Geo Location">Geo Location Table</Tab>
                <Tab eventKey={4} title="Entry"><SelectedEntry type={'entity'} id={this.props.entityid}/></Tab>
            </Tabs>
        )
    }
});

var EntityEventReferences = React.createClass({
    getInitialState: function() {
        return {
            entityDataAlertGroup:null,
            entityDataEvent:null,
            entityDataIncident:null, 
            defaultAlertGroupHeight:60,
            defaultEventHeight:60,
            defaultIncidentHeight:60,
            entityDataAlertGroupLoading:true,
            entityDataEventLoading:true,
            entityDataIncidentLoading:true,
        }
    },
    componentDidMount: function() {
        this.sourceRequest = $.get('scot/api/v2/entity/' + this.props.entityid + '/alert', function(result) {
            var result = result.records
            this.setState({entityDataAlertGroup:result,entityDataAlertGroupLoading:false})
            if (result[0] != undefined) {
                this.setState({defaultAlertGroupHeight:200})
            }
        }.bind(this));
        this.sourceRequest = $.get('scot/api/v2/entity/' + this.props.entityid + '/event', function(result) {
            var result = result.records
            this.setState({entityDataEvent:result,entityDataEventLoading:false})
            if (result[0] != undefined) {
                this.setState({defaultEventHeight:200})
            }
        }.bind(this));
        this.sourceRequest = $.get('scot/api/v2/entity/' + this.props.entityid + '/incident', function(result) {
            var result = result.records
            this.setState({entityDataIncident:result,entityDataIncidentLoading:false})
            if (result[0] != undefined) {
                this.setState({defaultIncidentHeight:200})
            }
        }.bind(this));
    },
    onAlertGroupSelectionChange: function(newSelectedId, data) {
        for (prop in newSelectedId) {
            window.location.assign('#/alertgroup/'+prop);
        }
    },
    onEventSelectionChange: function(newSelectedId, data) {
        for (prop in newSelectedId) {
            window.location.assign('#/event/'+prop);
        }
    },
    onIncidentSelectionChange: function(newSelectedId, data) {
        for (prop in newSelectedId) {
            window.location.assign('#/incident/'+prop);
        }
    },
    render: function() {
        var columns = [
            { name: 'id', width:100 },
            { name: 'subject' }
        ]
        var alertColumns = [
            { name: 'alertgroup', width:100},
            { name: 'subject' }
        ]
        return (
            <div>
                <h4>AlertGroups</h4>
                <DataGrid idProperty='alertgroup' dataSource={this.state.entityDataAlertGroup} columns={alertColumns} style={{height:this.state.defaultAlertGroupHeight}} onSelectionChange={this.onAlertGroupSelectionChange} selected={this.state.entityDataAlertGroup} emptyText={'No records'} loading={this.state.entityDataAlertGroupLoading} loadMaskOverHeader={false}/>
                <div style={{marginTop:'90px'}}>
                    <h4>Events</h4>
                    <DataGrid idProperty='id' dataSource={this.state.entityDataEvent} columns={columns} style={{height:this.state.defaultEventHeight}} onSelectionChange={this.onEventSelectionChange} selected={this.state.entityDataEvent} emptyText={'No records'} loading={this.state.entityDataEventLoading} loadMaskOverHeader={false}/>
                </div>
                <div style={{marginTop:'90px'}}>
                    <h4>Incidents</h4>
                    <DataGrid idProperty='id' dataSource={this.state.entityDataIncident} columns={columns} style={{height:this.state.defaultIncidentHeight}} onSelectionChange={this.onIncidentSelectionChange} selected={this.state.entityDataIncident} emptyText={'No records'} loading={this.state.entityDataIncidentLoading} loadMaskOverHeader={false}/>
                </div>
            </div>
        )
    }
});

module.exports = Flair;
