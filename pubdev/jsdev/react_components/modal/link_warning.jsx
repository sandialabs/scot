let React = require('react');
let Modal = require('react-modal');
let Button = require('react-bootstrap/lib/Button');

const customStyles = {
    content: {
        top: '50%',
        left: '50%',
        right: 'auto',
        bottom: 'auto',
        marginRight: '-50%',
        transform: 'translate(-50%, -50%)'
    }
};

let LinkWarning = React.createClass({
    proceed: function () {
        window.open(this.props.link);
        this.props.linkWarningToggle();
    },
    componentWillMount: function () {
        let myDomain = window.location.href;
        let reg = new RegExp(/((https?|ftp):\/\/[a-zA-Z0-9\-_\.]+\.)?([a-zA-Z0-9\-_\.]+\.([a-zA-Z]{1,63}))/, 'i');
        let linkRegResult = this.props.link.match(reg);
        let myDomainRegResult = myDomain.match(reg);
        if (linkRegResult != undefined && myDomainRegResult != undefined) {
            let linkDomain = linkRegResult[3];
            let myDomain = myDomainRegResult[3];
            if (linkDomain == myDomain) {
                this.proceed();
            }
        } else if (linkRegResult == undefined) {
            this.proceed();
        }
        /*
        if ($.isUrlInternal(this.props.link)) {
            this.proceed();
        }*/
    },
    render: function () {
        return (
            <div>
                <Modal
                    isOpen={true}
                    onRequestClose={this.props.linkWarningToggle}
                    style={customStyles}>
                    <div className="modal-header">
                        <img src="/images/close_toolbar.png" className="close_toolbar" onClick={this.props.linkWarningToggle} />
                        <h3 id="myModalLabel">Browse to site?</h3>
                    </div>
                    <div className="modal-body" style={{ overflowX: "auto" }}>
                        The link you clicked may take you to a site outside SCOT. If this is a link an attacker controls you may be tipping your hand.
                        <br />
                        <b>{this.props.link}</b>
                    </div>
                    <div className="modal-footer">
                        <Button id='cancel-delete' onClick={this.props.linkWarningToggle}>Cancel</Button>
                        <Button bsStyle='info' id='proceed' onClick={this.proceed}>Proceed</Button>
                    </div>
                </Modal>
            </div>
        );
    }
});
module.exports = LinkWarning;
