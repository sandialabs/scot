import React from "react";
import $ from "jquery";
let Button = require("react-bootstrap/lib/Button.js");

export default class Promote extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            newURL: null,
            newType: null
        };
    }

    componentDidMount = () => {
        if (this.props.type === "alert") {
            this.setState({ newType: "Event" });
            this.setState({ newURL: "event" });
        } else if (this.props.type === "event") {
            this.setState({ newType: "Incident" });
            this.setState({ newURL: "incident" });
        }
    };

    promote = () => {
        let data = JSON.stringify({ promote: "new" });
        $.ajax({
            type: "put",
            url: "scot/api/v2/" + this.props.type + "/" + this.props.id,
            data: data,
            contentType: "application/json; charset=UTF-8",
            success: function (data) {
                console.log("successfully promoted");
                window.location.assign("#/" + this.state.newURL + "/" + data.pid);
            }.bind(this),
            error: function (data) {
                this.props.errorToggle("error", "Failed to promote", data);
            }.bind(this)
        });
    };

    render = () => {
        return (
            <Button
                bsStyle="warning"
                eventkey="1"
                bsSize="xsmall"
                onClick={this.promote}
            >
                <img src="/images/megaphone.png" alt="" />
                <span>Promote to {this.state.newType}</span>
            </Button>
        );
    };
}
