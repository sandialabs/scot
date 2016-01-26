var React           = require('react');

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
            <div>
                <span className="pull-right btn-group" style={{marginTop: 17, boxShadow: '0px 0px 50px 5px #8A8A8A'}} id="high_level_dropdown">
                    <button className="btn btn-inverse intel events incidents tasks" onClick={this.props.entryToggle}>
                        Add <b>Entry</b>
                    </button>
                    <button className="btn btn-inverse dropdown-toggle intel events incidents tasks" data-toggle="dropdown">
                        <span className="caret" style={{marginTop: 8}} />
                    </button>
                    <ul className="dropdown-menu">
                        <li><a onclick="openFileUploadDialog()">Upload <b>File</b></a></li>
                        <li><a onClick={this.props.historyToggle}>View <b>History</b></a></li>
                        <li><a onClick={this.toggleFlair}>Toggle <b>Flair</b></a></li>
                        <li><a onClick={this.props.permissionsToggle}><b>Permissions</b></a></li>
                        <li><a className="alerts events incidents" onClick={this.props.entitiesToggle}>List <b>Entities</b></a></li>
                        <li><a className="events" onclick="delete_event()"><b>Delete </b>Event</a></li>
                    </ul>
                </span>
            </div>
        )
    }
});

module.exports = EntryHeaderOptions;
