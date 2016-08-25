var React                   = require('react');
var Button                  = require('react-bootstrap/lib/Button');
var ButtonGroup             = require('react-bootstrap/lib/ButtonGroup');
var Popover                 = require('react-bootstrap/lib/Popover');
var Tabs                    = require('react-bootstrap/lib/Tabs');
var Tab                     = require('react-bootstrap/lib/Tab');
var Inspector               = require('react-inspector');
var SelectedEntry           = require('../entry/selected_entry.jsx');
var AddEntry                = require('../components/add_entry.jsx');
var Draggable               = require('react-draggable');


var EntityDetail = React.createClass({
    getInitialState: function() {
        var tabs = [];
        return {
            entityData:null,
            entityid: this.props.entityid,
            entityHeight: '500px',
            entityWidth: '500px',
            tabs: tabs,
            initialLoad:false,
        }
    },
    componentDidMount: function () {
        var currentTabArray = this.state.tabs;
        if (this.props.entityid == undefined) {
            $.ajax({
                type: 'GET',
                url: 'scot/api/v2/' + this.props.entitytype + '/' +this.props.entityvalue.toLowerCase()
            }).success(function(result) {
                var entityid = result.id;
                this.setState({entityid:entityid});
                $.ajax({
                    type: 'GET',
                    url: 'scot/api/v2/' + this.props.entitytype + '/' + entityid 
                }).success(function(result) {
                    //this.setState({entityData:result})
                    var newTab = {data:result, entityid:entityid, entitytype:this.props.entitytype}
                    currentTabArray.push(newTab);
                    this.setState({tabs:currentTabArray,currentKey:entityid,initialLoad:true});
                }.bind(this));
            }.bind(this))
        } else {
            $.ajax({
                type: 'GET',
                url: 'scot/api/v2/' + this.props.entitytype + '/' + this.state.entityid
            }).success(function(result) {
                //this.setState({entityData:result})
                var newTab = {data:result, entityid:result.id, entitytype:this.props.entitytype}
                currentTabArray.push(newTab);
                this.setState({tabs:currentTabArray,currentKey:result.id,initialLoad:true});
            }.bind(this));
        }
        //Esc key closes popup
        function escHandler(event){
            //prevent from working when in input
            if ($('input').is(':focus')) {return};
            //check for esc with keyCode
            if (event.keyCode == 27) {
                this.props.flairToolbarOff();
                event.preventDefault();
            }
        }
        $(document).keydown(escHandler.bind(this))
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
    componentWillReceiveProps: function(nextProps) {
        var checkForInitialLoadComplete = {
            checkForInitialLoadComplete: function() {
                if (this.state.initialLoad == false) {
                    setTimeout(checkForInitialLoadComplete.checkForInitialLoadComplete,50);
                } else {
                    if (nextProps != undefined) {
                        //TODO Fix next conditional for undefined that prevents multiple calls for the same ID at load time on a nested entity
                        if (nextProps.entitytype != null && (nextProps.entityid != undefined)) {
                            for (var i=0; i < this.state.tabs.length; i++) {
                                if (nextProps.entityid == this.state.tabs[i].entityid || (this.state.tabs[i].entitytype == 'guide' && nextProps.entitytype == 'guide')) {
                                    this.setState({currentKey:nextProps.entityid})
                                    return    
                                }
                            }
                            var currentTabArray = this.state.tabs;
                            if (nextProps.entityid == undefined) {
                                $.ajax({
                                    type: 'GET',
                                    url: 'scot/api/v2/' + nextProps.entitytype + '/' + nextProps.entityvalue.toLowerCase()
                                }).success(function(result) {
                                    var entityid = result.id;
                                    this.setState({entityid:entityid});
                                    $.ajax({
                                        type: 'GET',
                                        url: 'scot/api/v2/' + nextProps.entitytype + '/' + entityid
                                    }).success(function(result) {
                                        var newTab = {data:result, entityid:entityid, entitytype:nextProps.entitytype}
                                        currentTabArray.push(newTab);
                                        this.setState({tabs:currentTabArray,currentKey:nextProps.entityid})
                                    }.bind(this));
                                }.bind(this))
                            } else {
                                $.ajax({
                                    type: 'GET',
                                    url: 'scot/api/v2/' + nextProps.entitytype + '/' + nextProps.entityid
                                }).success(function(result) {
                                    var newTab = {data:result, entityid:nextProps.entityid, entitytype:nextProps.entitytype}
                                    currentTabArray.push(newTab);
                                    this.setState({tabs:currentTabArray,currentKey:nextProps.entityid})
                                }.bind(this));
                            } 
                        }       
                    }
                }
            }.bind(this)
        }
        checkForInitialLoadComplete.checkForInitialLoadComplete();
    },
    initDrag: function(e) {
        var elem = document.getElementById('dragme');
        startX = e.clientX;
        startY = e.clientY;
        startWidth = parseInt(document.defaultView.getComputedStyle(elem).width, 10);
        startHeight = parseInt(document.defaultView.getComputedStyle(elem).height, 10);
        document.documentElement.addEventListener('mousemove', this.doDrag, false);
        document.documentElement.addEventListener('mouseup', this.stopDrag, false);
        this.blockiFrameMouseEvent();
    },
    doDrag: function(e) {
        var elem = document.getElementById('dragme')
        elem.style.width = (startWidth + e.clientX - startX) + 'px';
        elem.style.height = (startHeight + e.clientY - startY) + 'px';
    },
    stopDrag: function(e) {
        document.documentElement.removeEventListener('mousemove', this.doDrag, false);    document.documentElement.removeEventListener('mouseup', this.stopDrag, false);
        this.allowiFrameMouseEvent();
    },
    moveDivInit: function(e) {
        document.documentElement.addEventListener('mouseup', this.moveDivStop,false);
        this.blockiFrameMouseEvent();
    },
    moveDivStop: function(e) {
        document.documentElement.removeEventListener('mouseup', this.moveDivStop, false);
        this.allowiFrameMouseEvent();
    },
    blockiFrameMouseEvent: function() {
        $('iframe').each(function(index,ifr){
            $(ifr).addClass('pointerEventsOff')
        }) 
    },
    allowiFrameMouseEvent: function() {
        $('iframe').each(function(index,ifr){
            $(ifr).removeClass('pointerEventsOff')
        })
    },
    handleSelectTab(key) {
        this.setState({currentKey:key});
    },
    render: function() {
        //This makes the size that was last used hold for future entities
        /*if (entityPopUpHeight && entityPopUpWidth) {
            entityHeight = entityPopUpHeight;
            entityWidth = entityPopUpWidth;
        }*/
        var tabsArr = [];
        for (var i=0; i < this.state.tabs.length; i++) {
            var z = i+1;
            var title = 'tab';
            if (this.state.tabs[i].entitytype == 'guide') {
                title = 'guide'
            } else {
                title = this.state.tabs[i].data.value.slice(0,8);
            }
            tabsArr.push(<Tab className='tab-content' eventKey={this.state.tabs[i].entityid} title={title}><TabContents data={this.state.tabs[i].data} type={this.props.type} id={this.props.id} entityid={this.state.tabs[i].entityid} entitytype={this.state.tabs[i].entitytype} i={z} key={z}/></Tab>)
        }
        return (
            <Draggable handle="#handle" onMouseDown={this.moveDivInit}>
                <div id="dragme" className='box react-draggable entityPopUp' style={{height:this.state.entityHeight,width:this.state.entityWidth, display:'flex', flexFlow:'column'}}>
                    <div id='popup-flex-container' style={{height: '100%', display:'flex', flexFlow:'row'}}>
                        <div id="entity_detail_container" style={{height: '100%', flexFlow: 'column', display: 'flex', width:'100%'}}>
                            <div id='handle' style={{width:'100%',background:'#292929', color:'white', fontWeight:'900', fontSize: 'large', textAlign:'center', cursor:'move',flex: '0 1 auto'}}><div><span className='pull-left' style={{paddingLeft:'5px'}}><i className="fa fa-arrows" ariaHidden="true"/></span><span className='pull-right' style={{cursor:'pointer',paddingRight:'5px'}}><i className="fa fa-times" onClick={this.props.flairToolbarOff}/></span></div></div>
                            <Tabs className='tab-content' defaultActiveKey={this.props.entityid} activeKey={this.state.currentKey} onSelect={this.handleSelectTab} bsStyle='pills'>
                                {tabsArr}                     
                            </Tabs>
                        </div>
                        <div id='sidebar' onMouseDown={this.initDrag} style={{flex:'0 1 auto', height: '100%', backgroundColor: 'black', borderTop: '2px solid black', borderBottom: '2px solid black', cursor: 'nwse-resize', overflow: 'hidden', width:'5px'}}/>
                    </div>
                    <div id='footer' onMouseDown={this.initDrag} style={{display: 'block', height: '5px', backgroundColor: 'black', borderTop: '2px solid black', borderBottom: '2px solid black', cursor: 'nwse-resize', overflow: 'hidden'}}>
                    </div>
                </div>
            </Draggable>  
        )
        /*if (this.props.entitytype == 'entity') {
            return (
                <Draggable handle="#handle" onMouseDown={this.moveDivInit}>
                    <div id="dragme" className='box react-draggable entityPopUp' style={{height:this.state.entityHeight,width:this.state.entityWidth}}> 
                        <div id="entity_detail_container" style={{height: '100%', flexFlow: 'column', display: 'flex'}}>
                            <div id='handle' style={{width:'100%',background:'#292929', color:'white', fontWeight:'900', fontSize: 'large', textAlign:'center', cursor:'move',flex: '0 1 auto'}}><div><span className='pull-left' style={{paddingLeft:'5px'}}><i className="fa fa-arrows" ariaHidden="true"/></span><span className='pull-right' style={{cursor:'pointer',paddingRight:'5px'}}><i className="fa fa-times" onClick={this.props.flairToolbarOff}/></span></div></div>
                            <div style={{flex: '0 1 auto',marginLeft: '10px'}}>
                                <h3 id="myModalLabel">Entity {this.state.entityData != null ? <EntityValue value={this.state.entityData.value} /> : <div style={{display:'inline-flex',position:'relative'}}>Loading...</div> }</h3>
                            </div>
                            <div style={{overflow:'auto',flex:'1 1 auto', margin:'10px'}}>
                            {this.state.entityData != null ? <EntityBody data={this.state.entityData} entityid={this.state.entityid} type={this.props.type} id={this.props.id}/> : <div>Loading...</div>}
                            </div>
                            <div id='footer' onMouseDown={this.initDrag} style={{display: 'block', height: '5px', backgroundColor: 'black', borderTop: '2px solid black', borderBottom: '2px solid black', cursor: 'nwse-resize', overflow: 'hidden'}}>
                            </div>
                        </div>
                    </div>
                </Draggable>
            )
        } else if (this.props.entitytype == 'guide') {
            var guideurl = '/#/guide/' + this.state.entityid;
            return (
                <Draggable handle="#handle" onMouseDown={this.moveDivInit}>
                    <div id="dragme" className='box react-draggable entityPopUp' style={{height:this.state.entityHeight,width:this.state.entityWidth}}> 
                        <div id="entity_detail_container" style={{height: '100%', flexFlow: 'column', display: 'flex'}}>
                            <div id='handle' style={{width:'100%',background:'#292929', color:'white', fontWeight:'900', fontSize: 'large', textAlign:'center', cursor:'move',flex: '0 1 auto'}}><div><span className='pull-left' style={{paddingLeft:'5px'}}><i className="fa fa-arrows" ariaHidden="true"/></span><span className='pull-right' style={{cursor:'pointer',paddingRight:'5px'}}><i className="fa fa-times" onClick={this.props.flairToolbarOff}/></span></div></div>
                            <div style={{flex: '0 1 auto',marginLeft: '10px'}}>
                                <a href={guideurl} target="_blank"><h3 id="myModalLabel">Guide {this.state.entityData != null ? <span><span><EntityValue value={this.state.entityid} /></span><div><EntityValue value={this.state.entityData.applies_to} /></div></span> : <div style={{display:'inline-flex',position:'relative'}}>Loading...</div> }</h3></a>
                            </div>
                            <div style={{overflow:'auto',flex:'1 1 auto', margin:'10px'}}>
                            {this.state.entityData != null ? <GuideBody entityid={this.state.entityid} entitytype={this.props.entitytype}/> : <div>Loading...</div>}
                            </div>
                            <div id='footer' onMouseDown={this.initDrag} style={{display: 'block', height: '5px', backgroundColor: 'black', borderTop: '2px solid black', borderBottom: '2px solid black', cursor: 'nwse-resize', overflow: 'hidden'}}>
                            </div>
                        </div>
                    </div>
                </Draggable>
            )
        }*/
    },
    
});

var TabContents = React.createClass({
    render: function() {
        if (this.props.entitytype == 'entity') {
            return (
                <div className='tab-content'>
                    <div style={{flex: '0 1 auto',marginLeft: '10px'}}>
                        <h3 id="myModalLabel">Entity: {this.props.data != null ? <EntityValue value={this.props.data.value} /> : <div style={{display:'inline-flex',position:'relative'}}>Loading...</div> }</h3>
                    </div>
                    <div style={{height:'100%',display:'flex', flex:'1 1 auto', margin:'10px', flexFlow:'inherit', minHeight:'1px'}}>
                    {this.props.data != null ? <EntityBody data={this.props.data} entityid={this.props.entityid} type={this.props.type} id={this.props.id}/> : <div>Loading...</div>}
                    </div>
                </div>
            )
        } else if (this.props.entitytype == 'guide') {
            var guideurl = '/#/guide/' + this.props.entityid;
            return (
                <div className='tab-content'> 
                    <div style={{flex: '0 1 auto',marginLeft: '10px'}}>
                        <a href={guideurl} target="_blank"><h3 id="myModalLabel">Guide {this.props.data != null ? <span><span><EntityValue value={this.props.entityid} /></span><div><EntityValue value={this.props.data.applies_to} /></div></span> : <div style={{display:'inline-flex',position:'relative'}}>Loading...</div> }</h3></a>
                    </div>
                    <div style={{overflow:'auto',flex:'1 1 auto', margin:'10px'}}>
                    {this.props.data != null ? <GuideBody entityid={this.props.entityid} entitytype={this.props.entitytype}/> : <div>Loading...</div>}
                    </div> 
                </div>
            )
        }
    }
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
                        entityEnrichmentGeoArr.push(<Tab eventKey={enrichmentEventKey} style={{overflow:'auto'}} title={prop}><GeoView data={entityData[prop].data} type={this.props.type} id={this.props.id} entityData={this.props.data}/></Tab>);
                        enrichmentEventKey++;
                    } else if (entityData[prop].type == 'data') {
                        entityEnrichmentDataArr.push(<Tab eventKey={enrichmentEventKey} style={{overflow:'auto'}} title={prop}><EntityEnrichmentButtons dataSource={entityData[prop]} type={this.props.type} id={this.props.id} /></Tab>);
                        enrichmentEventKey++;
                    } else if (entityData[prop].type == 'link') {
                        entityEnrichmentLinkArr.push(<Button bsSize='small' target='_blank' href={entityData[prop].data.url}>{entityData[prop].data.title}</Button>)
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
            <Tabs className='tab-content' defaultActiveKey={1} bsStyle='tabs'>
                <Tab eventKey={1} style={{overflow:'auto'}} title={this.state.appearances}>{entityEnrichmentLinkArr}<span><br/><b>Appears: {this.state.appearances} times</b></span><br/><EntityReferences entityid={this.props.entityid} updateAppearances={this.updateAppearances}/><br/></Tab>
                <Tab eventKey={2} style={{overflow:'auto'}} title="Entry"><Button bsSize='small' onClick={this.entryToggle}>Add Entry</Button><br/>
                {this.state.entryToolbar ? <AddEntry title={'Add Entry'} type='entity' targetid={this.props.entityid} id={'add_entry'} addedentry={this.entryToggle} /> : null} <SelectedEntry type={'entity'} id={this.props.entityid}/></Tab>
                {entityEnrichmentGeoArr}
                {entityEnrichmentDataArr}
            </Tabs>
        )
    }
    
});

var GeoView = React.createClass({
    getInitialState: function() {
        return {
            copyToEntryToolbar: false,
            copyToEntityToolbar: false,
        }
    },
    copyToEntry: function() {
        if (this.state.copyToEntryToolbar == false) {
            this.setState({copyToEntryToolbar: true});
        } else {
            this.setState({copyToEntryToolbar: false})
        }
    },
    copyToEntity: function() {
        if (this.state.copyToEntityToolbar == false) {
            this.setState({copyToEntityToolbar:true})
        } else {
            this.setState({copyToEntityToolbar: false})
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
                <Button bsSize='small' onClick={this.copyToEntity}>Copy to <b>{"entity"}</b> entry</Button>
                <Button bsSize='small' onClick={this.copyToEntry}>Copy to <b>{this.props.type} {this.props.id}</b> entry</Button>
                {this.state.copyToEntryToolbar ? <AddEntry title='CopyToEntry' type={this.props.type} targetid={this.props.id} id={this.props.id} addedentry={this.copyToEntry} content={copy}/> : null}
                {this.state.copyToEntityToolbar ? <AddEntry title='CopyToEntry' type={'entity'} targetid={this.props.entityData.id} id={this.props.entityData.id} addedentry={this.copyToEntity} content={copy}/> : null}
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
                <div style={{overflow:'auto'}}> 
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
            //aHref = '/#/alert/' + this.props.data.id;
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

var GuideBody = React.createClass ({
    getInitialState: function() {
        return {
            entryToolbar:false
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
        //Lazy Loading SelectedEntry as it is not actually loaded when placed at the top of the page due to the calling order. 
        var SelectedEntry = require('../entry/selected_entry.jsx');
        return (
            <Tabs className='tab-content' defaultActiveKey={1} bsStyle='pills'>
                <Tab eventKey={1} style={{overflow:'auto'}}><Button bsSize='small' onClick={this.entryToggle}>Add Entry</Button><br/>
                {this.state.entryToolbar ? <AddEntry title={'Add Entry'} type='guide' targetid={this.props.entityid} id={'add_entry'} addedentry={this.entryToggle} /> : null} <SelectedEntry type={'guide'} id={this.props.entityid} isPopUp={1} /></Tab>
            </Tabs>
        )
    }
})

module.exports = EntityDetail;
