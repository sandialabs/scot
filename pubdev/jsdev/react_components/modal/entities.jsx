var React           = require('react');
var Modal           = require('react-modal');

const customStyles = {
    content : {
        top     : '50%',
        left    : '50%',
        right   : 'auto',
        bottom  : 'auto',
        marginRight: '-50%',
        transform:  'translate(-50%, -50%)'
    }
}

var Entities = React.createClass({
    getInitialState: function() {
        return {
            entitiesBody:false,
            data: ''
        }
    },
    componentDidMount: function() {
    this.serverRequest = $.get('/scot/api/v2/'+ this.props.type + '/' + this.props.id + '/entity', function (result) {
            var result = result.records;
            this.setState({entitiesBody:true, data:result})
        }.bind(this));
    }, 
    render: function() {
        return (
            <div>
                <Modal
                    isOpen={true}
                    onRequestClose={this.props.entitiesToggle}
                    style={customStyles}>
                    <div className="modal-header">
                        <img src="/images/close_toolbar.png" className="close_toolbar" onClick={this.props.entitiesToggle} />
                        <h3 id="myModalLabel">List of Entities</h3>
                    </div>                        
                    <div className="modal-body">
                        {this.state.entitiesBody ? <EntitiesData data={this.state.data} /> :null}
                    </div>
                    <div className="modal-footer">
                        <button class="btn" onClick={this.props.entitiesToggle}>Done</button>
                    </div>
                </Modal>         
            </div>        
        )
    }
});

var EntitiesData = React.createClass({
    render: function() {
        var rows = [];
        var data = this.props.data;
        var obj = {};
        for (var prop in data) {
            var type = data[prop].type;
            var value = data[prop].value;
            console.log(value);
            /*if (obj.hasOwnProperty(type)) {
                var arr = [];
                //arr.push(obj[type])
                //arr.push(value);
                //obj[type] = arr;
                //console.log(arr);
                //console.log(obj);
                console.log('lots of entries')
            } else {
                //obj[type] = value; 
                var arr = [];
                arr.push(value);
                obj[type] = arr;
                console.log(obj);
                console.log(obj[type]);
            }*/
            var arr=[];
            arr.push(obj[type]);
            arr.push(data[prop].value);
            obj[type] = arr;
            console.log(obj[type]);
            console.log(obj);
            //obj.type = value;//data[prop].value;
            //console.log(obj);
            //rows.push(<EntitiesDataIterator data={data[prop]} />);
        }
        //console.log(obj);
        return (
            <div>
                {rows}
            </div>
        )
    }
});

var EntitiesDataIterator = React.createClass({
    render: function() {
        data = this.props.data;
        return (
            <div>{data.id} PlaceHolder</div>
        )   
    }
});

module.exports = Entities;
