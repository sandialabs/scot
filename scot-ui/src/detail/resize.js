export const ResizeAlertTable = {
    resize: function () {
        if (document.getElementById("detail-container")) {
            console.log("we have a detail container");

            let alert_table = document.getElementById("detail-container").getElementsByClassName("rt-table")[0];
            let alert_row   = document.getElementsByClassName("rt-tbody")[0].getElementsByClassName("rt-tr")[0];
            let total_length = 0;
            let min_length = 15;
            const pct_of_total  = [];
            const new_widths    = [];

            for (let td of alert_row.getElementsByClassName("rt-td")) {
                total_length += td.innerText.length + min_length;
            }

            for (let td of alert_row.getElementsByClassName("rt-td")) {
                let td_length = td.innerText.length + min_length;
                let pct_length = td_length / total_length;
                pct_of_total.push(pct_length);
            }

            let total_width = alert_row.clientWidth;
            let default_pct = 0.015;
            let default_width = total_width * default_pct; // width of one cell
            // default width * number of cells
            let allocated_width = default_pct * alert_row.getElementsByClassName("rt-td").length * total_width;
            // what happens when allocated is bigger?
            let unallocated_width = total_width - allocated_width;

            for (let pct of pct_of_total) {
                let new_width = pct * unallocated_width + default_width;
                new_widths.push(new_width);
            }

            for (let i = 0; i < alert_table.children.length; i++ ) {
                let rows = alert_table.children[i].getElementsByClassName("rt-tr");
                for (let child of rows) {
                    let tds = child.children;
                    for (let j = 0; j < tds.length; j++ ) {
                        let td = tds[j];
                        let new_width   = 0;
                        if ( j < 2 ) {
                            new_width = 85;
                        }
                        else {
                            new_width = new_widths[j];
                        }
                        td.style.maxWidth = new_width + "px";
                        td.style.width = new_width + "px";
                        td.style.flex = new_width + " 0 auto";
                    }
                }
            }

        }
        else {
            console.log("no detail-container");
        }
    }
};

export default ResizeAlertTable;
