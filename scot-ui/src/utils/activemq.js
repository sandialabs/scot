import * as SessionStorage from "../utils/session_storage";
import $ from 'jquery'

export class Amq {
  constructor() {
    this.client = "";
    this.whoami = "";
    this.amqdebug = "";
    this.activemqaction = "";
    this.activemqaction = "";
    this.activemqid = "";
    this.activemqwho = "";
    this.activemqtype = "";
    this.activemqguid = "";
    this.activemqhostname = "";
    this.activemqpid = "";
    this.activemqwhen = "";
    this.activemqwall = "";
    this.cb_map = new Map();
  }

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
    this.client = this.get_guid();
    this.whoami = SessionStorage.getSessionStorage("whoami");
    $.ajax({
      type: "POST",
      url: "/scotaq/amq",
      data: {
        message: "chat",
        type: "listen",
        clientId: this.client,
        destination: "topic://scot"
      },
      success: function (data) {
        console.log("Registered client as " + this.client);
        if (!restart) {
          //only start the update if this is not a restart. Restart will just use the new clientid once it is live.
          setTimeout(
            function () {
              this.get_data();
            }.bind(this),
            1000
          );
        }
      }.bind(this),
      error: function (data) {
        console.log("Error: failed to register client, retry in 1 sec");
        setTimeout(function () {
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
        clientId: this.client,
        timeout: 20000,
        d: now.getTime(),
        r: Math.random(),
        json: "true",
        username: this.whoami
      },
      success: function (data) {
        console.log("Received Message");
        setTimeout(
          function () {
            this.get_data();
          }.bind(this),
          40
        );
        let messages = $(data)
          .text()
          .split("\n");
        messages.forEach(function (message, key) {
          if (message !== "") {
            let json = JSON.parse(message);
            console.log(json);
            this.process_message(json);
            this.handle_update(json);
            return true;
          }
        }.bind(this));
      }.bind(this),
      error: function () {
        setTimeout(
          function () {
            this.getData(this.client);
          }.bind(this),
          1000
        );
        console.log("AMQ not detected, retrying in 1 second.");
      }
    });
  };

  checkNumber(number) {
    let parsed = parseInt(number, 10);
    if (isNaN(parsed)) {
      return false
    } else {
      return true;
    }
  }

  create_callback_object = (key, callback) => {
    let intkey = key;
    if (this.checkNumber(intkey)) {
      intkey = parseInt(intkey, 10)
    }
    if (this.cb_map.has(intkey)) {
      this.cb_map.get(intkey).add(callback);
    } else {
      let newset = new Set();
      newset.add(callback)
      this.cb_map.set(intkey, newset)
    }
  };

  remove_callback_object = (key, callback) => {
    let callbacks = this.cb_map.get(key)
    callbacks.forEach(function (element) {
      if (callback == element) {
        callbacks.delete(callback);
      }
    }.bind(this));
  };


  process_message = payload => {

    if (payload.action === "wall") {
      this.activemqwho = payload.data.who;
      this.activemqmessage = payload.data.message;
      this.activemqwhen = payload.data.when;
      this.activemqwall = true;
    } else {
      this.activemqaction = payload.action;
      this.activemqid = payload.data.id;
      this.activemqtype = payload.data.type;
      this.activemqwho = payload.data.who;
      this.activemqguid = payload.guid;
      this.activemqhostname = payload.hostname;
      this.activemqpid = payload.pid;
    }
  }

  execute_callback_function = searchstring => {
    try {
      let f = this.cb_map.get(searchstring);
      if (f !== undefined) {
        f.forEach(function (item) {
          item();
        });
      }
      let noti = this.cb_map.get('notification');
      if (noti !== undefined) {
        noti.forEach(function (item) {
          item();
        })
      }
    } catch (e) {
      throw e;
    }
  }


  handle_update = message => {
    let searchstring = "";
    if (message.action === 'wall') {
      searchstring = 'wall'
    } else if (message.action === 'created') {
      searchstring = `${message.data.type}:listview`
    } else if (message.action === 'updated') {
      searchstring = message.data.id
    } else if (message.action === 'deleted') {
      searchstring = message.data.id
    }
    this.execute_callback_function(searchstring);
  }
}