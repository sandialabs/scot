var React           = require('react');
var ButtonGroup     = require('react-bootstrap/lib/ButtonGroup.js');
var Button          = require('react-bootstrap/lib/Button.js');
var MenuItem        = require('react-bootstrap/lib/MenuItem.js');
var DropdownButton  = require('react-bootstrap/lib/DropdownButton.js');
var Promote         = require('../components/promote.jsx');
var Appactions      = require('../flux/actions.jsx');

var SelectedHeaderOptions = React.createClass({
    toggleFlair: function() { 
        if (typeof globalFlairState === 'undefined') {
            globalFlairState = true;
        }
        $('iframe').each(function(index, ifr) {
            if(ifr.contentDocument != null) {
                var ifrContents = $(ifr).contents();
                var off = ifrContents.find('.entity-off');
                var on = ifrContents.find('.entity');
                if (globalFlairState == false) {
                    ifrContents.find('.extras').show();
                    ifrContents.find('.flair-off').hide();
                    off.each(function(index, entity) {
                        $(entity).addClass('entity');
                        $(entity).removeClass('entity-off');
                    });
                } else {
                    ifrContents.find('.extras').hide();
                    ifrContents.find('.flair-off').show();
                    on.each(function(index, entity) {
                        $(entity).addClass('entity-off');
                        $(entity).removeClass('entity');
                    });

                }

            }
        });
        var off = $('.entity-off');
        var on = $('.entity');
        if (!globalFlairState) {
            globalFlairState = true;
            $('.extras').show();
            $('.flair-off').hide();
            off.each(function(index, entity) {
                $(entity).addClass('entity');
                $(entity).removeClass('entity-off');
            });
        } else {
            $('.extras').hide();
            $('.flair-off').show();
            globalFlairState = false;
            on.each(function(index, entity) {
                $(entity).addClass('entity-off');
                $(entity).removeClass('entity');
            });
        }
    },
    //All methods containing alert are only used by selected_entry when viewing an alertgroupand interacting with an alert.
    alertOpenSelected: function() {
        var array = []
        var data = JSON.stringify({status:'open'})
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
    },
    alertCloseSelected: function() {
        var time = Math.round(new Date().getTime() / 1000)
        var data = JSON.stringify({status:'closed', closed: time})
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
    },
    alertPromoteSelected: function() {
        var data = JSON.stringify({promote:'new'})
        var array = [];
        $('tr.selected').each(function(index,tr) {
            var id = $(tr).attr('id');
            array.push(id);
        }.bind(this));
        //Start by promoting the first one in the array
        $.ajax({
            type:'put',
            url: '/scot/api/v2/alert/'+array[0],
            data: data,
            contentType: 'application/json; charset=UTF-8',
            success: function(response){
                //With the entry number, promote the others into the existing event
                var promoteTo = {
                    promote:response.pid
                }
                for (i=1; i < array.length; i++) {
                    $.ajax({
                        type:'put',
                        url: '/scot/api/v2/alert/'+array[i],
                        data: JSON.stringify(promoteTo),
                        contentType: 'application/json; charset=UTF-8',
                        success: function(response){
                            console.log('success');
                        }.bind(this),
                        error: function() {
                            console.log('failure');
                        }.bind(this)
                    })
                }
            }.bind(this),
            error: function() {
                console.log('failure');
            }.bind(this)
        })
        
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
        var text = prompt("Please Enter Event ID to promote into")
        var array = [];
        if (text != '' && text != null){
            $('tr.selected').each(function(index,tr) {
                var id = $(tr).attr('id');
                array.push(id);
            }.bind(this));
            for (i=0; i < array.length; i++) {
                if ($.isNumeric(text)) {
                    var data = {
                        promote:parseInt(text)
                    }
                    $.ajax({
                        type: 'PUT',
                        url: '/scot/api/v2/alert/' + array[i],
                        data: JSON.stringify(data),
                        contentType: 'application/json; charset=UTF-8',
                        success: function(response){
                            if($.isNumeric(text)){
                                window.location = '#/event/' + text
                            }
                        }.bind(this),
                        error: function() {
                            console.log('failure');
                        }.bind(this)
                    })
                } else {
                    prompt("Please use numbers only")
                    this.selectExisting();
                }
            }
        }
    },
    alertExportCSV: function(){
        var keys = []
        $('.alertTableHorizontal').find('th').each(function(key,value){
            var obj = $(value).text();
            keys.push(obj);
        });
        var csv = ''
        $('tr.selected').each(function(x,y) {
            var storearray = []
            $(y).find('td').each(function(x,y) {
                var obj = $(y).text()
                obj = obj.replace(/,/g,'|')
                storearray.push(obj)
            })
            csv += storearray.join() + '\n'
        });
        var result = keys.join() + "\n"
        csv = result + csv;
        var data_uri = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv)
        window.open(data_uri)
    },
    alertDeleteSelected: function(){
        if(confirm("Are you sure you want to Delete? This action can not be undone.")){
            var array = [];
            $('tr.selected').each(function(index,tr) {
                var id = $(tr).attr('id');
                array.push(id);
            }.bind(this));
            for (i=0; i < array.length; i++) {
                $.ajax({
                    type:'delete',
                    url: '/scot/api/v2/alert/'+array[i],
                    success: function(response){
                        console.log('success');
                    }.bind(this),
                    error: function() {
                        console.log('failure');
                    }.bind(this)
                });
            }        
        }
    },
    componentDidMount: function() {
        //open, close, and promote alerts
        $(document.body).keydown(function(event){
            if($('input').is(':focus')) {return}
            switch (event.keyCode) {
                case 79:
                    this.alertOpenSelected();
                    break;
                case 67:
                    this.alertCloseSelected();
                    break;
                case 80:
                    this.alertPromoteSelected();
                    break;
            }
        }.bind(this))
    },
    guideToggle: function() {
        this.props.flairToolbarToggle(this.props.guideID,null,'guide')
    },
    createGuide: function() {
       var data = JSON.stringify({subject: 'ENTER A GUIDE NAME',applies_to:[this.props.subjectName],entry:[]})
        $.ajax({
            type: 'POST',
            url: '/scot/api/v2/guide',
            data: data,
            contentType: 'application/json; charset=UTF-8',
        }).success(function(response){
            window.open('/#/guide/' + response.id);        
        }.bind(this)) 
    },
    reparseFlair: function() {
        $.ajax({
            type: 'put',
            url: '/scot/api/v2/'+this.props.type+'/'+this.props.id,
            data: JSON.stringify({parsed:0}),
            contentType: 'application/json; charset=UTF-8',
        }).success(function(response){
            console.log('reparsing started');
        }.bind(this))
    },
    manualUpdate: function() {
        this.props.updated(null,null);
    },
    render: function() { 
        var subjectType = this.props.subjectType;
        var type = this.props.type;
        var id = this.props.id;
        var status = this.props.status;
        if (type != 'alertgroup') {
            var newType = null;
            var showPromote = true;
            if (status != 'promoted') {
                if (type == "alert") {
                    newType = "Event"
                } else if (type == "event") {
                    newType = "Incident"
                } else if (type == "incident" || type == "guide") {
                    showPromote = false;
                } 
            } else {
                showPromote = false;
            }
            return (
                <div className="entry-header">
                    <Button bsStyle='success' onClick={this.props.entryToggle} bsSize='small'>Add Entry</Button>
                    <Button eventKey="1" onClick={this.toggleFlair} bsSize='small'>Toggle <b>Flair</b></Button>
                    <Button eventKey="3" onClick={this.props.viewedByHistoryToggle} bsSize='small'><b>Viewed By History</b></Button>
                    <Button eventKey="4" onClick={this.props.changeHistoryToggle} bsSize='small'><b>{subjectType} History</b></Button>
                    <Button eventKey="5" onClick={this.props.permissionsToggle} bsSize='small'><b>Permissions</b></Button>
                    <Button eventKey="6" onClick={this.props.entitiesToggle} bsSize='small'>List <b>Entities</b></Button>
                    {showPromote ? <Button bsStyle='warning' eventKey="7" bsSize='small'><Promote type={type} id={id} updated={this.props.updated} /></Button> : null}
                    <Button bsStyle='danger' eventKey="8" onClick={this.props.deleteToggle} bsSize='small'><b>Delete</b> {subjectType}</Button>
                    <Button bsStyle='info' eventKey="9" onClick={this.manualUpdate} bsSize='small' style={{float:'right'}}><i className='fa fa-refresh' aria-hidden='true'></i></Button>
                </div>
            )
        } else {
            if (this.props.aIndex != undefined) {
                return (
                    <div className="entry-header">
                        <Button eventKey='1' onClick={this.toggleFlair} bsSize='small'>Toggle <b>Flair</b></Button>
                        <Button eventKey="2" onClick={this.reparseFlair} bsSize='small'><b>Reparse</b> Flair</Button>
                        {this.props.guideID == null ? null : <span>{this.props.guideID != 0 ? <Button eventKey='3' onClick={this.guideToggle} bsSize='small'>Guide</Button> : <Button eventKey='3' onClick={this.createGuide} bsSize='small'>Create Guide</Button>}</span>}
                        <Button eventKey='4' onClick={this.props.sourceToggle} bsSize='small'>View <b>Source</b></Button> 
                        <Button eventKey='5' onClick={this.props.entitiesToggle} bsSize='small'>View <b>Entities</b></Button>
                        <Button eventKey="6" onClick={this.props.viewedByHistoryToggle} bsSize='small'><b>Viewed By History</b></Button>
                        <Button eventKey='7' onClick={this.props.changeHistoryToggle} bsSize='small'><b>{subjectType} History</b></Button>
                        <Button eventKey='8' onClick={this.alertOpenSelected} bsSize='small'><b>Open</b> Selected</Button>
                        <Button eventKey='9' onClick={this.alertCloseSelected} bsSize='small'><b>Close</b> Selected</Button>
                        <Button eventKey='10' onClick={this.alertPromoteSelected} bsSize='small'><b><u>P</u>romote</b> Selected</Button> 
                        <Button eventKey='11' onClick={this.props.entryToggle} bsSize='small'>Add <b>Entry</b></Button>
                        <Button eventKey='12' onClick={this.alertSelectExisting} bsSize='small'><b>Add</b> Selected to <b>Existing Event</b></Button> 
                        <Button eventKey='13' onClick={this.alertExportCSV} bsSize='small'>Export to <b>CSV</b></Button>
                        <Button eventKey='14' onClick={this.alertDeleteSelected} bsSize='small'><b>Delete</b> Selected</Button> 
                        <Button bsStyle='info' eventKey="9" onClick={this.manualUpdate} bsSize='small' style={{float:'right'}}><i className='fa fa-refresh' aria-hidden='true'></i></Button>
                    </div>
                )
            } else { 
                return (
                    <div className="entry-header">
                        <Button eventKey='1' onClick={this.toggleFlair} bsSize='small'>Toggle <b>Flair</b></Button>
                        <Button eventKey="2" onClick={this.reparseFlair} bsSize='small'><b>Reparse</b> Flair</Button>
                        {this.props.guideID == null ? null : <span>{this.props.guideID != 0 ? <Button eventKey='3' onClick={this.guideToggle} bsSize='small'>Guide</Button> : <Button eventKey='3' onClick={this.createGuide} bsSize='small'>Create Guide</Button>}</span>}
                        <Button eventKey='4' onClick={this.props.sourceToggle} bsSize='small'>View <b>Source</b></Button> 
                        <Button eventKey='5' onClick={this.props.entitiesToggle} bsSize='small'>View <b>Entities</b></Button>
                        <Button eventKey="6" onClick={this.props.viewedByHistoryToggle} bsSize='small'><b>Viewed By History</b></Button>
                        <Button eventKey='7' onClick={this.props.changeHistoryToggle} bsSize='small'><b>{subjectType} History</b></Button> 
                        <Button bsStyle='info' eventKey="9" onClick={this.manualUpdate} bsSize='small' style={{float:'right'}}><i className='fa fa-refresh' aria-hidden='true'></i></Button>
                    </div>
                )
            }
        }
    }
});

module.exports = SelectedHeaderOptions;
