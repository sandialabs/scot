# react-tinymce

React TinyMCE component

## Installing

```bash
$ npm install react-tinymce
```

## Demo

http://instructure-react.github.io/react-tinymce/

## Example

```js
import React from 'react';
import ReactDOM from 'react-dom';
import TinyMCE from 'react-tinymce';

const App = React.createClass({
  handleEditorChange(e) {
    console.log(e.target.getContent());
  },

  render() {
    return (
      <TinyMCE
        content="<p>This is the initial content of the editor</p>"
        config={{
          plugins: 'autolink link image lists print preview',
          toolbar: 'undo redo | bold italic | alignleft aligncenter alignright'
        }}
        onChange={this.handleEditorChange}
      />
    );
  }
});

ReactDOM.render(<App/>, document.getElementById('container'));
```

## Dependency

This component depends on `tinymce` being globally accessible.

```html
<script src="//tinymce.cachefly.net/4.2/tinymce.min.js"></script>
```

## License

MIT
