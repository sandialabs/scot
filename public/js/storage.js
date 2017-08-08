function setLocalStorage( name, value ) {
    localStorage.setItem( name, value );
}

function removeLocalStorage( name ) {
    localStorage.removeItem( name );
}

function getLocalStorage( name ) {
    return localStorage[ name ];
}

function setSessionStorage( name, value ) {
    localStorage.setItem( name, value );
}

function removeSessionStorage( name ) {
    localStorage.removeItem( name );
}

function getSessionStorage( name ) {
    return localStorage[ name ];
}

