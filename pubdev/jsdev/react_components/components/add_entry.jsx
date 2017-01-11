'use strict';
var React       = require('react')
var TinyMCE     = require('react-tinymce')
var Dropzone    = require('../../../node_modules/react-dropzone')
var Button      = require('react-bootstrap/lib/Button.js');
var marksave = false
var addentrydata = true

var recently_updated = 0

var reply = false
var timestamp = new Date()
var output = "By You ";
timestamp = new Date(timestamp.toString())
output  = output + timestamp.toLocaleString()
var AddEntryModal = React.createClass({
	getInitialState: function(){
	return {
	    edit: false, stagecolor: '#000',enable: true, addentry: true, saved: true, enablesave: true}
	},
	componentWillMount: function(){
        if(this.props.stage == 'Edit'){
            reply = false;
            $.ajax({
                type: 'GET',
                url:  '/scot/api/v2/entry/'+ this.props.id
                }).success(function(response){
                    recently_updated = response.updated
                    if(response.body == ""){
                        $('#tiny_' + this.props.id + '_ifr').contents().find("#tinymce").html(response.body_plain)
                    }
                    else{
                        $('#tiny_' + this.props.id + '_ifr').contents().find("#tinymce").html(response.body)
                    }
                }.bind(this))
        }
        else if (this.props.title == 'Add Entry'){
            reply = false
            $('#tiny_' + this.props.id + '_ifr').contents().find("#tinymce").text('')
        }
        else if(this.props.title == 'Reply Entry'){
            reply = true
            $.ajax({
                type: 'GET',
                url:  '/scot/api/v2/entry/'+ this.props.id
        }).success(function(response){
            if (response.body_flair == '') {
                this.setState({subitem: response.body});
            } else {
                this.setState({subitem: response.body_flair});
            }
        }.bind(this))
        var newheight;
        newheight= document.getElementById('iframe_'+this.props.id).contentWindow.document.body.scrollHeight;
        newheight = newheight + 'px'
        this.setState({height: newheight})
        } 
    },
    componentDidMount: function() {
        //$('#tiny_' + this.props.id + '_ifr').css('height', '100px')
        $('.entry-wrapper').scrollTop($('.entry-wrapper').scrollTop() + $('#not_saved_entry_'+this.props.id).position().top)
        if(this.props.title == 'CopyToEntry') {
            $('#tiny_' + this.props.id + '_ifr').contents().find("#tinymce").html(this.props.content)
        }
    },
    shouldComponentUpdate: function() {
        return false; //prevent updating this component because it causes the page container to scroll upwards and lose focus due to a bug in paste_preprocess.
    },
	render: function() {
        var item = this.state.subitem
        var not_saved_entry_id = 'not_saved_entry_'+this.props.id
        var tinyID = 'tiny_'+this.props.id
            return (
                <div id={not_saved_entry_id} className={'not_saved_entry'}>
                    <div className={'row-fluid entry-outer'} style={{border: '3px solid blue',marginLeft: 'auto', marginRight: 'auto', width:'99.3%'}}>
                        <div className={'row-fluid entry-header'}>
                            <div className="entry-header-inner">[<a style={{color:'black'}} href={"#/not_saved_0"}>Not_Saved_0</a>]by {whoami}
                                <span className='pull-right' style={{display:'inline-flex',paddingRight:'3px'}}>
                                    <Button bsSize={'xsmall'} onClick={this.submit}>Submit</Button>
                                    <Button bsSize={'xsmall'} onClick={this.onCancel}>Cancel</Button>
                                </span>
                            </div>
                        </div>
                        <TinyMCE id={tinyID} content={""} className={'inputtext'} config={{plugins: 'advlist lists link image charmap print preview hr anchor pagebreak searchreplace wordcount visualblocks visualchars code fullscreen insertdatetime media nonbreaking save table contextmenu directionality emoticons template paste textcolor colorpicker textpattern imagetools', paste_retain_style_properties: 'all', paste_data_images:true, paste_preprocess: function(plugin, args) { function replaceA(string) { return string.replace(/<(\/)?a([^>]*)>/g, '<$1span$2>') }; args.content = replaceA(args.content); },relative_urls: false, remove_script_host:false, link_assume_external_targets:true, toolbar1: 'full screen spellchecker | undo redo | bold italic | alignleft aligncenter alignright | bullist numlist | forecolor backcolor fontsizeselect fontselect formatselect | blockquote code link image insertdatetime', theme:'modern', content_css:'/css/entryeditor.css', height:250}} />  
                    </div>    
                </div>
            )
    },
    onCancel: function(){
        this.props.addedentry()
        this.setState({change:false})
        //click refresh detail button on screen to refresh data while the tinymce window was open since it held back updates of the DOM
        if ($('#refresh-detail')) {
            $('#refresh-detail').click();
        }
    },
	submit: function(){
        if($('#tiny_' + this.props.id + '_ifr').contents().find("#tinymce").text() == "" && $('#' + this.props.id + '_ifr').contents().find("#tinymce").find('img').length == 0) {
            alert("Please Add Some Text")
        }
        else {    
            if(this.props.stage == 'Reply') {
                var data = new Object()
                $('#tiny_' + this.props.id + '_ifr').contents().find("#tinymce").each(function(x,y){
                    $(y).find('img').each(function(key, value){
                        if ($(value)[0].src.startsWith('blob')) { //Checking to see if it's a locally copied file
                            var canvas = document.createElement('canvas');
                            var set = new Image();
                            set = $(value);
                            canvas.width =  set[0].width;
                            canvas.height = set[0].height;
                            var ctx = canvas.getContext('2d');
                            ctx.drawImage(set[0], 0, 0);
                            var dataURL = canvas.toDataURL("image/png");
                            $(value).attr('src', dataURL);
                        }
                    })
                })    
                data = JSON.stringify({parent: Number(this.props.id), body: $('#tiny_' + this.props.id + '_ifr').contents().find("#tinymce").html(), target_id:Number(this.props.targetid) , target_type: this.props.type})
                $.ajax({
                    type: 'post',
                    url: '/scot/api/v2/entry',
                    data: data,
                    contentType: 'application/json; charset=UTF-8',
                    success: function(response){
                    }.bind(this),
                    error: function(response) {
                        this.props.errorToggle("Failed to add entry.")
                    }.bind(this) 
                })               
                this.props.addedentry()
            }
            else if (this.props.stage == 'Edit'){
                $.ajax({
                    type: 'GET',
                    url: '/scot/api/v2/entry/'+this.props.id
                }).success(function(response){
                    if(recently_updated != response.updated){
                        this.forEdit(false)
                        var set = false
                        var Confirm = {
                            launch: function(set){
                                this.forEdit(set)
                            }.bind(this)
                        }
                        $.confirm({
                            icon: 'glyphicon glyphicon-warning',
                            confirmButtonClass: 'btn-info',
                            cancelButtonClass: 'btn-info',
                            confirmButton: 'Yes, override change?',
                            cancelButton: 'No, Keep change from ' + response.owner + '?',
                            content: response.owner+"'s edit:" +'\n\n'+response.body,
                            backgroundDismiss: false,
                            title: "Edit Conflict" + '\n\n',
                            confirm: function(){
                                Confirm.launch(true)
                            },
                            cancel: function(){
                                return 
                            }
                        })
                    } else {
                        this.forEdit(true)
                    }
                }.bind(this))
            }
            else if(this.props.type == 'alert'){ 
                var data;
                $('#tiny_' + this.props.id + '_ifr').contents().find("#tinymce").each(function(x,y){
                    $(y).find('img').each(function(key, value){
                        if ($(value)[0].src.startsWith('blob')) {   //Checking if it's a locally copied file
                            var canvas = document.createElement('canvas');
                            var set = new Image();
                            set = $(value);
                            canvas.width =  set[0].width;
                            canvas.height = set[0].height;
                            var ctx = canvas.getContext('2d');
                            ctx.drawImage(set[0], 0, 0);
                            var dataURL = canvas.toDataURL("image/png");
                            $(value).attr('src', dataURL);
                        }
                    })
                })
                data = JSON.stringify({body: $('#tiny_' + this.props.id + '_ifr').contents().find("#tinymce").html(), target_id: Number(this.props.targetid), target_type: 'alert',  parent: 0})
                $.ajax({
                    type: 'post', 
                    url: '/scot/api/v2/entry',
                    data: data,
                    contentType: 'application/json; charset=UTF-8',
                    success: function(response){
                    }.bind(this),
                    error: function(response) {
                        this.props.errorToggle("Failed to add entry.")
                    }.bind(this) 
                })
                this.props.addedentry()
            }	
            else {
                var data = new Object();
                $('#tiny_' + this.props.id + '_ifr').contents().find("#tinymce").each(function(x,y){
                    $(y).find('img').each(function(key, value){
                        if ($(value)[0].src.startsWith('blob')) {   //Checking if its a locally copied file 
                            var canvas = document.createElement('canvas');
                            var set = new Image();
                            set = $(value);
                            canvas.width =  set[0].width;
                            canvas.height = set[0].height;
                            var ctx = canvas.getContext('2d');
                            ctx.drawImage(set[0], 0, 0);
                            var dataURL = canvas.toDataURL("image/png");
                            $(value).attr('src', dataURL); 
                        }
                    }) 
                }) 
                data = {parent: 0, body: $('#tiny_' + this.props.id + '_ifr').contents().find("#tinymce").html(), target_id: Number(this.props.targetid) , target_type: this.props.type}
                $.ajax({
                    type: 'post',
                    url: '/scot/api/v2/entry',
                    data: JSON.stringify(data),
                    contentType: 'application/json; charset=UTF-8',
                    success: function(response){
                    }.bind(this),
                    error: function(response) {
                        this.props.errorToggle("Failed to add entry.")
                    }.bind(this)
                })
                this.props.addedentry()
            }
        }
    },
    forEdit: function(set){
        if(set){
            $('#tiny_' + this.props.id + '_ifr').contents().find("#tinymce").each(function(x,y){
                $(y).find('img').each(function(key, value){
                    if ($(value)[0].src.startsWith('blob')) {   //Checking if its a lcoally copied file
                        var canvas = document.createElement('canvas');
                        var set = new Image();
                        set = $(value);
                        canvas.width =  set[0].width;
                        canvas.height = set[0].height;
                        var ctx = canvas.getContext('2d');
                        ctx.drawImage(set[0], 0, 0);
                        var dataURL = canvas.toDataURL("image/png");
                        $(value).attr('src', dataURL);
                    }
                })
            })
            var data = {
                parent: Number(this.props.parent), 
                body: $('#tiny_' + this.props.id + '_ifr').contents().find("#tinymce").html(), 
                target_id: Number(this.props.targetid) , 
                target_type: this.props.type
            }
            $.ajax({
                type: 'put',
                url: '/scot/api/v2/entry/'+this.props.id,
                data: JSON.stringify(data),
                contentType: 'application/json; charset=UTF-8',
                success: function(response){
                    
                }.bind(this),
                error: function(response) {
                    this.props.errorToggle("Failed to edit entry.")
                }.bind(this)
            })

            this.props.addedentry()
        }
    }
});

module.exports = AddEntryModal

