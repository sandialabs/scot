import React from 'react'
import Button from 'react-bootstrap/lib/Button';
import $ from 'jquery'
import { WithContext as ReactTags } from 'react-tag-input';


export default class Badge extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      source: false,
      tag: false,
    }
  }

  toggleBadgeEntry = (badgetype) => {
    if (this.state[badgetype] == false) {
      this.setState({ [badgetype]: true });
    } else if (this.state[badgetype] == true) {
      this.setState({ [badgetype]: false });
    }
  }

  render() {
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
          {this.state.source ? <NewBadge data={data} type={type} id={id} badgeType={this.props.badgeType} toggleBadgeEntry={this.toggleBadgeEntry} updated={this.props.updated} errorToggle={this.props.errorToggle} /> : null}
          {this.state.tag ? <NewBadge data={data} type={type} id={id} badgeType={this.props.badgeType} toggleBadgeEntry={this.toggleBadgeEntry} updated={this.props.updated} errorToggle={this.props.errorToggle} /> : null}
          {this.props.badgeType === 'tag' ?
            this.state.tag ? <span className='add-tag-button'><Button bsSize={'xsmall'} bsStyle={'danger'} onClick={() => { this.toggleBadgeEntry(this.props.badgeType) }}><span className='glyphicon glyphicon-minus' aria-hidden='true'></span></Button></span> : <span className='remove-tag-button'><Button bsSize={'xsmall'} bsStyle={'success'} onClick={() => { this.toggleBadgeEntry(this.props.badgeType) }}><span className='glyphicon glyphicon-plus' aria-hidden='true'></span></Button></span> :
            this.props.badgeType === 'source' ?
              this.state.source ? <span className='add-source-button'><Button bsSize={'xsmall'} bsStyle={'danger'} onClick={() => { this.toggleBadgeEntry(this.props.badgeType) }}><span className='glyphicon glyphicon-minus' aria-hidden='true'></span></Button></span> : <span className='remove-source-button'><Button bsSize={'xsmall'} bsStyle={'success'} onClick={() => { this.toggleBadgeEntry(this.props.badgeType) }}><span className='glyphicon glyphicon-plus' aria-hidden='true'></span></Button></span> : null}
        </td>
      </th>
    );
  }
};

class BadgeDataIterator extends React.Component {

  badgeDelete = () => {
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
  }

  render() {
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
};

class NewBadge extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      suggestions: []
    };
  }

  handleAddition = tag => {
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
    if (!newBadgeArr.includes(tag['text'])) {
      newBadgeArr.push(tag['text']);
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
  }

  handleSuggestionOrTagConversion = (oldarray) => {
    let formattedSuggArray = oldarray.map(function (item) {
      let newobj = {}
      newobj['id'] = item
      newobj['text'] = item
      return newobj
    });
    return formattedSuggArray;
  }

  handleInputChange = input => {
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
  }

  handleDelete = () => {
    //blank since buttons are handled outside of this
  }

  handleDrag = () => {
    //blank since buttons are handled outside of this
  }

  render() {
    let suggestions = this.state.suggestions;
    suggestions = this.handleSuggestionOrTagConversion(suggestions);

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
};
