import React from "react";
import PropTypes from "prop-types";
import { Button, MenuItem, OverlayTrigger, Tooltip } from "react-bootstrap";
import $ from "jquery";
import * as SessionStorage from "../utils/session_storage";

class Marker extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      isMarked: false
    };

    this.removeMarkedItemsHandler = this.removeMarkedItemsHandler.bind(this);
    this.getMarkedItemsHandler = this.getMarkedItemsHandler.bind(this);
    this.setMarkedItemsHandler = this.setMarkedItemsHandler.bind(this);
    this.getSelectedAlerts = this.getSelectedAlerts.bind(this);
  }

  componentWillMount() {
    this.mounted = true;

    this.getMarkedItemsHandler();
  }

  componentWillUnmount() {
    this.mounted = false;
  }

  componentWillReceiveProps(nextProps) {
    this.getMarkedItemsHandler();
    if (nextProps.isAlert) {
      //set marked to false if alert since we can't predict if new ones are selected
      this.setState({ isMarked: false });
    }
  }

  render() {
    if (this.props.type === "entry") {
      return (
        <MenuItem
          onClick={
            this.state.isMarked
              ? this.removeMarkedItemsHandler
              : this.setMarkedItemsHandler
          }
        >
          <i
            style={{ color: `${this.state.isMarked ? "green" : ""} ` }}
            className={`fa fa${this.state.isMarked ? "-check" : ""}-square-o`}
            aria-hidden="true"
          />
          {this.state.isMarked ? <span>Marked</span> : <span>Mark</span>}
        </MenuItem>
      );
    } else {
      return (
        <OverlayTrigger
          placement="top"
          overlay={
            <Tooltip id="mark_tooltip">
              Mark selected{" "}
              {this.props.isAlert ? <span>alerts</span> : this.props.type}
            </Tooltip>
          }
        >
          <Button
            bsSize="xsmall"
            onClick={
              this.state.isMarked
                ? this.removeMarkedItemsHandler
                : this.setMarkedItemsHandler
            }
          >
            <i
              style={{ color: `${this.state.isMarked ? "green" : ""} ` }}
              className={`fa fa${this.state.isMarked ? "-check" : ""}-square-o`}
              aria-hidden="true"
            />
            {this.props.isAlert ? <span>Mark selected</span> : null}

            {/* { this.state.isMarked ? <span>Marked</span> : <span>Mark</span> }*/}
          </Button>
        </OverlayTrigger>
      );
    }
  }

  getMarkedItemsHandler() {
    let markedItems = getMarkedItems();
    let isMarked = false;

    if (markedItems) {
      for (let key of markedItems) {
        if (key.id === this.props.id && key.type === this.props.type) {
          isMarked = true;
          break;
        }
      }
    }
    this.setState({ isMarked: isMarked });
  }

  removeMarkedItemsHandler() {
    if (this.props.isAlert) {
      let selectedAlerts = this.getSelectedAlerts();
      for (let i = 0; i < selectedAlerts.length; i++) {
        removeMarkedItems("alert", selectedAlerts[i]);
      }
    } else {
      removeMarkedItems(this.props.type, this.props.id);
    }
    this.setState({ isMarked: false });
  }

  setMarkedItemsHandler() {
    if (this.props.isAlert) {
      //parse alerts then iterate through them to add to marking list
      let selectedAlerts = this.getSelectedAlerts();
      for (let i = 0; i < selectedAlerts.length; i++) {
        setMarkedItems("alert", selectedAlerts[i], this.props.string);
      }
    } else {
      setMarkedItems(this.props.type, this.props.id, this.props.string);
    }
    this.setState({ isMarked: true });
  }

  getSelectedAlerts() {
    let array = [];

    $("tr.selected").each(function(index, tr) {
      let id = $(tr).attr("id");
      array.push(id);
    });

    return array;
  }
}

export const removeMarkedItems = (type, id) => {
  let currentMarked = getMarkedItems();

  if (currentMarked) {
    for (let i = 0; i < currentMarked.length; i++) {
      if (currentMarked[i].type === type && currentMarked[i].id === id) {
        currentMarked.splice(i, 1);
        break;
      }
    }

    SessionStorage.setLocalStorage("marked", JSON.stringify(currentMarked));
  }
};

export const getMarkedItems = () => {
  let markedItems = SessionStorage.getLocalStorage("marked");
  if (markedItems) {
    markedItems = JSON.parse(markedItems);
    return markedItems;
  }
};

export const setMarkedItems = (type, id, string) => {
  let nextMarked = [];
  let currentMarked = getMarkedItems();

  if (currentMarked) {
    for (let key of currentMarked) {
      if (key.type !== type || key.id !== id) {
        nextMarked.push(key);
      }
    }
  }

  nextMarked.push({ id: id, type: type, subject: string.substring(0, 120) });
  SessionStorage.setLocalStorage("marked", JSON.stringify(nextMarked));
};

Marker.propTypes = {
  isMarked: PropTypes.bool
};

Marker.defaultProps = {
  isMarked: false
};

export default Marker;
