var React           = require('react');
var ButtonGroup     = require('react-bootstrap/lib/ButtonGroup.js');
var Button          = require('react-bootstrap/lib/Button.js');
var MenuItem        = require('react-bootstrap/lib/MenuItem.js');
var DropdownButton  = require('react-bootstrap/lib/DropdownButton.js');

var EntryHeaderOptions = React.createClass({
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
        return (
            <div className="entry-header">
                <ButtonGroup>
                    <Button>File</Button>
                    <Button>View</Button>
                    <DropdownButton title="Actions" id="bg-nested-dropdown">
                        <MenuItem eventKey="1" onClick={this.toggleFlair}>Toggle <b>Flair</b></MenuItem>
                        <MenuItem eventKey="2" onClick={this.props.historyToggle}>View <b>History</b></MenuItem>
                        <MenuItem eventKey="3" onClick={this.props.permissionsToggle}><b>Permissions</b></MenuItem>
                        <MenuItem eventKey="4" onClick={this.props.entitiesToggle}>List <b>Entities</b></MenuItem>
                        <MenuItem eventKey="5" onclick={this.props.deleteEvent}><b>Delete</b> Event</MenuItem>
                    </DropdownButton> 
                </ButtonGroup>
                <Button bsStyle='success' className="pull-right" onClick={this.props.entryToggle}>Add Entry</Button>
            </div>
        )
    }
});
/* original render
<span className="pull-right btn-group" style={{marginTop: 17, boxShadow: '0px 0px 50px 5px #8A8A8A'}} id="high_level_dropdown">
                    <button className="btn btn-inverse intel events incidents tasks" onClick={this.props.entryToggle}>
                        Add <b>Entry</b>
                    </button>
                    <button className="btn btn-inverse dropdown-toggle intel events incidents tasks" data-toggle="dropdown">
                        <span className="caret" style={{marginTop: 8}} />
                    </button>
                        <ul className='dropdown-menu'>
                        <li><a onclick="openFileUploadDialog()">Upload <b>File</b></a></li>
                        <li><a onClick={this.props.historyToggle}>View <b>History</b></a></li>
                        <li><a onClick={this.toggleFlair}>Toggle <b>Flair</b></a></li>
                        <li><a onClick={this.props.permissionsToggle}><b>Permissions</b></a></li>
                        <li><a className="alerts events incidents" onClick={this.props.entitiesToggle}>List <b>Entities</b></a></li>
                        <li><a className="events" onclick="delete_event()"><b>Delete </b>Event</a></li>
                    </ul>
                </span>
*/
module.exports = EntryHeaderOptions;
