export const setLocalStorage = ( name, value ) => {
    localStorage.setItem( name, value );
};

export const removeLocalStorage = ( name ) =>{
    localStorage.removeItem( name );
};

export const getLocalStorage = ( name ) => {
    return localStorage[ name ];
};

export const setSessionStorage = ( name, value ) => {
    localStorage.setItem( name, value );
};

export const removeSessionStorage = ( name ) => {
    localStorage.removeItem( name );
};

export const getSessionStorage = ( name ) => {
    return localStorage[ name ];
};