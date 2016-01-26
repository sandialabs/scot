React popup component
===========

![](https://dl.dropboxusercontent.com/u/6306766/react-popup.png)

## Note!

A React 0.12.* supported version can be found in the 0.1 branch and 0.1.* tagged releases

## Install

For now this component is only available as a CommonJS module. Install it with npm (`npm install react-popup --save`). The module exports a react component with static methods. Here's a simple example:

    var Popup = require('react-popup');

    React.render(
    	<Popup />,
    	document.getElementById('popupContainer')
    );

    Popup.alert('This is an alert popup');

## Configuration

You configure the popup by passing properties to the component. Available options are:

    <Popup
        className="mm-popup"
        btnClass="mm-popup__btn"
        closeBtn={true}
        closeHtml={null}
        defaultOk="Ok"
        defaultCancel="Cancel"
        wildClasses={false} />

Above are defaults and for the popup to work you don't have to change anything. If `wildClasses` is set to `false` all classes will be added as BEM style modifiers. If set to `true` you have complete freedom and the class will be displayed exactly as you defined it. Look at this example:

    Popup.create({
        className: 'prompt'
    });

The above popup would have the class `mm-popup__box--prompt` if `wildClasses` is false and if true, it would just be `prompt`. The same goes for button classes.

## Usage

Using the popup is very simple. Only one popup can be visible at the same time and if a popup is created when another is visible, it will be added to the queue. When a popup closes, the next popup in the queue will be display. To get started, here's a simple example:

    Popup.alert('Hello, look at me');

The code above will display a popup with the text "Hello, look at me" and an "Ok" button that closes the popup. The `alert` method is just an alias for this:

    Popup.create({
    	title: null,
    	content: 'Hello, look at me',
    	className: 'alert',
    	buttons: {
    		right: ['ok']
    	}
    });

### Popup options

To create a popup, you have two methods you can use: `create` and `register`. The `create` method automatically puts the new popup in the queue and the `register` method just creates a popup for later use. All popup creations return an ID. More on how to use the ID further down. Now, all available options are:

    {
    	title: null, // or string
    	content: 'text', // or a react component (to set html you have to use a component, the string will be escaped)
    	buttons: {
    		left: [{}, ...],
    		right: [{}, ...]
    	},
    	className: null, // or string
    	noOverlay: true, // hide overlay layer (default is false, overlay visible)
    	position: {x: 0, y: 0} // or a function, more on this further down
    }

#### Buttons

The popup supports two arrays of buttons, left and right. These just renders two divs with corresponding classes, how you style it is up to you. A button requires the following properties:

    {
    	text: 'My button text',
    	className: 'special-btn', // optional
    	action: function (popup) {
    		// do stuff
    		popup.close();
    	}
    }

You can also use the default buttons: `ok` and `cancel`. These uses the "defaultOk" and "defaultCancel" texts and the action function just closes the popup. Great for simple alerts. Use them like this:

    buttons: {
    	left: ['cancel'],
    	right: ['ok']
    }

#### Position

The position property is useful to display a popup in another position, like next to the trigger. The easy use is to just set an object with x and y values: `{x: 100, y: 200}`. The more advanced option is to use a function. When using a function you will be given the DOM node of the popup box, what you do with it is up to you. One thing to have in mind is that, when rendered, the popup has the styling `opacity: 0`. This is to give you a chance to know the popup dimensions when you position the element. The popup box will automatically be visible if you do not use positioning or if you use an object, but when using a function you need to do it yourself. Here's a simple example to display the popup centered above a button:

    var trigger = document.getElementById('trigger');

    trigger.addEventListener('click', function (e) {
    	e.preventDefault();

    	var _this = this;

    	Popup.create({
			content: 'This popup will be displayed right above this button.',
			buttons: {
				right: ['ok']
			},
			noOverlay: true, // Make it look like a tooltip
			position: function (box) {
				var bodyRect      = document.body.getBoundingClientRect(),
				    btnRect       = _this.getBoundingClientRect(),
				    btnOffsetTop  = btnRect.top - bodyRect.top,
				    btnOffsetLeft = btnRect.left - bodyRect.left;

				box.style.top  = (btnOffsetTop - box.offsetHeight - 10) + 'px';
				box.style.left = (btnOffsetLeft + (_this.offsetWidth / 2) - (box.offsetWidth / 2)) + 'px';
				box.style.margin = 0;
				box.style.opacity = 1;
			}
		});
    });
