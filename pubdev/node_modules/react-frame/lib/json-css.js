// convert styles object to css string

module.exports = function (styles) {
  return styles.map((s) => {
    var rules = '';

    for (var sel in s) {
      if (s.hasOwnProperty(sel)) {
        var style = s[sel];
        var rule = sel + '{';
        for (var k in style) {
          if (style.hasOwnProperty(k) && style[k] != null && typeof style[k] !== 'undefined') {
            rule += (k+':'+style[k]+';');
          }
        }
        rule += '}';
        rules += rule;
      }
    }

    return rules;
  }).join('');
};
