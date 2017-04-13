import _typeof from 'babel-runtime/helpers/typeof';
var hasDocument = (typeof document === 'undefined' ? 'undefined' : _typeof(document)) === 'object' && document !== null;
var hasWindow = (typeof window === 'undefined' ? 'undefined' : _typeof(window)) === 'object' && window !== null && window.self === window;

export default hasDocument && hasWindow;