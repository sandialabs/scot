let React = require('react');
let Button = require('react-bootstrap/lib/Button');
let ReactTags = require('react-tag-input').WithContext;

let Badge = React.createClass({
    getInitialState: function () {
        return { badgeEntry: false };
    },


    toggleBadgeEntry: function () {
        this.setState({ badgeEntry: !this.state.badgeEntry })
    },
    render: function () {
        let rows = [];
        let id = this.props.id;
        let type = this.props.type;
        let data = this.props.data;
        let badgevar = "";

        if (this.props.badgeType === 'tag') {
            badgevar = "Tags"
        } else if (this.props.badgeType === 'source') {
            badgevar = "Sources"
        }


        //Don't show if guide
        if (this.props.type == 'guide') {
            return (<th />);
        }

        if (data != undefined) {
            for (let i = 0; i < data.length; i++) {
                rows.push(<BadgeDataIterator data={data} badgeType={this.props.badgeType} dataOne={data[i]} id={id} type={type} updated={this.props.updated} key={i} errorToggle={this.props.errorToggle} />);
            }
        }
        return (
            <th>
                <th>
                    {badgevar}:
                </th>
                <td>
                    {rows}
                    {this.state.badgeEntry ?
                        <NewBadge data={data} type={type} id={id} badgeType={this.props.badgeType} toggleBadgeEntry={this.toggleBadgeEntry} updated={this.props.updated} errorToggle={this.props.errorToggle} /> : null}
                    {this.props.badgeType === 'tag' ?
                        this.state.badgeEntry ? <span className='add-tag-button'><Button bsSize={'xsmall'} bsStyle={'danger'} onClick={this.toggleBadgeEntry}><span className='glyphicon glyphicon-minus' aria-hidden='true'></span></Button></span> : <span className='remove-tag-button'><Button bsSize={'xsmall'} bsStyle={'success'} onClick={this.toggleBadgeEntry}><span className='glyphicon glyphicon-plus' aria-hidden='true'></span></Button></span> :
                        this.props.badgeType === 'source' ?
                            this.state.badgeEntry ? <span className='add-source-button'><Button bsSize={'xsmall'} bsStyle={'danger'} onClick={this.toggleBadgeEntry}><span className='glyphicon glyphicon-minus' aria-hidden='true'></span></Button></span> : <span className='remove-source-button'><Button bsSize={'xsmall'} bsStyle={'success'} onClick={this.toggleBadgeEntry}><span className='glyphicon glyphicon-plus' aria-hidden='true'></span></Button></span> : null}
                </td>
            </th>
        );
    }
});

let BadgeDataIterator = React.createClass({

    badgeDelete: function () {
        let badgeType = this.props.badgeType;
        let data = this.props.data;
        let newBadgeArr = [];
        for (let i = 0; i < data.length; i++) {
            if (data[i] != undefined) {
                if (typeof (data[i]) == 'string') {
                    if (data[i] != this.props.dataOne) {
                        newBadgeArr.push(data[i]);
                    }
                } else {
                    if (data[i].value != this.props.dataOne.value) {
                        newBadgeArr.push(data[i].value);
                    }
                }
            }
        }

        let newobject = {};
        newobject[badgeType] = newBadgeArr;

        $.ajax({
            type: 'put',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.id,
            data: JSON.stringify(newobject),
            contentType: 'application/json; charset=UTF-8',
            success: function (data) {
                console.log('deleted' + this.props.badgeType + ' data');
            }.bind(this),
            error: function (data) {
                this.props.errorToggle('Failed to delete' + badgeType + ', data ');
            }.bind(this)
        });
    },
    render: function () {
        let dataOne = this.props.dataOne;
        let value;
        if (typeof (dataOne) == 'string') {
            value = dataOne;
        } else if (typeof (dataOne) == 'object') {
            if (dataOne != undefined) {
                value = dataOne.value;
            }
        }


        return (
            (this.props.badgeType === 'tag') ? <span id="event_tag" className='tagButton'>{value} <span className='tagButtonClose'><i onClick={this.badgeDelete} className="fa fa-times" /></span></span> :
                (this.props.badgeType === 'source') ? <span id="event_source" className='sourceButton'>{value} <span className='sourceButtonClose'><i onClick={this.badgeDelete} className="fa fa-times" /></span></span> : null
        );
    }
});

let NewBadge = React.createClass({
    getInitialState: function () {
        return {
            suggestions: this.props.options
        };
    },


    handleAddition: function (tag) {
        let newBadgeArr = [];
        let badgeType = this.props.badgeType;
        let data = this.props.data;
        for (let i = 0; i < data.length; i++) {
            if (data[i] != undefined) {
                if (typeof (data[i]) == 'string') {
                    newBadgeArr.push(data[i]);
                } else {
                    newBadgeArr.push(data[i].value);
                }
            }
        }
        if (!newBadgeArr.includes(tag)) {
            newBadgeArr.push(tag);
            let newobject = {};
            newobject[badgeType] = newBadgeArr;
            $.ajax({
                type: 'put',
                url: 'scot/api/v2/' + this.props.type + '/' + this.props.id,
                data: JSON.stringify(newobject),
                contentType: 'application/json; charset=UTF-8',
                success: function () {
                    console.log('success: ' + this.props.badgeType + ' added');
                    this.props.toggleBadgeEntry();
                }.bind(this),
                error: function (data) {
                    this.props.errorToggle('Failed to add ' + this.props.badgeType + ' data ');
                    this.props.toggleBadgeEntry();
                }.bind(this)
            });
        } else {
            this.props.errorToggle(this.props.badgeType + ' already exists');
        }


    },
    handleInputChange: function (input) {
        let arr = [];
        let endpoint = this.props.badgeType;
        $.ajax({
            type: 'get',
            url: '/scot/api/v2/ac/' + endpoint + '/' + input,
            success: function (result) {
                for (let i = 0; i < result.records.length; i++) {
                    arr.push(result.records[i]);
                }
                this.setState({ suggestions: arr });
            }.bind(this),
            error: function (data) {
                this.props.errorToggle('Failed to get autocomplete data for tag', data);
            }.bind(this)
        });
    },
    handleDelete: function () {
        //blank since buttons are handled outside of this
    },
    handleDrag: function () {
        //blank since buttons are handled outside of this
    },
    render: function () {
        let suggestions = this.state.suggestions;
        return (
            <span className='tag-new'>
                <ReactTags
                    suggestions={suggestions}
                    handleAddition={this.handleAddition}
                    handleDelete={this.handleDelete}
                    handleDrag={this.handleDrag}
                    handleInputChange={this.handleInputChange}
                    minQueryLength={1}
                    customCSS={1} />
            </span>
        );
    }
});

module.exports = Badge;
