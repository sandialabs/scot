# react-lightbox
ReactJS Lightbox lib

Example:

```css
html, body {
  margin: 0;
  height: 100%;
  overflow: hidden;
}

.react-lightbox {
  
}

.react-lightbox-image {
  float: left;
  width: 50px;
  height: 50px;
  background-size: cover;
  margin: 10px;
  cursor: pointer;
}

.react-lightbox-overlay {
  position: absolute;
  opacity: 0;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: radial-gradient(ellipse at center, rgba(25,25,25,0.5) 0%,rgba(25,25,25,0.25) 100%);
  transition: opacity 0.5s ease-in-out;
}

.react-lightbox-overlay-open {
  opacity: 1;
}

.react-lightbox-carousel-image {
  position: absolute;
  border-radius: 50%;
  width: 400px;
  height: 400px;
  top:0;
  bottom: 0;
  left: 0;
  right: 0;
  margin: auto;
  background-size: cover;
  transition: transform 0.25s ease-in, opacity 0.25s ease-in;
  opacity: 1;
  transform: translate3d(0, 0, 0);
  box-shadow: 0 0 40px rgba(25, 25, 25, 0.5);
}
.react-lightbox-carousel-image-backward {
  transform: translate3d(-400px, 0, 0);
  opacity: 0;
}
.react-lightbox-carousel-image-forward {
  transform: translate3d(400px, 0, 0);
  opacity: 0;
}

.my-controls {
  position: absolute;
  width: 600px;
  height: 100px;
  text-align: center;
  top:0;
  bottom: 0;
  left: 0;
  right: 0;
  margin: auto;
  z-index: 1;
}
.my-button {
  font-size: 24px;
  background-color: #EAEAEA;
  border-radius: 50%;
  width: 50px;
  line-height: 50px;
  height: 50px;
  color: #333;
  cursor: pointer;
  font-weight: bold;
  font-family: 'Arial Black';
  opacity: 0.8;
}
.my-button:hover {
  background-color: #FFF;
}
.my-button-left {
  float: left;
}
.my-button-right {
  float: right;
}
```

```js
var React = require('react');
var Lightbox = require('react-lightbox');

var Controls = React.createClass({
  render: function () {
    return DOM.div({
      className: 'my-controls'
    }, 
      DOM.div({
        className: 'my-button my-button-left',
        onClick: this.props.backward
      }, '<'),
      DOM.div({
        className: 'my-button my-button-right',
        onClick: this.props.forward
      }, '>')
    );
  }
});

React.render(
  <Lightbox
    pictures={[
      'https://pbs.twimg.com/profile_images/269279233/llama270977_smiling_llama_400x400.jpg',
      'https://pbs.twimg.com/profile_images/1905729715/llamas_1_.jpg',
      'http://static.comicvine.com/uploads/original/12/129924/3502918-llama.jpg',
      'http://fordlog.com/wp-content/uploads/2010/11/llama-smile.jpg'
    ]}
    keyboard
    controls={Controls}
  />
, document.body);
```
Pictures can also be React components