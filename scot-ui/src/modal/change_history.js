let React           = require( 'react' );
let ReactTime       = require( 'react-time' ).default;
let Modal           = require( 'react-modal' );
let Button          = require( 'react-bootstrap/lib/Button' );
const customStyles = {
    content : {
        top     : '50%',
        left    : '50%',
        right   : 'auto',
        bottom  : 'auto',
        marginRight: '-50%',
        transform:  'translate(-50%, -50%)'
    }
};

let ChangeHistory = React.createClass( {
    getInitialState: function() {
        return {
            historyBody:false,
            data: ''
        };
    },
    componentDidMount: function() {
        $.ajax( {
            type: 'get',
            url: '/scot/api/v2/'+ this.props.type + '/' + this.props.id + '/history',
            success: function ( result ) {
                this.setState( {historyBody:true, data:result.records} );
            }.bind( this ),
            error: function( data ) {
                this.props.errorToggle( 'Failed to get change history', data );
            }.bind( this )
        } );
    }, 
    render: function() {
        return (
            <div>
                <Modal
                    isOpen={true}
                    onRequestClose={this.props.changeHistoryToggle}
                    style={customStyles}>
                    <div className="modal-header">
                        <img src="/images/close_toolbar.png" className="close_toolbar" onClick={this.props.changeHistoryToggle} />
                        <h3 id="myModalLabel">{this.props.subjectType} Change History</h3>
                    </div>
                    <div className="modal-body" style={{maxHeight: '30vh', width:'700px',overflowY:'auto'}}>
                        {this.state.historyBody ? <ChangeHistoryData data={this.state.data} /> : null }
                    </div>
                    <div className="modal-footer">
                        <Button onClick={this.props.changeHistoryToggle}>Done</Button>
                    </div>
                </Modal>
            </div>
        );
    }
} );

let ChangeHistoryData = React.createClass( {
    render: function() {
        let rows = [];
        let data = this.props.data;
        for ( let prop in data ) {
            rows.push( <ChangeHistoryDataIterator data={data[prop]} /> ); 
        }
        return (
            <div>
                {rows}
            </div>
        );
    }
} );


let ChangeHistoryDataIterator = React.createClass( {
    render: function() {
        let data = this.props.data;
        return (
            <div>ID: {data.id} - <ReactTime value={data.when * 1000} format="MM/DD/YYYY hh:mm:ss a" /> - {data.who} - {data.what}</div>
        );}
} );



module.exports = ChangeHistory;
