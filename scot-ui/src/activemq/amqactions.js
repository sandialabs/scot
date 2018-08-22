import $ from "jquery";
import * as SessionStorage from "../utils/session_storage";
let Dispatcher = require("./dispatcher");
let client;
let whoami;

var Actions = {
  restartClient: function() {
    register_client(true); //restart client
  }
};

export default Actions;
