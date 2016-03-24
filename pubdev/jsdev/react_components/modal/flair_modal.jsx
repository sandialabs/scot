var React                   = require('react');
var Modal                   = require('react-modal');
var Button                  = require('react-bootstrap/lib/Button');
var ButtonGroup             = require('react-bootstrap/lib/ButtonGroup');
var Tabs                    = require('react-bootstrap/lib/Tabs');
var Tab                     = require('react-bootstrap/lib/Tab');
var DataGrid                = require('react-datagrid');
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
                        <div><EntityOptions value={this.state.entityData} entityid={this.props.entityid} /></div>
                    </div>
                    <div className="modal-body" style={{height: 'auto', overflowY:'auto',width:'800px'}}>
                        <EntityBody data={this.state.entityData} entityid={this.props.entityid}/> 
                    </div>
                    <div className="modal-footer">
                        <button class="btn" onClick={this.props.flairToolbarToggle}>Done</button>
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
                <Button>Search SCOT</Button>
                <Button>Search Splunk</Button>
                <Button>Robtex Lookup<img style={{height:'15px'}} src='/images/warning.png'/></Button>
            </ButtonGroup>
        )
    }
});

var EntityBody = React.createClass({
    render: function() {
        return (
            <Tabs defaultActiveKey={1}>
                <Tab eventKey={1} title="References"><EntityEventReferences entityid={this.props.entityid}/></Tab>
                <Tab eventKey={2} title="SIDD Data">SIDD Data Table</Tab>
                <Tab eventKey={3} title="Geo Location">Geo Location Table</Tab>
                <Tab eventKey={4} title="Entry">Entries go here</Tab>
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
        }
    },
    componentDidMount: function() {
        this.sourceRequest = $.get('scot/api/v2/entity/' + this.props.entityid + '/alertgroup', function(result) {
            var result = result.records
            this.setState({entityDataAlertGroup:result})
        }.bind(this));
        this.sourceRequest = $.get('scot/api/v2/entity/' + this.props.entityid + '/event', function(result) {
            var result = result.records
            this.setState({entityDataEvent:result})
        }.bind(this));
        this.sourceRequest = $.get('scot/api/v2/entity/' + this.props.entityid + '/incident', function(result) {
            var result = result.records
            this.setState({entityDataIncident:result})
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
        return (
            <div>
                <h4>AlertGroups</h4>
                <DataGrid idProperty='id' dataSource={this.state.entityDataAlertGroup} columns={columns} style={{height:200}} onSelectionChange={this.onAlertGroupSelectionChange} selected={this.state.entityDataAlertGroup} emptyText={'No records'}/>
                <div style={{marginTop:'90px'}}>
                    <h4>Events</h4>
                    <DataGrid idProperty='id' dataSource={this.state.entityDataEvent} columns={columns} style={{height:250}} onSelectionChange={this.onEventSelectionChange} selected={this.state.entityDataEvent} emptyText={'No records'}/>
                </div>
                <div style={{marginTop:'90px'}}>
                    <h4>Incidents</h4>
                    <DataGrid idProperty='id' dataSource={this.state.entityDataIncident} columns={columns} style={{height:250}} onSelectionChange={this.onIncidentSelectionChange} selected={this.state.entityDataIncident} emptyText={'No records'}/>
                </div>
            </div>
        )
    }
});

module.exports = Flair;
