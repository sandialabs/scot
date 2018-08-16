export default function debounce( callback, wait = 200, immediate = false ) {
    let timeout;

    return function( ...args ) {
        clearTimeout( timeout );

        timeout = setTimeout( () => {
            timeout = null;
            if ( !immediate ) callback.apply( this, args );
        }, wait );

        if ( immediate && !timeout ) callback.apply( this, [...args] );
    };
}
