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
    alertOpenSelected: function() {
        var data = JSON.stringify({status:'open'})
        var id = this.props.aID;
        $.ajax({
            type:'put',
            url: '/scot/api/v2/alert/'+id,
            data: data,
            success: function(response){
                console.log('success');
            }.bind(this),
            error: function() {
                console.log('failure');
            }.bind(this)
        })
    },
    alertCloseSelected: function() {
        var time = Math.round(new Date().getTime() / 1000)
        var data = JSON.stringify({status:'closed', closed: time})
        var id = this.props.aID;
        $.ajax({
            type:'put',
            url: '/scot/api/v2/alert/'+id,
            data: data,
            success: function(response){
                console.log('success');
            }.bind(this),
            error: function() {
                console.log('failure');
            }.bind(this)
        })
    },
    alertPromoteSelected: function() {
        var data = JSON.stringify({promote:'new'})
        var id= this.props.aID;
        $.ajax({
            type:'put',
            url: '/scot/api/v2/alert/'+id,
            data: data,
            success: function(response){
                console.log('success');
            }.bind(this),
            error: function() {
                console.log('failure');
            }.bind(this)
        })
    },
    alertUnpromoteSelected: function() {
        var data = JSON.stringify({unpromote:this.props.aID})
        var id = this.props.aID;
        $.ajax({
            type:'put',
            url: '/scot/api/v2/alert/'+id,
            data: data,
            success: function(response){
                console.log('success');
            }.bind(this),
            error: function() {
                console.log('failure');
            }.bind(this)
        })
    },
    alertSelectExisting: function() {
        var text = prompt("Please Enter Event ID to promote into")
        var id = this.props.aID;
        if ($.isNumeric(text)) {
            var data = {
                promote:text
            }
            $.ajax({
                type: 'PUT',
                url: '/scot/api/v2/alert/' + id,
                data: JSON.stringify(data),
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
    },
    alertExportCSV: function(){
        var keys = []
        $.each(this.state.columns, function(key, value){
            keys.push(value['name']);
        });
        var csv = ''
        $('.subtable'+this.state.key).find('.z-selected').each(function(key, value){
            var storearray = []
            $(value).find('.z-content').each(function(x,y) {
                var obj = $(y).text()
                obj = obj.replace(/,/g,'|')
                storearray.push(obj)
            });
            csv += storearray.join() + '\n'
        });
            var result = keys.join() + "\n"
            csv = result + csv;
            var data_uri = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv)
        setTimeout(
        function() {
            this.reloadentry()
        }.bind(this), 1000)
            this.setState({setreload: false})
            window.open(data_uri)
    },
    alertDeleteSelected: function(){
        if(confirm("Are you sure you want to Delete? This action can not be undone.")){
            var data = JSON.stringify({promote:'delete'})
            var id = this.props.aID;
            $.ajax({
                type:'put',
                url: '/scot/api/v2/alert/'+id,
                data: data,
                success: function(response){
                    console.log('success');
                }.bind(this),
                error: function() {
                    console.log('failure');
                }.bind(this)
            });
        }
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
                    <ButtonGroup bsSize='small'> 
                        <Button bsStyle='success' onClick={this.props.entryToggle}>Add Entry</Button>
                        <Button eventKey="1" onClick={this.toggleFlair}>Toggle <b>Flair</b></Button>
                        <Button eventKey="2" onClick={this.props.historyToggle}>View <b>History</b></Button>
                        <Button eventKey="3" onClick={this.props.permissionsToggle}><b>Permissions</b></Button>
                        <Button eventKey="4" onClick={this.props.entitiesToggle}>List <b>Entities</b></Button>
                        {showPromote ? <Button bsStyle='warning' eventKey="6"><Promote type={type} id={id} updated={this.props.updated} /></Button> : null}
                        <Button bsStyle='danger' eventKey="5" onClick={this.props.deleteToggle}><b>Delete</b> {subjectType}</Button>
                    </ButtonGroup>
                </div>
            )
        } else {
           return (
                <div className="entry-header">
                    <ButtonGroup bsSize='small' style={{display:'inline-flex'}}>
                        <Button eventKey='1' onClick={this.toggleFlair}>Toggle <b>Flair</b></Button>
                        <Button eventKey='2' onClick={this.props.guideToggle}>Guide</Button>
                        <Button eventKey='3' onClick={this.props.sourceToggle}>View <b>Source</b></Button> 
                        <Button eventKey='4' onClick={this.props.entitiesToggle}>View <b>Entities</b></Button>
                        {this.props.alertSelected ? <Button eventKey='5' onClick={this.props.historyToggle}>View <b>Alert History</b></Button> : <Button eventKey='4' onClick={this.props.historyToggle}>View <b>AlertGroup History</b></Button> }
                        {this.props.alertSelected ? <Button eventKey='6' onClick={this.props.entryToggle}>Add Entry</Button> : null}
                        {this.props.aStatus == 'closed' ? <div>{this.props.alertSelected ? <Button eventKey='7' onClick={this.alertOpenSelected}><b>Open</b> Selected</Button> : null}</div> : null}
                        {this.props.aStatus == 'open' ? <div>{this.props.alertSelected ? <Button eventKey='8' onClick={this.alertCloseSelected}><b>Close</b> Selected</Button> : null}</div> : null}
                        {this.props.aStatus == 'open' ? <div>{this.props.alertSelected ? <Button eventKey='9' onClick={this.alertPromoteSelected}><b>Promote</b> Selected</Button> : null}</div> : null}
                        {this.props.aStatus == 'promoted' ? <div>{this.props.alertSelected ? <Button eventKey='10' onClick={this.alertUnpromoteSelected}><b>Un-Promote</b> Selected</Button> : null}</div> : null}
                        {this.props.alertSelected ? <Button eventKey='11' onClick={this.alertSelectExisting}><b>Add</b> Selected to <b>Existing Event</b></Button> : null}
                        {this.props.alertSelected ? <Button eventKey='12' onClick={this.alertExportCSV}>Export to <b>CSV</b></Button> : null}
                        {this.props.alertSelected ? <Button eventKey='13' onClick={this.alertDeleteSelected}><b>Delete</b> Selected</Button> : null}
                    </ButtonGroup>
                </div>
           )
        }
    }
});

module.exports = SelectedHeaderOptions;
