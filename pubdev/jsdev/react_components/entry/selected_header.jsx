var React                   = require('react');
var ReactTime               = require('react-time');
var SelectedHeaderOptions   = require('./selected_header_options.jsx');
var DeleteEvent             = require('../modal/delete.jsx').DeleteEvent;
var Owner                   = require('../modal/owner.jsx');
var Entities                = require('../modal/entities.jsx');
var ChangeHistory           = require('../modal/change_history.jsx');
var ViewedByHistory         = require('../modal/viewed_by_history.jsx');
var SelectedPermission      = require('../components/permission.jsx');
var AutoAffix               = require('react-overlays/lib/AutoAffix.js');
var Affix                   = require('react-overlays/lib/Affix.js');
var Sticky                  = require('react-sticky');
var Button                  = require('react-bootstrap/lib/Button');
var ButtonToolbar           = require('react-bootstrap/lib/ButtonToolbar');
var OverlayTrigger          = require('react-bootstrap/lib/OverlayTrigger');
var Popover                 = require('react-bootstrap/lib/Popover');
var DropdownButton          = require('react-bootstrap/lib/DropdownButton');
var MenuItem                = require('react-bootstrap/lib/MenuItem');
var Modal                   = require('react-modal');
var DebounceInput           = require('react-debounce-input');
var SelectedEntry           = require('./selected_entry.jsx');
var Tag                     = require('../components/tag.jsx');
var Source                  = require('../components/source.jsx');
var Crouton                 = require('react-crouton');
var Store                   = require('../activemq/store.jsx');
var AppActions              = require('../flux/actions.jsx');
var Notification            = require('react-notification-system');
var AddFlair                = require('../components/add_flair.jsx').AddFlair;
var Watcher                 = require('../components/add_flair.jsx').Watcher;
var EntityDetail            = require('../modal/entity_detail.jsx');
var ESearch                 = require('../components/esearch.jsx');
var LinkWarning             = require('../modal/link_warning.jsx');

var SelectedHeader = React.createClass({
    getInitialState: function() {
        return {
            showEventData:false,
            headerData:null,
            showSource:false,
            sourceData:'',
            tagData:'',
            showTag:false,
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
            flairToolbar:false,
            linkWarningToolbar:false,
            refreshing:false,
            loading: false,
            sourceLoaded:false,
            eventLoaded:false,
            tagLoaded:false,
            entryLoaded:false,
            entityLoaded:false,
            alertSelected:false,
            aIndex:null,
            aType:null,
            aStatus:null,
            aID:0,
            guideID: null,
            errorDisplay: false,
            fileUploadToolbar: false,
        }
    },
    componentWillMount: function() {
        this.setState({loading:true});
    },
    componentDidMount: function() {
        //this.setState({loading:true});
        var entryType = 'entry';
        if (this.props.type == 'alertgroup') { entryType = 'alert' };
        //source load 
        $.ajax({
            type: 'get',
            url:'scot/api/v2/' + this.props.type + '/' + this.props.id + '/source',
            success:function(result) {
                var sourceResult = result.records;
                this.setState({showSource:true, sourceData:sourceResult})
                if (this.state.showSource == true && this.state.showEventData == true && this.state.showTag == true && this.state.showEntryData == true && this.state.showEntityData == true) {
                    this.setState({loading:false});        
                }
            }.bind(this),
            error: function(result) {
                this.setState({showSource:true})
                if (this.state.showSource == true && this.state.showEventData == true && this.state.showTag == true && this.state.showEntryData == true && this.state.showEntityData == true) {
                    this.setState({loading:false});        
                }
                this.errorToggle("No data returned for source lookup (404 or another network error) Error: " + result.responseText);
            }.bind(this),
        });
        //Main Type Load
        $.ajax({
            type:'get',
            url:'scot/api/v2/' + this.props.type + '/' + this.props.id,
            success:function(result) {
                var eventResult = result;
                this.setState({headerData:eventResult,showEventData:true})
                if (this.state.showSource == true && this.state.showEventData == true && this.state.showTag == true && this.state.showEntryData == true && this.state.showEntityData == true) {
                    this.setState({loading:false})
                }
            }.bind(this),
            error: function(result) {
                this.setState({showEventData:true})
                if (this.state.showSource == true && this.state.showEventData == true && this.state.showTag == true && this.state.showEntryData == true && this.state.showEntityData == true) {
                    this.setState({loading:false})
                }
                this.errorToggle("No data returned for main lookup (404 or another network error) Error: " + result.responseText);
            }.bind(this),
        });
        //tag load
        $.ajax({
            type: 'get',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.id + '/tag',
            success: function(result) {
                var tagResult = result.records;
                this.setState({showTag:true, tagData:tagResult});
                if (this.state.showSource == true && this.state.showEventData == true && this.state.showTag == true && this.state.showEntryData == true && this.state.showEntityData == true) {
                    this.setState({loading:false});
                }
            }.bind(this),
            error: function(result) {
                this.setState({showTag:true});
                if (this.state.showSource == true && this.state.showEventData == true && this.state.showTag == true && this.state.showEntryData == true && this.state.showEntityData == true) {
                    this.setState({loading:false});
                } 
                this.errorToggle("No data returned for tag lookup (404 or another network error) Error: " + result.responseText);
            }.bind(this),
        });
        //entry load
        $.ajax({
            type: 'get',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.id + '/' + entryType, 
            success: function(result) {
                var entryResult = result.records;
                this.setState({showEntryData:true, entryData:entryResult})
                Watcher.pentry(null,this.flairToolbarToggle,this.props.type,this.linkWarningToggle,this.props.id,null)
                if (this.state.showSource == true && this.state.showEventData == true && this.state.showTag == true && this.state.showEntryData == true && this.state.showEntityData == true) {
                    this.setState({loading:false});
                }
            }.bind(this),
            error: function(result) {
                this.setState({showEntryData:true})
                if (this.state.showSource == true && this.state.showEventData == true && this.state.showTag == true && this.state.showEntryData == true && this.state.showEntityData == true) {
                    this.setState({loading:false});
                }
                this.errorToggle("No data returned for entry lookup (404 or another network error) Error: " + result.responseText);
            }
        });
        //entity load
        $.ajax({
            type: 'get',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.id + '/entity',
            success: function(result) {
                var entityResult = result.records;
                this.setState({showEntityData:true, entityData:entityResult})
                var waitForEntry = {
                    waitEntry: function() {
                        if(this.state.showEntryData == false && alertgroupforentity === false) {
                            setTimeout(waitForEntry.waitEntry,50);
                        } else {
                            alertgroupforentity = false;
                            setTimeout(function(){AddFlair.entityUpdate(entityResult,this.flairToolbarToggle,this.props.type,this.linkWarningToggle,this.props.id,this.scrollTo)}.bind(this));
                            if (this.state.showSource == true && this.state.showEventData == true && this.state.showTag == true && this.state.showEntryData == true && this.state.showEntityData == true) {
                                this.setState({loading:false});        
                            }
                        }
                    }.bind(this)
                };
                waitForEntry.waitEntry();
            }.bind(this),
            error: function(result) {
                this.setState({showEntityData:true})
                if (this.state.showSource == true && this.state.showEventData == true && this.state.showTag == true && this.state.showEntryData == true && this.state.showEntityData == true) {
                    this.setState({loading:false});
                }
                this.errorToggle("No data returned for entity lookup (404 or another network error) Error: " + result.responseText);
            }.bind(this)
        });
        //guide load
        if (this.props.type == 'alertgroup') {
            $.ajax({
                type:'get',
                url: 'scot/api/v2/' + this.props.type + '/' + this.props.id + '/guide', 
                success: function(result) {
                    if (result.records[0] != undefined) {
                        var guideID = result.records[0].id;
                        this.setState({guideID: guideID});
                    } else {
                        this.setState({guideID: 0});
                    }
                }.bind(this),
                error: function(result) {
                    this.setState({guideID: null})
                    this.errorToggle("No data returned for guide lookup (404 or another network error) Error: " + reuslt.responseText);
                }.bind(this)
            });     
        }
        Store.storeKey(this.state.key);
        Store.addChangeListener(this.updated); 
        Store.storeKey('entryNotification')
    }, 
    updated: function(_type,_message) { 
        this.setState({refreshing:true, sourceLoaded:false,eventLoaded:false,tagLoaded:false,entryLoaded:false,entityLoaded:false});
        var entryType = 'entry';
        if (this.props.type == 'alertgroup') {entryType = 'alert'};
        setTimeout(function(){
            //source load
            $.ajax({
                type: 'get',
                url:'scot/api/v2/' + this.props.type + '/' + this.props.id + '/source',
                success:function(result) {
                    var sourceResult = result.records;
                    this.setState({showSource:true, sourceLoaded:true, sourceData:sourceResult})
                    if (this.state.sourceLoaded == true && this.state.eventLoaded == true && this.state.tagLoaded == true && this.state.entryLoaded == true && this.state.entityLoaded == true) {
                        this.setState({refreshing:false});
                    } 
                }.bind(this),
                error: function(result) {
                    this.setState({showSource:true, sourceLoaded:true})
                    if (this.state.sourceLoaded == true && this.state.eventLoaded == true && this.state.tagLoaded == true && this.state.entryLoaded == true && this.state.entityLoaded == true) {
                        this.setState({refreshing:false});
                    } 
                    this.errorToggle("No data returned for source lookup (404 or another network error) Error: " + result.responseText);
                }.bind(this),
            });
            //main type load
            $.ajax({
                type:'get',
                url:'scot/api/v2/' + this.props.type + '/' + this.props.id,
                success:function(result) {
                    var eventResult = result;
                    this.setState({headerData:eventResult,showEventData:true, eventLoaded:true})
                    if (this.state.sourceLoaded == true && this.state.eventLoaded == true && this.state.tagLoaded == true && this.state.entryLoaded == true && this.state.entityLoaded == true) {
                        this.setState({refreshing:false})
                    }
                }.bind(this),
                error: function(result) {
                    this.setState({showEventData:true, eventLoaded:true})
                    if (this.state.sourceLoaded == true && this.state.eventLoaded == true && this.state.tagLoaded == true && this.state.entryLoaded == true && this.state.entityLoaded == true) {
                        this.setState({refreshing:false})
                    }
                    this.errorToggle("No Data Returned (404 or another network error) Error: " + result.responseText);
                }.bind(this),
            });    
            //tag load
            $.ajax({
                type: 'get',
                url: 'scot/api/v2/' + this.props.type + '/' + this.props.id + '/tag',
                success: function(result) {
                    var tagResult = result.records;
                    this.setState({showTag:true, tagLoaded:true, tagData:tagResult});
                    if (this.state.sourceLoaded == true && this.state.eventLoaded == true && this.state.tagLoaded == true && this.state.entryLoaded == true && this.state.entityLoaded == true) {
                        this.setState({refreshing:false});
                    }
                }.bind(this),
                error: function(result) {
                    this.setState({showTag:true, tagLoaded:true});
                    if (this.state.sourceLoaded == true && this.state.eventLoaded == true && this.state.tagLoaded == true && this.state.entryLoaded == true && this.state.entityLoaded == true) {
                        this.setState({refreshing:false});
                    } 
                    this.errorToggle("No data returned for tag lookup (404 or another network error) Error: " + result.responseText);
                }.bind(this),
            });
            //entry load
            $.ajax({
                type: 'get',
                url: 'scot/api/v2/' + this.props.type + '/' + this.props.id + '/' + entryType,
                success: function(result) {
                    var entryResult = result.records;
                    this.setState({showEntryData:true, entryLoaded:true, entryData:entryResult})
                    Watcher.pentry(null,this.flairToolbarToggle,this.props.type,this.linkWarningToggle,this.props.id,null)
                    if (this.state.sourceLoaded == true && this.state.eventLoaded == true && this.state.tagLoaded == true && this.state.entryLoaded == true && this.state.entityLoaded == true) {
                        this.setState({refreshing:false});
                    } 
                }.bind(this),
                error: function(result) {
                    this.setState({showEntryData:true, entryLoaded:true})
                    if (this.state.sourceLoaded == true && this.state.eventLoaded == true && this.state.tagLoaded == true && this.state.entryLoaded == true && this.state.entityLoaded == true) {
                        this.setState({refreshing:false});
                    } 
                    this.errorToggle("No data returned for entry lookup (404 or another network error) Error: " + result.responseText);
                }
            });
            //entity load
            $.ajax({
                type: 'get',
                url: 'scot/api/v2/' + this.props.type + '/' + this.props.id + '/entity',
                success: function(result) {
                    var entityResult = result.records;
                    this.setState({showEntityData:true, entityLoaded:true, entityData:entityResult})
                    var waitForEntry = {
                        waitEntry: function() {
                            if(this.state.entryLoaded == false && alertgroupforentity === false){
                                setTimeout(waitForEntry.waitEntry,50);
                            } else {
                                alertgroupforentity = false;
                                setTimeout(function(){AddFlair.entityUpdate(entityResult,this.flairToolbarToggle,this.props.type,this.linkWarningToggle,this.props.id)}.bind(this));
                                if (this.state.sourceLoaded == true && this.state.eventLoaded == true && this.state.tagLoaded == true && this.state.entryLoaded == true && this.state.entityLoaded == true) {
                                    this.setState({refreshing:false});
                                }
                            }
                        }.bind(this)
                    };
                    waitForEntry.waitEntry();                    
                }.bind(this),
                error: function(result) {
                    this.setState({showEntityData:true})
                    if (this.state.sourceLoaded == true && this.state.eventLoaded == true && this.state.tagLoaded == true && this.state.entryLoaded == true && this.state.entityLoaded == true) {
                        this.setState({refreshing:false});
                    } 
                    this.errorToggle("No data returned for entity lookup (404 or another network error) Error: " + result.responseText);
                }.bind(this)
            });
        }.bind(this),0)
        //error popup if an error occurs
        if (_type!= undefined && _message != undefined) {
            this.errorToggle(_message);
        }
    },
    /*granular updates -- to be implemented later 
    updatedType: function() {
        this.eventRequest = $.get('scot/api/v2/' + this.props.type + '/' + this.props.id, function(result) {
            var eventResult = result;
            this.setState({showEventData:true, eventLoaded:true, headerData:eventResult})
        }.bind(this)); 
    },
    updatedSource: function() {
       this.sourceRequest = $.get('scot/api/v2/' + this.props.type + '/' + this.props.id + '/source', function(result) {
            var sourceResult = result.records;
            this.setState({showSource:true, sourceLoaded:true, sourceData:sourceResult})
       }.bind(this)); 
    },
    updatedTag: function() {
        this.tagRequest = $.get('scot/api/v2/' + this.props.type + '/' + this.props.id + '/tag', function(result) {
            var tagResult = result.records;
            this.setState({showTag:true, tagLoaded:true, tagData:tagResult});
        }.bind(this));
    },
    updatedEntry: function() {
        var entryType = 'entry';
        if (this.props.type == 'alertgroup') {entryType = 'alert'};
        this.entryRequest = $.get('scot/api/v2/' + this.props.type + '/' + this.props.id + '/' + entryType, function(result) {
            var entryResult = result.records;
            this.setState({showEntryData:true, entryLoaded:true, entryData:entryResult}) 
        }.bind(this)); 
        this.entityRequest = $.get('scot/api/v2/' + this.props.type + '/' + this.props.id + '/entity', function(result) {
            var entityResult = result.records;
            this.setState({showEntityData:true, entityLoaded:true, entityData:entityResult})
            var waitForEntry = {
                waitEntry: function() {
                    if(this.state.entryLoaded == false && alertgroupforentity === false){
                        setTimeout(waitForEntry.waitEntry,50);
                    } else {
                        alertgroupforentity = false;
                        setTimeout(function(){AddFlair.entityUpdate(entityResult,this.flairToolbarToggle,this.props.type,this.linkWarningToggle,this.props.id)}.bind(this));
                    }
                }.bind(this)
            };
            waitForEntry.waitEntry();
        }.bind(this));
     },*/
    errorToggle: function(string) {
        if (this.state.errorDisplay == false) {
            this.setState({notificationMessage:string,notificationType:'error',errorDisplay:true})
        } else {
            this.setState({errorDisplay:false})
        }
    },
    flairToolbarToggle: function(id,value,type){
        //if (this.state.flairToolbar == false) {
            this.setState({flairToolbar:true,entityid:id,entityvalue:value,entitytype:type})
        //} else {
        //    this.setState({flairToolbar:false})
        //}
    },
    flairToolbarOff: function() {
        this.setState({flairToolbar:false})
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
            for (prop in headerData.view_history) {
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
            var win = window.open('viewSource.html') //, '_blank')
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
    summaryUpdate: function() {
        this.forceUpdate();
    },
    scrollTo: function() {
        if (this.props.taskid != undefined) { 
            $('.entry-wrapper').scrollTop($('.entry-wrapper').scrollTop() + $('#iframe_'+this.props.taskid).position().top -30)
        }
    },
    render: function() {
        var headerData = this.state.headerData;         
        var viewedby = this.viewedbyfunc(headerData);
        var type = this.props.type;
        var subjectType = this.titleCase(this.props.type);
        var id = this.props.id; 
        return (
            <div>
                <div id="header">
                <div id="NewEventInfo" className="entry-header-info-null" style={{width:'100%'}}>
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
                                    <th>Owner: </th>
                                    <td><span>{this.state.showEventData ? <Owner key={id} data={this.state.headerData.owner} type={type} id={id} updated={this.updated} />: null}</span></td>
                                    <th>Updated: </th>
                                    <td><span id='event_updated' style={{color: 'white',lineHeight: '12pt', fontSize: '12pt', paddingTop:'5px'}} >{this.state.showEventData ? <EntryDataUpdated data={this.state.headerData.updated} /> : null}</span></td>
                                    {(type == 'event' || type == 'incident') && this.state.showEventData ? <th>Promoted From:</th> : null}
                                    {(type == 'event' || type == 'incident') && this.state.showEventData ? <PromotedData data={this.state.headerData.promoted_from} type={type} id={id} /> : null}
                                    
                                    <th>Tags: </th>
                                    <td>{this.state.showTag ? <Tag data={this.state.tagData} id={id} type={type} updated={this.updated}/> : null}</td>
                                    <th>Source: </th>
                                    <td>{this.state.showSource ? <Source data={this.state.sourceData} id={id} type={type} updated={this.updated} /> : null }</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
                <Notification ref="notificationSystem" /> 
                {this.state.errorDisplay ? <Crouton type={this.state.notificationType} id={Date.now()} message={this.state.notificationMessage} buttons="CLOSE MESSAGE" onDismiss={this.errorToggle}/> : null}
                {this.state.flairToolbar ? <EntityDetail flairToolbarToggle={this.flairToolbarToggle} flairToolbarOff={this.flairToolbarOff} entityid={this.state.entityid} entityvalue={this.state.entityvalue} entitytype={this.state.entitytype} type={this.props.type} id={this.props.id} errorToggle={this.errorToggle}/> : null}
                {this.state.linkWarningToolbar ? <LinkWarning linkWarningToggle={this.linkWarningToggle} link={this.state.link}/> : null}
                {this.state.viewedByHistoryToolbar ? <ViewedByHistory viewedByHistoryToggle={this.viewedByHistoryToggle} id={id} type={type} subjectType={subjectType} viewedby={viewedby}/> : null}
                {this.state.changeHistoryToolbar ? <ChangeHistory changeHistoryToggle={this.changeHistoryToggle} id={id} type={type} subjectType={subjectType}/> : null} 
                {this.state.entitiesToolbar ? <Entities entitiesToggle={this.entitiesToggle} entityData={this.state.entityData} flairToolbarToggle={this.flairToolbarToggle} flairToolbarOff={this.flairToolbarOff} /> : null}
                {this.state.deleteToolbar ? <DeleteEvent subjectType={subjectType} type={type} id={id} deleteToggle={this.deleteToggle} updated={this.updated} /> :null}
                {this.state.showEventData ? <SelectedHeaderOptions type={type} subjectType={subjectType} id={id} status={this.state.headerData.status} promoteToggle={this.promoteToggle} permissionsToggle={this.permissionsToggle} entryToggle={this.entryToggle} entitiesToggle={this.entitiesToggle} changeHistoryToggle={this.changeHistoryToggle} viewedByHistoryToggle={this.viewedByHistoryToggle} deleteToggle={this.deleteToggle} updated={this.updated} alertSelected={this.state.alertSelected} aIndex={this.state.aIndex} aType={this.state.aType} aStatus={this.state.aStatus} flairToolbarToggle={this.flairToolbarToggle} flairToolbarOff={this.flairToolbarOff} sourceToggle={this.sourceToggle} guideID={this.state.guideID} subjectName={this.state.headerData.subject} fileUploadToggle={this.fileUploadToggle} fileUploadToolbar={this.state.fileUploadToolbar}/> : null} 
                {this.state.permissionsToolbar ? <SelectedPermission updateid={id} id={id} type={type} permissionData={this.state.headerData} permissionsToggle={this.permissionsToggle} updated={this.updated}/> : null}
                </div>
                {this.state.showEventData ? <SelectedEntry id={id} type={type} entryToggle={this.entryToggle} updated={this.updated} entryData={this.state.entryData} entityData={this.state.entityData} headerData={this.state.headerData} showEntryData={this.state.showEntryData} showEntityData={this.state.showEntityData} alertSelected={this.alertSelected} summaryUpdate={this.summaryUpdate} flairToolbarToggle={this.flairToolbarToggle} flairToolbarOff={this.flairToolbarOff} linkWarningToggle={this.linkWarningToggle} entryToolbar={this.state.entryToolbar} isAlertSelected={this.state.alertSelected} aType={this.state.aType} aID={this.state.aID} alertPreSelectedId={this.props.alertPreSelectedId} errorToggle={this.errorToggle} fileUploadToggle={this.fileUploadToggle} fileUploadToolbar={this.state.fileUploadToolbar}/> : null}
            </div>
        )
    }
});

var EntryDataUpdated = React.createClass({
    render: function() {
        data = this.props.data;
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
            $(document.body).keydown(function(event){
                //prevent from working when in input
                if ($('input').is(':focus')) {return};
                //check for character "o" for 79 or "c" for 67
                if (this.state.buttonStatus != 'promoted') {
                    if (event.keyCode == 79) {
                        this.statusAjax('open');
                    } else if (event.keyCode == 67) {
                        this.statusAjax('closed');
                    }
                }
            }.bind(this))
        }
    },
    componentWillReceiveProps: function() {
        this.setState({buttonStatus:this.props.data.status});
    },
    eventStatusToggle: function () {
        if (this.state.buttonStatus == 'open') {
            this.statusAjax('closed');
        } else if (this.state.buttonStatus == 'closed') {
            this.statusAjax('open');
        } 
    },
    closeAll: function() {
        this.statusAjax('closed');
    },
    openAll: function() {
        this.statusAjax('open');
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
        if (this.state.buttonStatus == 'open') {
            buttonStyle = 'danger';
            classStatus = 'alertgroup_open' 
        } else if (this.state.buttonStatus == 'closed') {
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
        if (this.props.type == 'guide') {
            return(<div/>)
        } else {
            return (
                <div>
                    {this.props.type == 'alertgroup' ? <ButtonToolbar>
                        <OverlayTrigger trigger='hover' placement='top' overlay={<Popover id={this.props.id}>open/closed/promoted alerts</Popover>}>
                            <DropdownButton bsSize='xsmall' bsStyle={buttonStyle} title={title} id="dropdown" className={classStatus}>
                                <MenuItem eventKey='1' onClick={this.openAll} bsSize='xsmall'><b>Open</b> All Alerts</MenuItem>
                                <MenuItem eventKey='2' onClick={this.closeAll}><b>Close</b> All Alerts</MenuItem>
                            </DropdownButton>
                        </OverlayTrigger></ButtonToolbar> : <DropdownButton bsSize='xsmall' bsStyle={buttonStyle} id="event_status" className={classStatus} style={{fontSize: '14px'}} title={this.state.buttonStatus}>
                            <MenuItem eventKey='1' onClick={this.openAll}>Open Event</MenuItem>
                            <MenuItem eventKey='2' onClick={this.closeAll}>Close Event</MenuItem>
                        </DropdownButton> }
                </div>
            )
        }
    }
});

var EntryDataSubject = React.createClass({
    getInitialState: function() {
        return {
            value:this.props.data.subject,
            updatedSubject: false,
        }
    },
    componentWillReceiveProps: function() {
        if (this.state.updatedSubject != true) {
            this.setState({value:this.props.data.subject});
        }
    },
    handleChange: function(event) {
        this.setState({value:event.target.value});
        if (this.state.value != this.props.data.subject) {
            var json = {'subject':this.state.value}
            $.ajax({
                type: 'put',
                url: 'scot/api/v2/' + this.props.type + '/' + this.props.id,
                data: JSON.stringify(json),
                contentType: 'application/json; charset=UTF-8',
                success: function(data) {
                    console.log('success: ' + data);
                    this.setState({updatedSubject: true});
                    AppActions.updateItem(this.props.id,'headerUpdate'); 
                }.bind(this),
                error: function() { 
                    this.props.updated('error','Failed to update the subject');
                }.bind(this)
            });
        }
    },
    render: function() {
        //if this is rewritten you can built it from scratch by using an input box with onBlur={handleChange}
        if (this.state.value != undefined) {
            var subjectLength = this.state.value.length;
            var subjectWidth = subjectLength * 14;
            if (subjectWidth <= 200) {
                subjectWidth = 200;
            }
        } else {
            var subjectWidth = 1000;
        }
        return (
            <div>{this.props.subjectType} {this.props.id}: <DebounceInput debounceTimeout={1000} forceNotifyOnBlur={true} type='text' value={this.state.value} onChange={this.handleChange} style={{width:subjectWidth+'px',lineHeight:'normal'}} /></div>
        )
    }
});

var PromotedData = React.createClass({
    render: function() {
        var promotedFromType = null;
        if (this.props.type == 'event') {
            promotedFromType = 'alert'
        } else if (this.props.type == 'incident') {
            promotedFromType = 'event'
        }
        var arr = [];
        for (i=0; i < this.props.data.length; i++) {
            if (i > 0) {arr.push(<div> , </div>)}
            var link = '/#/' + promotedFromType + '/' + this.props.data[i];
            arr.push(<div><a href={link}>{this.props.data[i]}</a></div>)
        }
        return (
           <td><span id='promoted_from' style={{color: 'white', lineHeight: '12pt', fontSize: '12pt', paddingTop:'5px', display:'flex'}}>{arr}</span></td> 
        )
    }   
});

module.exports = SelectedHeader;
