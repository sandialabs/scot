'use strict';

var React           = require('react');
var Modal           = require('react-modal');
var TinyMCE         = require('react-tinymce');

const customStyles = {
    content : {
        top     : '50%',
        left    : '50%',
        right   : 'auto',
        bottom  : 'auto',
        marginRight: '-50%',
        transform:  'translate(-50%, -50%)',
        width: '80%'
    }
}

var EntryEditor = React.createClass({
    save: function() {
            var jsonData = {};
            $.ajax({
                type: 'GET',
                url: '/scot/api/v2/event/' + id,
                dataType: 'json',
                async: false,
                success: function(data, status) {
                    jsonData = data;
                    
                },
                error: function(err) {
                    console.error(err.toString());
                }
            }); 
    },
    testsave: function() { 
        this.props.entryToggle();
    },
    render: function() {

        return (
            <div>
                <Modal
                    isOpen={true}
                    onRequestClose={this.props.entryToggle}
                    style={customStyles}>
                    <div className="modal-header">
                        <h3 id="myModalLabel"><b>{this.props.type} # {this.props.id}</b> - Add Entry</h3>
                    </div>
                    <div className="modal-body" style={{height: '90%'}}>
                        <TinyMCE
                        content=""
                        config={{
                        plugins: 'autolink link image lists print preview',
                        toolbar: 'undo redo | bold italic | alignleft aligncenter alignright'
                        }}
                        onChange={this.handleEditorChange}
                        />
                    </div>
                    <div className="modal-footer">
                        <button className="btn" onClick={this.testsave}>Save</button>
                        <button className="btn" onClick={this.props.entryToggle}>Cancel</button>
                    </div>
                </Modal>
            </div> 
        );
    } 
});

module.exports = EntryEditor
