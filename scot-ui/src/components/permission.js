import React from "react";
import $ from "jquery";
let Button = require("react-bootstrap/lib/Button");
let ReactTags = require("react-tag-input").WithContext;

let SelectedPermission = React.createClass({
  getInitialState: function() {
    return { readPermissionEntry: false, modifyPermissionEntry: false };
  },
  toggleNewReadPermission: function() {
    if (this.state.readPermissionEntry == false) {
      this.setState({ readPermissionEntry: true });
    } else if (this.state.readPermissionEntry == true) {
      this.setState({ readPermissionEntry: false });
    }
  },
  toggleNewModifyPermission: function() {
    if (this.state.modifyPermissionEntry == false) {
      this.setState({ modifyPermissionEntry: true });
    } else if (this.state.modifyPermissionEntry == true) {
      this.setState({ modifyPermissionEntry: false });
    }
  },
  permissionsfunc: function(permissionData) {
    console.log(permissionData.groups);
    let writepermissionsarr = [];
    let readpermissionsarr = [];
    let readwritepermissionsarr = [];
    for (let prop in permissionData.groups) {
      let fullprop = permissionData.groups[prop];
      if (prop == "read") {
        permissionData.groups[prop].forEach(function(fullprop) {
          readpermissionsarr.push(fullprop);
        });
      } else if (prop == "modify") {
        permissionData.groups[prop].forEach(function(fullprop) {
          writepermissionsarr.push(fullprop);
        });
      }
    }
    readwritepermissionsarr.push(readpermissionsarr);
    readwritepermissionsarr.push(writepermissionsarr);
    return readwritepermissionsarr;
  },
  render: function() {
    let modifyRows = [];
    let readRows = [];
    let permissionData = this.props.permissionData;
    let data = this.permissionsfunc(permissionData); //pos 0 is read and pos 1 is write
    let id = this.props.id;
    let type = this.props.type;
    if (data[0] !== undefined) {
      for (let i = 0; i < data[0].length; i++) {
        let read_modify = "read";
        readRows.push(
          <PermissionIterator
            data={data[0][i]}
            dataRead={data[0]}
            dataModify={data[1]}
            updateid={this.props.updateid}
            id={id}
            type={type}
            read_modify={read_modify}
            updated={this.props.updated}
          />
        );
      }
    }
    if (data[1] !== undefined) {
      for (let i = 0; i < data[1].length; i++) {
        let read_modify = "modify";
        modifyRows.push(
          <PermissionIterator
            data={data[1][i]}
            dataRead={data[0]}
            dataModify={data[1]}
            updateid={this.props.updateid}
            id={id}
            type={type}
            read_modify={read_modify}
            updated={this.props.updated}
          />
        );
      }
    }
    if (type == "entry") {
      return (
        <div id="" className="">
          <span style={{ display: "inline-flex" }}>
            Read Groups: {readRows}
            {this.state.readPermissionEntry ? (
              <span style={{ display: "inherit", color: "white" }}>
                <NewPermission
                  readUpdate={1}
                  modifyUpdate={0}
                  dataRead={data[0]}
                  dataModify={data[1]}
                  type={type}
                  updateid={this.props.updateid}
                  id={id}
                  toggleNewReadPermission={this.toggleNewReadPermission}
                  updated={this.props.updated}
                  permissionsToggle={this.props.permissionsToggle}
                />
              </span>
            ) : null}
            {this.state.readPermissionEntry ? (
              <Button
                bsSize="xsmall"
                bsStyle={"danger"}
                onClick={this.toggleNewReadPermission}
              >
                <span
                  className="glyphicon glyphicon-minus"
                  aria-hidden="true"
                />
              </Button>
            ) : (
              <Button
                bsSize="xsmall"
                bsStyle={"success"}
                onClick={this.toggleNewReadPermission}
              >
                <span className="glyphicon glyphicon-plus" aria-hidden="true" />
              </Button>
            )}
            <span style={{ paddingLeft: "5px" }}>Modify Groups: </span>
            {modifyRows}
            {this.state.modifyPermissionEntry ? (
              <span style={{ display: "inherit", color: "white" }}>
                <NewPermission
                  readUpdate={0}
                  modifyUpdate={1}
                  dataRead={data[0]}
                  dataModify={data[1]}
                  type={type}
                  updateid={this.props.updateid}
                  id={id}
                  toggleNewModifyPermission={this.toggleNewModifyPermission}
                  updated={this.props.updated}
                  permissionsToggle={this.props.permissionsToggle}
                />
              </span>
            ) : null}
            {this.state.modifyPermissionEntry ? (
              <Button
                bsSize="xsmall"
                bsStyle={"danger"}
                onClick={this.toggleNewModifyPermission}
              >
                <span
                  className="glyphicon glyphicon-minus"
                  aria-hidden="true"
                />
              </Button>
            ) : (
              <Button
                bsSize="xsmall"
                bsStyle={"success"}
                onClick={this.toggleNewModifyPermission}
              >
                <span className="glyphicon glyphicon-plus" aria-hidden="true" />
              </Button>
            )}
          </span>
        </div>
      );
    } else {
      return (
        <div
          id=""
          className="toolbar entry-header-info-null"
          style={{ paddingTop: "0px" }}
        >
          <span
            style={{
              display: "inline-flex",
              paddingRight: "10px",
              paddingLeft: "5px"
            }}
          >
            <h4>Permissions:</h4>
          </span>
          Read Groups: {readRows}
          {this.state.readPermissionEntry ? (
            <NewPermission
              readUpdate={1}
              modifyUpdate={0}
              dataRead={data[0]}
              dataModify={data[1]}
              type={type}
              updateid={this.props.updateid}
              id={id}
              toggleNewReadPermission={this.toggleNewReadPermission}
              updated={this.props.updated}
              permissionsToggle={this.props.permissionsToggle}
            />
          ) : null}
          {this.state.readPermissionEntry ? (
            <Button
              bsSize={"xsmall"}
              bsStyle={"danger"}
              onClick={this.toggleNewReadPermission}
            >
              <span className="glyphicon glyphicon-minus" aria-hidden="true" />
            </Button>
          ) : (
            <Button
              bsSize={"xsmall"}
              bsStyle={"success"}
              onClick={this.toggleNewReadPermission}
            >
              <span className="glyphicon glyphicon-plus" aria-hidden="true" />
            </Button>
          )}
          <span style={{ paddingLeft: "5px" }}>Modify Groups: </span>
          {modifyRows}
          {this.state.modifyPermissionEntry ? (
            <NewPermission
              readUpdate={0}
              modifyUpdate={1}
              dataRead={data[0]}
              dataModify={data[1]}
              type={type}
              updateid={this.props.updateid}
              id={id}
              toggleNewModifyPermission={this.toggleNewModifyPermission}
              updated={this.props.updated}
              permissionsToggle={this.props.permissionsToggle}
            />
          ) : null}
          {this.state.modifyPermissionEntry ? (
            <Button
              bsSize={"xsmall"}
              bsStyle={"danger"}
              onClick={this.toggleNewModifyPermission}
            >
              <span className="glyphicon glyphicon-minus" aria-hidden="true" />
            </Button>
          ) : (
            <Button
              bsSize={"xsmall"}
              bsStyle={"success"}
              onClick={this.toggleNewModifyPermission}
            >
              <span className="glyphicon glyphicon-plus" aria-hidden="true" />
            </Button>
          )}
          <img
            src="/images/close_toolbar.png"
            className="close_toolbar"
            onClick={this.props.permissionsToggle}
          />
        </div>
      );
    }
  }
});

let PermissionIterator = React.createClass({
  getInitialState: function() {
    return {
      key: this.props.updateid
    };
  },
  permissionDelete: function() {
    let newPermission = {};
    let tempArr = [];
    let data = this.props.data;
    let dataRead = this.props.dataRead;
    let dataModify = this.props.dataModify;
    let toggle = this.props.permissionsToggle;
    if (this.props.read_modify == "read") {
      for (let i = 0; i < dataRead.length; i++) {
        if (dataRead[i] != data) {
          tempArr.push(dataRead[i]);
        }
      }
      newPermission.read = tempArr;
      newPermission.modify = dataModify;
    } else if (this.props.read_modify == "modify") {
      for (let j = 0; j < dataModify.length; j++) {
        if (dataModify[j] != data) {
          tempArr.push(dataModify[j]);
        }
      }
      newPermission.read = dataRead;
      newPermission.modify = tempArr;
    }
    $.ajax({
      type: "put",
      url: "scot/api/v2/" + this.props.type + "/" + this.props.id,
      data: JSON.stringify({ groups: newPermission }),
      contentType: "application/json; charset=UTF-8",
      success: function() {
        console.log("success");
      }.bind(this),
      error: function(data) {
        this.props.errorToggle("error Failed to delete group", data);
      }.bind(this)
    });
  },
  render: function() {
    let data = this.props.data;
    let type = this.props.type;
    if (type == "entry") {
      return (
        <span id="permission_source" className="permissionButton">
          {data}
          <span
            className="fa fa-times permissionButtonClose"
            aria-hidden="true"
            onClick={this.permissionDelete}
          />
        </span>
      );
    } else {
      return (
        <span id="permission_source" className="permissionButton">
          {data}
          <span
            className="fa fa-times permissionButtonClose"
            aria-hidden="true"
            onClick={this.permissionDelete}
          />
        </span>
      );
    }
  }
});

let NewPermission = React.createClass({
  getInitialState: function() {
    return {
      suggestions: this.props.options,
      key: this.props.updateid
    };
  },
  handleAddition: function(tag) {
    let newPermission = {};
    let dataRead = this.props.dataRead;
    let dataModify = this.props.dataModify;
    let toggle = this.props.permissionsToggle;
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
      type: "put",
      url: "scot/api/v2/" + this.props.type + "/" + this.props.id,
      data: JSON.stringify({ groups: newPermission }),
      contentType: "application/json; charset=UTF-8",
      success: function() {
        console.log("success: permission added");
        toggle();
      }.bind(this),
      error: function(data) {
        toggle();
        this.props.errorToggle("error Failed to add group", data);
      }.bind(this)
    });
  },
  handleInputChange: function(input) {
    //blank until there's a lookup for group permissions
    /*let arr = [];
        this.serverRequest = $.get('/scot/api/v2/ac/source/' + input, function (result) {
            let result = result.records;
            console.log(result);
            for (let prop in result) {
                arr.push(result[prop].value)
            }
            this.setState({suggestions:arr})
        }.bind(this));*/
  },
  handleDelete: function() {
    //blank since buttons are handled outside of this
  },
  handleDrag: function() {
    //blank since buttons are handled outside of this
  },
  render: function() {
    let suggestions = this.state.suggestions;
    return (
      <span className="tag-new">
        <ReactTags
          suggestions={suggestions}
          handleAddition={this.handleAddition}
          handleInputChange={this.handleInputChange}
          handleDelete={this.handleDelete}
          handleDrag={this.handleDrag}
          minQueryLength={1}
          customCSS={1}
        />
      </span>
    );
  }
});
module.exports = SelectedPermission;
