var React           = require('react');
var Modal           = require('react-modal');
var Button          = require('react-bootstrap/lib/Button');
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
            entitiesBody:true,
        }
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
                    <div className="modal-body" style={{height:'600px', overflowY:'auto'}}>
                        {this.state.entitiesBody ? <EntitiesData data={this.props.entityData} /> :null}
                    </div>
                    <div className="modal-footer">
                        <Button onClick={this.props.entitiesToggle}>Done</Button> 
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
        var originalobj = {};
        originalobj['entities'] = {};
        var obj = originalobj.entities;
        for (var prop in data) {
            var type = data[prop].type;
            var value = prop;
            if (obj.hasOwnProperty(type)) { 
                obj[type].push(value); 
            } else { 
                var arr = [];
                arr.push(value);
                obj[type] = arr;
            } 
        }
        for (var prop in obj) {
            var type = prop;
            var value = obj[prop];
            rows.push(<EntitiesDataHeaderIterator type={type} value={value}/>);
        }
        return (
            <div>
                {rows}
            </div>
        )
    }
});

var EntitiesDataHeaderIterator = React.createClass({
    render: function() {
        var rows = [];
        var type = this.props.type;
        var value = this.props.value;
        for (var i=0;i<value.length;i++) {
            var eachValue = value[i];
            rows.push(<EntitiesDataValueIterator eachValue={eachValue} />);
        }
        return (
            <div style={{border:'1px solid black',width:'500px'}}>
                <h3>{type}</h3>
                <div style={{fontWeight:'normal',maxHeight:'300px',overflowY:'auto'}}>
                    {rows}
                </div>            
            </div>
        )   
    }
});

var EntitiesDataValueIterator = React.createClass({
    render: function() {
        var eachValue = this.props.eachValue;
        return (
            <span>{eachValue}<br/></span>
        )
    }
});
module.exports = Entities;
