import React from 'react';
import CookieBanner from '../src';
import {cookie} from '../src';

cookie('accepts-cookies', '');

const Example = React.createClass({

  propTypes: {},

  getInitialState() {
    return {
      dismissOnScroll: true
    };
  },

  resetCookies() {
    cookie('accepts-cookies', '');
    this.refresh();
  },

  toggleDismissOnScroll() {
    this.setState({ dismissOnScroll: !this.state.dismissOnScroll });
  },

  refresh() {
    this.setState({});
  },

  render() {
    return (
      <div style={{height: 2000, fontFamily: 'sans-serif'}}>
        <CookieBanner
          styles={{button: {color: 'blue'}}}
          dismissOnScroll={this.state.dismissOnScroll}
          message='your own custom message'
          link={{msg: 'link to cookie policy', url: 'http://nocookielaw.com/'}}
          buttonMessage='close button message'
          onAccept={this.refresh}/>

        <div style={{margin: 20}}>
          <p>accepts-cookies: {cookie('accepts-cookies') ? 'true' : 'false'}</p>
          <button onClick={this.toggleDismissOnScroll}>{this.state.dismissOnScroll ? 'Disable' : 'Activate'} "dismissOnScroll"</button>
          <button onClick={this.resetCookies}>Reset Cookies</button>
          <h2>Try dismissing with a scroll</h2>
        </div>
      </div>
    );
  }

});

React.render(<Example />, document.getElementById('container'));