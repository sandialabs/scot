import React from "react";
import Home from "./home";
import { ReportPage, SingleReport } from "../components/dashboard/report";
import { NOTIFICATION_TYPES } from "../components/dashboard/activity";
import { UserConfigProvider } from "../utils/userConfig";
import * as Cookies from "../utils/cookies";
import * as SessionStorage from "../utils/session_storage";
import $ from "jquery";
import Search from "../components/esearch";
import Wall from "../debug-components/wall";
import Login from "../modal/login.js";
import { Link } from "react-router-dom";
import { Route } from "react-router-dom";
let Navbar = require("react-bootstrap/lib/Navbar.js");
let Nav = require("react-bootstrap/lib/Nav.js");
let NavItem = require("react-bootstrap/lib/NavItem.js");
let NavDropdown = require("react-bootstrap/lib/NavDropdown.js");
let MenuItem = require("react-bootstrap/lib/MenuItem.js");
let LinkContainer = require("react-router-bootstrap/lib/LinkContainer.js");
let ListView = require("../list/list-view.js");
var Notification = require("react-notification-system");

window.jQuery = window.$ = require("jquery/dist/jquery");

class App extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      open: false,
      notificationSetting: "on",
      login: false,
      csrf: "",
      origurl: "",
      sensitivity: "",
      whoami: undefined,
      handler: undefined,
      eestring: "",
      clientId: null
    };
  }

  componentWillReceiveProps = nextProps => {
    let viewModeSetting = Cookies.checkCookie("viewMode");
    let notificationSetting = Cookies.checkCookie("notification");
    if (nextProps.match.params.value) {
      var listViewFilterSetting = Cookies.checkCookie(
        "listViewFilter" + nextProps.match.params.value.toLowerCase()
      );
      var listViewSortSetting = Cookies.checkCookie(
        "listViewSort" + nextProps.match.params.value.toLowerCase()
      );
      var listViewPageSetting = Cookies.checkCookie(
        "listViewPage" + nextProps.match.params.value.toLowerCase()
      );
    }
    if (notificationSetting === undefined) {
      notificationSetting = "on";
    }

    if (!this.state.handler) {
      this.GetHandler();
    }

    if (!this.state.whoami) {
      this.WhoAmIQuery();
    }

    this.setState({
      viewMode: viewModeSetting,
      notificationSetting: notificationSetting,
      listViewFilter: listViewFilterSetting,
      listViewSort: listViewSortSetting,
      listViewPage: listViewPageSetting
    });
  };

  componentDidMount = () => {
    this.GetHandler();
    this.WhoAmIQuery();
    this.props.registerClient();
    this.props.createCallbackObject("wall", this.notification);
    //TODO: Remove this stuff also
    // Store.storeKey( 'wall' );
    // Store.addChangeListener( this.wall );
    // Store.storeKey( 'notification' );
    // Store.addChangeListener( this.notification );

    //ee
    if (this.props.match.url === "/") {
      $(document.body).keydown(
        function(e) {
          this.ee(e);
        }.bind(this)
      );
    }
  };

  eedraw = () => {
    $("#content").css("transform", "rotateX(20deg)");
    $(document.body).prepend(
      '<span id="ee">Lbh sbhaq gur rtt. Cbfg gb gur jnyy "V sbhaq gur rtt, pna lbh?"</span>'
    );
  };

  eeremove = () => {
    $("#content").css("transform", "rotateX(0deg)");
    $("#ee").remove();
  };

  componentWillUnmount = () => {
    SessionStorage.removeSessionStorage("whoami");
  };

  componentWillMount = () => {
    //Get landscape/portrait view if the cookie exists
    // let viewModeSetting = Cookies.checkCookie( 'viewMode' );
    // let notificationSetting = Cookies.checkCookie( 'notification' );
    // if ( this.props.match.params.value ) {
    //     var listViewFilterSetting = Cookies.checkCookie( 'listViewFilter'+this.props.match.params.value.toLowerCase() );
    //     var listViewSortSetting = Cookies.checkCookie( 'listViewSort'+this.props.match.params.value.toLowerCase() );
    //     var listViewPageSetting = Cookies.checkCookie( 'listViewPage'+this.props.match.params.value.toLowerCase() );
    //     globalFilter = listViewFilterSetting;
    //     globalPage = listViewPageSetting;
    //     globalSort = listViewSortSetting;
    // }
    // if ( notificationSetting == undefined ) {
    //     notificationSetting = 'on';
    // }
    // this.setState( {viewMode:viewModeSetting, notificationSetting:notificationSetting, listViewFilter:listViewFilterSetting,listViewSort:listViewSortSetting, listViewPage:listViewPageSetting} );
  };

  ee = e => {
    let ee = "837279877769847269697171";
    if (ee.includes(this.state.eestring)) {
      if (this.state.eestring + e.keyCode === ee) {
        this.eedraw();
        setTimeout(this.eeremove, 2000);
      } else {
        if ($("input").is(":focus")) {
          return;
        }
        if (e.ctrlKey !== true && e.metaKey !== true) {
          let eestring = this.state.eestring + e.keyCode;
          this.setState({ eestring: eestring });
        }
      }
    } else {
      this.setState({ eestring: "" });
    }
  };

  notification = () => {
    // Don't show on dashboard if filtered type
    if (
      this.props.match.path === "/" &&
      this.props.match.isExact &&
      NOTIFICATION_TYPES.includes(this.props.stateProps.activemqstate)
    ) {
      return;
    }

    //Notification display in update as it will run on every amq message matching 'main'.
    let notification = this.refs.notificationSystem;
    //not showing notificaiton on entity due to "flooding" on an entry update that has many entities causing a storm of AMQ messages
    if (
      this.props.stateProps.activemqwho !== "scot-alerts" &&
      this.props.stateProps.activemqwho !== "scot-admin" &&
      this.props.stateProps.activemqwho !== "scot-flair" &&
      this.props.stateProps.notification !== undefined &&
      this.props.stateProps.activemqwho !== this.state.whoami &&
      this.props.stateProps.activemqwho !== "" &&
      this.props.stateProps.activemqwho !== "api" &&
      this.props.stateProps.activemqwall !== true &&
      this.props.stateProps.activemqtype !== "entity" &&
      this.state.notificationSetting === "on"
    ) {
      notification.addNotification({
        message:
          this.props.stateProps.activemqwho +
          this.props.stateProps.activemqmessage +
          this.props.stateProps.activemqid,
        level: "info",
        autoDismiss: 5,
        action:
          this.props.stateProps.activemqstate !== "delete"
            ? {
                label: "View",
                callback: function() {
                  window.open(
                    "/#/" +
                      this.props.stateProps.activemqtype +
                      "/" +
                      this.props.stateProps.activemqid
                  );
                }
              }
            : null
      });
    }
  };

  wall = message => {
    // Don't show on dashboard
    if (this.props.match.path === "/" && this.props.match.isExact) {
      return;
    }

    var notification = this.refs.notificationSystem;
    var date = new Date(message.activemqwhen * 1000);
    date = date.toLocaleString();
    if (message.activemqwall === true) {
      notification.addNotification({
        message:
          date + " " + message.activemqwho + ": " + message.activemqmessage,
        level: "warning",
        autoDismiss: 0
      });
      // message.activemqwall = false;
    }
  };

  errorToggle = (string, result) => {
    let errorString = string;
    if (result) {
      if (result.responseJSON) {
        if (result.responseJSON.error === "Authentication Required") {
          this.setState({ csrf: result.responseJSON.csrf }); //set csrf here since it can change after the login prompt loads
          this.loginToggle(result.responseJSON.csrf);
          return;
        }
      } else if (result.statusText === "Service Unavailable") {
        errorString = result.statusText; //Use server error message if available.
      }
    }

    let notification = this.refs.notificationSystem;
    notification.addNotification({
      message: errorString,
      level: "error",
      autoDismiss: 0
    });
  };

  notificationToggle = () => {
    if (this.state.notificationSetting === "off") {
      this.setState({ notificationSetting: "on" });
      Cookies.setCookie("notification", "on", 1000);
    } else {
      this.setState({ notificationSetting: "off" });
      Cookies.setCookie("notification", "off", 1000);
    }
  };

  loginToggle = (csrf, loggedin) => {
    //Only open modal once - if other requests come in to open the modal just bypass since the login page is active
    if (!this.state.login && loggedin !== true) {
      let origurl = this.props.location.pathname;
      this.props.history.push("/");
      this.setState({ login: true, origurl: origurl });
    } else if (this.state.login && loggedin === true) {
      this.setState({ login: false });
      this.props.history.push(this.state.origurl);
    }
  };

  LogOut = () => {
    //Logs out of SCOT
    $.ajax({
      type: "get",
      url: "/logout",
      success: function(data) {
        this.setState({ login: true });
        console.log("Successfully logged out");
        //Call whoami so we can get a csrf token
        this.WhoAmIQuery();
      }.bind(this),
      error: function(data) {
        this.error("Failed to log out", data);
      }.bind(this)
    });
  };

  WhoAmIQuery = () => {
    $.ajax({
      type: "get",
      url: "scot/api/v2/whoami",
      success: function(result) {
        SessionStorage.setSessionStorage("whoami", result.user);
        if (result.data) {
          this.setState({
            sensitivity: result.data.sensitivity,
            whoami: result.user
          });
        }
      }.bind(this),
      error: function(data) {
        this.errorToggle("Failed to get current user", data);
      }.bind(this)
    });
  };

  GetHandler = () => {
    $.ajax({
      type: "get",
      url: "/scot/api/v2/handler?current=1",
      success: function(response) {
        this.setState({ handler: response.records[0].username });
      }.bind(this),
      error: function(data) {
        this.errorToggle("Failed to get current user", data);
      }.bind(this)
    });
  };

  render = () => {
    let IH = "Incident Handler: " + this.state.handler;
    let type;

    if (this.props.match.params.value) {
      type = this.props.match.params.value.toLowerCase();
    }

    return (
      <UserConfigProvider>
        <Navbar inverse fixedTop={true} fluid={true}>
          <Navbar.Header>
            <Navbar.Brand>
              <Link to="/" style={{ margin: "0", padding: "0" }}>
                <img src="/images/scot.png" alt="" style={{ width: "50px" }} />
              </Link>
            </Navbar.Brand>
            <Navbar.Toggle />
          </Navbar.Header>
          <Navbar.Collapse>
            <Nav>
              <LinkContainer to="/alertgroup" activeClassName="active">
                <NavItem>Alert</NavItem>
              </LinkContainer>
              <LinkContainer to="/event" activeClassName="active">
                <NavItem>Event</NavItem>
              </LinkContainer>
              <LinkContainer to="/incident" activeClassName="active">
                <NavItem>Incident</NavItem>
              </LinkContainer>
              <LinkContainer to="/intel" activeClassName="active">
                <NavItem>Intel</NavItem>
              </LinkContainer>
              <NavDropdown id="nav-dropdown" title={"More"}>
                <LinkContainer to="/task" activeClassName="active">
                  <MenuItem>Task</MenuItem>
                </LinkContainer>
                <LinkContainer to="/guide" activeClassName="active">
                  <MenuItem>Guide</MenuItem>
                </LinkContainer>
                <MenuItem href="/revl.html#/visualization">
                  Visualization
                </MenuItem>
                <LinkContainer to="/signature" activeClassName="active">
                  <MenuItem>Signature</MenuItem>
                </LinkContainer>
                <LinkContainer to="/entity" activeClassName="active">
                  <MenuItem>Entity</MenuItem>
                </LinkContainer>
                <LinkContainer to="/reports" activeClassName="active">
                  <MenuItem>Reports</MenuItem>
                </LinkContainer>
                <MenuItem divider />
                <MenuItem href="/admin/index.html">Administration</MenuItem>
                <MenuItem href="/docs/index.html">Documentation</MenuItem>
                <MenuItem divider />
                <MenuItem href="/cyberchef.htm">Cyber Chef</MenuItem>
                <MenuItem divider />
                <MenuItem href="/#/" onClick={this.LogOut}>
                  Log Out
                </MenuItem>
              </NavDropdown>
              <NavItem href="/incident_handler.html">{IH}</NavItem>
            </Nav>
            <span id="ouo_warning" className="ouo-warning">
              {this.state.sensitivity}
            </span>
            <span
              id="scot_version"
              style={{
                float: "right",
                marginTop: "3px",
                padding: "10px 10px",
                position: "relative",
                color: "white"
              }}
              className="scot_version"
            >
              V3.5
            </span>
            <Search errorToggle={this.errorToggle} />
          </Navbar.Collapse>
        </Navbar>
        <div className="mainNavPadding">
          <Login
            csrf={this.state.csrf}
            modalActive={this.state.login}
            loginToggle={this.loginToggle}
            WhoAmIQuery={this.WhoAmIQuery}
            GetHandler={this.GetHandler}
            errorToggle={this.errorToggle}
            origurl={this.state.origurl}
          />
          <Notification ref="notificationSystem" />
          {/* Home Page Dashboard */}
          <Route
            exact
            path="/"
            render={props => (
              <Home
                loggedIn={!this.state.login}
                sensitivity={this.state.sensitivity}
                errorToggle={this.errorToggle}
                clientId={this.state.clientId}
                createCallbackObject={this.props.createCallbackObject}
                removeCallbackObject={this.props.removeCallbackObject}
              />
            )}
          />
          {type === "alert" ? (
            <Route exact path="/alert">
              <ListView
                id={this.props.match.params.id}
                id2={this.props.match.params.id2}
                viewMode={this.state.viewMode}
                type={type}
                notificationToggle={this.notificationToggle}
                notificationSetting={this.state.notificationSetting}
                listViewFilter={this.state.listViewFilter}
                listViewSort={this.state.listViewSort}
                listViewPage={this.state.listViewPage}
                errorToggle={this.errorToggle}
                history={this.props.history}
                createCallbackObject={this.props.createCallbackObject}
                removeCallbackObject={this.props.removeCallbackObject}
              />
            </Route>
          ) : null}
          {type === "alertgroup" ? (
            <ListView
              id={this.props.match.params.id}
              id2={this.props.match.params.id2}
              viewMode={this.state.viewMode}
              type={type}
              notificationToggle={this.notificationToggle}
              notificationSetting={this.state.notificationSetting}
              listViewFilter={this.state.listViewFilter}
              listViewSort={this.state.listViewSort}
              listViewPage={this.state.listViewPage}
              errorToggle={this.errorToggle}
              history={this.props.history}
              createCallbackObject={this.props.createCallbackObject}
              removeCallbackObject={this.props.removeCallbackObject}
            />
          ) : null}
          {type === "entry" ? (
            <ListView
              id={this.props.match.params.id}
              id2={this.props.match.params.id2}
              viewMode={this.state.viewMode}
              type={type}
              notificationToggle={this.notificationToggle}
              notificationSetting={this.state.notificationSetting}
              listViewFilter={this.state.listViewFilter}
              listViewSort={this.state.listViewSort}
              listViewPage={this.state.listViewPage}
              errorToggle={this.errorToggle}
              history={this.props.history}
              createCallbackObject={this.props.create_callback_object}
              removeCallbackObject={this.props.remove_callback_object}
            />
          ) : null}
          {type === "event" ? (
            <ListView
              id={this.props.match.params.id}
              id2={this.props.match.params.id2}
              viewMode={this.state.viewMode}
              type={type}
              notificationToggle={this.notificationToggle}
              notificationSetting={this.state.notificationSetting}
              listViewFilter={this.state.listViewFilter}
              listViewSort={this.state.listViewSort}
              listViewPage={this.state.listViewPage}
              errorToggle={this.errorToggle}
              history={this.props.history}
              createCallbackObject={this.props.createCallbackObject}
              removeCallbackObject={this.props.removeCallbackObject}
            />
          ) : null}
          {type === "incident" ? (
            <ListView
              id={this.props.match.params.id}
              id2={this.props.match.params.id2}
              viewMode={this.state.viewMode}
              type={type}
              notificationToggle={this.notificationToggle}
              notificationSetting={this.state.notificationSetting}
              listViewFilter={this.state.listViewFilter}
              listViewSort={this.state.listViewSort}
              listViewPage={this.state.listViewPage}
              errorToggle={this.errorToggle}
              history={this.props.history}
              createCallbackObject={this.props.createCallbackObject}
              removeCallbackObject={this.props.removeCallbackObject}
            />
          ) : null}
          {type === "task" ? (
            <ListView
              isTask={true}
              queryType={this.props.match.params.type}
              viewMode={this.state.viewMode}
              type={this.props.match.params.value}
              id={this.props.match.params.id}
              id2={this.props.match.params.id2}
              notificationToggle={this.notificationToggle}
              notificationSetting={this.state.notificationSetting}
              listViewFilter={this.state.listViewFilter}
              listViewSort={this.state.listViewSort}
              listViewPage={this.state.listViewPage}
              errorToggle={this.errorToggle}
              history={this.props.history}
              createCallbackObject={this.props.createCallbackObject}
              removeCallbackObject={this.props.removeCallbackObject}
            />
          ) : null}
          {type === "guide" ? (
            <ListView
              id={this.props.match.params.id}
              id2={this.props.match.params.id2}
              viewMode={this.state.viewMode}
              type={type}
              notificationToggle={this.notificationToggle}
              notificationSetting={this.state.notificationSetting}
              listViewFilter={this.state.listViewFilter}
              listViewSort={this.state.listViewSort}
              listViewPage={this.state.listViewPage}
              errorToggle={this.errorToggle}
              history={this.props.history}
              createCallbackObject={this.props.createCallbackObject}
              removeCallbackObject={this.props.removeCallbackObject}
            />
          ) : null}
          {type === "intel" ? (
            <ListView
              id={this.props.match.params.id}
              id2={this.props.match.params.id2}
              viewMode={this.state.viewMode}
              type={type}
              notificationToggle={this.notificationToggle}
              notificationSetting={this.state.notificationSetting}
              listViewFilter={this.state.listViewFilter}
              listViewSort={this.state.listViewSort}
              listViewPage={this.state.listViewPage}
              errorToggle={this.errorToggle}
              history={this.props.history}
              createCallbackObject={this.props.createCallbackObject}
              removeCallbackObject={this.props.removeCallbackObject}
            />
          ) : null}
          {type === "signature" ? (
            <ListView
              id={this.props.match.params.id}
              id2={this.props.match.params.id2}
              viewMode={this.state.viewMode}
              type={type}
              notificationToggle={this.notificationToggle}
              notificationSetting={this.state.notificationSetting}
              listViewFilter={this.state.listViewFilter}
              listViewSort={this.state.listViewSort}
              listViewPage={this.state.listViewPage}
              errorToggle={this.errorToggle}
              history={this.props.history}
              createCallbackObject={this.props.createCallbackObject}
              removeCallbackObject={this.props.removeCallbackObject}
            />
          ) : null}
          {type === "entity" ? (
            <ListView
              id={this.props.match.params.id}
              id2={this.props.match.params.id2}
              viewMode={this.state.viewMode}
              type={type}
              notificationToggle={this.notificationToggle}
              notificationSetting={this.state.notificationSetting}
              listViewFilter={this.state.listViewFilter}
              listViewSort={this.state.listViewSort}
              listViewPage={this.state.listViewPage}
              errorToggle={this.errorToggle}
              history={this.props.history}
              createCallbackObject={this.props.createCallbackObject}
              removeCallbackObject={this.props.removeCallbackObject}
            />
          ) : null}
          {type === "reports" && !this.props.match.params.id && <ReportPage />}
          {type === "reports" &&
            this.props.match.params.id && (
              <SingleReport reportType={this.props.match.params.id} />
            )}
          {/* {type == "amq" ? (
            <AMQ type="amq" errorToggle={this.errorToggle} />
          ) : null} */}
          {type === "wall" ? <Wall errorToggle={this.errorToggle} /> : null}
        </div>
      </UserConfigProvider>
    );
  };
}

export default class AMQ extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      client: "",
      whoami: "",
      amqdebug: "",
      activemqaction: "",
      activemqid: "",
      activemqwho: "",
      activemqtype: "",
      activemqguid: "",
      activemqhostname: "",
      activemqpid: "",
      activemqwhen: "",
      activemqwall: "",
      cb_obj_array: []
    };
    this.get_guid = this.get_guid.bind(this);
    this.create_callback_object = this.create_callback_object.bind(this);
    this.register_client = this.register_client.bind(this);
    this.get_data = this.get_data.bind(this);
  }

  //AMQ STUFF
  s4 = () => {
    return Math.floor((1 + Math.random()) * 0x10000)
      .toString(16)
      .substring(1);
  };

  get_guid = () => {
    return (
      this.s4() +
      this.s4() +
      this.s4() +
      this.s4() +
      this.s4() +
      this.s4() +
      this.s4() +
      this.s4()
    );
  };

  register_client = restart => {
    this.setState({
      client: this.get_guid(),
      whoami: SessionStorage.getSessionStorage("whoami")
    });
    $.ajax({
      type: "POST",
      url: "/scotaq/amq",
      data: {
        message: "chat",
        type: "listen",
        clientId: this.client,
        destination: "topic://scot"
      },
      success: function(data) {
        console.log("Registered client as " + this.state.client);
        if (!restart) {
          //only start the update if this is not a restart. Restart will just use the new clientid once it is live.
          setTimeout(
            function() {
              this.get_data();
            }.bind(this),
            1000
          );
        }
      }.bind(this),
      error: function(data) {
        console.log("Error: failed to register client, retry in 1 sec");
        setTimeout(function() {
          this.register_client();
        }, 1000);
      }.bind(this)
    });
  };

  get_data = () => {
    let now = new Date();
    $.ajax({
      type: "GET",
      url: "/scotaq/amq",
      data: {
        /*loc: location.hash, */
        clientId: this.state.client,
        timeout: 20000,
        d: now.getTime(),
        r: Math.random(),
        json: "true",
        username: this.whoami
      },
      success: function(data) {
        console.log("Received Message");
        setTimeout(
          function() {
            this.get_data();
          }.bind(this),
          40
        );
        let messages = $(data)
          .text()
          .split("\n");
        $.each(messages, function(key, message) {
          if (message !== "") {
            let json = JSON.parse(message);
            console.log(json);
            this.process_message(message);
            this.handle_update(message);
            return true;
          }
        });
      }.bind(this),
      error: function() {
        setTimeout(
          function() {
            this.getData(this.client);
          }.bind(this),
          1000
        );
        console.log("AMQ not detected, retrying in 1 second.");
      }
    });
  };

  create_callback_object = (key, callback) => {
    let newobject = Object;
    newobject["key"] = key;
    newobject["callback"] = callback;
    let newArray = this.state.cb_obj_array;
    newArray.push(newobject);
    this.setState({ cb_obj_array: newArray });
  };

  remove_callback_object = key => {
    for (var i = 0; i < this.cb_obj_array.length; i++)
      if (this.cb_obj_array[i].key === key) {
        this.cb_obj_array.splice(i, 1);
        break;
      }
  };

  process_message = payload => {
    if (this.amqdebug === true) {
      this.activemqaction = payload.action.activemq.action;
      this.activemqid = payload.action.activemq.data.id;
      this.activemqtype = payload.action.activemq.data.type;
      this.activemqwho = payload.action.activemq.data.who;
      this.activemqguid = payload.action.activemq.guid;
      this.activemqhostname = payload.action.activemq.hostname;
      this.activemqpid = payload.action.activemq.pid;
    }

    if (payload.action.activemq.action === "wall") {
      this.activemqwho = payload.action.activemq.data.who;
      this.activemqmessage = payload.action.activemq.data.message;
      this.activemqwhen = payload.action.activemq.data.when;
      this.activemqwall = true;
    }
  };

  //TODO: Implment better handle update function
  handle_update = message => {
    let search_key =
      message.action.activemq.type + ":" + message.action.activemq.id;
    if (this.cb_obj_array[search_key]) {
      this.cb_obj_array[search_key];
    } else {
      throw "Key: " + search_key + " doesn't exist in state.";
    }
  };

  render = () => {
    console.log("hey");
    return (
      <App
        location={this.props.location}
        match={this.props.match}
        history={this.props.history}
        createCallbackObject={this.create_callback_object}
        removeCallbackObject={this.remove_callback_object}
        registerClient={this.register_client}
        getData={this.get_data}
      />
    );
  };
}
