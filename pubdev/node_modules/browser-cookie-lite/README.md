

    @version    1.0.4
    @date       2015-03-13
    @stability  3 - Stable



Browser Cookie Lite
===================

Get and set the cookies associated with the current document in browser.

API
---

```javascript
// Get a cookie
cookie(name) -> String

// Set a cookie
cookie(name, value, [ttl], [path], [domain], [secure]) -> String
```

-   **name** `String` - The name of the cookie.
-   **value** `String` - The value of the cookie.
-   **ttl** `Number, optional` - Time to live in seconds.
    If set to 0, or omitted, the cookie will expire
    at the end of the session (when the browser closes).
    If set to negative, the cookie is deleted.
-   **path** `String, optional` - The path in which the cookie will be available on.
    If set to '/', the cookie will be available within the entire domain.
    If set to '/foo/', the cookie will only be available within
    the /foo/ directory and all sub-directories such as /foo/bar/ of domain.
    The default value is the current path of the current document location.
-   **domain** `String, optional` - The domain that the cookie is available to.
    (e.g., 'example.com', '.example.com' (includes all subdomains), 'subdomain.example.com')
    If not specified, defaults to the host portion of the current document location.
-   **secure** `String, optional` - Indicates that the cookie should only be transmitted
    over a secure HTTPS connection from the client.


Examples
--------

```javascript
// simple set
cookie("test", "a")
// complex set - cookie(name, value, ttl, path, domain, secure)
cookie("test", "a", 60*60*24, "/api", "*.example.com", true)
// get
cookie("test")
// destroy
cookie("test", "", -1)
```


Notes
-----

-   This implementation returns always a string,
    so unset cookie and cookie set to empty string are equal.

-   You SHOULD use as few and as small cookies as possible to minimize network
    bandwidth due to the Cookie header being included in every request.

-   Unless sent over a secure channel (such as HTTPS),
    the information in cookies is transmitted in the clear text.

    1.  All sensitive information conveyed in these headers is exposed to
        an eavesdropper.
    2.  A malicious intermediary could alter the headers as they travel
        in either direction, with unpredictable results.
    3.  A malicious client could alter the Cookie header before
        transmission, with unpredictable results.

-   RFC 2109 section 6.3 recommended minimum limitations:

    1.  At least 4096 bytes per cookie.
    2.  At least 20 cookies per unique host or domain name.
    3.  At least 300 cookies total.

    Setting more than 20 cookies per host may results in the oldest cookie being lost.

    RFC 6265 raises limits for at least 50 cookies per domain and 3000 cookies total.


External links
--------------

-   [Source-code on Github](https://github.com/litejs/browser-cookie-lite)
-   [Package on npm](https://npmjs.org/package/browser-cookie-lite)
-   [RFC 2109 - HTTP State Management Mechanism](http://tools.ietf.org/html/rfc2109)
-   [RFC 6265 - HTTP State Management Mechanism](http://tools.ietf.org/html/rfc6265)



### Licence

Copyright (c) 2012, 2014 Lauri Rooden &lt;lauri@rooden.ee&gt;  
[The MIT License](http://lauri.rooden.ee/mit-license.txt)



