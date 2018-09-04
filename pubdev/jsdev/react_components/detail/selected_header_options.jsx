let React           = require( 'react' );
let ButtonGroup     = require( 'react-bootstrap/lib/ButtonGroup.js' );
let Button          = require( 'react-bootstrap/lib/Button.js' );
let Promote         = require( '../components/promote.jsx' );
let Marker          = require( '../components/marker.jsx' ).default;
let TrafficLightProtocol = require( '../components/traffic_light_protocol.jsx' );

let SelectedHeaderOptions = React.createClass( {
    getInitialState: function() {
        return {
            globalFlairState: true,
            // promoteRemaining: null,
        };
    },
    toggleFlair: function() {
        let newGlobalFlairState = !this.state.globalFlairState;
        this.props.toggleFlair();
        $( 'iframe' ).each( function( index, ifr ) {
            if( ifr.contentDocument != null ) {
                let ifrContents = $( ifr ).contents();
                let off = ifrContents.find( '.entity-off' );
                let on = ifrContents.find( '.entity' );
                if ( this.state.globalFlairState == false ) {
                    ifrContents.find( '.extras' ).show();
                    ifrContents.find( '.flair-off' ).hide();
                    off.each( function( index, entity ) {
                        $( entity ).addClass( 'entity' );
                        $( entity ).removeClass( 'entity-off' );
                    } );
                } else {
                    ifrContents.find( '.extras' ).hide();
                    ifrContents.find( '.flair-off' ).show();
                    on.each( function( index, entity ) {
                        $( entity ).addClass( 'entity-off' );
                        $( entity ).removeClass( 'entity' );
                    } );
                }
            }
        }.bind( this ) );
        this.setState( {globalFlairState: newGlobalFlairState} );

    },
    //All methods containing alert are only used by selected_entry when viewing an alertgroupand interacting with an alert.
    alertOpenSelected: function() {
        let array = [];
        $( 'tr.selected' ).each( function( index,tr ) {
            let id = $( tr ).attr( 'id' );
            array.push( {id:id,status:'open'} );
        }.bind( this ) );
        let data = JSON.stringify( {alerts:array} );

        this.props.ToggleProcessingMessage( true );

        $.ajax( {
            type:'put',
            url: '/scot/api/v2/'+this.props.type + '/' +this.props.id,
            data: data,
            contentType: 'application/json; charset=UTF-8',
            success: function( ){
                console.log( 'success' );
                this.props.ToggleProcessingMessage( false );
            }.bind( this ),
            error: function( data ) {
                this.props.errorToggle( 'failed to open selected alerts', data );
                this.props.ToggleProcessingMessage( false );
            }.bind( this )
        } );
    },

    alertCloseSelected: function() {
        let time = Math.round( new Date().getTime() / 1000 );
        let array = [];
        $( 'tr.selected' ).each( function( index,tr ) {
            let id = $( tr ).attr( 'id' );
            array.push( {id:id,status:'closed', closed:time} );
        }.bind( this ) );
        let data = JSON.stringify( {alerts:array} );

        this.props.ToggleProcessingMessage( true );

        $.ajax( {
            type:'put',
            url: '/scot/api/v2/'+this.props.type + '/'+ this.props.id,
            data: data,
            contentType: 'application/json; charset=UTF-8',
            success: function( ){
                console.log( 'success' );
                this.props.ToggleProcessingMessage( false );
            }.bind( this ),
            error: function( data ) {
                this.props.errorToggle( 'failed to close selected alerts', data );
                this.props.ToggleProcessingMessage( false );
            }.bind( this )
        } );
    },

    alertPromoteSelected: function() {
        let data = JSON.stringify( {promote:'new'} );
        let array = [];
        $( 'tr.selected' ).each( function( index,tr ) {
            let id = $( tr ).attr( 'id' );
            array.push( id );
        }.bind( this ) );

        this.props.ToggleProcessingMessage( true );
        // this.setState( {promoteRemaining:array.length} );

        //Start by promoting the first one in the array
        $.ajax( {
            type:'put',
            url: '/scot/api/v2/alert/'+array[0],
            data: data,
            contentType: 'application/json; charset=UTF-8',
            success: function( response ){
                //With the entry number, promote the others into the existing event
                let promoteTo = {
                    promote:response.pid
                };

                // if ( this.state.promoteRemaining > 0 ){
                //     this.setState( {promoteRemaining: array.length -1 } );
                // }

                for ( let i=0; i < array.length; i++ ) {

                    $.ajax( {
                        type:'put',
                        url: '/scot/api/v2/alert/'+array[i],
                        data: JSON.stringify( promoteTo ),
                        contentType: 'application/json; charset=UTF-8',
                        success: function( ){
                            console.log( 'success' );
                            // if ( this.state.promoteRemaining > 0 ){
                            //     this.setState( {promoteRemaining: array.length -1 } );
                            // }

                            if ( i+1 == array.length ) {
                                this.props.ToggleProcessingMessage( false );
                            }

                        }.bind( this ),
                        error: function( data ) {
                            this.props.errorToggle( 'failed to promoted selected alerts', data );
                            // if ( this.state.promoteRemaining > 0 ){
                            //     this.setState( {promoteRemaining: array.length -1 } );
                            // }
                        }.bind( this )
                    } );
                }
            }.bind( this ),
            error: function( data ) {
                this.props.errorToggle( 'failed to promoted selected alerts', data );
            }.bind( this )
        } );

    },
    /*Future use?
    alertUnpromoteSelected: function() {
        var data = JSON.stringify({unpromote:this.props.aIndex})
        var array = [];
        $('tr.selected').each(function(index,tr) {
            var id = $(tr).attr('id');
            array.push(id);
        }.bind(this));
        for (i=0; i < array.length; i++) {
            $.ajax({
                type:'put',
                url: '/scot/api/v2/alert/'+array[i],
                data: data,
                contentType: 'application/json; charset=UTF-8',
                success: function(response){
                    console.log('success');
                }.bind(this),
                error: function() {
                    console.log('failure');
                }.bind(this)
            })
        }
    },*/
    alertSelectExisting: function() {
        let text = prompt( 'Please Enter Event ID to promote into' );
        let array = [];
        if ( text != '' && text != null ){
            $( 'tr.selected' ).each( function( index,tr ) {
                let id = $( tr ).attr( 'id' );
                array.push( id );
            }.bind( this ) );
            for ( let i=0; i < array.length; i++ ) {
                if ( $.isNumeric( text ) ) {
                    let data = {
                        promote:parseInt( text )
                    };
                    $.ajax( {
                        type: 'PUT',
                        url: '/scot/api/v2/alert/' + array[i],
                        data: JSON.stringify( data ),
                        contentType: 'application/json; charset=UTF-8',
                        success: function( ){
                            if( $.isNumeric( text ) ){
                                window.location = '#/event/' + text;
                            }
                        }.bind( this ),
                        error: function( data ) {
                            this.props.errorToggle( 'failed to promote into existing event', data );
                        }.bind( this )
                    } );
                } else {
                    prompt( 'Please use numbers only' );
                    this.selectExisting();
                }
            }
        }
    },
    alertExportCSV: function(){
        let keys = [];
        $( '.alertTableHorizontal' ).find( 'th' ).each( function( key,value ){
            let obj = $( value ).text();
            keys.push( obj );
        } );
        let csv = '';
        $( 'tr.selected' ).each( function( x,y ) {
            let storearray = [];
            $( y ).find( 'td' ).each( function( x,y ) {
                let copy = $( y ).clone( false );
                $( copy ).find( '.extras' ).remove();
                let value = $( copy ).text();
                value = value.replace( /,/g,'|' );
                storearray.push( value );
            } );
            csv += storearray.join() + '\n';
        } );
        let result = keys.join() + '\n';
        csv = result + csv;
        let data_uri = 'data:text/csv;charset=utf-8,' + encodeURIComponent( csv );
        window.open( data_uri );
    },
    alertDeleteSelected: function(){
        if( confirm( 'Are you sure you want to Delete? This action can not be undone.' ) ){
            let array = [];
            $( 'tr.selected' ).each( function( index,tr ) {
                let id = $( tr ).attr( 'id' );
                array.push( id );
            }.bind( this ) );
            for ( let i=0; i < array.length; i++ ) {
                $.ajax( {
                    type:'delete',
                    url: '/scot/api/v2/alert/'+array[i],
                    success: function( ){
                        console.log( 'success' );
                    }.bind( this ),
                    error: function( data ) {
                        this.props.errorToggle( 'failed to delete selected alerts' , data );
                    }.bind( this )
                } );
            }
        }
    },
    PrintPrepare: function() {
        $('iframe').contents().each( function(x, y) {
            $(y).find('blockquote').each( function( index, block) {
                $(block).css({'max-height': '5000px'})
            })
            $(y).find('pre').each( function( index, pre) {
                $(pre).css({'max-height': '5000px', 'word-wrap': 'break-word' })
            })
        });
        setTimeout( function() {
            this.forceUpdate();
        }.bind(this), 500);
        setTimeout( function() {
            $('#print-button').click();
        }, 1000);
    },
    Print: function() {
        window.print();
    },
    componentDidMount: function() {
        //open, close SELECTED alerts
        if ( this.props.type == 'alertgroup' || this.props.type == 'alert' ) {
            $( '#main-detail-container' ).keydown( function( event ){
                if( $( 'input' ).is( ':focus' ) ) {return;}
                if ( event.keyCode == 79 && ( event.ctrlKey != true && event.metaKey != true ) ) {
                    this.alertOpenSelected();
                }
                if ( event.keyCode == 67 && ( event.ctrlKey != true && event.metaKey != true ) ) {
                    this.alertCloseSelected();
                }
            }.bind( this ) );
        }
        $( '#main-detail-container' ).keydown( function( event ){
            if( $( 'input' ).is( ':focus' ) ) {return;}
            if ( event.keyCode == 84 && ( event.ctrlKey != true && event.metaKey != true ) ) {
                this.toggleFlair();
            }
        }.bind( this ) ); },

    componentWillUnmount: function() {
        $( '#main-detail-container' ).unbind( 'keydown' );
    },

    guideToggle: function() {
        let entityoffset = {top: 0, left: 0}; //set to 0 so it appears in a default location.
        this.props.flairToolbarToggle( this.props.guideID,null,'guide', entityoffset, null );
    },

    sourceToggle: function() {
        let entityoffset = {top: 0, left: 0}; //set to 0 so it appears in a default location.
        this.props.flairToolbarToggle( this.props.id,null,'source', entityoffset, null);
    },

    createGuide: function() {
        let data = JSON.stringify( {subject: 'ENTER A GUIDE NAME',applies_to:[this.props.subjectName]} );
        $.ajax( {
            type: 'POST',
            url: '/scot/api/v2/guide',
            data: data,
            contentType: 'application/json; charset=UTF-8',
            success: function( response ){
                window.open( '/#/guide/' + response.id );
            }.bind( this ),
            error: function( data ) {
                this.props.errorToggle( 'failed to create a new guide', data );
            }.bind( this )
        } );
    },
    reparseFlair: function() {
        $.ajax( {
            type: 'put',
            url: '/scot/api/v2/'+this.props.type+'/'+this.props.id,
            data: JSON.stringify( {parsed:0} ),
            contentType: 'application/json; charset=UTF-8',
            success: function( ){
                console.log( 'reparsing started' );
            }.bind( this ),
            error: function( data ) {
                this.props.errorToggle( 'failed to reparse flair', data );
            }.bind( this )
        } );
    },

    createLinkSignature: function() {
        $.ajax( {
            type: 'POST',
            url: '/scot/api/v2/signature',
            data: JSON.stringify( {target: {id:this.props.id, type: this.props.type}, name: 'Name your Signature', status: 'disabled'} ),
            contentType: 'application/json; charset=UTF-8',
            success: function( response ) {
                const url = '/#/signature/'+response.id;
                window.open( url,'_blank' );
            }.bind( this ),
            error: function( data ) {
                this.props.errorToggle( 'failed to create a signature', data );
            }.bind( this )
        } );
    },

    manualUpdate: function() {
        this.props.updated( null,null );
    },
    render: function() {
        let subjectType = this.props.subjectType;
        let type = this.props.type;
        let id = this.props.id;
        let status = this.props.status;

        let string = '';

        if ( this.props.headerData.subject ) {
            string = this.props.headerData.subject;
        } else if ( this.props.headerData.value ) {
            string = this.props.headerData.value;
        } else if ( this.props.headerData.name ) {
            string = this.props.headerData.name;
        } else if ( this.props.headerData.body ) {
            string = this.props.headerData.body;
        }

        if ( type != 'alertgroup' ) {
            let newType;
            let showPromote = true;
            if ( status != 'promoted' ) {
                if ( type == 'alert' ) {
                    newType = 'Event';
                } else if ( type == 'event' ) {
                    newType = 'Incident';
                } else if ( type == 'incident' || type == 'guide' || type == 'intel' || type == 'signature' || type == 'entity' ) {
                    showPromote = false;
                }
            } else {
                showPromote = false;
            }
            return (
                <div className="entry-header detail-buttons">
                    {type != 'entity' ? <Button eventKey="1" bsStyle='success' onClick={this.props.entryToggle} bsSize='xsmall'><i className="fa fa-plus-circle" aria-hidden="true"></i> Add Entry</Button> : null }
                    {type != 'entity' ? <Button eventKey="2" onClick={this.props.fileUploadToggle} bsSize='xsmall'><i className="fa fa-upload" aria-hidden="true"></i> Upload File</Button> : null }
                    <Button eventKey="3" onClick={this.toggleFlair} bsSize='xsmall'><i className="fa fa-eye-slash" aria-hidden="true"></i> Toggle Flair</Button>
                    {type == 'alertgroup' || type == 'event' || type == 'intel' ? <Button eventKey="4" onClick={this.props.viewedByHistoryToggle} bsSize='xsmall'><img src='/images/clock.png'/> Viewed By History</Button> : null}
                    <Button eventKey="5" onClick={this.props.changeHistoryToggle} bsSize='xsmall'><img src='/images/clock.png'/> {subjectType} History</Button>
                    {type != 'entity' ? <Button eventKey="6" onClick={this.props.permissionsToggle} bsSize='xsmall'><i className="fa fa-users" aria-hidden="true"></i> Permissions</Button> : null }
                    <TrafficLightProtocol type={type} id={id} tlp={this.props.headerData.tlp} />
                    <Button eventKey="7" onClick={this.props.entitiesToggle} bsSize='xsmall'><span className='entity'>__</span> View Entities</Button>
                    {type == 'guide' ? <Button eventKey='8' onClick={this.props.guideRedirectToAlertListWithFilter} bsSize='xsmall'><i className="fa fa-table" aria-hidden='true'></i> View Related Alerts</Button> : null}
                    <Button onClick={this.props.linksModalToggle} bsSize='xsmall'><i className='fa fa-link' aria-hidden='true'></i> Links</Button>
                    {showPromote ? <Promote type={type} id={id} updated={this.props.updated} errorToggle={this.props.errorToggle} /> : null}
                    {type != 'signature' ? <Button bsSize='xsmall' onClick={this.createLinkSignature}><i className="fa fa-pencil" aria-hidden="true"></i> Create & Link Signature</Button> : null}
                    {type == 'signature' ? <Button eventKey='11' onClick={this.props.showSignatureOptionsToggle} bsSize='xsmall' bsStyle='warning'>View Custom Options</Button> : null}
                    <Button onClick={this.PrintPrepare} bsSize='xsmall' bsStyle='info'><i className='fa fa-print' aria-hidden='true'></i> Print</Button>
                    <Button onClick={this.Print} style={{display:'none'}} id="print-button"></Button>
                    <Button onClick={this.props.exportToggle} bsSize='xsmall' id='export-button'><i className='fa fa-share' aria-hidden='true'></i> Export {subjectType} </Button>
                    <Button bsStyle='danger' eventKey="9" onClick={this.props.deleteToggle} bsSize='xsmall'><i className="fa fa-trash" aria-hidden="true"></i> Delete {subjectType}</Button>
                    <ButtonGroup style={{float:'right'}}>
                        <Marker type={type} id={id} string={string} />
                        <Button onClick={this.props.markModalToggle} bsSize='xsmall'>Marked Objects</Button>
                        <Button id='refresh-detail' bsStyle='info' eventKey="10" onClick={this.manualUpdate} bsSize='xsmall' style={{float:'right'}}><i className='fa fa-refresh' aria-hidden='true'></i></Button>
                    </ButtonGroup>

                </div>
            );
        } else {
            if ( this.props.aIndex != undefined ) {
                return (
                    <div className="entry-header second-menu detail-buttons">
                        <Button eventKey='1' onClick={this.toggleFlair} bsSize='xsmall'><i className="fa fa-eye-slash" aria-hidden="true"></i> Toggle Flair</Button>
                        <Button eventKey="2" onClick={this.reparseFlair} bsSize='xsmall'><i className='fa fa-refresh' aria-hidden='true'></i> Reparse Flair</Button>
                        {this.props.guideID == null ? null : this.props.guideID != 0 ? <Button eventKey='3' onClick={this.guideToggle} bsSize='xsmall'><img src='/images/guide.png'/> Guide</Button> : <Button eventKey='3' onClick={this.createGuide} bsSize='xsmall'><img src='/images/guide.png'/> Create Guide</Button>}}
                        {this.props.headerData == null ? null : <Button eventKey='4' onClick={this.sourceToggle} bsSize='xsmall'><img src='/images/code.png'/> View Source</Button>}
                        <Button eventKey='5' onClick={this.props.entitiesToggle} bsSize='xsmall'><span className='entity'>__</span> View Entities</Button>
                        {type == 'alertgroup' || type == 'event' || type == 'intel' ? <Button eventKey="6" onClick={this.props.viewedByHistoryToggle} bsSize='xsmall'><img src='/images/clock.png'/> Viewed By History</Button> : null}
                        <Button eventKey='7' onClick={this.props.changeHistoryToggle} bsSize='xsmall'><img src='/images/clock.png'/> {subjectType} History</Button>
                        <TrafficLightProtocol type={type} id={id} tlp={this.props.headerData.tlp} />
                        <Button eventKey='8' onClick={this.alertOpenSelected} bsSize='xsmall' bsStyle='danger'><img src='/images/open.png'/> Open Selected</Button>
                        <Button eventKey='9' onClick={this.alertCloseSelected} bsSize='xsmall' bsStyle='success'><i className="fa fa-flag-checkered" aria-hidden="true"></i> Close Selected</Button>
                        <Button eventKey='10' onClick={this.alertPromoteSelected} bsSize='xsmall' bsStyle='warning'><img src='/images/megaphone.png'/> Promote Selected</Button>
                        <Button eventKey='11' onClick={this.alertSelectExisting} bsSize='xsmall'><img src='/images/megaphone_plus.png' /> Add Selected to <b>Existing Event</b></Button>
                        <Button eventKey='12' onClick={this.props.entryToggle} bsSize='xsmall'><i className="fa fa-plus-circle" aria-hidden="true"></i> Add Entry</Button>
                        <Button eventKey="13" onClick={this.props.fileUploadToggle} bsSize='xsmall'><i className="fa fa-upload" aria-hidden="true"></i> Upload File</Button>
                        <Button eventKey='14' onClick={this.alertExportCSV} bsSize='xsmall'><img src='/images/csv_text.png'/> Export to CSV</Button>
                        <Button onClick={this.props.linksModalToggle} bsSize='xsmall'><i className='fa fa-link' aria-hidden='true'></i> Links</Button>
                        <Marker type={type} id={id} string={string} isAlert={true} getSelectedAlerts={this.getSelectedAlerts} />
                        <Button bsSize='xsmall' onClick={this.createLinkSignature}><i className="fa fa-pencil" aria-hidden="true"></i> Create & Link Signature</Button>
                        <Button onClick={this.PrintPrepare} bsSize='xsmall' bsStyle='info'><i className='fa fa-print' aria-hidden='true'></i> Print</Button>
                        <Button onClick={this.Print} style={{display:'none'}} id="print-button"></Button>
                        <Button eventKey='15' onClick={this.alertDeleteSelected} bsSize='xsmall' bsStyle='danger'><i className="fa fa-trash" aria-hidden="true"></i> Delete Selected</Button>
                        <Button bsStyle='danger' eventKey="17" onClick={this.props.deleteToggle} bsSize='xsmall'><i className="fa fa-trash" aria-hidden="true"></i> Delete {subjectType}</Button>
                        <ButtonGroup style={{float:'right'}}>
                            <Marker type={type} id={id} string={string} />
                            <Button onClick={this.props.markModalToggle} bsSize='xsmall'>Marked Actions</Button>
                            <Button bsStyle='info' eventKey="16" onClick={this.manualUpdate} bsSize='xsmall' style={{float:'right'}}><i className='fa fa-refresh' aria-hidden='true'></i></Button>
                        </ButtonGroup>
                    </div>
                );
            } else {
                return (
                    <div className="entry-header detail-buttons">
                        <Button eventKey='1' onClick={this.toggleFlair} bsSize='xsmall'><i className="fa fa-eye-slash" aria-hidden="true"></i> Toggle Flair</Button>
                        <Button eventKey="2" onClick={this.reparseFlair} bsSize='xsmall'><i className='fa fa-refresh' aria-hidden='true'></i> Reparse Flair</Button>
                        {this.props.guideID == null ? null : <span>{this.props.guideID != 0 ? <Button eventKey='3' onClick={this.guideToggle} bsSize='xsmall'><img src='/images/guide.png'/> Guide</Button> : <Button eventKey='3' onClick={this.createGuide} bsSize='xsmall'><img src='/images/guide.png'/> Create Guide</Button>}</span>}
                        {this.props.headerData == null ? null : <Button eventKey='4' onClick={this.sourceToggle} bsSize='xsmall'><img src='/images/code.png'/> View Source</Button>}
                        <Button eventKey='5' onClick={this.props.entitiesToggle} bsSize='xsmall'><span className='entity'>__</span> View Entities</Button>
                        {type == 'alertgroup' || type == 'event' || type == 'intel' ? <Button eventKey="6" onClick={this.props.viewedByHistoryToggle} bsSize='xsmall'><img src='/images/clock.png'/> Viewed By History</Button> : null}
                        <Button eventKey='7' onClick={this.props.changeHistoryToggle} bsSize='xsmall'><img src='/images/clock.png'/> {subjectType} History</Button>
                        <TrafficLightProtocol type={type} id={id} tlp={this.props.headerData.tlp} />
                        <Button onClick={this.props.linksModalToggle} bsSize='xsmall'><i className='fa fa-link' aria-hidden='true'></i> Links</Button>
                        <Button bsSize='xsmall' onClick={this.createLinkSignature}><i className="fa fa-pencil" aria-hidden="true"></i> Create & Link Signature</Button>
                        <Button onClick={this.PrintPrepare} bsSize='xsmall' bsStyle='info'><i className='fa fa-print' aria-hidden='true'></i> Print</Button>
                        <Button onClick={this.Print} style={{display:'none'}} id="print-button"></Button>
                        <Button bsStyle='danger' eventKey="8" onClick={this.props.deleteToggle} bsSize='xsmall'><i className="fa fa-trash" aria-hidden="true"></i> Delete {subjectType}</Button>
                        <ButtonGroup style={{float:'right'}}>
                            <Marker type={type} id={id} string={string} />
                            <Button onClick={this.props.markModalToggle} bsSize='xsmall'>Marked Actions</Button>
                            <Button bsStyle='info' eventKey="9" onClick={this.manualUpdate} bsSize='xsmall' style={{float:'right'}}><i className='fa fa-refresh' aria-hidden='true'></i></Button>
                        </ButtonGroup>
                    </div>
                );
            }
        }
    }
} );

module.exports = SelectedHeaderOptions;
