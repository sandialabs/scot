var React                   = require('react');
var Button                  = require('react-bootstrap/lib/Button');
var ButtonGroup             = require('react-bootstrap/lib/ButtonGroup');
var Popover                 = require('react-bootstrap/lib/Popover');
var Tabs                    = require('react-bootstrap/lib/Tabs');
var Tab                     = require('react-bootstrap/lib/Tab');
var Inspector               = require('react-inspector');
var SelectedEntry           = require('../entry/selected_entry.jsx');
var AddEntryModal           = require('./add_entry.jsx');
var Draggable               = require('react-draggable');


var EntityDetail = React.createClass({
    getInitialState: function() {
        return {
            entityData:null,
            entityid: this.props.entityid,
        }
    },
    componentDidMount: function () {
        if (this.props.entityid == undefined) {
            $.ajax({
                type: 'GET',
                url: 'scot/api/v2/entity/'+this.props.entityvalue.toLowerCase()
            }).success(function(result) {
                var entityid = result.id;
                this.setState({entityid:entityid});
                $.ajax({
                    type: 'GET',
                    url: 'scot/api/v2/entity/' + entityid 
                }).success(function(result) {
                    this.setState({entityData:result})
                }.bind(this));
            }.bind(this))
        } else {
            $.ajax({
                type: 'GET',
                url: 'scot/api/v2/entity/' + this.state.entityid
            }).success(function(result) {
                this.setState({entityData:result})
            }.bind(this));
        }
        //Esc key closes popup
        function escHandler(event){
            //prevent from working when in input
            if ($('input').is(':focus')) {return};
            //check for esc with keyCode
            if (event.keyCode == 27) {
                this.props.flairToolbarToggle();
                event.preventDefault();
            }
        }
        $(document).keydown(escHandler.bind(this))
        //Resize function that acts as a resizer for Chrome because Chrome disallows resizing below the initial height and width- causes a lot of lag in the application so we're not using it for now.
        /*function resizableStart(e){
            this.originalW = this.clientWidth;
            this.originalH = this.clientHeight;
            this.onmousemove = resizableCheck;
            this.onmouseup = this.onmouseout = resizableEnd;
        }
        function resizableCheck(e){
            if(this.clientWidth !== this.originalW || this.clientHeight !== this.originalH) {
                this.originalX = e.clientX;
                this.originalY = e.clientY;
                this.onmousemove = resizableMove;
            }
        }
        function resizableMove(e){
            var newW = this.originalW + e.clientX - this.originalX,
                newH = this.originalH + e.clientY - this.originalY;
            if(newW < this.originalW){
                this.style.width = newW + 'px';
            }
            if(newH < this.originalH){
                this.style.height = newH + 'px';
            }
        }
        function resizableEnd(){
            this.onmousemove = this.onmouseout = this.onmouseup = null;
        }
        var els = document.getElementsByClassName('resizable');
        for(var i=0, len=els.length; i<len; ++i){
            els[i].onmouseover = resizableStart;
        }*/
    },
    componentWillUnmount: function() {
        //removes escHandler bind
        $(document).off('keydown')
        //This makes the size that was last used hold for future entities 
        /*var height = $('#dragme').height();
        var width = $('#dragme').width();
        entityPopUpHeight = height;
        entityPopUpWidth = width;*/
    },
    render: function() {
        var entityHeight = '500px';
        var entityWidth = '600px';
        //This makes the size that was last used hold for future entities
        /*if (entityPopUpHeight && entityPopUpWidth) {
            entityHeight = entityPopUpHeight;
            entityWidth = entityPopUpWidth;
        }*/
        return (
            <Draggable handle="#handle">
                <div id="dragme" className='box react-draggable entityPopUp resizable' style={{height:entityHeight,width:entityWidth}}> 
                    <div id="entity_detail_container" style={{height: '100%', flexFlow: 'column', display: 'flex'}}>
                        <div id='handle' style={{width:'100%',background:'#7A8092', color:'white', fontWeight:'900', fontSize: 'large', textAlign:'center', cursor:'move',flex: '0 1 auto'}}><div><span className='pull-left'><i className="fa fa-arrows" ariaHidden="true"/></span><span className='pull-right' style={{cursor:'pointer'}}><i className="fa fa-times" onClick={this.props.flairToolbarToggle}/></span></div></div>
                        <div style={{flex: '0 1 auto',marginLeft: '10px'}}>
                            <h3 id="myModalLabel">Entity {this.state.entityData != null ? <EntityValue value={this.state.entityData.value} /> : <div style={{display:'inline-flex',position:'relative'}}>Loading...</div> }</h3>
                        </div>
                        <div style={{overflow:'auto',flex:'1 1 auto', margin:'10px'}}>
                        {this.state.entityData != null ? <EntityBody data={this.state.entityData} entityid={this.state.entityid} type={this.props.type} id={this.props.id}/> : <div>Loading...</div>}
                        </div>
                        <div id='footer'>
                        </div>
                    </div>
                </div>
            </Draggable>
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
                        entityEnrichmentDataArr.push(<Tab eventKey={enrichmentEventKey} title={prop}><EntityEnrichmentButtons dataSource={entityData[prop]} type={this.props.type} id={this.props.id} /></Tab>);
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
        //PopOut available
        //var href = '/#/entity/' + this.props.entityid + '/' + this.props.type + '/' + this.props.id;
        return (
            <Tabs defaultActiveKey={1} bsStyle='pills'>
                <Tab eventKey={1} title={this.state.appearances}>{entityEnrichmentLinkArr}<span><br/><b>Appears: {this.state.appearances} times</b></span><br/><EntityReferences entityid={this.props.entityid} updateAppearances={this.updateAppearances}/><br/></Tab>
                <Tab eventKey={2} title="Entry"><Button onClick={this.entryToggle}>Add Entry</Button><br/>
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
            <div>
                <Button onClick={this.copyToEntry}>Copy to <b>{this.props.type} {this.props.id}</b> entry</Button>
                {this.state.copyToEntryToolbar ? <AddEntryModal title='CopyToEntry' type={this.props.type} targetid={this.props.id} id={this.props.id} addedentry={this.copyToEntry} content={copy}/> : null}
                <div className="entityTableWrapper">
                    <table className="tablesorter entityTableHorizontal" id={'sortableentitytable'} width='100%'>
                        {trArr}    
                    </table>
                </div>
            </div>     
        )
    }
})

var EntityEnrichmentButtons = React.createClass({
    render: function() { 
        var dataSource = this.props.dataSource; 
        return (
            <div style={{position:'relative'}}>
                <div style={{overflow:'auto',position:'absolute'}}> 
                    <Inspector.default data={dataSource} expandLevel={4} />
                </div>
            </div>
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
            for(var i=0; i < result.length; i++) {
                if (result[i] != null) {
                    if (result[i].status == 'promoted'){
                        arrPromoted.push(<ReferencesBody type={'alert'} data={result[i]} index={i}/>)
                    } else if (result[i].status == 'closed') {
                        arrClosed.push(<ReferencesBody type={'alert'} data={result[i]} index={i}/>)
                    } else {
                        arrOpen.push(<ReferencesBody type={'alert'} data={result[i]} index={i}/>)
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
            for(var i=0; i < result.length; i++) {
                if (result[i] != null) {
                    if (result[i].status == 'promoted'){
                        arrPromoted.push(<ReferencesBody type={'event'} data={result[i]} index={i}/>)
                    } else if (result[i].status == 'closed') {
                        arrClosed.push(<ReferencesBody type={'event'} data={result[i]} index={i}/>)
                    } else {
                        arrOpen.push(<ReferencesBody type={'event'} data={result[i]} index={i}/>)
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
            for(var i=0; i < result.length; i++) {
                if (result[i] != null) {
                    if (result[i].status == 'promoted'){
                        arrPromoted.push(<ReferencesBody type={'incident'} data={result[i]} index={i}/>)
                    } else if (result[i].status == 'closed') {
                        arrClosed.push(<ReferencesBody type={'incident'} data={result[i]} index={i}/>)
                    } else {
                        arrOpen.push(<ReferencesBody type={'incident'} data={result[i]} index={i}/>)
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
            for(var i=0; i < result.length; i++) {
                if (result[i] != null) {
                    if (result[i].status == 'promoted'){
                        arrPromoted.push(<ReferencesBody type={'intel'} data={result[i]} index={i}/>)
                    } else if (result[i].status == 'closed') {
                        arrClosed.push(<ReferencesBody type={'intel'} data={result[i]} index={i}/>)
                    } else {
                        arrOpen.push(<ReferencesBody type={'intel'} data={result[i]} index={i}/>)
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
                        this.setState({showSummary:true,summaryData:entryResult[i].body_flair})
                        $('#entityTable' + this.props.data.id).qtip({ 
                            content: {text: $(entryResult[i].body_flair)}, 
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
    render: function() {
        var id = this.props.data.id;
        var trId = 'entityTable' + this.props.data.id;
        var aHref = null;
        var promotedHref = null;
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
            aHref = '/#/alertgroup/' + this.props.data.alertgroup;
            promotedHref = '/#/event/' + this.props.data.promotion_id;
        } else if (this.props.type == 'event') {
            promotedHref = '/#/incident/' + this.props.data.promotion_id;
            aHref = '/#/' + this.props.type + '/' + this.props.data.id;
        }
        else {
            aHref = '/#/' + this.props.type + '/' + this.props.data.id;
        }
        return (
            <tr id={trId} index={this.props.index}>
                <td valign='top' style={{textAlign:'center',cursor: 'pointer'}} onClick={this.onClick}><i className="fa fa-eye fa-1" aria-hidden="true"></i></td>
                {this.props.data.status == 'promoted' ? <td valign='top' style={{paddingRight:'4px', paddingLeft:'4px'}}><Button bsSize='xsmall' bsStyle={'warning'} id={this.props.data.id} href={promotedHref} target="_blank" style={{lineHeight: '12pt', fontSize: '10pt', marginLeft: 'auto'}}>{this.props.data.status}</Button></td> : <td valign='top' style={{color: statusColor, paddingRight:'4px', paddingLeft:'4px'}}>{this.props.data.status}</td>}
                <td valign='top' style={{paddingRight:'4px', paddingLeft:'4px'}}><a href={aHref} target="_blank">{this.props.data.id}</a></td>
                <td valign='top' style={{paddingRight:'4px', paddingLeft:'4px'}}>{this.props.type}</td>
                <td valign='top' style={{paddingRight:'4px', paddingLeft:'4px', textAlign:'center'}}>{this.props.data.entry_count}</td>
                <td valign='top' style={{paddingRight:'4px', paddingLeft:'4px'}}>{this.props.data.subject}</td>
            </tr>
        )    
    }
})

module.exports = EntityDetail;
