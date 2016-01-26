# react-menu

An accessible menu component built for React.JS

See example at [http://instructure-react.github.io/react-menu/](http://instructure-react.github.io/react-menu/)

## Basic Usage

```html
/** @jsx React.DOM */

var react = require('react');

var Menu = require('react-menu');
var MenuTrigger = Menu.MenuTrigger;
var MenuOptions = Menu.MenuOptions;
var MenuOption = Menu.MenuOption;

var App = React.createClass({

  render: function() {
    return (
      <Menu className='myMenu'>
        <MenuTrigger>
          ⚙
        </MenuTrigger>
        <MenuOptions>

          <MenuOption>
            1st Option
          </MenuOption>

          <MenuOption onSelect={this.someHandler}>
            2nd Option
          </MenuOption>

          <div className='a-non-interactive-menu-item'>
            non-selectable item
          </div>

          <MenuOption disabled={true} onDisabledSelect={this.otherHanlder}>
            diabled option
          </MenuOption>

        </MenuOptions>
      </Menu>
    );
  }
});

React.renderComponent(<App />, document.body);

```

For a working example see the `examples/basic` example

## Styles

Bring in default styles by calling `injectCSS` on the `Menu` component.

```javascript
var Menu = require('react-menu');

Menu.injectCSS();
```

Default styles will be added to the top of the head, and thus any styles you
write will override any of the defaults.

The following class names are used / available for modification in your own stylsheets:

```
.Menu
.Menu__MenuTrigger
.Menu__MenuOptions
.Menu__MenuOption
.Menu__MenuOptions--vertical-bottom
.Menu__MenuOptions--vertical-top
.Menu__MenuOptions--horizontal-right
.Menu__MenuOptions--horizontal-left
```

The last four class names control the placement of menu options when the menu
would otherwise bleed off the screen. See `/lib/helpers/injectCSS.js` for
defaults. The `.Menu__MenuOptions` element will always have a vertical and
horizontal modifier.
