var blacklist = require('blacklist');
var React = require('react');
var ReactDOM = require('react-dom');

module.exports = React.createClass({
  displayName: 'Frame',

  render() {
    this._children = this.props.children;
    // render children manually
    var props = blacklist(this.props, 'children');
    return <iframe {...props} onLoad={this.renderFrame}/>;
  },

  updateStylesheets(styleSheets) {
    var links = this.head.querySelectorAll('link');
    for(var i = 0, l = links.length; i < l; i++) {
      var link = links[i];
      link.parentNode.removeChild(link);
    }

    if(styleSheets && styleSheets.length) {
      styleSheets.forEach((href) => {
        var link = document.createElement('link');
        link.setAttribute('rel', 'stylesheet');
        link.setAttribute('type', 'text/css');
        link.setAttribute('href', href);
        this.head.appendChild(link);
      });
    }
  },

  updateCss(css) {
    if(!this.styleEl) {
      var el = document.createElement('style');
      el.type = 'text/css';
      this.head.appendChild(el);
      this.styleEl = el;
    }

    var el = this.styleEl;

    if(el.styleSheet) {
      el.styleSheet.cssText = css;
    } else {
      var cssNode = document.createTextNode(css);
      if(this.cssNode) el.removeChild(this.cssNode);
      el.appendChild(cssNode);
      this.cssNode = cssNode;
    }
  },

  renderFrame() {
    var frame = ReactDOM.findDOMNode(this);
    this.head = frame.contentDocument.head;
    this.body = frame.contentDocument.body;

    this.updateStylesheets(this.props.styleSheets);
    this.updateCss(this.props.css);

    ReactDOM.render(this._children, this.body);
  },

  componentDidMount() {
    setTimeout(this.renderFrame, 0);
  },

  componentWillReceiveProps(nextProps) {
    if(nextProps.styleSheets.join('') !== this.props.styleSheets.join('')) {
      this.updateStylesheets(nextProps.styleSheets);
    }

    if(nextProps.css !== this.props.css) {
      this.updateCss(nextProps.css);
    }

    var frame = ReactDOM.findDOMNode(this);
    ReactDOM.render(nextProps.children, frame.contentDocument.body);
  },

  componentWillUnmount() {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this).contentDocument.body);
  }
});
