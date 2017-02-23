const blacklist = require('blacklist');
const React = require('react');
const ReactDOM = require('react-dom');

class Frame extends React.Component {
  componentWillReceiveProps(nextProps) {
    if (nextProps.styleSheets.join('') !== this.props.styleSheets.join('')) {
      this.updateStylesheets(nextProps.styleSheets);
    }

    if (nextProps.css !== this.props.css) {
      this.updateCss(nextProps.css);
    }

    const frame = ReactDOM.findDOMNode(this);
    ReactDOM.render(nextProps.children, frame.contentDocument.getElementById('root'));
  }

  componentDidMount() {
    setTimeout(this.renderFrame.bind(this), 0);
  }

  componentWillUnmount() {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this).contentDocument.getElementById('root'));
  }

  updateStylesheets(styleSheets) {
    const links = this.head.querySelectorAll('link');
    for (let i = 0, l = links.length; i < l; i++) {
      const link = links[i];
      link.parentNode.removeChild(link);
    }

    if (styleSheets && styleSheets.length) {
      styleSheets.forEach((href) => {
        const link = document.createElement('link');
        link.setAttribute('rel', 'stylesheet');
        link.setAttribute('type', 'text/css');
        link.setAttribute('href', href);
        this.head.appendChild(link);
      });
    }
  }

  updateCss(css) {
    if (!this.styleEl) {
      const el = document.createElement('style');
      el.type = 'text/css';
      this.head.appendChild(el);
      this.styleEl = el;
    }

    const el = this.styleEl;

    if (el.styleSheet) {
      el.styleSheet.cssText = css;
    } else {
      const cssNode = document.createTextNode(css);
      if (this.cssNode) el.removeChild(this.cssNode);
      el.appendChild(cssNode);
      this.cssNode = cssNode;
    }
  }

  renderFrame() {
    const { styleSheets, css } = this.props;
    const frame = ReactDOM.findDOMNode(this);
    const root = document.createElement('div');

    root.setAttribute('id', 'root');

    this.head = frame.contentDocument.head;
    this.body = frame.contentDocument.body;
    this.body.appendChild(root);

    this.updateStylesheets(styleSheets);
    this.updateCss(css);

    ReactDOM.render(this._children, root);
  }

  render() {
    this._children = this.props.children;
    // render children manually
    const props = blacklist(this.props, 'children', 'styleSheets', 'css');
    return <iframe {...props} onLoad={this.renderFrame} />;
  }
}

module.exports = Frame;
