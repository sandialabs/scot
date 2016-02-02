var mainColor = 'hsl(200, 50%, 50%)';

jss({
  body: {
    color: mainColor,
    background: lighten(mainColor, 45),
    'font-size': '20px',
    'font-family': '"Helvetica Neue", helvetica, arial'
  },

  h1: {
    color: darken(mainColor, 20)
  }
});

function lighten(hsl, amount) {
  return adjustHSL(hsl, amount, '+');
}

function darken(hsl, amount) {
  return adjustHSL(hsl, amount, '-');
}

function adjustHSL(hsl, amount, operation) {
  var split = hsl.split(',');
  var lightness = parseInt(split[2], 10);
  var value = operation == '+' ?
    lightness + amount :
    lightness - amount;
  split[2] = ' '+value+'%)';
  return split.join(',');
}

