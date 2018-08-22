import React from "react";
import Index from "../main";
import $ from "jquery";
import * as SessionStorage from "../utils/session_storage";
import Dispatcher from "./dispatcher";

let client;
let whoami;

//AMQ STUFF
export const s4 = () => {
  return Math.floor((1 + Math.random()) * 0x10000)
    .toString(16)
    .substring(1);
};

export const get_guid = () => {
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

export const register_client = restart => {
  return new Promise(function(resolve, reject) {
    client = this.get_guid();
    whoami = SessionStorage.getSessionStorage("whoami");
    $.ajax({
      type: "POST",
      url: "/scotaq/amq",
      data: {
        message: "chat",
        type: "listen",
        clientId: client,
        destination: "topic://scot"
      }
    })
      .success(function() {
        console.log("Registered client as " + client);
        if (!restart) {
          //only start the update if this is not a restart. Restart will just use the new clientid once it is live.
          setTimeout(function() {}, 1000);
        }
        resolve(client);
      })
      .error(function() {
        console.log("Error: failed to register client, retry in 1 sec");
        reject("unable to register client");
      });
  });
};

export const getData = (client, whoami) => {
  let now = new Date();
  $.ajax({
    type: "GET",
    url: "/scotaq/amq",
    data: {
      /*loc: location.hash, */
      clientId: client,
      timeout: 20000,
      d: now.getTime(),
      r: Math.random(),
      json: "true",
      username: whoami
    }
  })
    .success(function(data) {
      console.log("Received Message");
      setTimeout(function() {
        this.getData();
      }, 40);
      let messages = $(data)
        .text()
        .split("\n");
      $.each(messages, function(key, message) {
        if (message != "") {
          let json = JSON.parse(message);
          console.log(json);
          //TODO: Handle the messsage here
          return true;
        }
      });
    })
    .error(function() {
      setTimeout(function() {
        this.getData(client);
      }, 1000);
      console.log("AMQ not detected, retrying in 1 second.");
    });
};
