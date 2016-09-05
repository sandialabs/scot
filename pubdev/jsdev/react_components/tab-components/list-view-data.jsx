var React           = require('react');
var Button          = require('react-bootstrap/lib/Button');

var ListViewData = React.createClass({
    getInitialState: function() {
        return {

        }
    },
    render: function() {
        var columns = this.props.columns;
        var data = this.props.data;
        var arr = [];
        var className = 'list-data-pane';
            for (z=0; z < data.length; z++) {
                arr.push(<ListViewDataEach columns={columns} dataOneRow={data[z]} z={z} type={this.props.type} selected={this.props.selected} selectedId={this.props.selectedId}/>)
            }
        return (
            <tbody className='list-view-table-data'>
                {arr}     
            </tbody>
        )
    },
    
});

var ListViewDataEach = React.createClass({
    clicked: function() {
        //process id, type, and taskid
        var mainid;
        var type = this.props.type;
        var rowid;
        var taskid;
        for (i=0; i < this.props.columns.length; i++) {
            if (this.props.columns[i] == 'id') {
                mainid = parseInt(this.props.dataOneRow[this.props.columns[i]])
                rowid = mainid;
            }
            if (this.props.columns[i].indexOf('.') !== -1) {
                var subthing  = this.props.columns[i].split('.')[1]; 
                if (subthing  == 'type') {
                    var rowType = this.props.columns[i].split('.').reduce(this.obj, this.props.dataOneRow)
                    type=rowType;
                }
                //This is for a target:{id} which references the id for a task
                if (subthing == 'id') {
                    var id = this.props.columns[i].split('.').reduce(this.obj, this.props.dataOneRow)
                    taskid= id;
                }
            }
        }
        this.props.selected(type,rowid,taskid)
        //scroll to
        var cParentTop =  $('.list-view-table-data').offset().top;
        var cTop = $('#'+rowid).offset().top - cParentTop;
        var cHeight = $('#'+rowid).outerHeight(true);
        var windowTop = $('#list-view-data-div').offset().top;
        var visibleHeight = $('#list-view-data-div').height();
        
        var scrolled = $('#list-view-data-div').scrollTop();
        if (cTop < (scrolled)) {
            $('#list-view-data-div').animate({'scrollTop': cTop-(visibleHeight/2)}, 'fast', '');
        } else if (cTop + cHeight + cParentTop> windowTop + visibleHeight) {
            $('#list-view-data-div').animate({'scrollTop': (cTop + cParentTop) - visibleHeight + scrolled + cHeight}, 'fast', 'swing');
        }
    },
    render: function() {
        var rowid;
        var mainid;
        var arr = [];
        var columns = this.props.columns;
        var dataOneRow = this.props.dataOneRow;
        var evenOdd = 'even';
        var backgroundColor;
        if (!isEven(this.props.z)) { evenOdd = 'odd' };
        var subClassName = 'table-row list-view-row'+evenOdd;
        for (i=0; i < columns.length; i++) {
            arr.push(<ListViewDataEachColumn dataOneRow={dataOneRow} columnsOne={columns[i]} type={this.props.type}/>)
        }
        //process id for the row
        for (i=0; i < this.props.columns.length; i++) {
            if (this.props.columns[i] == 'id') {
                mainid = parseInt(this.props.dataOneRow[this.props.columns[i]])
                rowid=mainid;
            }
        }
        if (this.props.selectedId == rowid) {
            backgroundColor = '#AEDAFF';
        }
        return (
            <tr className={subClassName} id={rowid} onClick={this.clicked} style={{backgroundColor:backgroundColor}}>
                {arr}
            </tr>
        )
    },
    componentDidMount: function() {
        var mainid;
        
        this.resizeTable();
        window.addEventListener('resize',this.resizeTable);
    },
    resizeTable: function() {
        for (i=0; i < this.props.columns.length; i++) {
            var className = '.' + this.props.columns[i] + '-list-header-column';
            var width = $('.list-view-table-data').find(className).width();
            $('.list-view-table-header').find(className).css('width',width);
        }
    },
    obj: function(obj, i) {
        return obj[i];
    }
});

var ListViewDataEachColumn = React.createClass({
    render: function() {
        var dataOneRow = this.props.dataOneRow;
        var columnsOne = this.props.columnsOne;
        var className = columnsOne + '-list-header-column' 
        var dataRender = dataOneRow[columnsOne];
        //break apart columns with a . because both are needed to get data reference
        if (columnsOne.indexOf('.') !== -1) {
            dataRender= columnsOne.split('.').reduce(this.obj, dataOneRow);
        }
        if (this.props.columnsOne == 'status') {
            dataRender = <ListViewStatus dataOneRow={dataOneRow} status={dataRender} type={this.props.type} />       
        }
        return (
            <td className={className}>
                {dataRender}
            </td>
        )
    },
    obj: function(obj, i) {
        return obj[i];
    }

})

var ListViewStatus = React.createClass({
    render: function() {
        var buttonStyle = '';
        var open = '';
        var closed = '';
        var promoted = '';
        var title = '';
        var classStatus = '';
        var color = '';
        if (this.props.status == 'open') {
            buttonStyle = 'danger';
            classStatus = 'alertgroup_open'
            color = 'red'
        } else if (this.props.status == 'closed') {
            buttonStyle = 'success';
            classStatus = 'alertgroup_closed'
            color = 'green'
        } else if (this.props.status == 'promoted') {
            buttonStyle = 'default'
            classStatus = 'alertgroup_promoted'
            color = 'orange'
        };
        if (this.props.type == 'alertgroup') {
            open = this.props.dataOneRow.open_count;
            closed = this.props.dataOneRow.closed_count;
            promoted = this.props.dataOneRow.promoted_count;
            title = open + ' / ' + closed + ' / ' + promoted;
        }
        if (this.props.type != 'alertgroup' && this.props.type != 'alert') { 
            return (
                <span style={{color:color}}>{this.props.status}</span>
            )
        } else {
            return (
                <Button bsSize='xsmall' bsStyle={buttonStyle} title={title} id="dropdown" className={classStatus} style={{width:'100%'}}>
                    <span>{title}</span>
                </Button>
            )
        }
    } 
})

function isEven(n) {
    return n % 2 == 0;
}

module.exports = ListViewData;
