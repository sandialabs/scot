var React                   = require('react');
var Modal                   = require('react-modal');
var Button                  = require('react-bootstrap/lib/Button');
var ButtonGroup             = require('react-bootstrap/lib/ButtonGroup');
var Popover                 = require('react-bootstrap/lib/Popover');
var Tabs                    = require('react-bootstrap/lib/Tabs');
var Tab                     = require('react-bootstrap/lib/Tab');
var Inspector               = require('react-inspector');
var SelectedEntry           = require('../entry/selected_entry.jsx');
var AddEntryModal           = require('./add_entry.jsx');
var Draggable               = require('react-draggable');

const customStyles = {
    content : {
        top     : '50%',
        left    : '50%',
        right   : 'auto',
        bottom  : 'auto',
        marginRight: '-50%',
        transform:  'translate(-50%, -50%)',
        maxWidth: '40%',
        overflowY: 'hidden',
    }
}

var Flair = React.createClass({
    getInitialState: function() {
        return {
            entityData:null,
            entityid: this.props.entityid,
        }
    },
    componentDidMount: function () {
        if (this.props.entityid == undefined) {
            $.get('scot/api/v2/entity/'+this.props.entityvalue.toLowerCase(), function(result) {
                var entityid = result.id;
                this.setState({entityid:entityid});
                this.Request = $.get('scot/api/v2/entity/' + entityid, function(result) {
                    this.setState({entityData:result})
                }.bind(this));
            }.bind(this))} 
            else {
                this.Request = $.get('scot/api/v2/entity/' + this.state.entityid, function(result) {
                    this.setState({entityData:result})
            }.bind(this));
        } 
    },
    render: function() {
        /*return (
            <div>
                <Modal
                    isOpen={true}
                    onRequestClose={this.props.flairToolbarToggle}
                    style={customStyles}>
                    <div className="modal-header">
                        <img src="/images/close_toolbar.png" className="close_toolbar" onClick={this.props.flairToolbarToggle} />
                        <h3 id="myModalLabel">Entity {this.state.entityData != null ? <EntityValue value={this.state.entityData.value} /> : <div style={{display:'inline-flex',position:'relative'}}>Loading...</div> }</h3>
                    </div>
                    <div className="modal-body" style={{height: '80vh', overflowY:'auto',width:'800px'}}>
                        {this.state.entityData != null ? <EntityBody data={this.state.entityData} entityid={this.state.entityid} /> : <div>Loading...</div>} 
                    </div>
                    <div className="modal-footer">
                        <Button onClick={this.props.flairToolbarToggle}>Done</Button>
                    </div>
                </Modal>
            </div>
        )*/
        /*return (
            <Draggable>
                <div style={{width:'400px'}}>
                    <div>
                        <h3 id="myModalLabel">Entity {this.state.entityData != null ? <EntityValue value={this.state.entityData.value} /> : <div style={{display:'inline-flex',position:'relative'}}>Loading...</div> }</h3>
                    </div>
                    <div>
                        {this.state.entityData != null ? <EntityBody data={this.state.entityData} entityid={this.state.entityid} /> : <div>Loading...</div>}
                    </div>
                    <div>
                        <Button onClick={this.props.flairToolbarToggle}>Done</Button>
                    </div>
                </div>
            </Draggable>
        )*/
        return (
            <div>
                <Modal isOpen={true}
                    onRequestClose={this.props.flairToolbarToggle}
                    style={customStyles}> 
                    <div className="modal-body" style={{height:'80vh'}}>
                        <h3 id="myModalLabel">Entity {this.state.entityData != null ? <EntityValue value={this.state.entityData.value} /> : <div style={{display:'inline-flex',position:'relative'}}>Loading...</div> }</h3> 
                        {this.state.entityData != null ? <EntityBody data={this.state.entityData} entityid={this.state.entityid} type={this.props.type} id={this.props.id}/> : <div>Loading...</div>}
                    </div>
                </Modal>
            </div>
        )
    },
    
});

var EntityValue = React.createClass({
    render: function() {
        return (
            <div className='flair_header'>{this.props.value}</div>
        )
    }
});

var EntityBody = React.createClass({
    getInitialState: function() {
        return {
            loading:"Loading Entries",
            entryToolbar:false,
            appearances:0,
        }
    },
    updateAppearances: function(appearancesNumber) {
        if (appearancesNumber != null) {
            if (appearancesNumber != 0) {
                var newAppearancesNumber = this.state.appearances + appearancesNumber;
                this.setState({appearances:newAppearancesNumber});
            }
        }
    },
    entryToggle: function() {
        if (this.state.entryToolbar == false) {
            this.setState({entryToolbar:true})
        } else {
            this.setState({entryToolbar:false})
        }
    },
    render: function() {
        var entityEnrichmentDataArr = [];
        var entityEnrichmentLinkArr = [];
        var entityEnrichmentGeoArr = [];
        var enrichmentEventKey = 4;
        if (this.props.data != undefined) {
            var entityData = this.props.data['data'];
            for (var prop in entityData) {
                if (entityData[prop] != undefined) {
                    if (prop == 'geoip') {
                        entityEnrichmentGeoArr.push(<Tab eventKey={enrichmentEventKey} title={prop}><GeoView data={entityData[prop].data} type={this.props.type} id={this.props.id}/></Tab>);
                        enrichmentEventKey++;
                    } else if (entityData[prop].type == 'data') {
                        entityEnrichmentDataArr.push(<Tab eventKey={enrichmentEventKey} title={prop}><EntityEnrichmentButtons dataSource={entityData[prop]} /></Tab>);
                        enrichmentEventKey++;
                    } else if (entityData[prop].type == 'link') {
                        entityEnrichmentLinkArr.push(<Button target='_blank' href={entityData[prop].data.url}>{entityData[prop].data.title}</Button>)
                        enrichmentEventKey++;
                    }
                }
            }
        }
        //Lazy Loading SelectedEntry as it is not actually loaded when placed at the top of the page due to the calling order. 
        var SelectedEntry = require('../entry/selected_entry.jsx');
        return (
            <Tabs defaultActiveKey={1} bsStyle='pills'>
                <Tab eventKey={1} title={this.state.appearances}><br/>{entityEnrichmentLinkArr}<br/><br/><span><b>Appears: {this.state.appearances} times</b></span><br/><EntityReferences entityid={this.props.entityid} updateAppearances={this.updateAppearances}/></Tab>
                <Tab eventKey={2} title="Entry"><br/><Button onClick={this.entryToggle}>Add Entry</Button><br/>
                {this.state.entryToolbar ? <AddEntryModal title={'Add Entry'} type='entity' targetid={this.props.entityid} id={'add_entry'} addedentry={this.entryToggle} /> : null} <SelectedEntry type={'entity'} id={this.props.entityid}/></Tab>
                {entityEnrichmentGeoArr}
                {entityEnrichmentDataArr}
            </Tabs>
        )
    }
    
});

var GeoView = React.createClass({
    getInitialState: function() {
        return {
            copyToEntryToolbar: false
        }
    },
    copyToEntry: function() {
        if (this.state.copyToEntryToolbar == false) {
            this.setState({copyToEntryToolbar: true});
        } else {
            this.setState({copyToEntryToolbar: false})
        }
    },
    render: function() { 
        var trArr           = [];
        var copyArr         = [];
        copyArr.push('<table>');
        for (var prop in this.props.data) {
            var keyProp = prop;
            var value = this.props.data[prop];
            trArr.push(<tr><td style={{paddingRight:'4px', paddingLeft:'4px'}}><b>{prop}</b></td><td style={{paddingRight:'4px', paddingLeft:'4px'}}>{this.props.data[prop]}</td></tr>);
            copyArr.push('<tr><td style={{paddingRight:"4px", paddingLeft:"4px"}}><b>' + prop + '</b></td><td style={{paddingRight:"4px", paddingLeft:"4px"}}>' + value + '</td></tr>')
        }
        copyArr.push('</table>');
        var copy = copyArr.join('');
        return(
            <div className='entityTableWrapper'>
                <Button onClick={this.copyToEntry}>Copy to Entry</Button>
                {this.state.copyToEntryToolbar ? <AddEntryModal title='CopyToEntry' type={this.props.type} targetid={this.props.id} id={this.props.id} addedentry={this.copyToEntry} content={copy}/> : null}
                <table className="tablesorter entityTableHorizontal" id={'sortableentitytable'} width='100%'>
                    {trArr}    
                </table>
            </div>     
        )
    }
})

var EntityEnrichmentButtons = React.createClass({
    render: function() { 
        var dataSource = this.props.dataSource; 
        return (
            <Inspector.default table data={dataSource} expandLevel={4} />
        ) 
    },
});

var EntityReferences = React.createClass({
    getInitialState: function() {
        return {
            entityDataAlertGroup:null,
            entityDataEvent:null,
            entityDataIncident:null,
            entityDataIntel:null,
            entityDataAlertGroupLoading:true,
            entityDataEventLoading:true,
            entityDataIncidentLoading:true,
            entityDataIntelLoading:true,
            navigateType: '',
            navigateId: null,
            selected:{},
        }
    },
    componentDidMount: function() {
        this.alertRequest = $.get('scot/api/v2/entity/' + this.props.entityid + '/alert', function(result) {
            var result = result.records
            var arr = [];
            var arrPromoted = [];
            var arrClosed = [];
            var arrOpen = [];
            //this.setState({entityDataEvent:result,entityDataEventLoading:false})
            for(var i=0; i < result.length; i++) {
                if (result[i] != null) {
                    if (result[i].status == 'promoted'){
                        arrPromoted.push(<ReferencesBody type={'alert'} data={result[i]} index={i}/>)
                       //arrPromoted.push(<ReferencesBlankRow />)
                    } else if (result[i].status == 'closed') {
                        arrClosed.push(<ReferencesBody type={'alert'} data={result[i]} index={i}/>)
                        //arrClosed.push(<ReferencesBlankRow />)
                    } else {
                        arrOpen.push(<ReferencesBody type={'alert'} data={result[i]} index={i}/>)
                        //arrOpen.push(<ReferencesBlankRow />)
                    }
                }
            }
            arr.push(arrPromoted);
            arr.push(arrClosed);
            arr.push(arrOpen);
            this.props.updateAppearances(result.length);
            this.setState({entityDataAlertGroup:arr})
        }.bind(this));
        this.eventRequest = $.get('scot/api/v2/entity/' + this.props.entityid + '/event', function(result) {
            var result = result.records
            var arr = [];
            var arrPromoted = [];
            var arrClosed = [];
            var arrOpen = [];
            //this.setState({entityDataEvent:result,entityDataEventLoading:false})
            for(var i=0; i < result.length; i++) {
                if (result[i] != null) {
                    if (result[i].status == 'promoted'){
                        arrPromoted.push(<ReferencesBody type={'event'} data={result[i]} index={i}/>)
                        //arrPromoted.push(<ReferencesBlankRow />)
                    } else if (result[i].status == 'closed') {
                        arrClosed.push(<ReferencesBody type={'event'} data={result[i]} index={i}/>)
                        //arrClosed.push(<ReferencesBlankRow />)
                    } else {
                        arrOpen.push(<ReferencesBody type={'event'} data={result[i]} index={i}/>)
                        //arrOpen.push(<ReferencesBlankRow />)
                    }
                }
            }
            arr.push(arrPromoted);
            arr.push(arrClosed);
            arr.push(arrOpen);
            this.props.updateAppearances(result.length);
            this.setState({entityDataEvent:arr})
        }.bind(this));   
        this.incidentRequest = $.get('scot/api/v2/entity/' + this.props.entityid + '/incident', function(result) {
            var result = result.records
            var arr = [];
            var arrPromoted = [];
            var arrClosed = [];
            var arrOpen = [];
            //this.setState({entityDataEvent:result,entityDataEventLoading:false})
            for(var i=0; i < result.length; i++) {
                if (result[i] != null) {
                    if (result[i].status == 'promoted'){
                        arrPromoted.push(<ReferencesBody type={'incident'} data={result[i]} index={i}/>)
                       //arrPromoted.push(<ReferencesBlankRow />)
                    } else if (result[i].status == 'closed') {
                        arrClosed.push(<ReferencesBody type={'incident'} data={result[i]} index={i}/>)
                       //arrClosed.push(<ReferencesBlankRow />)
                    } else {
                        arrOpen.push(<ReferencesBody type={'incident'} data={result[i]} index={i}/>)
                        //arrOpen.push(<ReferencesBlankRow />)
                    }
                }
            }
            arr.push(arrPromoted);
            arr.push(arrClosed);
            arr.push(arrOpen);
            this.props.updateAppearances(result.length);
            this.setState({entityDataIncident:arr})
        }.bind(this));  
        this.intelRequest = $.get('scot/api/v2/entity/' + this.props.entityid + '/intel', function(result) {
            var result = result.records
            var arr = [];
            var arrPromoted = [];
            var arrClosed = [];
            var arrOpen = [];
            //this.setState({entityDataEvent:result,entityDataEventLoading:false})
            for(var i=0; i < result.length; i++) {
                if (result[i] != null) {
                    if (result[i].status == 'promoted'){
                        arrPromoted.push(<ReferencesBody type={'intel'} data={result[i]} index={i}/>)
                        //arrPromoted.push(<ReferencesBlankRow />)
                    } else if (result[i].status == 'closed') {
                        arrClosed.push(<ReferencesBody type={'intel'} data={result[i]} index={i}/>)
                        //arrClosed.push(<ReferencesBlankRow />)
                    } else {
                        arrOpen.push(<ReferencesBody type={'intel'} data={result[i]} index={i}/>)
                        //arrOpen.push(<ReferencesBlankRow />)
                    }
                }
            }
            arr.push(arrPromoted);
            arr.push(arrClosed);
            arr.push(arrOpen);
            this.props.updateAppearances(result.length);
            this.setState({entityDataIntel:arr})
        }.bind(this));   
        $('#sortableentitytable').tablesorter();
    },
    componentDidUpdate: function() {
        $('#sortableentitytable').tablesorter(); 
    },
    render: function() {
        return (
            <div className='entityTableWrapper'>
            <table className="tablesorter entityTableHorizontal" id={'sortableentitytable'} width='100%'>
                <thead>
                    <tr>
                        <th>peek</th>
                        <th>status</th>
                        <th>id</th>
                        <th>type</th>
                        <th>entries</th>
                        <th>subject</th>   
                    </tr>
                </thead>
                <tbody>
                    {this.state.entityDataIncident}
                    {this.state.entityDataEvent}
                    {this.state.entityDataAlertGroup}
                    {this.state.entityDataIntel}
                </tbody>
            </table>
            </div>
        ) 
    }
});

var ReferencesBody = React.createClass({
    getIntialState: function() {
        return{
            showSummary:false,
            summaryExists:true,
        }
    },
    onClick: function() {
        $.ajax({
            type: 'GET',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.data.id + '/entry', 
            success: function(result) {
                var entryResult = result.records;
                var summary = false;
                for (i=0; i < entryResult.length; i++) {
                    if (entryResult[i].summary == 1) {
                        summary = true;
                        this.setState({showSummary:true,summaryData:entryResult[i].body})
                        $('#entityTable' + this.props.data.id).qtip({ 
                            content: {text: $(entryResult[i].body)}, 
                            style: { classes: 'qtip-scot' }, 
                            hide: 'unfocus', 
                            position: { my: 'top right', at: 'left', target: $('#entityTable'+this.props.data.id)},//[position.left,position.top] }, 
                            show: { ready: true, event: 'click' } 
                        });
                        break;
                    }
                }
                if (summary == false) {
                    $('#entityTable' + this.props.data.id).qtip({
                        content: {text: 'No Summary Found'},
                        style: { classes: 'qtip-scot' },
                        hide: 'unfocus',
                        position: { my: 'top right', at: 'left', target: $('#entityTable'+this.props.data.id)},
                        show: { ready: true, event: 'click' }
                    });
                } 
            }.bind(this),
            error: function() {
                console.log('no summary found for: ' + this.props.type + ':' + this.props.data.id);
            }.bind(this)
        })
    },
    navigateTo: function() {
        if (this.props.type == 'alert') {
            window.open('#/event/'+this.props.data.promotion_id);
        } else if (this.props.type == 'event') {
            window.open('#/incident/'+this.props.data.promotion_id);
        }
    },
    render: function() {
        var id = this.props.data.id;
        var trId = 'entityTable' + this.props.data.id;
        var href = null;
        var statusColor = null
        if (this.props.data.status == 'promoted') {
            statusColor = 'orange';
        }else if (this.props.data.status =='closed') {
            statusColor = 'green';
        } else if (this.props.data.status == 'open') {
            statusColor = 'red';
        } else {
            statusColor = 'black';
        }
        if (this.props.type == 'alert') {
            href = '/#/alertgroup/' + this.props.data.alertgroup;
        } else {
            href = '/#/' + this.props.type + '/' + this.props.data.id;
        }
        return (
            <tr id={trId} index={this.props.index}>
                <td valign='top' style={{textAlign:'center',cursor: 'pointer'}} onClick={this.onClick}><i className="fa fa-eye fa-1" aria-hidden="true"></i></td>
                {this.props.data.status == 'promoted' ? <td valign='top' style={{paddingRight:'4px', paddingLeft:'4px'}}><Button bsSize='xsmall' bsStyle={'warning'} id={this.props.data.id} onClick={this.navigateTo} style={{lineHeight: '12pt', fontSize: '10pt', marginLeft: 'auto'}}>{this.props.data.status}</Button></td> : <td valign='top' style={{color: statusColor, paddingRight:'4px', paddingLeft:'4px'}}>{this.props.data.status}</td>}
                <td valign='top' style={{paddingRight:'4px', paddingLeft:'4px'}}><a href={href} target="_blank">{this.props.data.id}</a></td>
                <td valign='top' style={{paddingRight:'4px', paddingLeft:'4px'}}>{this.props.type}</td>
                <td valign='top' style={{paddingRight:'4px', paddingLeft:'4px', textAlign:'center'}}>{this.props.data.entry_count}</td>
                <td valign='top' style={{paddingRight:'4px', paddingLeft:'4px'}}>{this.props.data.subject}</td>
            </tr>
        )    
    }
})

var ReferencesBlankRow = React.createClass({
    render: function() {
        return (
            <tr className='not_selectable'>
                <td style={{padding:'0'}}>
                </td>
                    <td colSpan="50" style={{padding:'1px'}}>
                </td>
            </tr>
        )   
    }
});

module.exports = Flair;
