# React Cookie Banner

React Cookie banner which can be dismissed with just a scroll. Because fuck The Cookie Law that's why.

If you *really* want to annoy your users you can disable this feature (highly discouraged!).

```jsx
import CookieBanner from 'react-cookie-banner';

React.renderComponent(
  <div>
    <CookieBanner
      message='Yes, we use cookies. If you don't like it change website, we won't miss you!'
      onAccept={() => {}}
      cookie='user-has-accepted-cookies'/>
  </div>,
  document.body);
```
[Live Demo](https://rawgit.com/buildo/react-cookie-banner/master/examples/index.html)

[More Examples](https://github.com/buildo/react-cookie-banner/tree/master/examples)

###Install
```
npm install --save react-cookie-banner
```

###API
```jsx
message:                  React.PropTypes.string,
onAccept:                 React.PropTypes.func,
link:                     React.PropTypes.shape({
                            msg: React.PropTypes.string, // defaults to 'Learn more'
                            url: React.PropTypes.string.isRequired,
                          }),
buttonMessage:            React.PropTypes.string,
cookie:                   React.PropTypes.string, // defaults to 'accepts-cookie'
dismissOnScroll:          React.PropTypes.bool, // true by default!
dismissOnScrollThreshold: React.PropTypes.number, // defaults to 0
closeIcon:                React.PropTypes.string, // this should be the className of the icon. if undefined use button
disableStyle:             React.PropTypes.bool,
styles:                   React.PropTypes.object, // override styles
className:                React.PropTypes.string,
children:                 React.PropTypes.element // rendered in replacement without any <div> wrapper
```
**Coming next**:
```jsx
shortMessage: React.PropTypes.string, // to be used with smaller screens
```

###Style
ReactCookieBanner by default uses its simple inline style. However you can easily disable it by passing
```jsx
<CookieBanner disableStyle={true} />
```
In this case you can style it using css classes. The banner is structured as follows:
```html
<div className={this.props.className + ' react-cookie-banner'}
  <span className='cookie-message'>
    {this.props.message}
    <a className='cookie-link'>
      Learn more
    </a>
  </span>
  <div className='button-close'>
    Got it
  </div>
</div>
```
You can also pass your own CustomCookieBanner as child component which will be rendered in replacement:
```jsx
<CookieBanner>
  <CustomCookieBanner {...myCustomProps} /> // rendered directly without any <div> wrapper
</CookieBanner>
```
Or you override the predefined inline-styles. This examples puts the message font back to normal weight and makes the banner slightly transparent:
```jsx
<CookieBanner styles={{banner: {backgroundColor: 'rgba(60, 60, 60, 0.8)'}, 
  message: {fontWeight: 400}}} message="..." />
```
See `src/styleUtils.js` for which style objects are availble to be overridden.

###Cookie manipulation
ReactCookieBanner uses and exports the library **```browser-cookie-lite```**

You can import and use it as follows:
```es6
import {cookie} from 'react-cookie-banner';

// simple set
cookie("test", "a")
// complex set - cookie(name, value, ttl, path, domain, secure)
cookie("test", "a", 60*60*24, "/api", "*.example.com", true)
// get
cookie("test")
// destroy
cookie("test", "", -1)
```
Please refer to [browser-cookie-lite](https://github.com/litejs/browser-cookie-lite) repo for more documentation.
