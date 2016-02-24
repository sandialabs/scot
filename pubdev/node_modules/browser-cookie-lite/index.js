


/*
* @version    1.0.4
* @date       2015-03-13
* @stability  3 - Stable
* @author     Lauri Rooden <lauri@rooden.ee>
* @license    MIT License
*/


// In browser `this` refers to the window object,
// in NodeJS `this` refers to the exports.

this.cookie = function(name, value, ttl, path, domain, secure) {

	if (arguments.length > 1) {
		return document.cookie = name + "=" + encodeURIComponent(value) +
			(ttl ? "; expires=" + new Date(+new Date()+(ttl*1000)).toUTCString() : "") +
			(path   ? "; path=" + path : "") +
			(domain ? "; domain=" + domain : "") +
			(secure ? "; secure" : "")
	}

	return decodeURIComponent((("; "+document.cookie).split("; "+name+"=")[1]||"").split(";")[0])
}
