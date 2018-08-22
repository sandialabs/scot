import React, { Component } from "react";
import ReactDOM from "react-dom";
import PropTypes from "prop-types";
import $ from "jquery";
import * as SessionStorage from "../../utils/session_storage";
import * as AMQ from "../../activemq/amq";
import { Well, Label, Badge } from "react-bootstrap";
import timeSince from "../../utils/timesince";
import {
  timeOlderThan,
  epochToTimeago,
  timeagoToEpoch
} from "../../utils/time";

const REFRESH_RATE = 30 * 1000; // 30 seconds

// Bootstrap styles for different notification types
const NOTIFICATION_LEVEL = {
  wall: "warning",
  create: "info",
  delete: "danger"
};

// Types of notifications we're interested in
// (used to hide normal notifications of these types)
export const NOTIFICATION_TYPES = ["create", "delete"];

// Time notifications will stay in activity bar
const NOTIFICATION_TIME = {
  create: 120,
  delete: 60,
  wall: 60 * 60 // 1 hour
};
const ACTIVITY_TYPE = {
  USER: 0,
  NOTIFICATION: 1
};

// localstorage key for persisting wall messages
const WALL_KEY = "walls";

class Activity extends Component {
  constructor(props) {
    super(props);

    this.state = {
      users: [],
      notifications: this.loadWall()
    };

    this.updateActivity = this.updateActivity.bind(this);
    this.updateUsers = this.updateUsers.bind(this);
    this.wallMessage = this.wallMessage.bind(this);
    this.notification = this.notification.bind(this);
    this.fetchError = this.fetchError.bind(this);
  }

  static propTypes = {};

  componentDidMount() {
    this.refreshTimer = setInterval(this.updateActivity, REFRESH_RATE);
    this.updateActivity();
    //TODO: Get data
    const amqClientPromise = AMQ.register_client();
    console.log("will be pending when logged", amqClientPromise);
    amqClientPromise
      .then(function getData(client) {
        console.log(
          "when resolve is found it comes here with the response, in this case users ",
          client
        );
        // return Promise.all(
        //   list.map(function(user) {
        //     return request(user.repos_url);
        //   })
        // );
      })
      // .then(function dosomething(param) {
      //   console.log('blah blh ', param)
      // })
      .catch(function handleErrors(error) {
        console.log(
          "when a reject is executed it will come here ignoring the then statement ",
          error
        );
      });
  }

  componentWillUnmount() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer);
    }
  }

  updateActivity() {
    this.updateUsers();

    // Clean out notifications
    let pruned = this.state.notifications.filter(notification => {
      return !timeOlderThan(
        notification.time * 1000,
        NOTIFICATION_TIME[notification.action]
      );
    });

    this.setState(
      {
        notifications: pruned
      },
      this.persistWall
    );
  }

  updateUsers() {
    $.ajax({
      type: "get",
      url: "/scot/api/v2/who",
      success: data => {
        this.setState({
          users: data.records.map(user => {
            return {
              type: ACTIVITY_TYPE.USER,
              who: user.username,
              time: timeagoToEpoch(user.last_activity)
            };
          })
        });
      },
      error: this.fetchError
    });
  }

  persistWall() {
    let walls = this.state.notifications.filter(notification => {
      return notification.action === "wall";
    });

    SessionStorage.setLocalStorage(WALL_KEY, JSON.stringify(walls));
  }

  loadWall() {
    let json = SessionStorage.getLocalStorage(WALL_KEY);
    if (json) {
      return JSON.parse(json);
    }
    return [];
  }

  wallMessage(message) {
    let notifications = this.state.notifications;
    notifications.push({
      type: ACTIVITY_TYPE.NOTIFICATION,
      time: message.activemqwhen,
      who: message.activemqwho,
      message: message.activemqmessage,
      level: NOTIFICATION_LEVEL.wall,
      action: "wall"
    });

    this.setState(
      {
        notifications: notifications
      },
      this.persistWall
    );
  }

  notification(message) {
    const ignoredUsers = ["scot-flair", "scot-alerts", "scot-admin", "", "api"];
    const interestedEvents = ["create", "delete"];

    // Ignore some notifications
    if (ignoredUsers.includes(message.activemqwho)) return;
    if (message.activemqwall === true) return;
    if (message.activemqtype === "entity") return;
    if (!interestedEvents.includes(message.activemqstate)) return;

    let notifications = this.state.notifications;
    notifications.push({
      type: ACTIVITY_TYPE.NOTIFICATION,
      time: Date.now() / 1000,
      who: message.activemqwho,
      message: message.activemqmessage + message.activemqid,
      level: NOTIFICATION_LEVEL[message.activemqstate],
      action: message.activemqstate
    });

    this.setState({
      notifications: notifications
    });
  }

  addDebugItems(count = 10) {
    let notifications = this.state.notifications;

    for (let i = 0; i < count; i++) {
      notifications.push({
        type: ACTIVITY_TYPE.NOTIFICATION,
        time: Date.now() / 1000,
        who: "fred",
        message: "blah",
        level: NOTIFICATION_LEVEL.create,
        action: "create"
      });
    }

    this.setState({
      notifications: notifications
    });
  }

  fetchError(error) {}

  buildActivityItem(item, i) {
    let badge = timeSince(epochToTimeago(item.time));
    let text = "";
    switch (item.type) {
      default:
      case ACTIVITY_TYPE.USER:
        text = item.who;
        break;
      case ACTIVITY_TYPE.NOTIFICATION:
        text = `${item.who}: ${item.message}`;
        break;
    }

    return (
      <ActivityItem key={i} badge={badge} style={item.level}>
        {text}
      </ActivityItem>
    );
  }

  render() {
    let { className = "" } = this.props;
    let classes = ["Activity", className];

    // Build activity items
    let items = this.state.users
      .concat(this.state.notifications)
      .sort((a, b) => {
        return b.time - a.time;
      })
      .map(this.buildActivityItem);

    // Calculate whether the marquee should scroll
    let stopped = true;
    if (this.marquee && this.well) {
      let marqueeValues = window.getComputedStyle(this.marquee);
      if (
        parseInt(marqueeValues.width) - parseInt(marqueeValues.paddingLeft) >
        this.well.offsetWidth
      ) {
        stopped = false;
      }
    }

    return (
      <Well
        bsSize="small"
        className={classes.join(" ")}
        ref={well => (this.well = ReactDOM.findDOMNode(well))}
      >
        <div
          className={`marquee ${stopped ? "stopped" : ""}`}
          ref={marquee => (this.marquee = marquee)}
        >
          {items}
        </div>
      </Well>
    );
  }
}

const ActivityItem = ({ children, badge = null, style = "default" }) => (
  <div className="activity-item">
    <Label bsStyle={style}>
      {children}
      {badge !== null && <Badge>{badge}</Badge>}
    </Label>
  </div>
);

export default Activity;
