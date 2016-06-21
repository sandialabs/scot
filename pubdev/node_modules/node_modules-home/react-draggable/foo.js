let event = document.createEvent('MouseEvents');
event.initMouseEvent('mouseup', true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null);
foo(event);

function foo(e: MouseEvent) {
  //...
}
