export const setLocalStorage = ( name, value ) =>{
    localStorage.setItem( name, value );
};

export const removeLocalStorage = ( name ) => {
    localStorage.removeItem( name );
};

export const getLocalStorage = ( name ) => {
    return localStorage[ name ];
};
