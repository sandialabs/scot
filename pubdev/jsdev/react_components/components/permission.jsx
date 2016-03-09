var React           = require('react');
var Button          = require('react-bootstrap/lib/Button');
var ReactTags       = require('react-tag-input').WithContext;

var SelectedPermission = React.createClass({
    getInitialState: function () {
        return {readPermissionEntry:false,modifyPermissionEntry:false}
    },
    toggleNewReadPermission: function () {
        if (this.state.readPermissionEntry == false) {
            this.setState({readPermissionEntry:true})

        } else if (this.state.readPermissionEntry == true) {
            this.setState({readPermissionEntry:false})
        };
    },
    toggleNewModifyPermission: function () {
        if (this.state.modifyPermissionEntry == false) {
            this.setState({modifyPermissionEntry:true})

        } else if (this.state.modifyPermissionEntry == true) {
            this.setState({modifyPermissionEntry:false})
        };
    },
    permissionsfunc: function(permissionData) {
        console.log(permissionData.groups);
        var writepermissionsarr = [];
        var readpermissionsarr = [];
        var readwritepermissionsarr = [];
        for (prop in permissionData.groups) {
            var fullprop = permissionData.groups[prop]
            if (prop == 'read') {
                permissionData.groups[prop].forEach(function(fullprop) {
                    readpermissionsarr.push(fullprop)
                });
            } else if (prop == 'modify') {
                permissionData.groups[prop].forEach(function(fullprop) {
                    writepermissionsarr.push(fullprop)
                });
            };
        };
        readwritepermissionsarr.push(readpermissionsarr);
        readwritepermissionsarr.push(writepermissionsarr);
        return readwritepermissionsarr;
    }, 
    render: function() {
        var modifyRows = [];
        var readRows = [];
        var permissionData = this.props.permissionData;
        var data = this.permissionsfunc(permissionData);//pos 0 is read and pos 1 is write
        var id = this.props.id;
        var type = this.props.type;
        for (var prop in data[0]) { 
            var read_modify = 'read';
            readRows.push(<PermissionIterator data={data[0][prop]} dataRead={data[0]} dataModify={data[1]} id={id} type={type} read_modify={read_modify} updated={this.props.updated} />);
        }
        for (var prop in data[1]) {
            var read_modify = 'modify'; 
            modifyRows.push(<PermissionIterator data={data[1][prop]} dataRead={data[0]} dataModify={data[1]} id={id} type={type} read_modify={read_modify} updated={this.props.updated} />);
        }
        if (type == 'entry') {
            return ( 
               <div id="" className="">
                    <span style={{display:'inline-flex'}}>
                        Read Groups: {readRows}
                        {this.state.readPermissionEntry ? <span style={{display:'inherit',color:'white'}}><NewPermission readUpdate={1} modifyUpdate={0} dataRead={data[0]} dataModify={data[1]} type={type} id={id} toggleNewReadPermission={this.toggleNewReadPermission} updated={this.props.updated} permissionsToggle={this.props.permissionsToggle}/></span>: null}
                        {this.state.readPermissionEntry ? <Button bsSize='xsmall' bsStyle={'danger'} onClick={this.toggleNewReadPermission}><span className='glyphicon glyphicon-minus' ariaHidden='true'></span></Button> : <Button bsSize='xsmall' bsStyle={'success'} onClick={this.toggleNewReadPermission}><span className='glyphicon glyphicon-plus' ariaHidden='true'></span></Button>} 
                        
                        <span style={{paddingLeft:'5px'}}>Modify Groups: </span>{modifyRows}
                        {this.state.modifyPermissionEntry ? <span style={{display:'inherit',color:'white'}}><NewPermission readUpdate={0} modifyUpdate={1} dataRead={data[0]} dataModify={data[1]} type={type} id={id} toggleNewModifyPermission={this.toggleNewModifyPermission} updated={this.props.updated} permissionsToggle={this.props.permissionsToggle}/></span> : null}
                        {this.state.modifyPermissionEntry ? <Button bsSize='xsmall' bsStyle={'danger'} onClick={this.toggleNewModifyPermission}><span className='glyphicon glyphicon-minus' ariaHidden='true'></span></Button> : <Button bsSize='xsmall' bsStyle={'success'} onClick={this.toggleNewModifyPermission}><span className='glyphicon glyphicon-plus' ariaHidden='true'></span></Button>}
                    </span>
                </div> 
            )
        }
        else {
            return (
                <div id="" className="toolbar entry-header-info-null">
                    <img src="/images/close_toolbar.png" className="close_toolbar" onClick={this.props.permissionsToggle} />
                    <span style={{display:'inline-flex',paddingRight:'10px',paddingLeft:'5px'}}>
                        <h3>Permissions:</h3>
                    </span>
                        Read Groups: {readRows} 
                        {this.state.readPermissionEntry ? <NewPermission readUpdate={1} modifyUpdate={0} dataRead={data[0]} dataModify={data[1]} type={type} id={id} toggleNewReadPermission={this.toggleNewReadPermission} updated={this.props.updated} permissionsToggle={this.props.permissionsToggle}/> : null }
                        {this.state.readPermissionEntry ? <Button bsSize={'xsmall'} bsStyle={'danger'} onClick={this.toggleNewReadPermission}><span className='glyphicon glyphicon-minus' ariaHidden='true'></span></Button> : <Button bsSize={'xsmall'} bsStyle={'success'} onClick={this.toggleNewReadPermission}><span className='glyphicon glyphicon-plus' ariaHidden='true'></span></Button>}
                        <span style={{paddingLeft:'5px'}}>Modify Groups: </span>{modifyRows}
                        {this.state.modifyPermissionEntry ? <NewPermission readUpdate={0} modifyUpdate={1} dataRead={data[0]} dataModify={data[1]} type={type} id={id} toggleNewModifyPermission={this.toggleNewModifyPermission} updated={this.props.updated} permissionsToggle={this.props.permissionsToggle}/> : null}
                        {this.state.modifyPermissionEntry ? <Button bsSize={'xsmall'} bsStyle={'danger'} onClick={this.toggleNewModifyPermission}><span className='glyphicon glyphicon-minus' ariaHidden='true'></span></Button> : <Button bsSize={'xsmall'} bsStyle={'success'} onClick={this.toggleNewModifyPermission}><span className='glyphicon glyphicon-plus' ariaHidden='true'></span></Button>}
                </div> 
            )
        }
    }
}); 

var PermissionIterator = React.createClass({
   permissionDelete: function () {
        var newPermission = {};
        var tempArr = [];
        var data = this.props.data;
        var dataRead = this.props.dataRead;
        var dataModify = this.props.dataModify;
        var toggle = this.props.permissionsToggle;
        if (this.props.read_modify == 'read') {
            for (var prop in dataRead) {
                if (dataRead[prop] != data) {
                    tempArr.push(dataRead[prop]);
                }
            }
            newPermission.read = tempArr;
            newPermission.modify = dataModify;
        } else if (this.props.read_modify == 'modify') {
            for (var prop in dataModify) {
                if (dataModify[prop] != data) {  
                    tempArr.push(dataModify[prop]);
                }
            }
            newPermission.read = dataRead;
            newPermission.modify = tempArr;
        } 
        $.ajax({
            type: 'put',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.id,
            data: JSON.stringify({'groups':newPermission}),
            contentType: 'application/json; charset=UTF-8',
            success: function(data) {
                console.log('success');
                this.props.updated();
            }.bind(this),
            error: function() {
                this.props.updated('red','Failed to delete group');
            }.bind(this)
        })
   },
   render: function() {
        data = this.props.data;
        type = this.props.type;
        if (type == 'entry') {
            return (
                <Button id="permission_source" bsSize='xsmall' onClick={this.permissionDelete}>{data}<span style={{paddingLeft:'3px'}} className="glyphicon glyphicon-remove" ariaHidden="true"></span></Button>
            )
        } else {
            return ( 
                <Button id="permission_source" bsSize='xsmall' onClick={this.permissionDelete}>{data}<span style={{paddingLeft:'3px'}} className="glyphicon glyphicon-remove" ariaHidden="true"></span></Button> 
            )
        }
   }
});

var NewPermission = React.createClass({
    getInitialState: function() {
        return {
            suggestions: this.props.options
        }
    },
    handleAddition: function(tag) {
        var newPermission = {};
        var dataRead = this.props.dataRead;
        var dataModify = this.props.dataModify;
        var toggle = this.props.permissionsToggle;
        if (this.props.readUpdate == 1) {
            dataRead.push(tag);     
        } else if (this.props.modifyUpdate == 1) {
            dataModify.push(tag);
        }
        if (this.props.toggleNewModifyPermission != undefined) {
            toggle = this.props.toggleNewModifyPermission;
        } else if (this.props.toggleNewReadPermission != undefined) {
            toggle = this.props.toggleNewReadPermission;
        }
        newPermission.read = dataRead;
        newPermission.modify = dataModify;
        $.ajax({
            type: 'put',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.id,
            data: JSON.stringify({'groups':newPermission}),
            contentType: 'application/json; charset=UTF-8',
            success: function(data) {
                console.log('success: permission added');
                toggle();
                this.props.updated();
            }.bind(this),
            error: function() {
                toggle();
                this.props.updated('red','Failed to add source');
            }.bind(this)
        });
    },
    handleInputChange: function(input) {
         //blank until there's a lookup for group permissions
        /*var arr = [];
        this.serverRequest = $.get('/scot/api/v2/ac/source/' + input, function (result) {
            var result = result.records;
            console.log(result);
            for (var prop in result) {
                arr.push(result[prop].value)
            }
            this.setState({suggestions:arr})
        }.bind(this));*/
    },
    handleDelete: function () {
        //blank since buttons are handled outside of this
    },
    handleDrag: function () {
        //blank since buttons are handled outside of this
    }, 
    render: function() { 
        var suggestions = this.state.suggestions;
        return (
            <span className='tag-new'>
                <ReactTags
                    suggestions={suggestions}
                    handleAddition={this.handleAddition}
                    handleInputChange={this.handleInputChange}
                    handleDelete={this.handleDelete}
                    handleDrag={this.handleDrag}
                    minQueryLength={1}
                    customCSS={1}/>
            </span>
        )
    }
});
module.exports = SelectedPermission
