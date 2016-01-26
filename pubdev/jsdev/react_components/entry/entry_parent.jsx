var React = require('react');
var Frame = require('react-frame-component');

var EntryParent = React.createClass({
    iframe: function() {
        var rawMarkup = this.props.subitem.body_flair 
       var ifr = $('<iframe style={{width:"100%"}} sandbox="allow-popups allow-same-origin"></iframe>').attr('srcdoc', '<link rel="stylesheet" type="text/css" href="sandbox.css"></link><body>' + rawMarkup + '</body>'); 
        var iframe = '<iframe srcDoc="dangerouslySetInnerHTML={{ __html: '+{rawMarkup}+'}}"></iframe>'
        console.log(rawMarkup);
        console.log(iframe); 
        return ifr
    },
    norender: function() {
        var rawMarkup = this.props.subitem.body_flair;
        return (
            <div>
                <iframe srcDoc={rawMarkup}></iframe>
            </div>
        )
    },
    render: function() {
        var rawMarkup = this.props.subitem.body_flair;
        return (
            <div className="row-fluid entry-body">
                <div className="row-fluid entry-body-inner" style={{marginLeft: 'auto', marginRight: 'auto', width:'99.3%'}} dangerouslySetInnerHTML={{ __html: rawMarkup }}/>
            </div>            
        )
    }
});

module.exports = EntryParent;
