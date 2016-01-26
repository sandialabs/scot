'use strict';

var React = require('react');
var classNames = require('classnames');

if (process.env.NODE_ENV !== 'test') {
  require('./react-simpletabs.css');
}

var Tabs = React.createClass({
  displayName: 'Tabs',
  propTypes: {
    className: React.PropTypes.oneOfType([
      React.PropTypes.array,
      React.PropTypes.string,
      React.PropTypes.object
    ]),
    tabActive: React.PropTypes.number,
    onMount: React.PropTypes.func,
    onBeforeChange: React.PropTypes.func,
    onAfterChange: React.PropTypes.func,
    children: React.PropTypes.oneOfType([
      React.PropTypes.array,
      React.PropTypes.element
    ]).isRequired
  },
  getDefaultProps () {
    return { tabActive: 1 };
  },
  getInitialState () {
    return {
      tabActive: this.props.tabActive
    };
  },
  componentDidMount() {
    var index = this.state.tabActive;
    var $selectedPanel = this.refs['tab-panel'];
    var $selectedMenu = this.refs[`tab-menu-${index}`];

    if (this.props.onMount) {
      this.props.onMount(index, $selectedPanel, $selectedMenu);
    }
  },
  componentWillReceiveProps: function(newProps){
    if(newProps.tabActive && newProps.tabActive !== this.props.tabActive){
      this.setState({tabActive: newProps.tabActive});
    }
  },
  render () {
    var className = classNames('tabs', this.props.className);
    return (
      <div className={className}>
        {this._getMenuItems()}
        {this._getSelectedPanel()}
      </div>
    );
  },
  setActive(index, e) {
    e.preventDefault();

    var onAfterChange = this.props.onAfterChange;
    var onBeforeChange = this.props.onBeforeChange;
    var $selectedPanel = this.refs['tab-panel'];
    var $selectedTabMenu = this.refs[`tab-menu-${index}`];

    if (onBeforeChange) {
      var cancel = onBeforeChange(index, $selectedPanel, $selectedTabMenu);
      if(cancel === false){ return }
    }

    this.setState({ tabActive: index }, () => {
      if (onAfterChange) {
        onAfterChange(index, $selectedPanel, $selectedTabMenu);
      }
    });
  },
  _getMenuItems () {
    if (!this.props.children) {
      throw new Error('Tabs must contain at least one Tabs.Panel');
    }

    if (!Array.isArray(this.props.children)) {
      this.props.children = [this.props.children];
    }

    var $menuItems = this.props.children
      .map($panel => typeof $panel === 'function' ? $panel() : $panel)
      .filter($panel => $panel)
      .map(($panel, index) => {
        var ref = `tab-menu-${index + 1}`;
        var title = $panel.props.title;
        var classes = classNames(
          'tabs-menu-item',
          this.state.tabActive === (index + 1) && 'is-active'
        );

        return (
          <li ref={ref} key={index} className={classes}>
            <a onClick={this.setActive.bind(this, index + 1)}>
              {title}
            </a>
          </li>
        );
      });

    return (
      <nav className='tabs-navigation'>
        <ul className='tabs-menu'>{$menuItems}</ul>
      </nav>
    );
  },
  _getSelectedPanel () {
    var index = this.state.tabActive - 1;
    var $panel = this.props.children[index];

    return (
      <article ref='tab-panel' className='tab-panel'>
        {$panel}
      </article>
    );
  }
});

Tabs.Panel = React.createClass({
  displayName: 'Panel',
  propTypes: {
    title: React.PropTypes.string.isRequired,
    children: React.PropTypes.oneOfType([
      React.PropTypes.array,
      React.PropTypes.element
    ]).isRequired
  },
  render () {
    return <div>{this.props.children}</div>;
  }
});

module.exports = Tabs;
