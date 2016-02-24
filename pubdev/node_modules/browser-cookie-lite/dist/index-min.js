/*! litejs.com/MIT-LICENSE.txt */
this.cookie=function(a,e,b,c,d,f){return 1<arguments.length?document.cookie=a+"="+encodeURIComponent(e)+(b?"; expires="+(new Date(+new Date+1E3*b)).toUTCString():"")+(c?"; path="+c:"")+(d?"; domain="+d:"")+(f?"; secure":""):decodeURIComponent((("; "+document.cookie).split("; "+a+"=")[1]||"").split(";")[0])};
