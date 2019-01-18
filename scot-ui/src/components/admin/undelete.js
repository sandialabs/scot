import React, { PureComponent, Component } from 'react';
import ReactDOM from 'react-dom';
import PropTypes from 'prop-types';
import { Modal, Button, ButtonGroup, Panel, FormControl, Form, Col } from 'react-bootstrap';
import ReactTable from 'react-table';
import { removeMarkedItems } from '../marker';
import Notification from 'react-notification-system';
import $ from 'jquery'

const ACTION_BUTTONS = {
  READY: {
    style: 'default',
  },
  LOADING: {
    text: 'Processing...',
    style: 'default',
    disabled: true,
  },
  SUCCESS: {
    text: 'Success!',
    style: 'success',
  },
  ERROR: {
    text: 'Error!',
    style: 'danger',
  },
};

export class Undelete extends Component {
  constructor(props) {
    super(props);

    this.state = {
      data: [],
      allSelected: false,
    };

    this.handleTHeadCheckboxSelection = this.handleTHeadCheckboxSelection.bind(this);
    this.handleRowSelection = this.handleRowSelection.bind(this);
    this.handleCheckboxSelection = this.handleCheckboxSelection.bind(this);
    this.getDeletedItems = this.getDeletedItems.bind(this);
  }

  componentWillMount() {
    this.mounted = true;

    this.getDeletedItems();
  }

  componentWillUnmount() {
    this.mounted = false;
  }

  render() {

    const columns = [
      {
        Header: cell => {
          return (
            <div>
              <div className='mark-checkbox'><i className={`fa fa${this.state.allSelected ? '-check' : ''}-square-o`} aria-hidden="true"></i></div>

            </div>
          );
        },
        id: 'selected',
        accessor: d => d.selected,
        Cell: row => {
          return (
            <div>
              <div className='mark-checkbox'><i className={`fa fa${row.row.selected ? '-check' : ''}-square-o`} aria-hidden="true"></i></div>
            </div>
          );
        },
        maxWidth: 100,
        filterable: false,
      },
      {
        Header: 'Type',
        accessor: 'type',
        //id: 'target.type',
        //column: 'type',
        maxWidth: 150,
        sortable: true,
      },
      {
        Header: 'ID',
        accessor: 'data.id',
        id: 'data.id',
        column: 'id',
        maxWidth: 100,
        sortable: true,
      },
      {
        Header: 'Subject',
        accessor: 'data.subject',
        id: 'data.subject',
        column: 'subject',
        maxWidth: '100%',
        sortable: true,
      },
      {
        Header: 'Body',
        accessor: 'data.body',
        id: 'data.body',
        column: 'body',
        maxWidth: '100%',
        sortable: true,
      },

    ];

    let dataArr = [];
    for (let key in this.state.data) {
      dataArr.push(this.state.data[key]['data'])
    }

    return (
      <div>

        {this.state.data.length > 0 ?
          <ReactTable
            columns={columns}
            data={this.state.data}
            defaultPageSize={10}
            getTdProps={this.handleCheckboxSelection}
            getTheadThProps={this.handleTHeadCheckboxSelection}
            getTrProps={this.handleRowSelection}
            minRows={0}
            noDataText='No deleted items were found.'
            style={{
              maxHeight: '60vh'
            }}
            filterable
          />
          :
          <h3>No deleted items were found.</h3>
        }

        {this.state.data.length > 0 ? <Actions data={this.state.data} id={this.props.id} type={this.props.type} getDeletedItems={this.getDeletedItems} errorToggle={this.props.errorToggle} /> : null}
      </div>
    );
  }

  handleRowSelection(state, rowInfo, column) {
    return {
      onClick: event => {
        let data = this.state.data;

        for (let row of data) {
          if (rowInfo.row['data.id'] == row.data.id && rowInfo.row.type == row.type) {
            row.selected = true;
          } else {
            row.selected = false;
          }
        }

        this.setState({ data: data, allSelected: false });
        return;
      },
      style: {
        background: rowInfo != undefined ? rowInfo.row.selected ? 'rgb(174, 218, 255)' : null : null,
      }
    };
  }

  handleCheckboxSelection(state, rowInfo, column) {
    if (column.id == 'selected') {
      return {
        onClick: event => {
          let data = this.state.data;

          for (let row of data) {
            if (rowInfo.row['data.id'] == row.data.id && rowInfo.row.type == row.type) {
              if (row.selected) {
                row.selected = !row.selected;
              } else {
                row.selected = true;
              }
              break;
            }
          }

          this.setState({ data: data, allSelected: this.checkAllSelected(data) });
          event.stopPropagation();
          return;
        }
      };
    } else {
      return {};
    }
  }

  handleTHeadCheckboxSelection(state, rowInfo, column, instance) {
    if (column.id === 'selected') {
      return {
        onClick: event => {
          let data = this.state.data;
          let allSelected = !this.state.allSelected;

          for (let row of data) {
            for (let pageRow of state.pageRows) {
              if (row.data.id == pageRow['data.id'] && row.data.type == pageRow['data.type']) {                 //compare displayed rows to rows in dataset and only select those
                row.selected = allSelected;
                break;
              }
            }
          }

          this.setState({ data: data, allSelected: allSelected });
          return;
        }
      };
    } else {
      return {};
    }
  }

  checkAllSelected(data) {
    for (let row of data) {
      if (!row.selected) {
        return false;
      }
    }
    return true;
  }

  getDeletedItems() {
    $.ajax({
      type: 'get',
      url: '/scot/api/v2/deleted/?limit=0',
      success: function (data) {
        this.setState({ data: data.records });
      }.bind(this),
      error: function (data) {
        console.log('unable to get deleted items');
      }.bind(this),
    });
  }
}

class Actions extends Component {
  constructor(props) {
    super(props);

    this.state = {
      entry: false,
      thing: false,
      actionSuccess: false,
      linkContextString: null,
      linkPanel: false,
      pendingDelete: false,

      reparseButton: ACTION_BUTTONS.READY,
      deleteButton: ACTION_BUTTONS.READY,
      promoteButton: ACTION_BUTTONS.READY,
    };

    this.RemoveSelected = this.RemoveSelected.bind(this);
    this.MoveEntry = this.MoveEntry.bind(this);
    this.CopyEntry = this.CopyEntry.bind(this);
    this.EntryAjax = this.EntryAjax.bind(this);
    this.Link = this.Link.bind(this);
    this.LinkAjax = this.LinkAjax.bind(this);
    this.Reparse = this.Reparse.bind(this);
    this.ReparseAjax = this.ReparseAjax.bind(this);
    this.Promote = this.Promote.bind(this);
    this.PromoteAjax = this.PromoteAjax.bind(this);
    this.ToggleActionSuccess = this.ToggleActionSuccess.bind(this);
    this.ExpandLinkToggle = this.ExpandLinkToggle.bind(this);
    this.LinkContextChange = this.LinkContextChange.bind(this);
    this.deleteCallback = this.deleteCallback.bind(this);
    this.StartDelete = this.StartDelete.bind(this);
    this.Restore = this.Restore.bind(this);
    this.Purge = this.Purge.bind(this);
  }

  componentWillMount() {
    this.mounted = true;
  }

  componentWillUnmount() {
    this.mounted = false;
  }

  deleteCallback(success) {
    if (success === true) {
      this.RemoveSelected();
    }

    this.setState({
      pendingDelete: false,
    });
  }

  render() {
    let buttons = [];
    let entry = false, thing = false, alert = true;

    let numSelected = 0;
    for (let key of this.props.data) {
      if (key.type && key.selected) {
        numSelected++;

        if (key.type === 'entry') {
          entry = true;
        } else {
          thing = true;
        }

        if (key.type !== 'alert') {
          alert = false;
        }
      }
    }

    const addToEvent = numSelected != 0 && alert && this.props.type === 'event';

    const { reparseButton, deleteButton, promoteButton, pendingDelete } = this.state;

    let deleteThings = null;
    if (pendingDelete) {
      deleteThings = this.props.data.filter(thing => thing.selected)
        .map(thing => { return { type: thing.type, id: thing.id }; });
    }


    return (
      <div>
        <Notification ref='notificationSystem' />
        {this.state.actionSuccess ?
          <div>
            <Button bsStyle='success' onClick={this.props.getDeletedItems}>Action Successful! Click to reload data.</Button>
          </div>
          :
          <div style={{ display: 'grid' }}>
            <div>
              <h4 style={{ float: 'left' }}></h4> {this.props.data.length > 0 ? <h4 style={{ float: 'left' }}>Select a Deleted Object</h4> : null}
              <ButtonGroup style={{ float: 'right' }}>
                <Button bsStyle='success' onClick={this.Restore}>Restore</Button>
                <Button bsStyle='danger' onClick={this.Purge}>Purge</Button>
              </ButtonGroup>
            </div>
          </div>
        }
      </div>
    );
  }

  Restore(e) {
    for (let key of this.props.data) {
      if (key.selected) {
        $.ajax({
          type: 'put',
          url: '/scot/api/v2/deleted/' + key.id,
          data: JSON.stringify({ 'status': 'undelete' }),
          success: function () {
            let notification = this.refs.notificationSystem;
            notification.addNotification({
              message: 'Successfully Restored',
              level: 'success',
              autoDismiss: 0,
            });
            this.props.getDeletedItems();
          }.bind(this),
          error: function () {
            console.log('failed to restore items');
          }.bind(this),
        });
      }
    }
  }

  Purge(e) {
    for (let key of this.props.data) {
      if (key.selected) {
        $.ajax({
          type: 'delete',
          url: '/scot/api/v2/deleted/' + key.id,
          success: function () {
            let notification = this.refs.notificationSystem;
            notification.addNotification({
              message: 'Successfully Purged',
              level: 'success',
              autoDismiss: 0,
            });
            this.props.getDeletedItems();
          }.bind(this),
          error: function () {
            console.log('failed to purge items');
          }.bind(this)
        });
      }
    }
  }

  LinkContextChange(e) {
    this.setState({ linkContextString: e.target.value });
  }

  ExpandLinkToggle(newState) {
    if (newState == true || newState == false) {
      this.setState({ linkPanel: newState, linkContextString: '' });
    } else {
      let linkPanel = !this.state.linkPanel;
      this.setState({ linkPanel: linkPanel, linkContextString: '' });
    }
  }

  RemoveSelected() {
    for (let key of this.props.data) {
      if (key.selected) {
        removeMarkedItems(key.type, key.id);
      }
    }

    //update marked items after removal
    this.props.getDeletedItems();

    //turn off the action success buttons after removal
    if (this.state.actionSuccess) {
      this.setState({ actionSuccess: false });
    }
  }

  StartDelete() {
    this.setState({
      pendingDelete: true,
    });
  }

  MoveEntry() {
    for (let key of this.props.data) {
      if (key.selected && key.type == 'entry') {
        this.EntryAjax(key.id, true);
      }
    }
  }

  CopyEntry() {
    for (let key of this.props.data) {
      if (key.selected && key.type == 'entry') {
        this.EntryAjax(key.id, false);
      }
    }
  }

  Link() {


    for (let key of this.props.data) {
      if (key.selected) {

        let arrayToLink = [];
        let obj = {};
        let currentobj = {};

        //assign new thing to link
        obj.id = parseInt(key.id);
        obj.type = key.type;

        //assign current thing to link to
        currentobj.id = parseInt(this.props.id);
        currentobj.type = this.props.type;

        arrayToLink.push(obj);
        arrayToLink.push(currentobj);

        this.LinkAjax(arrayToLink);
      }

      /*
          if ( arrayToLink.length > 0 ) {
          //add current thing to be linked to
          let obj = {};
          obj.id = parseInt( this.props.id );
          obj.type = this.props.type;

          arrayToLink.push( obj );
          this.LinkAjax( arrayToLink );
      }*/
    }


  }

  Reparse() {
    this.setState({
      reparseButton: ACTION_BUTTONS.LOADING,
    });

    $.when(...this.props.data.filter((thing) => thing.selected)
      .map((thing) => {
        return this.ReparseAjax(thing);
      })
    ).then(
      // Success
      () => {
        this.setState({
          reparseButton: ACTION_BUTTONS.SUCCESS,
        });
      },
      // Failure
      (error) => {
        console.error(error);
        this.setState({
          reparseButton: ACTION_BUTTONS.ERROR,
        });
        this.props.errorToggle('error reparsing', error);
      }
    ).always(() => {
      setTimeout(() => {
        this.setState({
          reparseButton: ACTION_BUTTONS.READY,
        });
      }, 2000);
    });
  }

  ReparseAjax(thing) {
    return $.ajax({
      type: 'put',
      url: '/scot/api/v2/' + thing.type + '/' + thing.id,
      data: JSON.stringify({ parsed: 0 }),
      contentType: 'application/json; charset=UTF-8',
    });
  }

  Promote() {
    this.setState({
      promoteButton: ACTION_BUTTONS.LOADING,
    });

    let success = true;

    $.when(...this.props.data.filter((thing) => thing.selected)
      .map((thing) => {
        return this.PromoteAjax(thing);
      })
    ).then(
      // Success
      () => {
        this.setState({
          promoteButton: ACTION_BUTTONS.SUCCESS,
        });
      },
      // Failure
      (error) => {
        success = false;
        console.error(error);
        this.setState({
          promoteButton: ACTION_BUTTONS.ERROR,
        });
        this.props.errorToggle('error adding alerts to event', error);
      }
    ).always(() => {
      setTimeout(() => {
        this.setState({
          promoteButton: ACTION_BUTTONS.READY,
        });

        if (success) {
          window.location.reload();
        }
      }, 2000);
    });
  }

  PromoteAjax(thing) {
    return $.ajax({
      type: 'put',
      url: '/scot/api/v2/alert/' + thing.id,
      data: JSON.stringify({ promote: parseInt(this.props.id) }),
      contentType: 'application/json; charset=UTF-8',
    });
  }

  LinkAjax(arrayToLink) {
    let data = {};
    data.weight = 1; //passed in object
    data.vertices = arrayToLink; //link to current thing

    if (this.state.linkContextString) {           //add context string if one was submitted
      data.context = this.state.linkContextString;
    }

    $.ajax({
      type: 'post',
      url: '/scot/api/v2/link',
      data: JSON.stringify(data),
      contentType: 'application/json; charset=UTF-8',
      dataType: 'json',
      success: function (response) {
        console.log('successfully linked');
        this.ExpandLinkToggle(false);                          //disable link panel
        this.ToggleActionSuccess(true);
      }.bind(this),
      error: function (data) {
        this.props.errorToggle('failed to link', data);
      }.bind(this)
    });
  }

  EntryAjax(id, removeOriginal) {

    $.ajax({
      type: 'get',
      url: '/scot/api/v2/entry/' + id,
      success: function (response) {
        let data = {};
        data = { parent: 0, body: response.body, target_id: parseInt(this.props.id), target_type: this.props.type };
        $.ajax({
          type: 'post',
          url: '/scot/api/v2/entry',
          data: JSON.stringify(data),
          contentType: 'application/json; charset=UTF-8',
          dataType: 'json',
          success: function (response) {

            if (removeOriginal) {
              this.RemoveEntryAfterMove(id);
              this.RemoveSelected();
            } else {
              if (!this.state.actionSuccess) {
                this.ToggleActionSuccess(true);
              }
            }

          }.bind(this),
          error: function (data) {
            this.props.errorToggle('failed to create new entry', data);
          }.bind(this)
        });
      }.bind(this),
      error: function (data) {
        this.props.errorToggle('failed to get entry data', data);
      }.bind(this)
    });

  }

  RemoveEntryAfterMove(id) {
    $.ajax({
      type: 'delete',
      url: '/scot/api/v2/entry/' + id,
      success: function (response) {
        console.log('removed original entry');
      }.bind(this),
      error: function (data) {
        this.props.errorToggle('Failed to remove original entry', data);
      }.bind(this),
    });
  }

  ToggleActionSuccess(status) {

    if (status == true || status == false) {
      this.setState({ actionSuccess: status });
    } else {
      let newActionSuccess = !this.state.actionSuccess;
      this.setState({ actionSuccess: newActionSuccess });
    }

  }
}

Actions.propTypes = {
  data: PropTypes.object
};

Actions.defaultProps = {
  data: {}
};

Undelete.propTypes = {
  modalActive: PropTypes.bool
};

Undelete.defaultProps = {
  modalActive: true
};


