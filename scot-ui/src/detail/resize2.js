// put this where you want to use it
// import { getTextWidth, getCssStyle, getMaxColumnWidths, resizeColumns } from './resize2';

export const getTextWidth = (text, font) => {
    var canvas  = getTextWidth.canvas || (getTextWidth.canvas = document.createElement("canvas"));
    var context = canvas.getContext("2d");
    context.font = font;
    var metrics  = context.measureText(text);
    // console.log(`text ${text} width is ${metrics.width}`);
    var pad     = 20;
    return Math.floor(metrics.width + pad);
}

export const getCssStyle = (element, prop) => {
    return window.getComputedStyle(element, null).getPropertyValue(prop);
}

export const getCanvasFontSize = (el = document.body) => {
    const fontWeight    = getCssStyle(el, 'font-weight') || 'normal';
    const fontSize      = getCssStyle(el, 'font-size') || '16px';
    const fontFamily    = getCssStyle(el, 'font-family') || 'Times New Roman';
    return `${fontWeight} ${fontSize} ${fontFamily}`;
}

export const getNewColumnWidths = (alertTable) => {
    const maxWidths = [];
    const minWidths = [];
    let colindex = 0;

    let tableHead   = alertTable.getElementsByClassName("rt-thead")[0];
    let hrow        = tableHead.getElementsByClassName("rt-tr")[0];

    for (let th of hrow.getElementsByClassName("rt-th")) {
        let text = th.textContent;
        let width = getTextWidth(text, getCanvasFontSize(th));

        if ( typeof maxWidths[colindex] === 'undefined' ) {
            maxWidths[colindex] = 0;
        }
        if ( typeof minWidths[colindex] === 'undefined' ) {
            minWidths[colindex] = width;
        }
        if ( width > maxWidths[colindex] ) {
            maxWidths[colindex] = width;
        }
        if ( width < maxWidths[colindex] ) {
            minWidths[colindex] = width;
        }
        colindex++;
    }


    let tableBody   = alertTable.getElementsByClassName("rt-tbody")[0];
    // console.log(tableBody);
    let rows = tableBody.getElementsByClassName("rt-tr");
    for (let tr of rows) {
        colindex = 0;
        for (let td of tr.getElementsByClassName("rt-td")) {
            let text = td.textContent;
            let width = getTextWidth(text, getCanvasFontSize(td));
            if ( typeof maxWidths[colindex] === 'undefined' ) {
                maxWidths[colindex] = 0;
            }
            if ( typeof minWidths[colindex] === 'undefined' ) {
                minWidths[colindex] = width;
            }
            if ( width > maxWidths[colindex] ) {
                maxWidths[colindex] = width;
            }
            if ( width < minWidths[colindex] ) {
                minWidths[colindex] = width;
            }
            colindex++;
        }
    }

    let total_max_width = 0;
    for (let w of maxWidths) {
        total_max_width += w;
    }

    let newWidths = [];
    let displayWidth = alertTable.clientWidth;
    for (let i = 0; i < maxWidths.length; i++ ) {
        let maxw = maxWidths[i];
        let minw = minWidths[i];
        let r = maxw / total_max_width;
        let nw = r * displayWidth;

        if ( i < 3 ) {
            nw = minw;
        }
        else {
            if (minw < 80 ) {
                minw = 80;
            }

            if ( nw < minw ) {
                nw = minw;
            }

            if ( nw > 750 ) {
                nw = 750;
            }
        }
        
        newWidths.push(nw + 20);
    }

    return newWidths;
}

export const resizeColumns = () => {
    let alertTable  = document.getElementsByClassName("ReactTable")[1];
    let newWidths   = getNewColumnWidths(alertTable);
    // console.log(maxWidths);
    for (let i = 0; i < alertTable.children.length; i++ ) {
        let rows = alertTable.children[i].getElementsByClassName("rt-tr");
        for (let child of rows) {
            let tds = child.children;
            for (let j = 0; j< tds.length; j++ ) {
                let td = tds[j];
                let newwidth = newWidths[j] + 20;
                // console.log(`resize ${td.textContent} to ${newwidth}`);
                td.style.maxWidth   = newwidth +"px";
                td.style.width      = newwidth +"px";
                td.style.flex       = newwidth +" 0 auto";
            }
        }
    }
}


