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
        var newType = null;
        var showPromote = true;
        if (type == "alert") {
            newType = "Event"
        } else if (type == "event") {
            newType = "Incident"
        } else if (type == "incident") {
            showPromote = false;
        } 
        return (
            <div className="entry-header">
                <ButtonGroup> 
                        <DropdownButton bsStyle='info' title="Actions" id="bg-nested-dropdown">
                        <MenuItem bsStyle='primary' eventKey="1" onClick={this.toggleFlair}>Toggle <b>Flair</b></MenuItem>
                        <MenuItem bsStyle='primary' eventKey="2" onClick={this.props.historyToggle}>View <b>History</b></MenuItem>
                        <MenuItem bsStyle='primary' eventKey="3" onClick={this.props.permissionsToggle}><b>Permissions</b></MenuItem>
                        <MenuItem bsStyle='primary' eventKey="4" onClick={this.props.entitiesToggle}>List <b>Entities</b></MenuItem>
                        <MenuItem bsStyle='danger' eventKey="5" onClick={this.props.deleteToggle}><b>Delete</b> {subjectType}</MenuItem>
                        {showPromote ? <MenuItem bsStyle='primary' eventKey="6"><Promote type={type} id={id} /></MenuItem> : null}
                    </DropdownButton> 
                </ButtonGroup>
                <Button bsStyle='success' className="pull-right" onClick={this.props.entryToggle}>Add Entry</Button>
            </div>
        )
    }
});

module.exports = SelectedHeaderOptions;
