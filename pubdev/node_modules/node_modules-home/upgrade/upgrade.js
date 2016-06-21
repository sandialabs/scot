/**
 * UpgradeJS
 * A native NodeJS WebSocket library.
 * 
 * @author Dan Cobb
 * @version 1.0.2
 */

var crypto = require('crypto');

/**
 * Write upgrade handshake header to socket.
 * @param {ServerRequest} req ServerRequest from HTTPServer.
 * @param {Socket} socket Socket from upgrade event.
 * @see http://tools.ietf.org/html/rfc6455#section-1.3
 */
exports.writeHead = function (req, socket) {
    var key = req.headers['sec-websocket-key'];
    var hash = crypto.createHash('sha1');
    var $GUID = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';
    hash.update(key + $GUID, 'utf8');
    key = hash.digest('base64');
    
    socket.write(
        'HTTP/1.1 101 Web Socket Protocol Handshake\r\n' +
        'Upgrade: WebSocket\r\n' +
        'Connection: Upgrade\r\n' +
        'Sec-WebSocket-Accept: ' + key + '\r\n' +
        '\r\n'
    );
};

/**
 * Removes mask from incoming frame.
 * @param {Buffer} buffer Buffer object from data event of WebSocket.
 * @returns {String} Unmasked data.
 * @see http://stackoverflow.com/questions/8125507/how-can-i-send-and-receive-websocket-messages-on-the-server-side
 */
exports.getData = function (buffer) {
    var datalength = buffer[1] & 127;
    var indexFirstMask = 2;
    if (datalength == 126) {
        indexFirstMask = 4;
    } else if (datalength == 127) {
        indexFirstMask = 10;
    }
    
    var masks = buffer.slice(indexFirstMask, indexFirstMask + 4);
    var i = indexFirstMask + 4;
    var j = 0;
    var output = '';
    while (i < buffer.length) {
        var charCode = buffer[i] ^ masks[j % 4];
        output += String.fromCharCode(charCode);
        i += 1;
        j += 1;
    }
    return output;
};

/**
 * Wraps data in a websocket frame. Note that UpgradeJS does not support payloads larger than 125 bytes.
 * @param {String} msg Some data to wrap.
 * @returns {Buffer} Hex encoded Buffer.
 * @throws {RangeError}
 * @see http://stackoverflow.com/questions/8125507/how-can-i-send-and-receive-websocket-messages-on-the-server-side
 */
exports.frameData = function (msg) {
    // First 2 bytes are reserved.
    var frame = '81'; // 129d
    
    // Next 2 bytes are length of payload.
    if (msg.length <= 125) {
        var len = msg.length.toString(16);
        frame += (len.length == 1) ? ('0' + len) : len;
    } else {
        throw new RangeError('Frame data too large.');
    }
    
    // Encode message as hex.
    for (var i in msg) {
        frame += msg.charCodeAt(i).toString(16);
    }
    
    return new Buffer(frame, 'hex');
};

/**
 * Convenience method to lock send behavior to a specific socket.
 * @param {Socket} socket The socket to communicate over.
 * @returns {Function} Send behavior using a specific socket.
 * @example
 * var send = upgrade.getSend(socket);
 * send('foo');
 * send('bar');
 */
exports.getSend = function (socket) {
    return function (message) {
        var data = exports.frameData(message);
        socket.write(data);
    };
};

/**
 * Convenience method for sending framed data.
 * @param {String} msg Data to send across websocket.
 * @param {Socket} socket The socket to commincate over.
 * @throws {RangeError}
 * @example
 * upgrade.send('foo', socket);
 * upgrade.send('bar', socket);
 */
exports.send = function (msg, socket) {
    var data = exports.frameData(msg);
    socket.write(data);
};
