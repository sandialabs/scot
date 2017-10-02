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
        for (var prop in permissionData.groups) {
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
        if (data[0] !== undefined) {
            for (var i=0; i < data[0].length; i++) {
                var read_modify = 'read';
                readRows.push(<PermissionIterator data={data[0][i]} dataRead={data[0]} dataModify={data[1]} updateid={this.props.updateid} id={id} type={type} read_modify={read_modify} updated={this.props.updated} />);
            }
        }
        if (data[1] !== undefined) {
            for (var i=0; i < data[1].length; i++) {
                var read_modify = 'modify'; 
                modifyRows.push(<PermissionIterator data={data[1][i]} dataRead={data[0]} dataModify={data[1]} updateid={this.props.updateid} id={id} type={type} read_modify={read_modify} updated={this.props.updated} />);
            }
        }
        if (type == 'entry') {
            return ( 
               <div id="" className="">
                    <span style={{display:'inline-flex'}}>
                        Read Groups: {readRows}
                        {this.state.readPermissionEntry ? <span style={{display:'inherit',color:'white'}}><NewPermission readUpdate={1} modifyUpdate={0} dataRead={data[0]} dataModify={data[1]} type={type} updateid={this.props.updateid} id={id} toggleNewReadPermission={this.toggleNewReadPermission} updated={this.props.updated} permissionsToggle={this.props.permissionsToggle}/></span>: null}
                        {this.state.readPermissionEntry ? <Button bsSize='xsmall' bsStyle={'danger'} onClick={this.toggleNewReadPermission}><span className='glyphicon glyphicon-minus' aria-hidden='true'></span></Button> : <Button bsSize='xsmall' bsStyle={'success'} onClick={this.toggleNewReadPermission}><span className='glyphicon glyphicon-plus' aria-hidden='true'></span></Button>} 
                        
                        <span style={{paddingLeft:'5px'}}>Modify Groups: </span>{modifyRows}
                        {this.state.modifyPermissionEntry ? <span style={{display:'inherit',color:'white'}}><NewPermission readUpdate={0} modifyUpdate={1} dataRead={data[0]} dataModify={data[1]} type={type} updateid={this.props.updateid} id={id} toggleNewModifyPermission={this.toggleNewModifyPermission} updated={this.props.updated} permissionsToggle={this.props.permissionsToggle}/></span> : null}
                        {this.state.modifyPermissionEntry ? <Button bsSize='xsmall' bsStyle={'danger'} onClick={this.toggleNewModifyPermission}><span className='glyphicon glyphicon-minus' aria-hidden='true'></span></Button> : <Button bsSize='xsmall' bsStyle={'success'} onClick={this.toggleNewModifyPermission}><span className='glyphicon glyphicon-plus' aria-hidden='true'></span></Button>}
                    </span>
                </div> 
            )
        }
        else {
            return (
                <div id="" className="toolbar entry-header-info-null" style={{paddingTop:'0px'}}>
                    <span style={{display:'inline-flex',paddingRight:'10px',paddingLeft:'5px'}}>
                        <h4>Permissions:</h4>
                    </span>
                        Read Groups: {readRows} 
                        {this.state.readPermissionEntry ? <NewPermission readUpdate={1} modifyUpdate={0} dataRead={data[0]} dataModify={data[1]} type={type} updateid={this.props.updateid} id={id} toggleNewReadPermission={this.toggleNewReadPermission} updated={this.props.updated} permissionsToggle={this.props.permissionsToggle}/> : null }
                        {this.state.readPermissionEntry ? <Button bsSize={'xsmall'} bsStyle={'danger'} onClick={this.toggleNewReadPermission}><span className='glyphicon glyphicon-minus' aria-hidden='true'></span></Button> : <Button bsSize={'xsmall'} bsStyle={'success'} onClick={this.toggleNewReadPermission}><span className='glyphicon glyphicon-plus' aria-hidden='true'></span></Button>}
                        <span style={{paddingLeft:'5px'}}>Modify Groups: </span>{modifyRows}
                        {this.state.modifyPermissionEntry ? <NewPermission readUpdate={0} modifyUpdate={1} dataRead={data[0]} dataModify={data[1]} type={type} updateid={this.props.updateid} id={id} toggleNewModifyPermission={this.toggleNewModifyPermission} updated={this.props.updated} permissionsToggle={this.props.permissionsToggle}/> : null}
                        {this.state.modifyPermissionEntry ? <Button bsSize={'xsmall'} bsStyle={'danger'} onClick={this.toggleNewModifyPermission}><span className='glyphicon glyphicon-minus' aria-hidden='true'></span></Button> : <Button bsSize={'xsmall'} bsStyle={'success'} onClick={this.toggleNewModifyPermission}><span className='glyphicon glyphicon-plus' aria-hidden='true'></span></Button>}
                        <img src="/images/close_toolbar.png" className="close_toolbar" onClick={this.props.permissionsToggle} />
                </div> 
            )
        }
    }
}); 

var PermissionIterator = React.createClass({
    getInitialState: function() {
        return {
            key: this.props.updateid,
        }
    },
    permissionDelete: function () {
        var newPermission = {};
        var tempArr = [];
        var data = this.props.data;
        var dataRead = this.props.dataRead;
        var dataModify = this.props.dataModify;
        var toggle = this.props.permissionsToggle;
        if (this.props.read_modify == 'read') {
            for (var i=0; i < dataRead.length; i++) {
                if (dataRead[i] != data) {
                    tempArr.push(dataRead[i]);
                }
            }
            newPermission.read = tempArr;
            newPermission.modify = dataModify;
        } else if (this.props.read_modify == 'modify') {
            for (var i=0; i < dataModify.length; i++) {
                if (dataModify[i] != data) {  
                    tempArr.push(dataModify[i]);
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
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('error Failed to delete group', data);
            }.bind(this)
        })
   },
   render: function() {
        var data = this.props.data;
        var type = this.props.type;
        if (type == 'entry') {
            return (
                <span id="permission_source" className='permissionButton'>{data}<span className="fa fa-times permissionButtonClose" aria-hidden="true" onClick={this.permissionDelete} ></span></span>
            )
        } else {
            return ( 
                <span id="permission_source" className='permissionButton'>{data}<span className="fa fa-times permissionButtonClose" aria-hidden="true" onClick={this.permissionDelete}></span></span> 
            )
        }
   }
});

var NewPermission = React.createClass({
    getInitialState: function() {
        return {
            suggestions: this.props.options,
            key:this.props.updateid,
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
            }.bind(this),
            error: function(data) {
                toggle();
                this.props.errorToggle('error Failed to add group', data);
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
