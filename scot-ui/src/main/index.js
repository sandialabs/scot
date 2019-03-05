import Navbar from "react-bootstrap/lib/Navbar.js";
import Nav from "react-bootstrap/lib/Nav.js";
import NavItem from "react-bootstrap/lib/NavItem.js";
import NavDropdown from "react-bootstrap/lib/NavDropdown.js";
import MenuItem from "react-bootstrap/lib/MenuItem.js";
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
import ListView from '../list/list-view';
import Notification from "react-notification-system"
import LinkContainer from "react-router-bootstrap/lib/LinkContainer.js";
import Admin from '../components/admin/'
import { Amq } from '../utils/activemq'

// window.jQuery = window.$ = require("jquery/dist/jquery");

export default class App extends React.Component {
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
    this.notification = this.notification.bind(this);
    this.loginToggle = this.loginToggle.bind(this);
    this.errorToggle = this.errorToggle.bind(this);
    this.AMQ = new Amq();
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
    this.AMQ.register_client();
    this.AMQ.create_callback_object("wall", this.wall);
    this.AMQ.create_callback_object("notification", this.notification);

    //ee
    if (this.props.match.url === "/") {
      $(document.body).keydown(
        function (e) {
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
    let notificationSetting = Cookies.checkCookie('notification');
    if (notificationSetting == undefined) {
      notificationSetting = 'on';
    }
    this.setState({ notificationSetting: notificationSetting });
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
      this.AMQ.activemqwho !== "scot-alerts" &&
      this.AMQ.activemqwho !== "scot-admin" &&
      this.AMQ.activemqwho !== "scot-flair" &&
      notification !== undefined &&
      this.AMQ.activemqwho !== this.state.whoami &&
      this.AMQ.activemqwho !== "" &&
      this.AMQ.activemqwho !== "api" &&
      this.AMQ.activemqwall !== true &&
      this.AMQ.activemqtype !== "entity" &&
      this.state.notificationSetting === "on"
    ) {
      let message = `${this.AMQ.activemqwho} ${this.AMQ.activemqaction} ${this.AMQ.activemqtype} : ${this.AMQ.activemqid}`
      let type = this.AMQ.activemqtype;
      let state = this.AMQ.activemqstate;
      let activemqid = this.AMQ.activemqid;
      notification.addNotification({
        message: message,
        level: "info",
        autoDismiss: 5,
        action:
          state !== "delete"
            ? {
              label: "View",
              callback: function () {
                window.open(
                  "/#/" +
                  type +
                  "/" +
                  activemqid
                );
              }
            }
            : null
      });
    }
  };

  wall = (message) => {
    // Don't show on dashboard
    if (this.props.match.path === "/" && this.props.match.isExact) {
      return;
    }

    var notification = this.refs.notificationSystem;
    var date = new Date(this.AMQ.activemqwhen * 1000);
    date = date.toLocaleString();
    if (this.AMQ.activemqwall === true) {
      notification.addNotification({
        message:
          date + " " + this.AMQ.activemqwho + ": " + this.AMQ.activemqmessage,
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
      success: function (data) {
        this.setState({ login: true });
        console.log("Successfully logged out");
        //Call whoami so we can get a csrf token
        this.WhoAmIQuery();
      }.bind(this),
      error: function (data) {
        this.error("Failed to log out", data);
      }.bind(this)
    });
  };

  WhoAmIQuery = () => {
    $.ajax({
      type: "get",
      url: "scot/api/v2/whoami",
      success: function (result) {
        SessionStorage.setSessionStorage("whoami", result.user);
        if (result.data) {
          this.setState({
            sensitivity: result.data.sensitivity,
            whoami: result.user
          });
        }
      }.bind(this),
      error: function (data) {
        this.errorToggle("Failed to get current user", data);
      }.bind(this)
    });
  };

  GetHandler = () => {
    $.ajax({
      type: "get",
      url: "/scot/api/v2/handler?current=1",
      success: function (response) {
        this.setState({ handler: response.records[0].username });
      }.bind(this),
      error: function (data) {
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
                <img src="/images/scot-600h.png" alt="" style={{ width: "50px" }} />
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
                <LinkContainer to="/admin" activeClassName="active">
                  <MenuItem>Administration</MenuItem>
                </LinkContainer>
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
              V3.7
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
                createCallback={this.AMQ.create_callback_object}
                removeCallback={this.AMQ.remove_callback_object}
              />
            )}
          />
          {type === "admin" ? (
            <Route exact path="/admin">
              <Admin></Admin>
            </Route>
          ) : null}
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
                createCallback={this.AMQ.create_callback_object}
                removeCallback={this.AMQ.remove_callback_object}
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
              createCallback={this.AMQ.create_callback_object}
              removeCallback={this.AMQ.remove_callback_object}
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
              createCallback={this.AMQ.create_callback_object}
              removeCallback={this.AMQ.remove_callback_object}
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
              createCallback={this.AMQ.create_callback_object}
              removeCallback={this.AMQ.remove_callback_object}
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
              createCallback={this.AMQ.create_callback_object}
              removeCallback={this.AMQ.remove_callback_object}
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
              createCallback={this.AMQ.create_callback_object}
              removeCallback={this.AMQ.remove_callback_object}
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
              createCallback={this.AMQ.create_callback_object}
              removeCallback={this.AMQ.remove_callback_object}
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
              createCallback={this.AMQ.create_callback_object}
              removeCallback={this.AMQ.remove_callback_object}
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
              createCallback={this.AMQ.create_callback_object}
              removeCallback={this.AMQ.remove_callback_object}
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
              createCallback={this.AMQ.create_callback_object}
              removeCallback={this.AMQ.remove_callback_object}
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


