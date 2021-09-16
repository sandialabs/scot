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

export const getMaxColumnWidths = (alertTable) => {
    const maxWidths = [];
    let colindex = 0;

    let tableHead   = alertTable.getElementsByClassName("rt-thead")[0];
    let hrow        = tableHead.getElementsByClassName("rt-tr")[0];

    for (let th of hrow.getElementsByClassName("rt-th")) {
        if ( typeof maxWidths[colindex] === 'undefined' ) {
            maxWidths[colindex] = 0;
        }
        let text = th.textContent;
        let width = getTextWidth(text, getCanvasFontSize(th));
        if ( width > maxWidths[colindex] ) {
            maxWidths[colindex] = width;
        }
        if (maxWidths[colindex] > 450) {
            // console.log("truncating to 450px");
            maxWidths[colindex] = 450;
        }
        // console.log(`set width of header ${text} to ${width}`);
        colindex++;
    }


    let tableBody   = alertTable.getElementsByClassName("rt-tbody")[0];
    // console.log(tableBody);
    let rows = tableBody.getElementsByClassName("rt-tr");
    for (let tr of rows) {
        colindex = 0;
        for (let td of tr.getElementsByClassName("rt-td")) {
            if ( typeof maxWidths[colindex] === 'undefined' ) {
                maxWidths[colindex] = 0;
            }
            let text = td.textContent;
            let width = getTextWidth(text, getCanvasFontSize(td));
            if ( width > maxWidths[colindex] ) {
                // console.log(`col ${colindex} new max width = ${width}`);
                maxWidths[colindex] = width;
            }
            if (maxWidths[colindex] > 450) {
                // console.log("truncating to 450px");
                maxWidths[colindex] = 450;
            }
            colindex++;
        }
    }
    return maxWidths;
}

export const resizeColumns = () => {
    let alertTable  = document.getElementsByClassName("ReactTable")[1];
    let maxWidths   = getMaxColumnWidths(alertTable);
    // console.log(maxWidths);
    for (let i = 0; i < alertTable.children.length; i++ ) {
        let rows = alertTable.children[i].getElementsByClassName("rt-tr");
        for (let child of rows) {
            let tds = child.children;
            for (let j = 0; j< tds.length; j++ ) {
                let td = tds[j];
                let newwidth = maxWidths[j] + 20;
                // console.log(`resize ${td.textContent} to ${newwidth}`);
                td.style.maxWidth   = newwidth +"px";
                td.style.width      = newwidth +"px";
                td.style.flex       = newwidth +" 0 auto";
            }
        }
    }
}


