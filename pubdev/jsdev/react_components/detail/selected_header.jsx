var React                   = require('react');
var ReactTime               = require('react-time').default;
var SelectedHeaderOptions   = require('./selected_header_options.jsx');
var DeleteEvent             = require('../modal/delete.jsx').DeleteEvent;
var Owner                   = require('../modal/owner.jsx');
var Entities                = require('../modal/entities.jsx');
var ChangeHistory           = require('../modal/change_history.jsx');
var ViewedByHistory         = require('../modal/viewed_by_history.jsx');
var SelectedPermission      = require('../components/permission.jsx');
var Modal                   = require('react-modal');
var Button                  = require('react-bootstrap/lib/Button');
var ButtonToolbar           = require('react-bootstrap/lib/ButtonToolbar');
var OverlayTrigger          = require('react-bootstrap/lib/OverlayTrigger');
var Popover                 = require('react-bootstrap/lib/Popover');
var DropdownButton          = require('react-bootstrap/lib/DropdownButton');
var MenuItem                = require('react-bootstrap/lib/MenuItem');
var DebounceInput           = require('react-debounce-input');
var SelectedEntry           = require('./selected_entry.jsx');
var Tag                     = require('../components/tag.jsx');
var Source                  = require('../components/source.jsx');
var Store                   = require('../activemq/store.jsx');
var Notification            = require('react-notification-system');
var AddFlair                = require('../components/add_flair.jsx').AddFlair;
var EntityDetail            = require('../modal/entity_detail.jsx');
var LinkWarning             = require('../modal/link_warning.jsx');
var Link                    = require('react-router-dom').Link;
var InitialAjaxLoad;

var SelectedHeader = React.createClass({
    getInitialState: function() {
        var entityDetailKey = Math.floor(Math.random()*1000);
        return {
            showEventData:false,
            headerData:null,
            sourceData:'',
            tagData:'',
            permissionsToolbar:false,
            entitiesToolbar:false,
            changeHistoryToolbar:false,
            viewedByHistoryToolbar:false,
            entryToolbar:false, 
            deleteToolbar:false,
            promoteToolbar:false,
            notificationType:null,
            notificationMessage:null,
            key:this.props.id,
            showEntryData:false,
            entryData:'',
            showEntityData:false,
            entityData:'',
            entityid:null,
            entitytype:null,
            entityoffset:null,
            entityobj:null,
            flairToolbar:false,
            linkWarningToolbar:false,
            refreshing:false,
            loading: false,
            eventLoaded:false,
            entryLoaded:false,
            entityLoaded:false,
            alertSelected:false,
            aIndex:null,
            aType:null,
            aStatus:null,
            aID:0,
            guideID: null,
            fileUploadToolbar: false,
            isNotFound: false,
            runWatcher: false,
            entityDetailKey: entityDetailKey,
            showSignatureOptions: false,        
        }
    },
    componentWillMount: function() {
        this.setState({loading:true});
    },
    componentDidMount: function() {
        var delayFunction = {
            delay: function() {
                var entryType = 'entry';
                if (this.props.type == 'alertgroup') { entryType = 'alert' };
                //Main Type Load
                $.ajax({
                    type:'get',
                    url:'scot/api/v2/' + this.props.type + '/' + this.props.id,
                    success:function(result) {
                        if (this.isMounted()) {
                            var eventResult = result;
                            this.setState({headerData:eventResult,showEventData:true, isNotFound:false, tagData:eventResult.tag, sourceData:eventResult.source})
                            if (this.state.showEventData == true && this.state.showEntryData == true && this.state.showEntityData == true) {
                                this.setState({loading:false})
                            }
                        }
                    }.bind(this),
                    error: function(result) {
                        this.setState({showEventData:true, isNotFound:true})
                        if (this.state.showEventData == true && this.state.showEntryData == true && this.state.showEntityData == true) {
                            this.setState({loading:false})
                        }
                        this.props.errorToggle("Error: Failed to load detail data. Error message: " + result.responseText);
                    }.bind(this),
                });
                //entry load
                $.ajax({
                    type: 'get',
                    url: 'scot/api/v2/' + this.props.type + '/' + this.props.id + '/' + entryType, 
                    success: function(result) {
                        if (this.isMounted()) {
                            var entryResult = result.records;
                            this.setState({showEntryData:true, entryData:entryResult, runWatcher:true})
                            this.Watcher();
                            if (this.state.showEventData == true && this.state.showEntryData == true && this.state.showEntityData == true) {
                                this.setState({loading:false});
                            }
                        }
                    }.bind(this),
                    error: function(result) {
                        this.setState({showEntryData:true})
                        if (this.state.showEventData == true && this.state.showEntryData == true && this.state.showEntityData == true) {
                            this.setState({loading:false});
                        }
                        this.props.errorToggle("Error: Failed to load entry data. Error message: " + result.responseText);
                    }
                });
                //entity load
                $.ajax({
                    type: 'get',
                    url: 'scot/api/v2/' + this.props.type + '/' + this.props.id + '/entity',
                    success: function(result) {
                        if (this.isMounted()) {
                            var entityResult = result.records;
                            this.setState({showEntityData:true, entityData:entityResult})
                            var waitForEntry = {
                                waitEntry: function() {
                                    if(this.state.showEntryData == false && alertgroupforentity === false) {
                                        setTimeout(waitForEntry.waitEntry,50);
                                    } else {
                                        alertgroupforentity = false;
                                        setTimeout(function(){AddFlair.entityUpdate(entityResult,this.flairToolbarToggle,this.props.type,this.linkWarningToggle,this.props.id,this.scrollTo)}.bind(this));
                                        if (this.state.showEventData == true && this.state.showEntryData == true && this.state.showEntityData == true) {
                                            this.setState({loading:false});        
                                        }
                                    }
                                }.bind(this)
                            };
                            waitForEntry.waitEntry();
                        }
                    }.bind(this),
                    error: function(result) {
                        this.setState({showEntityData:true})
                        if (this.state.showEventData == true && this.state.showEntryData == true && this.state.showEntityData == true) {
                            this.setState({loading:false});
                        }
                        this.props.errorToggle("Error: Failed to load entity data.");
                    }.bind(this)
                });
                //guide load
                if (this.props.type == 'alertgroup') {
                    $.ajax({
                        type:'get',
                        url: 'scot/api/v2/' + this.props.type + '/' + this.props.id + '/guide', 
                        success: function(result) {
                            if (this.isMounted()) {
                                if (result.records[0] != undefined) {
                                    var guideID = result.records[0].id;
                                    this.setState({guideID: guideID});
                                } else {
                                    this.setState({guideID: 0});
                                }
                            }
                        }.bind(this),
                        error: function(result) {
                            this.setState({guideID: null})
                            this.props.errorToggle("Error: Failed to load guide data. Error message:" + result.responseText);
                        }.bind(this)
                    });     
                }
                Store.storeKey(this.props.id);
                Store.addChangeListener(this.updated); 
            }.bind(this)
        }
        InitialAjaxLoad = setTimeout(delayFunction.delay,400);
    },
    componentWillUnmount: function() {
        clearTimeout(InitialAjaxLoad)
    },
    componentDidUpdate: function() {
        //This runs the watcher which handles the entity popup and link warning.
        if(this.state.runWatcher == true) {
            this.Watcher();
        }
    },
    componentWillReceiveProps: function() {
        //resets the watcher flag to false. This will only get set to true if a call for entries is made.
        this.setState({runWatcher:false});
    },
    updated: function(_type,_message) { 
        this.setState({refreshing:true, eventLoaded:false,entryLoaded:false,entityLoaded:false});
        var entryType = 'entry';
        if (this.props.type == 'alertgroup') {entryType = 'alert'};
        //main type load
        $.ajax({
            type:'get',
            url:'scot/api/v2/' + this.props.type + '/' + this.props.id,
            success:function(result) {
                if (this.isMounted()) {
                    var eventResult = result;
                    this.setState({headerData:eventResult,showEventData:true, eventLoaded:true, isNotFound:false, tagData:eventResult.tag, sourceData:eventResult.source})
                    if (this.state.eventLoaded == true && this.state.entryLoaded == true && this.state.entityLoaded == true) {
                        this.setState({refreshing:false})
                    }
                }
            }.bind(this),
            error: function(result) {
                this.setState({showEventData:true, eventLoaded:true, isNotFound:true})
                if (this.state.eventLoaded == true && this.state.entryLoaded == true && this.state.entityLoaded == true) {
                    this.setState({refreshing:false})
                }
                this.props.errorToggle("Error: Failed to reload detail data. Error message: " + result.responseText);
            }.bind(this),
        });    
        //entry load
        $.ajax({
            type: 'get',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.id + '/' + entryType,
            success: function(result) {
                if (this.isMounted()) {
                    var entryResult = result.records;
                    this.setState({showEntryData:true, entryLoaded:true, entryData:entryResult, runWatcher:true})
                    this.Watcher();
                    if (this.state.eventLoaded == true && this.state.entryLoaded == true && this.state.entityLoaded == true) {
                        this.setState({refreshing:false});
                    } 
                }
            }.bind(this),
            error: function(result) {
                this.setState({showEntryData:true, entryLoaded:true})
                if (this.state.eventLoaded == true && this.state.entryLoaded == true && this.state.entityLoaded == true) {
                    this.setState({refreshing:false});
                } 
                this.props.errorToggle("Error: Failed to reload entry data. Error message: " + result.responseText);
            }
        });
        //entity load
        $.ajax({
            type: 'get',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.id + '/entity',
            success: function(result) {
                if (this.isMounted()) {
                    var entityResult = result.records;
                    this.setState({showEntityData:true, entityLoaded:true, entityData:entityResult})
                    var waitForEntry = {
                        waitEntry: function() {
                            if(this.state.entryLoaded == false && alertgroupforentity === false){
                                setTimeout(waitForEntry.waitEntry,50);
                            } else {
                                alertgroupforentity = false;
                                setTimeout(function(){AddFlair.entityUpdate(entityResult,this.flairToolbarToggle,this.props.type,this.linkWarningToggle,this.props.id)}.bind(this));
                                if (this.state.eventLoaded == true && this.state.entryLoaded == true && this.state.entityLoaded == true) {
                                    this.setState({refreshing:false});
                                }
                            }
                        }.bind(this)
                    };
                    waitForEntry.waitEntry(); 
                }
            }.bind(this),
            error: function(result) {
                this.setState({showEntityData:true})
                if (this.state.eventLoaded == true && this.state.entryLoaded == true && this.state.entityLoaded == true) {
                    this.setState({refreshing:false});
                } 
                this.props.errorToggle("Error: Failed to reload entity data.");
            }.bind(this)
        });
        //error popup if an error occurs
        if (_type!= undefined && _message != undefined) {
            this.props.errorToggle(_message);
        }
    },
    flairToolbarToggle: function(id,value,type,entityoffset,entityobj){
        this.setState({flairToolbar:true,entityid:id,entityvalue:value,entitytype:type,entityoffset:entityoffset, entityobj:entityobj})
    },
    flairToolbarOff: function() {
        if (this.isMounted()) {
            var newEntityDetailKey = this.state.entityDetailKey + 1;
            this.setState({flairToolbar:false, entityDetailKey:newEntityDetailKey})
        }
    },
    linkWarningToggle: function(href) {
        if (this.state.linkWarningToolbar == false) {
            this.setState({linkWarningToolbar:true,link:href})
        } else {
            this.setState({linkWarningToolbar:false})
        }
    },
    viewedbyfunc: function(headerData) {
        var viewedbyarr = [];
        if (headerData != null) {
            for (var prop in headerData.view_history) {
                viewedbyarr.push(prop);
            };
        }
        return viewedbyarr;
    },
    entryToggle: function() {
        if (this.state.entryToolbar == false) {
            this.setState({entryToolbar:true})
        } else {
            this.setState({entryToolbar:false})
            //click refresh detail button on screen to refresh data while the tinymce window was open since it held back updates of the DOM
            //hold off on refresh as the tinymce preventing update is currently commented out
            /*if ($('#refresh-detail')) {
                $('#refresh-detail').click();
            }*/
        }
    },
    deleteToggle: function() {
        if (this.state.deleteToolbar == false) {
            this.setState({deleteToolbar:true})
        } else {
            this.setState({deleteToolbar:false})
        } 
    },
    changeHistoryToggle: function() {
        if (this.state.changeHistoryToolbar == false) {
            this.setState({changeHistoryToolbar:true});
        } else {
            this.setState({changeHistoryToolbar:false});
        }
    },
    viewedByHistoryToggle: function() {
        if (this.state.viewedByHistoryToolbar == false) {
            this.setState({viewedByHistoryToolbar:true});
        } else {
            this.setState({viewedByHistoryToolbar:false});
        }
    },
    permissionsToggle: function() {
        if (this.state.permissionsToolbar == false) {
            this.setState({permissionsToolbar:true});
        } else {
            this.setState({permissionsToolbar:false});
        }
    },
    entitiesToggle: function() {
        if (this.state.entitiesToolbar == false) {
            this.setState({entitiesToolbar:true});
        } else {
            this.setState({entitiesToolbar:false});
        }
    },
    promoteToggle: function() {
        if (this.state.promoteToolbar == false) {
            this.setState({promoteToolbar:true});
        } else {
            this.setState({promoteToolbar:false});
        }
    },
    guideToggle: function() {
        window.open('#/guide/' + this.state.guideID);
    },
    fileUploadToggle: function() {
        if (this.state.fileUploadToolbar == false) {
            this.setState({fileUploadToolbar:true})
        } else {
            this.setState({fileUploadToolbar:false})
        }
    },
    titleCase: function(string) {
        var newstring = string.charAt(0).toUpperCase() + string.slice(1)
        return (
            newstring
        )
    },
    alertSelected: function(aIndex,aID,aType,aStatus){
        this.setState({alertSelected:true,aIndex:aIndex,aID:aID,aType:aType,aStatus:aStatus})
    },
    sourceToggle: function() {
        $.ajax({
            type: 'GET',
            url: '/scot/api/v2/alertgroup/'+this.props.id
        }).success(function(response){
            var win = window.open('/libs/viewSource.html') //, '_blank')
            var html =  response.body;
            var plain = response.body_plain;
            win.onload = function() {   
            if(html != undefined){
                $(win.document).find('#html').text(html)
            } else {
                $(win.document).find('.html').remove() }
            if(plain != undefined) {
                $(win.document).find('#plain').text(plain)
            }
            else {
                $(win.document).find('.plain').remove() }
            }
        })
    },
    Watcher: function() {
        if(this.props.type != 'alertgroup') {
            $('iframe').each(function(index,ifr) {
            //requestAnimationFrame waits for the frame to be rendered (allowing the iframe to fully render before excuting the next bit of code!!! 
                ifr.contentWindow.requestAnimationFrame( function() {
                    if(ifr.contentDocument != null) {
                        var arr = [];
                        //arr.push(this.props.type);
                        arr.push(this.checkFlairHover);
                        $(ifr).off('mouseenter');
                        $(ifr).off('mouseleave');
                        $(ifr).on('mouseenter', function(v,type) {
                            var intervalID = setInterval(this[0], 50, ifr);// this.flairToolbarToggle, type, this.props.linkWarningToggle, this.props.id);
                            $(ifr).data('intervalID', intervalID);
                            console.log('Now watching iframe ' + intervalID);
                        }.bind(arr));
                        $(ifr).on('mouseleave', function() {
                            var intervalID = $(ifr).data('intervalID');
                            window.clearInterval(intervalID);
                            console.log('No longer watching iframe ' + intervalID);
                        }); 
                    }
                }.bind(this));
            }.bind(this))
        } else {
            $('#detail-container').find('a, .entity').not('.not_selectable').each(function(index,tr) {
                $(tr).off('mousedown');
                $(tr).on('mousedown', function(index) { 
                    var thing = index.target;
                    if ($(thing)[0].className == 'extras') { thing = $(thing)[0].parentNode}; //if an extra is clicked reference the parent element
                    if ($(thing).attr('url')) {  //link clicked
                        var url = $(a).attr('url');
                        this.linkWarningToggle(url);
                    } else { //entity clicked
                        var entityid = $(thing).attr('data-entity-id');
                        var entityvalue = $(thing).attr('data-entity-value');
                        var entityoffset = $(thing).offset();                                      
                        var entityobj = $(thing);
                        this.flairToolbarToggle(entityid, entityvalue, 'entity', entityoffset, entityobj);
                    }
                }.bind(this))
            }.bind(this))
        };
    },
    checkFlairHover: function(ifr) {
        function returnifr() {
            return ifr;
        }
        if(this.props.type != 'alertgroup') {
            if(ifr.contentDocument != null) {
                $(ifr).contents().find('.entity').each(function(index, entity) {
                    if($(entity).css('background-color') == 'rgb(255, 0, 0)') {
                        $(entity).data('state', 'down');
                    } else if ($(entity).data('state') == 'down') {
                        $(entity).data('state', 'up');
                        var entityid = $(entity).attr('data-entity-id');
                        var entityvalue = $(entity).attr('data-entity-value');
                        var entityobj = $(entity);
                        var ifr = returnifr();
                        var entityoffset = {top: $(entity).offset().top+$(ifr).offset().top, left: $(entity).offset().left+$(ifr).offset().left}
                        this.flairToolbarToggle(entityid,entityvalue,'entity',entityoffset, entityobj)
                    }
                }.bind(this));
            }
            if(ifr.contentDocument != null) {
                $(ifr).contents().find('a').each(function(index,a) {
                    if($(a).css('color') == 'rgb(255, 0, 0)') {
                        $(a).data('state','down');
                    } else if ($(a).data('state') == 'down') {
                        $(a).data('state','up');
                        var url = $(a).attr('url');
                        this.linkWarningToggle(url);
                    }
                }.bind(this));
            }
        } 
    },
    summaryUpdate: function() {
        this.forceUpdate();
    },
    scrollTo: function() {
        if (this.props.taskid != undefined) { 
            $('.entry-wrapper').scrollTop($('.entry-wrapper').scrollTop() + $('#iframe_'+this.props.taskid).position().top -30)
        }
    },
    guideRedirectToAlertListWithFilter: function() {
        RegExp.escape = function(text) {
              return text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&");
        };
        //column, string, clearall (bool), type
        this.props.handleFilter(null,null,true,'alertgroup');
        this.props.handleFilter('subject', RegExp.escape(this.state.headerData.applies_to[0]), false, "alertgroup");
        window.open('#/alertgroup/');
    },
    showSignatureOptionsToggle: function() {
        if (this.state.showSignatureOptions == false) {
            this.setState({showSignatureOptions: true});
        } else {
            this.setState({showSignatureOptions: false});
        }
    },
    render: function() {
        var headerData = this.state.headerData;         
        var viewedby = this.viewedbyfunc(headerData);
        var type = this.props.type;
        var subjectType = this.titleCase(this.props.type);  //in signatures we're using the key "name"
        var id = this.props.id; 
        return (
            <div> {this.state.isNotFound ? <h1>No record found.</h1> :
            <div>
                <div id="header">
                    <div id="NewEventInfo" className="entry-header-info-null">
                        <div className='details-subject' style={{display: 'inline-flex',paddingLeft:'5px'}}>
                            {this.state.showEventData ? <EntryDataSubject data={this.state.headerData} subjectType={subjectType} type={type} id={this.props.id} updated={this.updated} />: null}
                            {this.state.refreshing ? <span style={{color:'lightblue'}}>Refreshing Data...</span> :null }
                            {this.state.loading ? <span style={{color:'lightblue'}}>Loading...</span> :null}    
                        </div> 
                        <div className='details-table toolbar'>
                            <table>
                                <tbody>
                                    <tr>
                                        <th></th>
                                        <td><div style={{marginLeft:'5px'}}>{this.state.showEventData ? <EntryDataStatus data={this.state.headerData} id={id} type={type} updated={this.updated} />: null}</div></td>
                                        {(type != 'entity') ?
                                            <th>Owner: </th> 
                                        :
                                            null
                                        }
                                        {(type != 'entity') ? 
                                            <td><span>{this.state.showEventData ? <Owner key={id} data={this.state.headerData.owner} type={type} id={id} updated={this.updated} errorToggle={this.props.errorToggle}/>: null}</span></td> 
                                        :
                                            null 
                                        }
                                        {(type != 'entity') ?
                                            <th>Updated: </th>
                                        :
                                            null
                                        }
                                        {(type != 'entity') ?
                                            <td><span id='event_updated'>{this.state.showEventData ? <EntryDataUpdated data={this.state.headerData.updated} /> : null}</span></td>
                                        :
                                            null
                                        }
                                        {(type == 'event' || type == 'incident') && this.state.showEventData ? <th>Promoted From:</th> : null}
                                        {(type == 'event' || type == 'incident') && this.state.showEventData ? <PromotedData data={this.state.headerData.promoted_from} type={type} id={id} /> : null}
                                        {(type != 'entity') && this.state.showEventData ? <Tag data={this.state.tagData} id={id} type={type} updated={this.updated}/> : null}
                                        {(type != 'entity') && this.state.showEventData ? <Source data={this.state.sourceData} id={id} type={type} updated={this.updated} /> : null }
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                    <Notification ref="notificationSystem" /> 
                    {this.state.linkWarningToolbar ? <LinkWarning linkWarningToggle={this.linkWarningToggle} link={this.state.link}/> : null}
                    {this.state.viewedByHistoryToolbar ? <ViewedByHistory viewedByHistoryToggle={this.viewedByHistoryToggle} id={id} type={type} subjectType={subjectType} viewedby={viewedby}/> : null}
                    {this.state.changeHistoryToolbar ? <ChangeHistory changeHistoryToggle={this.changeHistoryToggle} id={id} type={type} subjectType={subjectType}/> : null} 
                    {this.state.entitiesToolbar ? <Entities entitiesToggle={this.entitiesToggle} entityData={this.state.entityData} flairToolbarToggle={this.flairToolbarToggle} flairToolbarOff={this.flairToolbarOff} /> : null}
                    {this.state.deleteToolbar ? <DeleteEvent subjectType={subjectType} type={type} id={id} deleteToggle={this.deleteToggle} updated={this.updated} /> :null}
                    {this.state.showEventData ? <SelectedHeaderOptions type={type} subjectType={subjectType} id={id} status={this.state.headerData.status} promoteToggle={this.promoteToggle} permissionsToggle={this.permissionsToggle} entryToggle={this.entryToggle} entitiesToggle={this.entitiesToggle} changeHistoryToggle={this.changeHistoryToggle} viewedByHistoryToggle={this.viewedByHistoryToggle} deleteToggle={this.deleteToggle} updated={this.updated} alertSelected={this.state.alertSelected} aIndex={this.state.aIndex} aType={this.state.aType} aStatus={this.state.aStatus} flairToolbarToggle={this.flairToolbarToggle} flairToolbarOff={this.flairToolbarOff} sourceToggle={this.sourceToggle} guideID={this.state.guideID} subjectName={this.state.headerData.subject} fileUploadToggle={this.fileUploadToggle} fileUploadToolbar={this.state.fileUploadToolbar} guideRedirectToAlertListWithFilter={this.guideRedirectToAlertListWithFilter} showSignatureOptionsToggle={this.showSignatureOptionsToggle}/> : null} 
                    {this.state.permissionsToolbar ? <SelectedPermission updateid={id} id={id} type={type} permissionData={this.state.headerData} permissionsToggle={this.permissionsToggle} updated={this.updated}/> : null}
                </div>
                {this.state.showEventData && type != 'entity' ? <SelectedEntry id={id} type={type} entryToggle={this.entryToggle} updated={this.updated} entryData={this.state.entryData} entityData={this.state.entityData} headerData={this.state.headerData} showEntryData={this.state.showEntryData} showEntityData={this.state.showEntityData} alertSelected={this.alertSelected} summaryUpdate={this.summaryUpdate} flairToolbarToggle={this.flairToolbarToggle} flairToolbarOff={this.flairToolbarOff} linkWarningToggle={this.linkWarningToggle} entryToolbar={this.state.entryToolbar} isAlertSelected={this.state.alertSelected} aType={this.state.aType} aID={this.state.aID} alertPreSelectedId={this.props.alertPreSelectedId} errorToggle={this.props.errorToggle} fileUploadToggle={this.fileUploadToggle} fileUploadToolbar={this.state.fileUploadToolbar} showSignatureOptions={this.state.showSignatureOptions}/> : null}
                {this.state.showEventData && type == 'entity' ? <EntityDetail entityid={id} entitytype={'entity'} id={id} type={'entity'} fullScreen={true} errorToggle={this.props.errorToggle} linkWarningToggle={this.linkWarningToggle}/> : null} 
                {this.state.flairToolbar ? <EntityDetail key={this.state.entityDetailKey} flairToolbarToggle={this.flairToolbarToggle} flairToolbarOff={this.flairToolbarOff} entityid={this.state.entityid} entityvalue={this.state.entityvalue} entitytype={this.state.entitytype} type={this.props.type} id={this.props.id} errorToggle={this.props.errorToggle} entityoffset={this.state.entityoffset} entityobj={this.state.entityobj} linkWarningToggle={this.linkWarningToggle}/> : null}    
                </div>
            }
            </div>
        )
    }
});

var EntryDataUpdated = React.createClass({
    render: function() {
        var data = this.props.data;
        return (
            <div><ReactTime value={data * 1000} format="MM/DD/YY hh:mm:ss a" /></div>
        )
    }
});

var EntryDataStatus = React.createClass({
    getInitialState: function() {
        return {
            buttonStatus:this.props.data.status,
            key: this.props.id
        }
    },
    componentDidMount: function() {
        //Adds open/close hot keys for alertgroup
        if (this.props.type == 'alertgroup') {
            $('#landscape-list-view').keydown(function(event){
                //prevent from working when in input
                if ($('input').is(':focus')) {return};
                //check for character "o" for 79 or "c" for 67
                if (this.state.buttonStatus != 'promoted') {
                    if (event.keyCode == 79 && (event.ctrlKey != true && event.metaKey != true)) {
                        this.statusAjax('open');
                    } else if (event.keyCode == 67 && (event.ctrlKey != true && event.metaKey != true)) {
                        this.statusAjax('closed');
                    }
                }
            }.bind(this))
        }
    },
    componentWillUnmount: function() {
        $('#landscape-list-view').unbind('keydown');
    },
    componentWillReceiveProps: function() {
        this.setState({buttonStatus:this.props.data.status});
    },
    /*eventStatusToggle: function () {
        if (this.state.buttonStatus == 'open') {
            this.statusAjax('closed');
        } else if (this.state.buttonStatus == 'closed') {
            this.statusAjax('open');
        } 
    },*/
    trackAll: function() {
        this.statusAjax('tracked');
    },
    untrackAll: function() {
        this.statusAjax('untracked');
    },
    closeAll: function() {
        this.statusAjax('closed');
    },
    openAll: function() {
        this.statusAjax('open');
    },
    enableAll: function() {
        this.statusAjax('enabled');
    },
    disableAll: function() {
        this.statusAjax('disabled');
    },
    statusAjax: function(newStatus) {
        console.log(newStatus);
        var json = {'status':newStatus};
        $.ajax({
            type: 'put',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.id,
            data: JSON.stringify(json),
            contentType: 'application/json; charset=UTF-8',
            success: function(data) {
                console.log('success status change to: ' + data);
            }.bind(this),
            error: function() {
                this.props.updated('error','Failed to change status');
            }.bind(this)
        });
    },
    render: function() { 
        var buttonStyle = '';
        var open = '';
        var closed = '';
        var promoted = '';
        var title = '';
        var classStatus = '';
        var href;
        if (this.state.buttonStatus == 'open' || this.state.buttonStatus == 'disabled' || this.state.buttonStatus == 'untracked') {
            buttonStyle = 'danger';
            classStatus = 'alertgroup_open' 
        } else if (this.state.buttonStatus == 'closed' || this.state.buttonStatus == 'enabled' || this.state.buttonStatus == 'tracked') {
            buttonStyle = 'success';
            classStatus = 'alertgroup_closed'
        } else if (this.state.buttonStatus == 'promoted') {
            buttonStyle = 'default'
            classStatus = 'alertgroup_promoted'
        };

        if (this.props.type == 'alertgroup') {
            open = this.props.data.open_count;
            closed = this.props.data.closed_count;
            promoted = this.props.data.promoted_count;
            title = open + ' / ' + closed + ' / ' + promoted;
        }

        if (this.props.type == 'event') {
            href = '/#/incident/' + this.props.data.promotion_id;
        } else if (this.props.type == 'intel') {
            href = '/#/event/' + this.props.data.promotion_id;
        }
        
        if (this.props.type == 'guide' || this.props.type == 'intel') {
            return(<div/>)
        } else if (this.props.type == 'alertgroup') {
            return (
                <ButtonToolbar>
                    <OverlayTrigger placement='top' overlay={<Popover id={this.props.id}>open/closed/promoted alerts</Popover>}>
                        <DropdownButton bsSize='xsmall' bsStyle={buttonStyle} title={title} id="dropdown" className={classStatus}>
                            <MenuItem eventKey='1' onClick={this.openAll} bsSize='xsmall'><b>Open</b> All Alerts</MenuItem>
                            <MenuItem eventKey='2' onClick={this.closeAll}><b>Close</b> All Alerts</MenuItem>
                        </DropdownButton>
                    </OverlayTrigger>
                </ButtonToolbar>
            )
        } else if (this.props.type == 'incident') {
            return (
                <DropdownButton bsSize='xsmall' bsStyle={buttonStyle} id="event_status" className={classStatus} style={{fontSize: '14px'}} title={this.state.buttonStatus}>
                    <MenuItem eventKey='1' onClick={this.openAll}>Open Incident</MenuItem>
                    <MenuItem eventKey='2' onClick={this.closeAll}>Close Incident</MenuItem>
                </DropdownButton>
           ) 
        } else if (this.props.type == 'signature') {
            return ( 
                <DropdownButton bsSize='xsmall' bsStyle={buttonStyle} id="event_status" className={classStatus} style={{fontSize: '14px'}} title={this.state.buttonStatus}> 
                    <MenuItem eventKey='1' onClick={this.enableAll}>Enable Signature</MenuItem> 
                    <MenuItem eventKey='2' onClick={this.disableAll}>Disable Signature</MenuItem> 
                </DropdownButton>
            )
        } else if (this.props.type == 'entity') {
            return ( 
                <DropdownButton bsSize='xsmall' bsStyle={buttonStyle} id="event_status" className={classStatus} style={{fontSize: '14px'}} title={this.state.buttonStatus}> 
                    <MenuItem eventKey='1' onClick={this.trackAll}>Track</MenuItem> 
                    <MenuItem eventKey='2' onClick={this.untrackAll}>Untracked</MenuItem> 
                </DropdownButton>
            )
        } else {
            return (
                <div>
                    {this.state.buttonStatus == 'promoted' ? <a href={href} role='button' className={'btn btn-warning'}>{this.state.buttonStatus}</a>:
                        <DropdownButton bsSize='xsmall' bsStyle={buttonStyle} id="event_status" className={classStatus} style={{fontSize: '14px'}} title={this.state.buttonStatus}>
                            <MenuItem eventKey='1' onClick={this.openAll}>Open</MenuItem>
                            <MenuItem eventKey='2' onClick={this.closeAll}>Close</MenuItem>
                        </DropdownButton>
                    }
                </div>
            )
        }
    }
});

var EntryDataSubject = React.createClass({
    getInitialState: function() {
        var keyName = 'subject';
        var value = this.props.data.subject;
        if (this.props.type == 'signature') {
            keyName = 'name';
            value = this.props.data.name;
        } else if (this.props.type == 'entity') {
            keyName = 'value';
            value = this.props.data.value;
        }
        return {
            value:value,
            width:'',
            keyName: keyName,
        }
    },
    handleChange: function(event) {
        if (event != null ) {
            var keyName = this.state.keyName
            var json = {[keyName]:event.target.value};
            var newValue = event.target.value;
            $.ajax({
                type: 'put',
                url: 'scot/api/v2/' + this.props.type + '/' + this.props.id,
                data: JSON.stringify(json),
                contentType: 'application/json; charset=UTF-8',
                success: function(data) {
                    console.log('success: ' + data);
                    this.setState({value:newValue});
                    this.calculateWidth(newValue);
                }.bind(this),
                error: function() { 
                    this.props.updated('error','Failed to update the subject/name');
                }.bind(this)
            });
        }
    },
    componentDidMount: function() {
       this.calculateWidth(this.state.value); 
    },
    handleEnterKey: function(e) {
        if (e.key == 'Enter') {
            this.handleChange(e);
        }
    },
    calculateWidth: function(input) {
        var newWidth;
        $('#invisible').html($('<span></span>').text(input));
        newWidth = ($('#invisible').width() + 25) + 'px';
        this.setState({width:newWidth});
    },
    render: function() {
        //only disable the subject editor on an entity with a non-blank subject as editing it could damage flair.
        var isDisabled = false;
        if (this.props.type == 'entity' && this.state.value != '') {
            isDisabled = true;
        }
        return (
            <div>{this.props.subjectType} {this.props.id}: <input type='text' defaultValue={this.state.value} onKeyPress={this.handleEnterKey} onBlur={this.handleChange} style={{width:this.state.width,lineHeight:'normal'}} disabled={isDisabled} /></div>
        )
    }
});

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

var PromotedData = React.createClass({
    getInitialState: function() {
        return {
            showAllPromotedDataToolbar: false
        }
    },
    showAllPromotedDataToggle: function() {
        if (this.state.showAllPromotedDataToolbar == false) {
            this.setState({showAllPromotedDataToolbar: true});  
        } else {
            this.setState({showAllPromotedDataToolbar: false});
        }
    },
    render: function() {
        var promotedFromType = null;
        var fullarr = [];
        var shortarr = [];
        var shortforlength = 3;
        if (this.props.type == 'event') {
            promotedFromType = 'alert'
        } else if (this.props.type == 'incident') {
            promotedFromType = 'event'
        }
        //makes large array for modal
        for (var i=0; i < this.props.data.length; i++) {
            if (i > 0) {fullarr.push(<div> , </div>)}
            var link = '/' + promotedFromType + '/' + this.props.data[i];
            fullarr.push(<div key={this.props.data[i]}><Link to={link}>{this.props.data[i]}</Link></div>)
        }
        //makes small array for quick display in header
        if (this.props.data.length < 3 ) {
            shortforlength = this.props.data.length;
        }
        for (var i=0; i < shortforlength; i++) {
            if (i > 0) {shortarr.push(<div> , </div>)}
            var link = '/' + promotedFromType + '/' + this.props.data[i];
            shortarr.push(<div key={this.props.data[i]}><Link to={link}>{this.props.data[i]}</Link></div>)
        } 
        if (this.props.data.length > 3) {shortarr.push(<div onClick={this.showAllPromotedDataToggle}>,<a href='javascript:;'>...more</a></div>)}
        return (
            <td>
                <span id='promoted_from' style={{display:'flex'}}>{shortarr}</span> 
                {this.state.showAllPromotedDataToolbar ? <Modal isOpen={true} onRequestClose={this.showAllPromotedDataToggle} style={customStyles}>
                    <div className='modal-header'>
                        <img src='images/close_toolbar.png' className='close_toolbar' onClick={this.showAllPromotedDataToggle} />
                        <h3 id='myModalLabel'>Promoted From</h3>
                    </div>
                    <div className='modal-body promoted-from-full'>
                        {fullarr}    
                    </div>
                    <div className='modal-footer'>
                        <Button id='cancel-modal' onClick={this.showAllPromotedDataToggle}>Close</Button>
                    </div>
                </Modal> : null }
            </td>
        )
    }   
});

module.exports = SelectedHeader;
