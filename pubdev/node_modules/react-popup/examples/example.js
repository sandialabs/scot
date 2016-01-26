/**
 * @jsx React.DOM
 */

'use strict';

var React                  = require('react'),
    ReactDom               = require('react-dom'),
    Popup                  = require('../index'),
    alertBtn               = document.getElementById('alert'),
    alertWithTitle         = document.getElementById('alertWithTitle'),
    registeredAlertTrigger = document.getElementById('registeredAlertTrigger'),
    customButtons          = document.getElementById('customButtons'),
    position               = document.getElementById('position'),
    prompt                 = document.getElementById('prompt'),
    registeredAlert;

/** React debug */
window.react = React;

/** Render popup */
ReactDom.render(
	<Popup closeHtml="×" />,
	document.getElementById('popupContainer')
);

/** Alert */
alertBtn.addEventListener('click', function () {
	Popup.alert("This is an example of a normal alert box. Pass some text with additional title or send an ID of an already created popup.");
	Popup.alert("All popups will be queued and when first in line, displayed.");
});

/** Alert with title */
alertWithTitle.addEventListener('click', function () {
	Popup.alert("The alert can also have a title. Isn't it nice?", 'Lorem ipsum');
});

/** Pre-register alert popup */
registeredAlert = Popup.alert('You can register popups for use later. Set the third parameter to true for no queue. All popup creations will generate an ID, use this ID to display the popup.', null, true);

/** Display pre-registered popup */
registeredAlertTrigger.addEventListener('click', function () {
	Popup.queue(registeredAlert);
});

/** Prompt */
prompt.addEventListener('click', function () {
	Popup.prompt('What\'s your name?', null, {
		text: 'Continue',
		className: 'success',
		action: function (Box) {
			alert('You typed: ' + Box.value);
			Box.close();
		}
	});
});

/** Custom buttons */
customButtons.addEventListener('click', function () {
	Popup.create({
		title: null,
		content: 'This popup uses the create method directly to get more control. This popup demonstrates custom buttons.',
		buttons: {
			left: ['cancel'],
			right: [{
				text: 'Save',
				className: 'success',
				action: function () {
					/** This popup will be displayed after this one has closed */
					Popup.alert('Another popup yada yada');

					/** Close this popup. Close will always close the current visible one, if one is visible */
					Popup.close();
				}
			}]
		}
	});
});

/** Positioning */
position.addEventListener('click', function () {
	var _this = this;

	Popup.create({
		content: 'This popup will be displayed right above this button.',
		className: 'popin',
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