var React                   = require('react');
var Button                  = require('react-bootstrap/lib/Button');
var ButtonGroup             = require('react-bootstrap/lib/ButtonGroup');
var Popover                 = require('react-bootstrap/lib/Popover');
var Tabs                    = require('react-bootstrap/lib/Tabs');
var Tab                     = require('react-bootstrap/lib/Tab');
var Inspector               = require('react-inspector');
var SelectedEntry           = require('../detail/selected_entry.jsx');
var AddEntry                = require('../components/add_entry.jsx');
var Draggable               = require('react-draggable');
var DetailDataStatus        = require('../components/detail_data_status.jsx');
var Link                    = require('react-router-dom').Link;
var Store                   = require('../activemq/store.jsx');
var Marker                  = require('../components/marker.jsx').default;

var startX;
var startY;
var startWidth;
var startHeight;

var EntityDetail = React.createClass({
    getInitialState: function() {
        var tabs = [];
        var processedIdsArray = [];
        var entityHeight = '100%' //test
        var entityWidthint = 700;
        var entityWidth = entityWidthint + 'px';
        var entityMaxHeight = '70vh';
        if (this.props.fullScreen == true) {
            entityHeight = '95vh';
            entityWidth = '95%';
            entityMaxHeight = '95vh';
        }
        return {
            entityData:null,
            entityid: this.props.entityid,
            entityHeight: entityHeight,
            entityWidth: entityWidth,
            entityWidthint: entityWidthint,
            entityMaxHeight: entityMaxHeight,
            tabs: tabs,
            initialLoad:false,
            processedIds:processedIdsArray,
            valueClicked:'',
            defaultEntityOffset:this.props.entityoffset,
            entityobj: this.props.entityobj,
            height: null,
        }
    },
    componentDidMount: function () {
        var currentTabArray = this.state.tabs;
        var valueClicked = this.props.entityvalue;
        if (this.props.entityid == undefined) {
            $.ajax({
                type: 'GET',
                url: 'scot/api/v2/' + this.props.entitytype + '/byname',
                data: {name:valueClicked},
                success: function(result) {
                    var entityid = result.id;
                    if (this.isMounted()) {
                        this.setState({entityid:entityid});
                        $.ajax({
                            type: 'GET',
                            url: 'scot/api/v2/' + this.props.entitytype + '/' + entityid,
                            success: function(result) {
                                //this.setState({entityData:result})
                                var newTab = {data:result, entityid:entityid, entitytype:this.props.entitytype, valueClicked:result.value}
                                currentTabArray.push(newTab);
                                if (this.isMounted()) {
                                    var entityidsarray = [];
                                    entityidsarray.push(entityid);
                                    this.setState({tabs:currentTabArray,currentKey:entityid,initialLoad:true,processedIds:entityidsarray});
                                    Store.storeKey(entityid);
                                    Store.addChangeListener(this.updated);
                                }
                            }.bind(this),
                            error: function(data) {
                                this.props.errorToggle('failed to get entity detail information', data)
                            }.bind(this)
                        })
                    }
                }.bind(this),
                error: function(data) {
                    this.props.errorToggle('failed to get entity detail id information ', data)
                }.bind(this)
            })
        } else {
            $.ajax({
                type: 'GET',
                url: 'scot/api/v2/' + this.props.entitytype + '/' + this.state.entityid,
                success: function(result) {
                    //this.setState({entityData:result})
                    var newTab = {data:result, entityid:result.id, entitytype:this.props.entitytype, valueClicked:result.value}
                    currentTabArray.push(newTab);
                    if (this.isMounted()) {
                        var entityidsarray = [];
                        entityidsarray.push(result.id);
                        this.setState({tabs:currentTabArray,currentKey:result.id,initialLoad:true, processedIds:entityidsarray});
                        Store.storeKey(this.props.entityid);
                        Store.addChangeListener(this.updated);
                    }
                }.bind(this),
                error: function(data) {
                    this.props.errorToggle('failed to get entity detail information', data)
                }.bind(this)
            })
        }
        //Esc key closes popup
        function escHandler(event){
            //prevent from working when in input
            if ($('input').is(':focus')) {return};
            if ($('#main-search-results')[0] != undefined) {return}; //close search results before closing entity div
            //check for esc with keyCode
            if (event.keyCode == 27) {
                this.props.flairToolbarOff();
                event.preventDefault();
            }
        }
       
        

        $(document).keydown(escHandler.bind(this))
        this.containerHeightAdjust();
        window.addEventListener('resize',this.containerHeightAdjust);

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
                var addNewEntity = { //Initializing Function for adding an entry to be used later.
                    addNewEntity: function() {
                        var currentTabArray = this.state.tabs;
                        if (nextProps.entityid == undefined) {
                            $.ajax({
                                type: 'GET',
                                url: 'scot/api/v2/' + nextProps.entitytype + '/byname',
                                data: {name:nextProps.entityvalue},
                                success: function(result) {
                                    var entityid = result.id;
                                    if (this.isMounted()) {
                                        this.setState({entityid:entityid});
                                        $.ajax({
                                            type: 'GET',
                                            url: 'scot/api/v2/' + nextProps.entitytype + '/' + entityid,
                                            success: function(result) {
                                                var newTab = {data:result, entityid:entityid, entitytype:nextProps.entitytype, valueClicked:nextProps.entityvalue}
                                                currentTabArray.push(newTab);
                                                if (this.isMounted()) {
                                                    this.setState({tabs:currentTabArray,currentKey:nextProps.entityid})
                                                    Store.storeKey(nextProps.entityid);
                                                    Store.addChangeListener(this.updated);
                                                }
                                            }.bind(this),
                                            error: function(data) {
                                                this.props.errorToggle('failed to get entity detail information', data);
                                            }.bind(this)
                                        })
                                    }
                                }.bind(this),
                                error: function(data) {
                                    this.props.errorToggle('failed to get entity id detail information', data)
                                }.bind(this)
                            })
                        } else {
                            $.ajax({
                                type: 'GET',
                                url: 'scot/api/v2/' + nextProps.entitytype + '/' + nextProps.entityid,
                                success: function(result) {
                                    var newTab = {data:result, entityid:nextProps.entityid, entitytype:nextProps.entitytype, valueClicked:nextProps.entityvalue}
                                    currentTabArray.push(newTab);
                                    if (this.isMounted()) {
                                        this.setState({tabs:currentTabArray,currentKey:nextProps.entityid})
                                        Store.storeKey(nextProps.entityid);
                                        Store.addChangeListener(this.updated);
                                    }
                                }.bind(this),
                                error: function(data) {
                                    this.props.errorToggle('failed to get entity detail information', data)
                                }.bind(this)
                            })
                        }
                    }.bind(this)
                }
                if (this.state.initialLoad == false) {
                    setTimeout(checkForInitialLoadComplete.checkForInitialLoadComplete,50);
                } else {
                    if (nextProps != undefined) {
                        //TODO Fix next conditional for undefined that prevents multiple calls for the same ID at load time on a nested entity
                        if (nextProps.entitytype != null && (nextProps.entityid != undefined)) {
                            var nextPropsEntityIdInt = parseInt(nextProps.entityid);
                            for (var i=0; i < this.state.tabs.length; i++) {
                                if (nextPropsEntityIdInt == this.state.tabs[i].entityid || (this.state.tabs[i].entitytype == 'guide' && nextProps.entitytype == 'guide')) {
                                    if (this.isMounted()){
                                        this.setState({currentKey:nextPropsEntityIdInt})
                                    }
                                    return    
                                } else {
                                    var array = this.state.processedIds;
                                    var addEntity = true;
                                    for (var i=0; i < array.length; i++) {
                                        if (array[i] == nextPropsEntityIdInt) { // Check if entity is already being processed so we don't show it twice
                                            addEntity = false;
                                        } 
                                    }
                                    if (addEntity) {
                                        addNewEntity.addNewEntity();
                                        array.push(nextPropsEntityIdInt)
                                        this.setState({processedIds:array});
                                    }
                                }
                            }
                        }       
                    }
                }
            }.bind(this)
        }
        checkForInitialLoadComplete.checkForInitialLoadComplete();
        this.containerHeightAdjust();
    },
    updated: function () {
        var currentTabArray = this.state.tabs;
        var valueClicked = this.props.entityvalue;
        for (var j=0; j < currentTabArray.length; j++) {
            if (activemqid == currentTabArray[j].entityid) {
                var currentTabArrayIndex = j;
                $.ajax({
                    type: 'GET',
                    url: 'scot/api/v2/' + this.props.entitytype + '/' + currentTabArray[j].entityid,
                    success: function(result) {
                        //this.setState({entityData:result})
                        var newTab = {data:result, entityid:result.id, entitytype:this.props.entitytype, valueClicked:result.value}
                        currentTabArray[currentTabArrayIndex] = newTab;
                        if (this.isMounted()) {
                            var entityidsarray = [];
                            entityidsarray.push(result.id);
                            this.setState({tabs:currentTabArray,currentKey:result.id,initialLoad:true, processedIds:entityidsarray});
                        }
                    }.bind(this),
                    error: function(data) {
                        this.props.errorToggle('failed to get updated entity detail information', data)
                    }.bind(this)
                })
            }
        }
    },
    initDrag: function(e) {
        //remove the entityPopUpMaxSizeDefault class so it can be resized.
        if ($('#dragme').hasClass('entityPopUpMaxSizeDefault')) {
            var height = $('#dragme').height() + 'px';
            $('#dragme').css('height',height);
            $('#dragme').removeClass('entityPopUpMaxSizeDefault');
        }
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
    positionRightBoundsCheck: function(e) {
        if (!e) {
            return ($(document).width() - this.state.defaultEntityOffset.left - this.state.entityWidthint);
        } else {
            return ($(document).width() - (this.state.defaultEntityOffset.left + e ) - this.state.entityWidthint);
        }
    },
    containerHeightAdjust: function() {
        //only run this if we're in /#/entity and not as a popup
        if (this.props.fullScreen == true) {
            var scrollHeight;
            if ($('#list-view-container')[0]) {
                scrollHeight = $(window).height() - $('#list-view-container').height() - $('#header').height() - 70
                scrollHeight = scrollHeight + 'px'
            } else {
                scrollHeight = $(window).height() - $('#header').height() - 70
                scrollHeight = scrollHeight + 'px'
            }
            //$('#detail-container').css('height',scrollHeight);
            if (this.isMounted()) {
                this.setState({height:scrollHeight});
            }
        }
    },
    render: function() {
        //This makes the size that was last used hold for future entities
        /*if (entityPopUpHeight && entityPopUpWidth) {
            entityHeight = entityPopUpHeight;
            entityWidth = entityPopUpWidth;
        }*/
        var defaultOffsetY;
        var defaultOffsetX;
        var tabsArr = [];
        var DragmeClass = 'box react-draggable entityPopUp entityPopUpMaxSizeDefault'
        if (this.props.fullScreen == true || $('react-draggable-dragged')) { //Don't readd entityPopUpMaxSizeDefault if full screen or if the box has been dragged
            DragmeClass = 'box react-draggable entityPopUp'
        }
        if (this.props.fullScreen == true) {
            DragmeClass = DragmeClass + ' height100percent'
        }
        for (var i=0; i < this.state.tabs.length; i++) {
            var z = i+1;
            var title = 'tab';
            if (this.state.tabs[i].entitytype == 'guide') {
                title = 'guide'
            } else {
                if (this.state.tabs[i].valueClicked != undefined) {
                    title = this.state.tabs[i].valueClicked.slice(0,15);
                } else {
                    title = '';
                }
            }
            tabsArr.push(<Tab className='tab-content' eventKey={this.state.tabs[i].entityid} title={title}><TabContents data={this.state.tabs[i].data} type={this.props.type} id={this.props.id} entityid={this.state.tabs[i].entityid} entitytype={this.state.tabs[i].entitytype} valueClicked={this.state.tabs[i].valueClicked} i={z} key={z} errorToggle={this.props.errorToggle} linkWarningToggle={this.props.linkWarningToggle}/></Tab>)
        }
        if (this.state.defaultEntityOffset && this.state.entityobj) {
            var positionRightBoundsValue = this.positionRightBoundsCheck();
                if (this.positionRightBoundsCheck($(this.state.entityobj).width()) < 0) {
                    defaultOffsetX = this.state.defaultEntityOffset.left - this.state.entityWidthint;
                } else {
                    defaultOffsetX = this.state.defaultEntityOffset.left + $(this.state.entityobj).width();
                }
        } else {
            defaultOffsetY = 50;
            defaultOffsetX = 0;
        }
        if (this.props.fullScreen == true) {
            //entity detail is full screen mode
            return (
                <div id='popup-flex-container' style={{height: this.state.height}} className={'entity-full-screen'}>
                    <div id="entity_detail_container" style={{flexFlow: 'column', display: 'flex', width:'100%'}}>
                        <Tabs className='tab-content' defaultActiveKey={this.props.entityid} activeKey={this.state.currentKey} onSelect={this.handleSelectTab} bsStyle='pills'>
                            {tabsArr}                     
                        </Tabs>
                    </div>
                </div>
            )
        } else {
            return (
                <Draggable handle="#handle" onMouseDown={this.moveDivInit}>
                    <div id="dragme" className={DragmeClass} style={{width:this.state.entityWidth, left:defaultOffsetX, maxHeight:'90vh'}}>
                        <div id='popup-flex-container' style={{height: '100%', display:'flex', flexFlow:'row'}}>
                            <div id="entity_detail_container" style={{flexFlow: 'column', display: 'flex', width:'100%'}}>
                                <div id='handle' style={{width:'100%',background:'#292929', color:'white', fontWeight:'900', fontSize: 'large', textAlign:'center', cursor:'move',flex: '0 1 auto'}}><div><span className='pull-left' style={{paddingLeft:'5px'}}><i className="fa fa-arrows" aria-hidden="true"/></span><span className='pull-right' style={{cursor:'pointer',paddingRight:'5px'}}><i className="fa fa-times" style={{color:'red'}}onClick={this.props.flairToolbarOff}/></span></div></div>
                                <Tabs className='tab-content' defaultActiveKey={this.props.entityid} activeKey={this.state.currentKey} onSelect={this.handleSelectTab} bsStyle='pills'>
                                    {tabsArr}                     
                                </Tabs>
                            </div>
                            <div id='sidebar' onMouseDown={this.initDrag} style={{flex:'0 1 auto', backgroundColor: 'black', borderTop: '2px solid black', borderBottom: '2px solid black', cursor: 'nwse-resize', overflow: 'hidden', width:'5px'}}/>
                        </div>
                        <div id='footer' onMouseDown={this.initDrag} style={{display: 'block', height: '5px', backgroundColor: 'black', borderTop: '2px solid black', borderBottom: '2px solid black', cursor: 'nwse-resize', overflow: 'hidden'}}>
                        </div>
                    </div>
                </Draggable>  
            )
        }
    },
    
});

var TabContents = React.createClass({
    render: function() {
        if (this.props.entitytype == 'entity') {
            
            return (
                <div className='tab-content'>
                    <div style={{flex: '0 1 auto',marginLeft: '10px'}}>
                        <h4 id="myModalLabel">{this.props.data != null ? <EntityValue value={this.props.valueClicked} data={this.props.data} errorToggle={this.props.errorToggle} /> : <div style={{display:'inline-flex',position:'relative'}}>Loading...</div> }</h4>
                    </div>
                    <div style={{height:'100%',display:'flex', flex:'1 1 auto', marginLeft:'10px', flexFlow:'inherit', minHeight:'1px'}}>
                    {this.props.data != null ? <EntityBody data={this.props.data} entityid={this.props.entityid} type={this.props.type} id={this.props.id} errorToggle={this.props.errorToggle} linkWarningToggle={this.props.linkWarningToggle}/> : <div>Loading...</div>}
                    </div>
                </div>
            )
        } else if (this.props.entitytype == 'guide') {
            var guideurl = '/' + 'guide/' + this.props.entityid;
            return (
                <div className='tab-content'> 
                    <div style={{flex: '0 1 auto',marginLeft: '10px'}}>
                        <Link to={guideurl} target="_blank"><h4 id="myModalLabel">{this.props.data != null ? <span><span><EntityValue value={this.props.entityid} errorToggle={this.props.errorToggle} /></span><div><EntityValue value={this.props.data.applies_to} errorToggle={this.props.errorToggle} /></div></span> : <div style={{display:'inline-flex',position:'relative'}}>Loading...</div> }</h4></Link>
                    </div>
                    <div style={{overflow:'auto',flex:'1 1 auto', marginLeft:'10px'}}>
                    {this.props.data != null ? <GuideBody entityid={this.props.entityid} entitytype={this.props.entitytype}/> : <div>Loading...</div>}
                    </div> 
                </div>
            )
        }
    }
});

var EntityValue = React.createClass({
    render: function() {
        if (this.props.data != undefined) {  //Entity Detail Popup showing the entity type
            var entityurl = '/' + 'entity/' + this.props.data.id;
            
            return (
                <div className='flair_header'>
                    <div>
                        <Link to={entityurl} target="_blank">
                            Entity {this.props.data.id}
                        </Link>
                        <span>&nbsp;</span>
                        <DetailDataStatus status={this.props.data.status} id={this.props.data.id} type={'entity'} errorToggle={this.props.errorToggle} /> 
                        <span>&nbsp;</span>   
                        <Marker type='entity' id={this.props.data.id} string={this.props.value} />
                    </div>
                    <div>
                        <span>{this.props.data.type}:</span>
                        &nbsp;
                        <span>{this.props.value}</span>
                    </div>
                </div>
            )
        } else {                            //Guide Detail Popup showing the name of the guide that is being applied to
            return (
                <div className='flair_header'>{this.props.value}</div>
            )
        }
    }
});

var EntityBody = React.createClass({
    getInitialState: function() {
        return {
            loading:"Loading Entries",
            entryToolbar:false,
            appearances:0,
            showFullEntityButton:false,
        }
    },
    updateAppearances: function(appearancesNumber) {
        if (appearancesNumber != null) {
            if (appearancesNumber != 0) {
                var newAppearancesNumber = this.state.appearances + appearancesNumber;
                if (this.isMounted()) {
                    this.setState({appearances:newAppearancesNumber});
                }
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
    showFullEntityButton: function() {
        //don't show the button if in full screen entity view.
        if (this.props.type != 'entity') { 
            this.setState({showFullEntityButton:true});
        }
    },
    linkOnClickIntercept: function(e) {
        this.props.linkWarningToggle(e.target.id);
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
                        entityEnrichmentGeoArr.push(<Tab eventKey={enrichmentEventKey} className='entityPopUpButtons' style={{overflow:'auto'}} title={prop}><GeoView data={entityData[prop].data} type={this.props.type} id={this.props.id} entityData={this.props.data} errorToggle={this.props.errorToggle}/></Tab>);
                        enrichmentEventKey++;
                    } else if (entityData[prop].type == 'data') {
                        entityEnrichmentDataArr.push(<Tab eventKey={enrichmentEventKey} className='entityPopUpButtons' style={{overflow:'auto'}} title={prop}><EntityEnrichmentButtons dataSource={entityData[prop]} type={this.props.type} id={this.props.id} errorToggle={this.props.errorToggle}/></Tab>);
                        enrichmentEventKey++;
                    } else if (entityData[prop].type == 'link') {
                        entityEnrichmentLinkArr.push(<Button bsSize='xsmall' target='_blank' id={entityData[prop].data.url} onMouseDown={this.linkOnClickIntercept}>{entityData[prop].data.title}</Button>)
                        enrichmentEventKey++;
                    }
                }
            }
        }
        //Lazy Loading SelectedEntry as it is not actually loaded when placed at the top of the page due to the calling order. 
        var SelectedEntry = require('../detail/selected_entry.jsx');
        //PopOut available
        //var href = '/#/entity/' + this.props.entityid + '/' + this.props.type + '/' + this.props.id;
        var href = '/' + 'entity/'+this.props.entityid;
        return (
            <Tabs className='tab-content' defaultActiveKey={1} bsStyle='tabs'>
                <Tab eventKey={1} className='entityPopUpButtons' title={this.state.appearances} style={{height:'100%'}}>
                    <div>
                    {entityEnrichmentLinkArr}
                    </div>
                    <div style={{maxHeight: '30vh', overflowY: 'auto'}}>
                        <span><b>Appears: {this.state.appearances} times</b></span>{this.state.showFullEntityButton == true ? <span style={{paddingLeft:'5px'}}><Link to={href} style={{color:'#c400ff'}} target='_blank'>List truncated due to large amount of references. Click to view the whole entity</Link></span> : null}<br/><EntityReferences entityid={this.props.entityid} updateAppearances={this.updateAppearances} type={this.props.type} showFullEntityButton={this.showFullEntityButton} errorToggle={this.props.errorToggle}/><br/>
                    </div>
                    <hr style={{marginTop:'.5em', marginBottom:'.5em'}}/>
                    <div style={{maxHeight:'50vh', overflowY:'auto'}}>
                        <div>
                            <Button bsSize='xsmall' onClick={this.entryToggle}>Add Entry</Button><br/>
                        </div>
                        {this.state.entryToolbar ? <AddEntry entryAction={'Add'} type='entity' targetid={this.props.entityid} id={'add_entry'} addedentry={this.entryToggle} errorToggle={this.props.errorToggle}/> : null} 
                        <SelectedEntry type={'entity'} id={this.props.entityid} isPopUp={1} errorToggle={this.props.errorToggle}/>
                    </div>
                </Tab>
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
                <Button bsSize='xsmall' onClick={this.copyToEntity}>Copy to <b>{"entity"}</b> entry</Button>
                {this.props.type != 'alertgroup' ? <Button bsSize='xsmall' onClick={this.copyToEntry}>Copy to <b>{this.props.type} {this.props.id}</b> entry</Button> : null}
                {this.state.copyToEntryToolbar ? <AddEntry entryAction='Copy To Entry' type={this.props.type} targetid={this.props.id} id={this.props.id} addedentry={this.copyToEntry} content={copy} errorToggle={this.props.errorToggle}/> : null}
                {this.state.copyToEntityToolbar ? <AddEntry entryAction='Copy To Entry' type={'entity'} targetid={this.props.entityData.id} id={this.props.entityData.id} addedentry={this.copyToEntity} content={copy} errorToggle={this.props.errorToggle}/> : null}
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
            <div style={{overflowY:'auto', maxHeight: '70vh'}}>
                <div> 
                    <Inspector.default data={dataSource} expandLevel={4} />
                </div>
            </div>
        )
    },
});

var EntityReferences = React.createClass({
    getInitialState: function() {
        var maxRecords = 100;
        //if type == entity then the url is looking for a full screen entity view with all records.
        if (this.props.type == 'entity') {
            maxRecords = undefined;
        }
        return {
            entityDataAlertGroup:null,
            entityDataEvent:null,
            entityDataIncident:null,
            entityDataIntel:null,
            entityDataSignature: null,
            maxRecords: maxRecords,
            loadingAlerts: true,
            loadingEvents: true,
            loadingIncidents: true,
            loadingIntel: true,
            loadingSignature: true,
            loading: true,
        }
    },
    componentDidMount: function() {
        this.alertRequest = $.ajax({
            type: 'get',
            url: 'scot/api/v2/entity/' + this.props.entityid + '/alert',
            data: {sort:JSON.stringify({'id':-1})},
            traditional:true,
            success: function(result) {
                var result = result.records;
                var recordNumber = result.length; 
                var arr = [];
                var arrPromoted = [];
                var arrClosed = [];
                var arrOpen = [];
                if ( this.state.maxRecords ) { recordNumber = this.state.maxRecords }
                for(var i=0; i < recordNumber; i++) {
                    if (result[i] != null) {
                        if (result[i].status == 'promoted'){
                            arrPromoted.push(<ReferencesBody type={'alert'} data={result[i]} index={i} errorToggle={this.props.errorToggle}/>)
                        } else if (result[i].status == 'closed') {
                            arrClosed.push(<ReferencesBody type={'alert'} data={result[i]} index={i} errorToggle={this.props.errorToggle}/>)
                        } else {
                            arrOpen.push(<ReferencesBody type={'alert'} data={result[i]} index={i} errorToggle={this.props.errorToggle}/>)
                        }
                    }
                }
                arr.push(arrPromoted);
                arr.push(arrClosed);
                arr.push(arrOpen);
                if (this.isMounted()) {
                    if (result.length >= 100) {
                        this.props.showFullEntityButton();
                    }
                    this.props.updateAppearances(result.length);
                    this.setState({entityDataAlertGroup:arr,loadingAlerts:false})
                    if (this.state.loadingAlerts == false && this.state.loadingEvents == false && this.state.loadingIncidents == false && this.state.loadingIntel == false  && this.state.loadingSignature == false) {
                        this.setState({loading:false});
                    }
                }
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('failed to get entity references for alerts', data) 
            }.bind(this)
        })

        this.eventRequest = $.ajax({
            type: 'get',
            url: 'scot/api/v2/entity/' + this.props.entityid + '/event',
            data: {sort:JSON.stringify({'id':-1})},
            traditional: true,
            success: function(result) {
                var result = result.records;
                var recordNumber = result.length;
                var arr = [];
                var arrPromoted = [];
                var arrClosed = [];
                var arrOpen = [];
                if ( this.state.maxRecords ) { recordNumber = this.state.maxRecords } 
                for(var i=0; i < recordNumber; i++) {
                    if (result[i] != null) {
                        if (result[i].status == 'promoted'){
                            arrPromoted.push(<ReferencesBody type={'event'} data={result[i]} index={i} errorToggle={this.props.errorToggle}/>)
                        } else if (result[i].status == 'closed') {
                            arrClosed.push(<ReferencesBody type={'event'} data={result[i]} index={i} errorToggle={this.props.errorToggle}/>)
                        } else {
                            arrOpen.push(<ReferencesBody type={'event'} data={result[i]} index={i} errorToggle={this.props.errorToggle} />)
                        }
                    }
                }
                arr.push(arrPromoted);
                arr.push(arrClosed);
                arr.push(arrOpen);
                if (this.isMounted()) {
                    if (result.length >= 100) {
                        this.props.showFullEntityButton();
                    }
                    this.props.updateAppearances(result.length);
                    this.setState({entityDataEvent:arr,loadingEvents:false})
                    if (this.state.loadingAlerts == false && this.state.loadingEvents == false && this.state.loadingIncidents == false && this.state.loadingIntel == false && this.state.loadingSignature ) {
                        this.setState({loading:false});
                    }
                }
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('failed to get entity reference for events', data);
            }.bind(this)
        })

        this.incidentRequest = $.ajax({
            type: 'get',
            url: 'scot/api/v2/entity/' + this.props.entityid + '/incident',
            data: {sort:JSON.stringify({'id':-1})},
            traditional: true,
            success: function(result) {
                var result = result.records;
                var recordNumber = result.length;
                var arr = [];
                var arrPromoted = [];
                var arrClosed = [];
                var arrOpen = [];
                if ( this.state.maxRecords ) { recordNumber = this.state.maxRecords }
                for(var i=0; i < recordNumber; i++) {
                    if (result[i] != null) {
                        if (result[i].status == 'promoted'){
                            arrPromoted.push(<ReferencesBody type={'incident'} data={result[i]} index={i} errorToggle={this.props.errorToggle}/>)
                        } else if (result[i].status == 'closed') {
                            arrClosed.push(<ReferencesBody type={'incident'} data={result[i]} index={i} errorToggle={this.props.errorToggle}/>)
                        } else {
                            arrOpen.push(<ReferencesBody type={'incident'} data={result[i]} index={i} errorToggle={this.props.errorToggle}/>)
                        }
                    }
                }
                arr.push(arrPromoted);
                arr.push(arrClosed);
                arr.push(arrOpen);
                if (this.isMounted()) {
                    if (result.length >= 100) {
                        this.props.showFullEntityButton();
                    }
                    this.props.updateAppearances(result.length);
                    this.setState({entityDataIncident:arr, loadingIncidents:false})
                    if (this.state.loadingAlerts == false && this.state.loadingEvents == false && this.state.loadingIncidents == false && this.state.loadingIntel == false && this.state.loadingSignature == false) {
                        this.setState({loading:false});
                    }
                }
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('failed to get entity references for incidents', data)
            }.bind(this)
        })

        this.intelRequest = $.ajax({
            type: 'get',
            url: 'scot/api/v2/entity/' + this.props.entityid + '/intel',
            data: {sort:JSON.stringify({'id':-1})},
            traditional: true,
            success: function(result) {
                var result = result.records;
                var recordNumber = result.length;
                var arr = [];
                var arrPromoted = [];
                var arrClosed = [];
                var arrOpen = [];
                if ( this.state.maxRecords ) { recordNumber = this.state.maxRecords }
                for(var i=0; i < recordNumber; i++) {
                    if (result[i] != null) {
                        if (result[i].status == 'promoted'){
                            arrPromoted.push(<ReferencesBody type={'intel'} data={result[i]} index={i} errorToggle={this.props.errorToggle}/>)
                        } else if (result[i].status == 'closed') {
                            arrClosed.push(<ReferencesBody type={'intel'} data={result[i]} index={i} errorToggle={this.props.errorToggle}/>)
                        } else {
                            arrOpen.push(<ReferencesBody type={'intel'} data={result[i]} index={i} errorToggle={this.props.errorToggle}/>)
                        }
                    }
                }
                arr.push(arrPromoted);
                arr.push(arrClosed);
                arr.push(arrOpen);
                if (this.isMounted()) {
                    if (result.length >= 100) {
                        this.props.showFullEntityButton();
                    }
                    this.props.updateAppearances(result.length);
                    this.setState({entityDataIntel:arr, loadingIntel:false})
                    if (this.state.loadingAlerts == false && this.state.loadingEvents == false && this.state.loadingIncidents == false && this.state.loadingIntel == false && this.state.loadingSignature == false) {
                        this.setState({loading:false});
                    }
                }
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('failed to get entity references for intel') 
            }.bind(this)
        })
        
        this.signatureRequest = $.ajax({
            type: 'get',
            url: 'scot/api/v2/entity/' + this.props.entityid + '/signature',
            data: {sort:JSON.stringify({'id':-1})},
            traditional: true,
            success: function(result) {
                var result = result.records;
                var recordNumber = result.length;
                var arr = [];
                var arrPromoted = [];
                var arrClosed = [];
                var arrOpen = [];
                if ( this.state.maxRecords ) { recordNumber = this.state.maxRecords }
                for(var i=0; i < recordNumber; i++) {
                    if (result[i] != null) {
                        if (result[i].status == 'promoted'){
                            arrPromoted.push(<ReferencesBody type={'signature'} data={result[i]} index={i} errorToggle={this.props.errorToggle}/>)
                        } else if (result[i].status == 'closed') {
                            arrClosed.push(<ReferencesBody type={'signature'} data={result[i]} index={i} errorToggle={this.props.errorToggle}/>)
                        } else {
                            arrOpen.push(<ReferencesBody type={'signature'} data={result[i]} index={i} errorToggle={this.props.errorToggle}/>)
                        }
                    }
                }
                arr.push(arrPromoted);
                arr.push(arrClosed);
                arr.push(arrOpen);
                if (this.isMounted()) {
                    if (result.length >= 100) {
                        this.props.showFullEntityButton();
                    }
                    this.props.updateAppearances(result.length);
                    this.setState({entityDataSignature:arr, loadingSignature:false})
                    if (this.state.loadingAlerts == false && this.state.loadingEvents == false && this.state.loadingIncidents == false  && this.state.loadingIntel == false && this.state.loadingSignature == false) {
                        this.setState({loading:false});
                    }
                }
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('failed to get entity references for signature') 
            }.bind(this)
        })
        /*
        this.entityRequest = $.ajax({
            type: 'get',
            url: 'scot/api/v2/entity/' + this.props.entityid + '/entity',
            data: {sort:JSON.stringify({'id':-1})},
            traditional: true,
            success: function(result) {
                var result = result.records
                var arr = [];
                var arrPromoted = [];
                var arrClosed = [];
                var arrOpen = [];
                var recordNumber = this.state.maxRecords;
                if (isNaN(this.state.maxRecords) == true) { recordNumber = eval(this.state.maxRecords) }
                for(var i=0; i < recordNumber; i++) {
                    if (result[i] != null) {
                        if (result[i].status == 'promoted'){
                            arrPromoted.push(<ReferencesBody type={'entity'} data={result[i]} index={i} errorToggle={this.props.errorToggle}/>)
                        } else if (result[i].status == 'closed') {
                            arrClosed.push(<ReferencesBody type={'entity'} data={result[i]} index={i} errorToggle={this.props.errorToggle}/>)
                        } else {
                            arrOpen.push(<ReferencesBody type={'entity'} data={result[i]} index={i} errorToggle={this.props.errorToggle}/>)
                        }
                    }
                }
                arr.push(arrPromoted);
                arr.push(arrClosed);
                arr.push(arrOpen);
                if (this.isMounted()) {
                    if (result.length >= 100) {
                        this.props.showFullEntityButton();
                    }
                    this.props.updateAppearances(result.length);
                    this.setState({entityDataIntel:arr, loadingIntel:false})
                    if (this.state.loadingAlerts == false && this.state.loadingEvents == false && this.state.loadingIncidents == false && this.state.loadingIntel == false) {
                        this.setState({loading:false});
                    }
                }
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('failed to get entity references for entity') 
            }.bind(this)
        })*/
        $('#sortableentitytable'+this.props.entityid).tablesorter();
    },
    componentDidUpdate: function() {
        var config = $( '#sortableentitytable'+this.props.entityid)[ 0 ].config,
        // applies or reapplies a sort to the table; use false to not update the sort
        resort = true // or [ [0,0], [1,0] ] etc
        $.tablesorter.updateAll( config, resort );
    },
    render: function() {
        var id = 'sortableentitytable' + this.props.entityid;
        return (
            <div className='entityTableWrapper'>
            {this.state.loading ? <span>Loading: {this.state.loadingAlerts ? <span>Alerts </span> : null}{this.state.loadingEvents ? <span>Events </span> : null}{this.state.loadingIncidents ? <span>Incidents </span> : null}{this.state.loadingIntel ? <span>Intel </span> : null}{this.state.loadingSignature ? <span>Signature </span> : null}</span>: null}
            <table className="tablesorter entityTableHorizontal" id={id} width='100%'>
                <thead>
                    <tr>
                        <th>peek</th>
                        <th>status</th>
                        <th>id</th>
                        <th>type</th>
                        <th>entries</th>
                        <th>subject</th>   
                        <th>last updated</th>
                    </tr>
                </thead>
                <tbody>
                    {this.state.entityDataSignature}
                    {this.state.entityDataIntel}
                    {this.state.entityDataIncident}
                    {this.state.entityDataEvent}
                    {this.state.entityDataAlertGroup}
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
                for (var i=0; i < entryResult.length; i++) {
                    if (entryResult[i].class == 'summary') {
                        summary = true;
                        if (this.isMounted) {
                            this.setState({showSummary:true,summaryData:entryResult[i].body_plain})
                            $('#entityTable' + this.props.data.id).qtip({ 
                                content: {text: entryResult[i].body_plain}, 
                                style: { classes: 'qtip-scot' }, 
                                hide: 'unfocus', 
                                position: { my: 'top left', at: 'right', target: $('#entitySummaryRow'+this.props.data.id)},//[position.left,position.top] }, 
                                show: { ready: true, event: 'click' } 
                            });
                            break;
                        }
                    }
                }
                if (summary == false) {
                    $('#entityTable' + this.props.data.id).qtip({
                        content: {text: 'No Summary Found'},
                        style: { classes: 'qtip-scot' },
                        hide: 'unfocus',
                        position: { my: 'top left', at: 'right', target: $('#entitySummaryRow'+this.props.data.id)},
                        show: { ready: true, event: 'click' }
                    });
                } 
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('Summary Query failed for: ' + this.props.type + ':' + this.props.data.id, data);
            }.bind(this)
        })
    },
    render: function() {
        var id = this.props.data.id;
        var trId = 'entityTable' + this.props.data.id;
        var tdId = 'entitySummaryRow' + this.props.data.id;
        var aHref = null;
        var promotedHref = null;
        var statusColor = null;
        var daysSince = null;
        var subject = this.props.data.subject;
        var updatedTime = this.props.data.updated;
        var updatedTimeHumanReadable = '';
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
            aHref = '/' + this.props.type + '/' + this.props.data.id;
            //aHref = '/#/alertgroup/' + this.props.data.alertgroup;
            promotedHref = '/#/event/' + this.props.data.promotion_id;
        } else if (this.props.type == 'event') {
            promotedHref = '/#/incident/' + this.props.data.promotion_id;
            aHref = '/' + this.props.type + '/' + this.props.data.id;
        }
        else {
            aHref = '/' + this.props.type + '/' + this.props.data.id;
        }
        if (subject == undefined) {
            if (this.props.data.data != undefined) {
                if (this.props.data.data.alert_name != undefined) {
                    subject = this.props.data.data.alert_name;
                } else {
                    subject = '';
                }
            } else {
                subject = '';
            }
        }
        if (updatedTime != undefined) {
            daysSince = Math.floor((Math.round(new Date().getTime()/1000)-updatedTime)/86400);
            updatedTimeHumanReadable = new Date(1000 * updatedTime).toLocaleString()
        }
        return (
            <tr id={trId}>
                <td style={{textAlign:'center',cursor: 'pointer', verticalAlign: 'top'}} onClick={this.onClick} id={tdId}><i className="fa fa-eye fa-1" aria-hidden="true"></i></td>
                {this.props.data.status == 'promoted' ? <td style={{paddingRight:'4px', paddingLeft:'4px', verticalAlign: 'top'}}><Button bsSize='xsmall' bsStyle={'warning'} id={this.props.data.id} href={promotedHref} target="_blank" style={{lineHeight: '12pt', fontSize: '10pt', marginLeft: 'auto'}}>{this.props.data.status}</Button></td> : <td style={{color: statusColor, paddingRight:'4px', paddingLeft:'4px', verticalAlign: 'top'}}>{this.props.data.status}</td>}
                <td style={{paddingRight:'4px', paddingLeft:'4px', verticalAlign: 'top'}}><Link to={aHref} target="_blank">{this.props.data.id}</Link></td>
                <td style={{paddingRight:'4px', paddingLeft:'4px', verticalAlign: 'top'}}>{this.props.type}</td>
                <td style={{paddingRight:'4px', paddingLeft:'4px', textAlign:'center', verticalAlign: 'top'}}>{this.props.data.entry_count}</td>
                <td style={{paddingRight:'4px', paddingLeft:'4px', verticalAlign: 'top'}}>{subject}</td>
                <td style={{paddingRight:'4px', paddingLeft:'4px', verticalAlign: 'top'}} title={updatedTimeHumanReadable}>{daysSince} days ago</td>
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
        var SelectedEntry = require('../detail/selected_entry.jsx');
        return (
            <Tabs className='tab-content' defaultActiveKey={1} bsStyle='pills'>
                <Tab eventKey={1} style={{overflow:'auto', maxHeight:'70vh'}}>
                    <div>
                        <Button bsSize='xsmall' onClick={this.entryToggle}>Add Entry</Button><br/>
                    </div>
                    {this.state.entryToolbar ? <AddEntry entryAction={'Add'} type='guide' targetid={this.props.entityid} id={'add_entry'} addedentry={this.entryToggle} errorToggle={this.props.errorToggle}/> : null} 
                    <SelectedEntry type={'guide'} id={this.props.entityid} isPopUp={1} errorToggle={this.props.errorToggle}/>
                </Tab>
            </Tabs>
        )
    }
})

module.exports = EntityDetail;
