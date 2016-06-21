# Upgrade
### A simple Node websocket library to handle http upgrades.
Version **1.1.0**

---
* See: [NPM Page](https://npmjs.org/package/upgrade)
* See: [Github Repo](http://www.github.com/cobbdb/upgrade)

### Installation
> ```
npm install upgrade
```

### Usage
###### Here is an example of a basic upgrade setup:
> ```JavaScript
// server.js
var http = require('http');
var upgrade = require('upgrade');
var server = http.createServer();
server.on('upgrade', function (req, socket) {
    var send = upgrade.getSend(socket);
    upgrade.writeHead(req, socket);
    socket.on('data', function (buff) {
        var data = upgrade.getData(buff);
        console.log('> ' + data);
    });
    send('Welcome to the Server!');
});
server.listen(8000);
```
```JavaScript
// client.js
var socket = new WebSocket('ws://localhost:8000');
socket.onopen = function () {
    socket.send('Hello Server!');
    console.log('> Socket Open.');
};
socket.onmessage = function (evt) {
    var msg = evt.data;
    console.log('> ' + msg);
};
```


## writeHead(req, socket)
Write upgrade handshake header to socket.

**Parameters**

* {ServerRequest} req - ServerRequest from HTTPServer.
* {Socket} socket - Socket from upgrade event.

```JavaScript
server.on('upgrade', function (req, socket) {
    upgrade.writeHead(req, socket);
```


## getData(buffer)
Removes mask from incoming frame.

**Parameters**

* {Buffer} buffer - Buffer object from data event of WebSocket.

**Returns** {String} Unmasked data.

```JavaScript
socket.on('data', function (buff) {
    var data = upgrade.getData(buff);
```


## frameData(msg)
Wraps data in a websocket frame. Note that UpgradeJS does not support payloads larger than 125 bytes.

**Parameters**

* {String} msg - Some data to wrap.

**Returns** {Buffer} Hex encoded Buffer.  
**Throws** {RangeError}

```JavaScript
var data = exports.frameData(message);
socket.write(data);
```


## getSend(socket)
Convenience method to lock send behavior to a specific socket.

**Parameters**

* {Socket} socket - The socket to communicate over.

**Returns** {Function} Send behavior using a specific socket.

```JavaScript
var send = upgrade.getSend(socket);
send('foo');
send('bar');
```


## send(msg, socket)
Convenience method for sending framed data.

**Parameters**

* {String} msg - Data to send across websocket.
* {Socket} socket - The socket to commincate over.

**Throws** {RangeError}

```JavaScript
upgrade.send('foo', socket);
upgrade.send('bar', socket);
```

---
By Dan Cobb: <cobbdb@gmail.com> - [petitgibier.sytes.net](http://petitgibier.sytes.net)  
License: MIT
