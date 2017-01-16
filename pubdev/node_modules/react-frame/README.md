# react-frame
React components within an iframe for isolated css styling
### Installation
``` sh
npm install react-frame --save

```
**Notice**: There is a warning in react development mode.

Warning: render(): Rendering components directly into document.body is discouraged, since its children are often manipulated by third-party scripts and browser extensions. This may lead to subtle reconciliation issues. Try rendering into a container element created for your app.

### Demo
[https://pqx.github.io/react-frame](https://pqx.github.io/react-frame)
### Usage
``` javascript
<Frame
  styleSheets={['frame1.css']}
  css={'body{background-color:#eee;}'}>

  <div className="title">
    Parturient Ipsum Cursus Purus Justo
  </div>

</Frame>
```
### License
MIT
