import React        from 'react';
import ReactDOM     from 'react-dom';
import Panel        from 'react-bootstrap/lib/Panel.js';
import Badge        from 'react-bootstrap/lib/Badge.js';
import Button       from 'react-bootstrap/lib/Button.js';
import Modal        from 'react-bootstrap/lib/Modal.js';

class Api extends React.Component {
    constructor( props ) {
        super ( props );
        this.state = {
            Api: null,
            keys: null,
            availableGroups: null,
        }
    }

    GetKeys() {
        $.ajax({
            type: 'get',
            url: '/scot/api/v2/apikey',
            success: function(data) {
                this.setState({keys: data.records});
            }.bind(this),
            error: function() {
                this.setState({keys: 'failed to get keys'});
            }.bind(this)
        });
    }

    GetAvailableGroups() {
        $.ajax({
            type: 'get',
            url: '/scot/api/v2/group?limit=0',
            success: function(data) {
                this.setState({availableGroups: data.records});
            }.bind(this)
        })
    }
    
    CreateKey() {
        $.ajax({
            type: 'post',
            url: '/scot/api/v2/apikey',
            success: function(data) {
                this.GetKeys();
            }.bind(this),
        });
    }
    
    DeleteKey(e) {
        $.ajax({
            type: 'delete',
            url: '/scot/api/v2/apikey/' + e.target.id,
            success: function(data) {
                this.GetKeys();
            }.bind(this)
        });
    }

    AddGroup(e, currentgroup) {
        //add group here
        
        console.log(e);
        console.log(currentgroup);
    }

    DeleteGroup(e, currentgroup) {
        $.ajax({
            type: 'put',
            url: '/scot/api/v2/apikey/' + e.target.id,
            success: function(data) {
                this.GetKeys();
            }.bind(this)
        });
    }

    componentDidMount() {
        this.GetKeys();
        this.GetAvailableGroups();
    }

    render() {
        var keysArr = [];
        if (this.state.keys != undefined) {
            for (var i=0; i < this.state.keys.length; i++) {
                var keyActiveStatus;
                var keyActiveStatusCss; 
                var keyGroups;
                if (this.state.keys[i].active == 1) {keyActiveStatus = 'true'; keyActiveStatusCss = 'keyActive' } else { keyActiveStatus = 'false'; keyActiveStatusCss = 'keyNotActive' }
                if (this.state.keys[i].groups != undefined) {
                    for (var j=0; j < this.state.keys[i].groups.length; j++) {
                        keyGroups.push(<div>this.state.keys[i].groups[j]</div>);
                    }
                }
                keysArr.push(
                    <div>
                        <div>
                            <div>
                                <span>{this.state.keys[i].apikey}</span>
                                <span>{this.state.keys[i].username}</span>
                            </div>
                                <span>Key is <span className={keyActiveStatusCss}>{this.state.keys[i].active}</span></span>
                                <span className='pull-right pointer'><i id={this.state.keys[i].id} className="fa fa-trash" aria-hidden="true" onClick={this.DeleteKey}></i></span>
                            <div>
                                <GroupModal currentGroups={this.state.keys[i].groups} allGroups={this.state.availableGroups} DeleteGroup={this.DeleteGroup} AddGroup={this.AddGroup} />
                            </div>
                        </div>
                        <hr />
                    </div>
                )
            }
        }
        return (
            <div id='api' className='administration_api'>
                <h1>API</h1> 
                <Panel bsStyle='info' header='Your api keys'>
                    {keysArr}
                </Panel>
                
                <Button bsStyle='success' onClick={this.CreateKey}>Create API Key</Button>
                <p>Add group add/remove options</p>
            </div>
        );
    }
};

class GroupModal extends React.Component {
    constructor ( props ) {
        super ( props );
        this.Open = this.Open.bind(this);
        this.Close = this.Close.bind(this);
        this.AddGroup = this.AddGroup.bind(this);
        this.DeleteGroup = this.DeleteGroup.bind(this);
        this.state = {
            showModal: false
        }
    }

    Open() {
        this.setState({showModal: true});
    }

    Close() {
        this.setState({showModal: false});        
    }
    
    DeleteGroup (e) {
        this.props.DeleteGroup(e,'test');
    }

    AddGroup (e) {
        this.props.AddGroup(e, 'test');
    }

    render() {
        var allGroupArray = [];
        var currentGroupArray = [];
        for ( const i of this.props.allGroups ) {
            allGroupArray.push( <Button onClick={this.AddGroup}>{i.name}</Button> );
        }
        for ( const j of this.props.currentGroups ) {
            currentGroupArray.push( <span onClick={this.DeleteGroup}>{j}<i className='fa ta-times tagButtonClose'></i></span> );
        }
        return (
            <div>
                Current Groups: {currentGroupArray}
                <Button onClick={this.Open}>Add/RemoveGroups</Button>
                <Modal show={this.state.showModal} onHide={this.Close}>
                    <Modal.Header closeButton>
                        <Modal.Title>Add/Remove Groups to API key</Modal.Title>
                    </Modal.Header>
                    <Modal.Body>
                        <div>
                            Current Groups:
                            {currentGroupArray}
                        </div>  
                        <div>
                            Click to add group:
                            {allGroupArray}
                        </div>
                    </Modal.Body>
                </Modal>
            </div>
        )
    }
}

ReactDOM.render(<Api />,document.getElementById('api'));
