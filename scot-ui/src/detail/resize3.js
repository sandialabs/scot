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

export const getNewColumnSizes = (alertTable) => {

    const newColumnSize = [];

    let tableBody = alertTable.getElementsByClassName("rt-tbody")[0];
    let rows      = tableBody.getElementsByClassName("rt-tr");
    const tabSize   = [];
    const returned  = [];
    const overage   = [];
    const columnTitles  = [];

    let headers = alertTable
        .getElementsByClassName("rt-thead")[0]
        .getElementsByClassName("rt-th");
    for (let h of headers) {
        columnTitles.push(h.textContent);
    }

    let rowidx = 0;

    for (let row of rows) {
        let cols = row.getElementsByClassName("rt-td");
        let rowreturned = 0;
        let rowoverage  = 0;

        if ( typeof tabSize[rowidx] === 'undefined' ) {
            tabSize[rowidx] = [];
        }
        
        let cindex = 0;
        for (let col of cols) {
            let text = col.textContent;
            let textWidth = getTextWidth(text, getCanvasFontSize(col));
            // this is needed but fucks up the minimum change stuff
            //if ( text === "" ) {
                // might be svg
            //    if ( col.children[0].children[0].localName === 'svg' ) {
             //       textWidth = col.clientWidth;
            //    }
            //}
            let tdWidth = col.clientWidth;
            let diff    = textWidth - tdWidth;

            if ( diff > 0 ) {
                rowoverage += diff;
            }
            if ( diff < 0 ) {
                rowreturned += Math.abs(diff);
            }

            tabSize[rowidx][cindex] = {
                textWidth: textWidth,
                tdWidth: tdWidth,
                diff: diff
            };
            cindex ++;
        }
        returned.push(rowreturned);
        overage.push(rowoverage);
    }

    console.log(`space overage: ${overage}`);
    console.log(`space returned: ${returned}`);

    let minreturn   = 100000;
    let minreturnidx = 0;

    for (let r=0; r < tabSize.length; r++) {

        let rowoverage  = overage[r];
        let rowreturned = returned[r];
        let absdelta    = Math.abs(rowreturned);
        console.log(`absdelta for row ${r} is ${absdelta} current min = ${minreturn} from row ${minreturnidx} rowoverage is ${rowoverage}`);

        if ( absdelta < minreturn ) {
            console.log("setting new minimum");
            minreturn = absdelta;
            minreturnidx = r;
        }
        else {
            console.log("not smaller, skipping");
            continue;
        }

        console.log("New minreturn...");

        for (let c=0; c < tabSize[r].length; c++) {
            if ( typeof newColumnSize[c] === 'undefined' ) {
                newColumnSize[c] = 0;
            }
            let { textWidth, tdWidth, diff } = tabSize[r][c];
            
            let a = 0;
            if (diff < 0) {
                a = tdWidth + diff;
                console.log(`${columnTitles[c]} column ${c} = ${diff} = reducing from ${tdWidth} to ${a}`);
            }
            if (diff > 0 ) {
                let ratio = diff/rowoverage;
                let shareOfReturned = rowreturned * ratio;
                console.log(`share of returned = ${shareOfReturned}`);
                a = tdWidth + shareOfReturned;
                console.log(`${columnTitles[c]} column ${c} = ${diff} = ratio is ${ratio} increasing from ${tdWidth} to ${a}`);
            }
            newColumnSize[c] = a;
        }
    }
    console.log(`Minimum return delta ${minreturn} was row ${minreturnidx}`);
    console.log("NewColumnSizes =");
    console.log(newColumnSize);
    return newColumnSize;
};


export const getNewColumnWidths = (alertTable) => {
    const newWidths = [];

    let tableBody = alertTable.getElementsByClassName("rt-tbody")[0];
    let rows      = tableBody.getElementsByClassName("rt-tr");
    let colindex  = 0;
    let returnedSpace = 0;
    const oversize    = [];
    const osamount    = [];
    let totalos       = 0;
    // bug: last row wins
    let tr = rows[0];  //
        colindex    = 0;
        let tds = tr.getElementsByClassName("rt-td");
        for (let td of tds) {
            let text = td.textContent;
            let textWidth = getTextWidth(text, getCanvasFontSize(td));
            let tdWidth = td.clientWidth;

            if (tdWidth < textWidth) {
                let overage = textWidth - tdWidth;
                oversize.push(colindex);
                osamount.push(overage);
                totalos += overage;
            }

            if (tdWidth > textWidth) {
                let newwidth = textWidth + 20;
                newWidths[colindex] = newwidth;
                returnedSpace += tdWidth - newwidth;
            }
            else {
                newWidths[colindex] = tdWidth;
            }
            colindex++;
        }

    let oversizeCount = oversize.length;
    let extra = returnedSpace / oversizeCount; //evenly divide regained space 

    const extras = [];
    for (let amt of osamount) {
        let ratio = amt / totalos;
        let extra = Math.floor(returnedSpace * ratio);
        extras.push(extra);
    }



    console.log("number of cells oversize = "+oversizeCount);
    console.log(`Returned Space = ${returnedSpace}`);
    console.log(`Extras = `);
    console.log(extras);
    console.log("oversize = ");
    console.log(oversize);

    for (let idx of oversize) {
        console.log(`idx ${idx} was oversize`);
        console.log(`  orig size ${newWidths[idx]} adding ${extra}`);
        newWidths[idx] += extra;
    }
    console.log(newWidths);
    return newWidths;
}

export const resizeColumns = () => {
    let alertTable  = document.getElementsByClassName("ReactTable")[1];
    let newWidths   = getNewColumnSizes(alertTable);
    // console.log(maxWidths);
    for (let i = 0; i < alertTable.children.length; i++ ) {
        let rows = alertTable.children[i].getElementsByClassName("rt-tr");
        for (let child of rows) {
            let tds = child.children;
            for (let j = 0; j< tds.length; j++ ) {
                let td = tds[j];
                let newwidth = newWidths[j] ;
                // console.log(`resize ${td.textContent} to ${newwidth}`);
                td.style.maxWidth   = newwidth +"px";
                td.style.width      = newwidth +"px";
                td.style.flex       = newwidth +" 0 auto";
            }
        }
    }
}



