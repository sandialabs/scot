import React from "react";
let Modal = require("react-modal");
let Button = require("react-bootstrap/lib/Button");
const customStyles = {
  content: {
    top: "50%",
    left: "50%",
    right: "auto",
    bottom: "auto",
    marginRight: "-50%",
    transform: "translate(-50%, -50%)"
  }
};

export default class Entities extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      entitiesBody: true
    };
  }

  render = () => {
    return (
      <div>
        <Modal
          isOpen={true}
          onRequestClose={this.props.entitiesToggle}
          style={customStyles}
        >
          <div className="modal-header">
            <img
              src="/images/close_toolbar.png"
              className="close_toolbar"
              alt=""
              onClick={this.props.entitiesToggle}
            />
            <h3 id="myModalLabel">List of Entities</h3>
          </div>
          <div
            className="modal-body"
            style={{ maxHeight: "50vh", overflowY: "auto" }}
          >
            {this.state.entitiesBody ? (
              <EntitiesData
                data={this.props.entityData}
                flairToolbarToggle={this.props.flairToolbarToggle}
              />
            ) : null}
          </div>
          <div className="modal-footer">
            <Button onClick={this.props.entitiesToggle}>Done</Button>
          </div>
        </Modal>
      </div>
    );
  };
}

class EntitiesData extends React.Component {
  render = () => {
    let rows = [];
    let data = this.props.data;
    let originalobj = {};
    originalobj["entities"] = {};
    let obj = originalobj.entities;
    for (let prop in data) {
      let subobj = {};
      let type = data[prop].type;
      let id = data[prop].id;
      let value = prop;
      subobj[id] = value;
      if (obj.hasOwnProperty(type)) {
        obj[type].push(subobj);
      } else {
        let arr = [];
        arr.push(subobj);
        obj[type] = arr;
      }
    }
    for (let prop in obj) {
      let type = prop;
      let value = obj[prop];
      rows.push(
        <EntitiesDataHeaderIterator
          type={type}
          value={value}
          flairToolbarToggle={this.props.flairToolbarToggle}
        />
      );
    }
    return <div>{rows}</div>;
  };
}

class EntitiesDataHeaderIterator extends React.Component {
  render = () => {
    let rows = [];
    let type = this.props.type;
    let value = this.props.value;
    for (let i = 0; i < value.length; i++) {
      let eachValue = value[i];
      let entityId = null;
      let entityValue = null;
      for (let prop in eachValue) {
        entityId = prop;
        entityValue = eachValue[prop];
      }
      rows.push(
        <EntitiesDataValueIterator
          entityValue={entityValue}
          entityId={entityId}
          flairToolbarToggle={this.props.flairToolbarToggle}
        />
      );
    }
    return (
      <div style={{ border: "1px solid black", width: "500px" }}>
        <h3>{type}</h3>
        <div
          style={{
            fontWeight: "normal",
            maxHeight: "300px",
            overflowY: "auto"
          }}
        >
          {rows}
        </div>
      </div>
    );
  };
}

class EntitiesDataValueIterator extends React.Component {
  toggle = () => {
    this.props.flairToolbarToggle(
      this.props.entityId,
      this.props.entityValue,
      "entity"
    );
  };

  render = () => {
    let entityValue = this.props.entityValue;
    return (
      <a href="javascript: void(0)" onClick={this.toggle}>
        {entityValue}
        <br />
      </a>
    );
  };
}
