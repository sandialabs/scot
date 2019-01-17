import React from 'react';
import ReactDOM from 'react-dom';
import Panel from 'react-bootstrap/lib/Panel.js';
import Button from 'react-bootstrap/lib/Button.js';
import Modal from 'react-bootstrap/lib/Modal.js';
import $ from 'jquery'

export class Api extends React.Component {
  constructor(props) {
    super(props);
    this.GetKeys = this.GetKeys.bind(this);
    this.GetAvailableGroups = this.GetAvailableGroups.bind(this);
    this.CreateKey = this.CreateKey.bind(this);
    this.DeleteKey = this.DeleteKey.bind(this);
    this.GroupChange = this.GroupChange.bind(this);
    this.ToggleActiveStatus = this.ToggleActiveStatus.bind(this);
    this.state = {
      Api: null,
      keys: null,
      availableGroups: null,
    };
  }

  GetKeys() {
    $.ajax({
      type: 'get',
      url: '/scot/api/v2/apikey',
      success: function (data) {
        this.setState({ keys: data.records });
      }.bind(this),
      error: function () {
        this.setState({ keys: 'failed to get keys' });
      }.bind(this),
    });
  }

  GetAvailableGroups() {
    $.ajax({
      type: 'get',
      url: '/scot/api/v2/group?limit=0',
      success: function (data) {
        this.setState({ availableGroups: data.records });
      }.bind(this),
    });
  }

  CreateKey() {
    $.ajax({
      type: 'post',
      url: '/scot/api/v2/apikey',
      success: function () {
        this.GetKeys();
      }.bind(this),
    });
  }

  DeleteKey(e) {
    $.ajax({
      type: 'delete',
      url: `/scot/api/v2/apikey/${e.target.id}`,
      success: function () {
        this.GetKeys();
      }.bind(this),
    });
  }

  GroupChange(id, newGroup) {
    $.ajax({
      type: 'PUT',
      url: `/scot/api/v2/apikey/${id}`,
      data: JSON.stringify({ groups: newGroup }),
      contentType: 'application/json; charset=UTF-8',
      success: function () {
        this.GetKeys();
      }.bind(this),
    });
  }

  ToggleActiveStatus(id, newStatus) {
    $.ajax({
      type: 'PUT',
      url: `/scot/api/v2/apikey/${id}`,
      contentType: 'application/json; charset=UTF-8',
      data: JSON.stringify({ active: newStatus }),
      success: function () {
        this.GetKeys();
      }.bind(this),
    });
  }

  componentDidMount() {
    this.GetKeys();
    this.GetAvailableGroups();
  }

  render() {
    const keysArr = [];
    if (this.state.keys != undefined) {
      for (let i = 0; i < this.state.keys.length; i++) {
        let keyActiveStatus;
        let keyActiveStatusCss;
        const keyGroups = [];
        if (this.state.keys[i].active == 1) {
          keyActiveStatus = <span style={{ color: 'green' }}>active</span>
        }

        else {
          keyActiveStatus = <span style={{ color: 'red' }}>not active</span>
        }
        if (this.state.keys[i].groups != undefined) {
          for (let j = 0; j < this.state.keys[i].groups.length; j++) {
            keyGroups.push(<div>this.state.keys[i].groups[j]</div>);
          }
        }
        keysArr.push(<div>
          <div>
            <div>{this.state.keys[i].apikey}</div>
            <div>{this.state.keys[i].username}</div>
            <span>Key is {keyActiveStatus}</span>
            <span className='pull-right pointer'><i id={this.state.keys[i].id} className="fa fa-trash" aria-hidden="true" onClick={this.DeleteKey}></i></span>
            <div>
              <GroupModal id={this.state.keys[i].id} currentGroups={this.state.keys[i].groups} allGroups={this.state.availableGroups} GroupChange={this.GroupChange} ToggleActiveStatus={this.ToggleActiveStatus} keyActiveStatus={keyActiveStatus} keyActiveStatusCss={keyActiveStatusCss} />
            </div>
          </div>
          <hr />
        </div>);
      }
    }
    return (
      <div id='api' className='administration_api'>
        <h1>API</h1>
        <Panel bsStyle='info' header='Your api keys'>
          {keysArr}
        </Panel>

        <Button bsStyle='success' onClick={this.CreateKey}>Create API Key</Button>
      </div>
    );
  }
}

class GroupModal extends React.Component {
  constructor(props) {
    super(props);
    this.Open = this.Open.bind(this);
    this.Close = this.Close.bind(this);
    this.DeleteGroup = this.DeleteGroup.bind(this);
    /* this.AddGroup = this.AddGroup.bind(this); */ // Removed as we don't add groups to an api key
    this.ToggleActiveStatus = this.ToggleActiveStatus.bind(this);
    this.state = {
      showModal: false,
    };
  }

  Open() {
    this.setState({ showModal: true });
  }

  Close() {
    this.setState({ showModal: false });
  }

  DeleteGroup(e) {
    const newGroups = [];
    for (const i of this.props.currentGroups) {
      if (i != undefined) {
        if (i != e.target.parentNode.textContent) {
          newGroups.push(i);
        }
      }
    }
    this.props.GroupChange(this.props.id, newGroups);
  }
  /* Removed as we don't add groups to an api key
  AddGroup (e) {
      var newGroups = [];
      for ( const i of this.props.currentGroups) {
          if ( i != undefined ) {
              if ( i != e.target.textContent ) {
                  newGroups.push(i);
              }
          }
      }
      newGroups.push( e.target.textContent );
      this.props.GroupChange(this.props.id, newGroups);
  }
  */
  ToggleActiveStatus() {
    let newStatus;
    if (this.props.keyActiveStatus == 'active') {
      newStatus = 0;
    } else {
      newStatus = 1;
    }
    this.props.ToggleActiveStatus(this.props.id, newStatus);
  }

  render() {
    // var allGroupArray = [];  //Removed as we don't add groups to an api key
    const currentGroupArray = [];
    const currentGroupArrayEdit = [];
    // //Removed as we don't add groups to an api key
    /* if ( this.props.allGroups ) {
        for ( const i of this.props.allGroups ) {
            allGroupArray.push( <Button id={this.props.id} onClick={this.AddGroup} bsSize='xsmall'>{i.name}</Button> );
        }
    } */
    if (this.props.currentGroups) {
      for (const j of this.props.currentGroups) {
        currentGroupArrayEdit.push(<span className='tagButton'>{j}<i id={this.props.id} onClick={this.DeleteGroup} className='fa fa-times tagButtonClose'></i></span>);
      }
      for (const k of this.props.currentGroups) {
        currentGroupArray.push(<span className='tagButton'>{k}</span>);
      }
    }
    return (
      <div>
        Current Groups: {currentGroupArray}
        <div>
          <Button onClick={this.Open} bsSize='small'>Edit API key settings</Button>
        </div>
        <Modal show={this.state.showModal} onHide={this.Close}>
          <Modal.Header closeButton>
            <Modal.Title>Edit API key settings</Modal.Title>
          </Modal.Header>
          <Modal.Body>
            <div>
              <h4>Current Groups:</h4>
              {currentGroupArrayEdit}
            </div>
            {/* <div>
                            Click to add group:
                            {allGroupArray}
                        </div> */}
            <hr />
            <div>
              Key is <span className={this.props.keyActiveStatusCss}>{this.props.keyActiveStatus}</span>
              <Button onClick={this.ToggleActiveStatus} bsSize='xsmall'>Toggle Active Status</Button>
            </div>
          </Modal.Body>
        </Modal>
      </div>
    );
  }
}


