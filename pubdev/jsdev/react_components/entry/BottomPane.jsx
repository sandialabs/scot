var React       = require('react');
var ReactDOM    = require('react-dom');
var EntryContainer   = require('./entry_container.jsx');

var ids = [4002,4003]
ReactDOM.render(<EntryContainer ids={ids}/>, document.getElementById('content'));

