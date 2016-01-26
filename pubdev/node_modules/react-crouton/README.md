# React-Crouton

> A message component for reactjs

[Live Demo](http://xeodou.github.io/react-crouton)

## Getting Started

Install via [npm](http://npmjs.org/react-crouton)

```shell
   npm i react-crouton --save-dev
```

## Usage

```Javascript
var Crouton = require('react-crouton')

var data = {
    id: Date.now(),
    type: 'error',
    message: 'Hello React-Crouton',
    autoMiss: true || false,
    onDismiss: listener,
    buttons: [{
        name: 'close',
        listener: function() {

        }
    }],
    hidden: false,
    timeout: 2000
}

<Crouton
    id={data.id}
    type={data.type}
    message={data.message}
    onDismiss={data.onDismiss}
    buttons={data.buttons}
    hidden={data.hidden}
    timeout={data.timeout}
    autoMiss={data.autoMiss}/>

```

## Options

**id** required, every message need an unique id.

type: `number`

**message** required, the message what you want show.

type: `string` || `array`

example:

```
message: 'Hello React-Crouton'
message: ['Hello', 'React', '-', 'Crouton']
```

**type** required, define what type message you want to define.

type: `string`

**hidden** optional, control this property to show or hidden crouton.

type: `boolean`, default is `false`

**buttons** optional, define the buttons that you want show to the user.

type: `string` || `array`

example:

```
buttons: 'close'
butons: [{
    name: 'close'
}]
butons: [{
    name: 'close',
    listener: function() {
        console.log('close button clicked.')
    }
}]
butons: [{
    name: 'close',
    className: 'custom class name',
    listener: function() {
        console.log('close button clicked.')
    }
}]
```

**autoMiss** optional, crouton will auto missed if set this propterty, default is true.

type: `boolean`

**timeout** optional, set how long (ms) to auto dismiss the crouton.

type: `number`, default is `2000` ms (2 seconds)

**onDismiss** optional, crouton will invoke this listener when it dismissed.

type: `function`

## License

MIT
