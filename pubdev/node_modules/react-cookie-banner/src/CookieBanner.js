import React from 'react';
import cx from 'classnames';
import omit from 'lodash.omit';
import assign from 'lodash.assign';
import { cookie as cookieLite } from 'browser-cookie-lite';
import styleUtils from './styleUtils';

const propTypes = {
  message: React.PropTypes.string,
  onAccept: React.PropTypes.func,
  link: React.PropTypes.shape({
    msg: React.PropTypes.string,
    url: React.PropTypes.string.isRequired
  }),
  buttonMessage: React.PropTypes.string,
  cookie: React.PropTypes.string,
  dismissOnScroll: React.PropTypes.bool,
  dismissOnScrollThreshold: React.PropTypes.number,
  closeIcon: React.PropTypes.string,
  disableStyle: React.PropTypes.bool,
  styles: React.PropTypes.object,
  children: React.PropTypes.element,
  className: React.PropTypes.string
};

export default React.createClass({

  displayName: 'CookieBanner',

  propTypes: propTypes,

  getDefaultProps() {
    return {
      onAccept: () => {},
      dismissOnScroll: true,
      cookie: 'accepts-cookies',
      buttonMessage: 'Got it',
      dismissOnScrollThreshold: 0,
      styles: {}
    };
  },

  getInitialState() {
    return {
      listeningScroll: false
    };
  },

  componentDidMount() {
    this.addOnScrollListener();
  },

  addOnScrollListener(props) {
    props = props || this.props;
    if (!this.state.listeningScroll && !this.hasAcceptedCookies() && props.dismissOnScroll) {
      if (window.attachEvent) {
        //Internet Explorer
        window.attachEvent('onmousewheel', this.onScroll);
      } else if(window.addEventListener) {
        window.addEventListener('mousewheel', this.onScroll, false);
      }
      this.setState({ listeningScroll: true });
    }
  },

  removeOnScrollListener() {
    if (this.state.listeningScroll) {
      if (window.detachEvent) {
        //Internet Explorer
        window.detachEvent('onmousewheel', this.onScroll);
      } else if(window.removeEventListener) {
        window.removeEventListener('mousewheel', this.onScroll, false);
      }
      this.setState({ listeningScroll: false });
    }
  },

  onScroll() {
    // tacit agreement buahaha! (evil laugh)
    if (window.pageYOffset > this.props.dismissOnScrollThreshold) {
      this.onAccept();
    }
  },

  onAccept() {
    const { cookie, onAccept } = this.props;
    cookieLite(cookie, true, 60*60*24*365);
    onAccept({ cookie });
    this.removeOnScrollListener();
  },

  getStyle(style) {
    const { disableStyle, styles } = this.props;
    if (!disableStyle) {
      // apply custom styles if available
      return assign({}, styleUtils.getStyle(style), styles[style]);
    }
  },

  getCloseButton() {
    const { closeIcon, buttonMessage } = this.props;
    if (closeIcon) {
      return <i className={closeIcon} onClick={this.onAccept} style={this.getStyle('icon')}/>;
    }
    return (
      <div className='button-close' onClick={this.onAccept} style={this.getStyle('button')}>
        {buttonMessage}
      </div>
    );
  },

  getLink() {
    const { link } = this.props;
    if (link) {
      return (
        <a
          href={link.url}
          className='cookie-link'
          style={this.getStyle('link')}>
            {link.msg || 'Learn more'}
        </a>
      );
    }
  },

  getBanner() {
    const { children, className, message } = this.props;
    if (children) {
      return children;
    }

    const props = omit(this.props, Object.keys(propTypes));
    return (
      <div {...props} className={cx('react-cookie-banner', className)} style={this.getStyle('banner')}>
        <span className='cookie-message' style={this.getStyle('message')}>
          {message}
          {this.getLink()}
        </span>
        {this.getCloseButton()}
      </div>
    );
  },

  hasAcceptedCookies() {
    return (typeof window !== 'undefined') && cookieLite(this.props.cookie);
  },

  render() {
    return this.hasAcceptedCookies() ? null : this.getBanner();
  },

  componentWillReceiveProps(nextProps) {
    if (nextProps.dismissOnScroll) {
      this.addOnScrollListener(nextProps);
    } else {
      this.removeOnScrollListener();
    }
  },

  componentWillUnmount() {
    this.removeOnScrollListener();
  }

});