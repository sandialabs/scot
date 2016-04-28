var React           = require('react');
var ButtonGroup     = require('react-bootstrap/lib/ButtonGroup.js');
var Button          = require('react-bootstrap/lib/Button.js');
var MenuItem        = require('react-bootstrap/lib/MenuItem.js');
var DropdownButton  = require('react-bootstrap/lib/DropdownButton.js');
var Promote         = require('../components/promote.jsx');

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
    render: function() { 
        var subjectType = this.props.subjectType;
        var type = this.props.type;
        var id = this.props.id;
        var status = this.props.status;
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
    }
});

module.exports = SelectedHeaderOptions;
