var React               = require('react');
var ReactDateTime       = require('react-datetime');
var AceEditor           = require('react-ace');

var SignatureTable = React.createClass({
    getInitialState: function() {
        return {
            
        }
    },
    onChange: function(event) {
        var k  = event.target.id;
        var v = event.target.value;
        var json = {};
        json[k] = v;
        $.ajax({
            type: 'put',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.id,
            data: JSON.stringify(json),
            contentType: 'application/json; charset=UTF-8',
            success: function(data) {
                console.log('successfully changed signature data');
            }.bind(this),
            error: function() {
                this.props.errorToggle('Failed to updated incident data') 
            }.bind(this)
        })
    },
    inputOnChange: function(event) {
        this.setState({reportValue:event.target.value});
    },
    render: function() {
        return (
            <div className='signatureTable'>
                Test Signature Ace Editor
                <AceEditor
                    mode        = "java"
                    theme       = "github"
                    onChange    = {this.onChange}
                    name        = "unique_id_of_div"
                    editorProps = {{$blockScrolling: true}}
                />
            </div>
        )
    }
});

module.exports = SignatureTable;
