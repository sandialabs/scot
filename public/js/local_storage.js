function setLocalStorage( name, value ) {
    localStorage.setItem( name, value );
}

function removeLocalStorage( name ) {
    localStorage.removeItem( name );
}

function getLocalStorage( name ) {
    return localStorage[ name ];
}
