import React from 'react';
import { withStyles } from '@material-ui/core/styles';
import Checkbox from '@material-ui/core/Checkbox';
import TextField from '@material-ui/core/TextField'
import { Person, Group } from '@material-ui/icons'
import Button from '@material-ui/core/Button';
import Card from '@material-ui/core/Card';
import CardActions from '@material-ui/core/CardActions';
import CardContent from '@material-ui/core/CardContent';
import axios from 'axios'
import Typography from '@material-ui/core/Typography';
import { withSnackbar } from 'notistack';
import { WithContext as ReactTags } from 'react-tag-input';
import FormControlLabel from '@material-ui/core/FormControlLabel';
import Switch from '@material-ui/core/Switch';


const styles = theme => ({
  textField: {
    marginLeft: '-8px',
    marginRight: theme.spacing.unit,
  },
  root: {
    width: '100%',
    maxWidth: 360,
    backgroundColor: theme.palette.background.paper,
  },
  textInput: {
    backgroundColor: 'white',
    color: 'black'
  }
});

const initstate = {
  // ischecked: false,
  username: "",
  fullname: "",
  password: "",
  description: "",
  name: "",
  id: null,
  suggestions: [],
  groups: [],
  active: 0,
}


class UserGroupFormComponent extends React.Component {

  constructor(props) {
    super(props);
    this.state = initstate;
  }


  componentDidMount() {
    this.formatGroups();
    if (this.props.editObject) {
      if (this.props.type === 'user') {
        this.setState(
          {
            username: this.props.editObject.username,
            fullname: this.props.editObject.fullname,
            password: this.props.editObject.password,
            id: this.props.editObject.id,
            active: this.props.editObject.active,
            groups: this.props.editObject.groups
          }
        )
      }
      else if (this.props.type === 'group') {
        this.setState(
          {
            name: this.props.editObject.name,
            description: this.props.editObject.description,
            id: this.props.editObject.id,
          }
        )
      }
    }
  }

  formatGroups = () => {
    if (this.props.groups.length > 0) {
      let allgroups = [];
      this.props.groups.forEach(function (element) {
        let group = {};
        group['id'] = element.name
        group['text'] = element.name;
        allgroups.push(group)
      });
      this.setState({ suggestions: allgroups })
    }
  }


  resetState = () => {
    this.setState(initstate)
  }

  checkBlankInputs = (type) => {
    let bool = false;
    if (type === 'user') {
      if (this.state.username !== '' && this.state.fullname !== '' && this.state.password !== '') {
        bool = true;
      }
    } else {
      if (this.state.name !== '' && this.state.description !== '') {
        bool = true
      }
    }
    return bool
  }

  buildDataObj = (type) => {
    let obj = {}
    if (type === 'user') {
      obj['username'] = this.state.username;
      obj['fullname'] = this.state.fullname;
      obj['password'] = this.state.password;
      obj['groups'] = this.state.groups
      obj['active'] = this.state.active ? 1 : 0
    } else if (type === 'group') {
      obj['name'] = this.state.name;

      obj['description'] = this.state.description
    }
    return obj
  }

  handleGroups = (groups) => {
    const { enqueueSnackbar, type } = this.props;
    if (groups.length > 0) {
      let newgroups = [];
      groups.forEach(function (element) {
        newgroups.push(element.id)
      })
      this.setState({ groups: newgroups });
    } else {
      enqueueSnackbar(`Error handling groups  ${type}`, { variant: 'error' });
    }
  }


  handlePUT = () => {
    const { enqueueSnackbar, type } = this.props;
    let obj = this.buildDataObj(type);
    if (this.checkBlankInputs(type)) {
      axios.put(`/scot/api/v2/${type}/${this.state.id}`, obj)
        .then(function (response) {
          enqueueSnackbar(`Successfully updated ${type}.`, { variant: 'success' })
          this.resetState();
          this.props.fetchData(type)
          this.props.handleClose();
        }.bind(this))
        .catch(function (error) {
          // handle error
          enqueueSnackbar(`Failed updating ${type}`, { variant: 'error' });
        });
    }
  }

  handlePOST = () => {
    const { enqueueSnackbar, type } = this.props;
    let obj = this.buildDataObj(type);
    if (this.checkBlankInputs(type)) {
      axios.post(`/scot/api/v2/${type}/`, obj)
        .then(function (response) {
          console.log(response);
          enqueueSnackbar(`Successfully added ${type}.`, { variant: 'success' })
          this.resetState();
          this.props.fetchData(type)
          this.props.handleClose();
        }.bind(this))
        .catch(function (error) {
          // handle error
          enqueueSnackbar(`Failed creating ${type}`, { variant: 'error' });
          console.log(error);
        });
    }
  }

  handleChange = (event, value) => {
    if (event.nativeEvent.type === 'input') {
      let newval = event.target.value;
      this.setState({ [event.target.id]: newval })
    } else if (event.nativeEvent.type === 'click') {
      if (event.target.type === 'checkbox') {
        this.setState({ [event.target.value]: value })
      }
    } else {
      this.setState({ [event.target.name]: value.props.value })
    }
  };


  render() {
    const { classes, onClose, selectedValue, type, ...other } = this.props;

    return (
      <div>
        <Card className={classes.card}>
          <CardContent>
            {this.props.editObject ?
              <Typography variant="h5" component="h2">Edit {this.props.type} <b>{this.props.editObject.username} </b></Typography> :
              <Typography variant="h5" component="h2">Create {this.props.type} </Typography>
            }
            {this.props.type === 'group' ?
              <div>
                <TextField
                  id="name"
                  label="Group Name"
                  value={this.state.name}
                  onChange={this.handleChange}
                  variant="outlined"
                  helperText="Enter name of group"
                  fullWidth
                  InputLabelProps={{
                    shrink: true,
                  }}
                  style={{ marginTop: 8, marginBottom: 8 }}
                />
                <br />
                <TextField
                  id="description"
                  label="Description"
                  value={this.state.description}
                  onChange={this.handleChange}
                  variant="outlined"
                  helperText="Enter description for group"
                  InputLabelProps={{
                    shrink: true,
                  }}

                  fullWidth
                  style={{ marginTop: 8, marginBottom: 8 }}
                />
              </div>
              :
              <div>
                <TextField
                  id="username"
                  label="Username"
                  value={this.state.username}
                  onChange={this.handleChange}
                  variant="outlined"
                  helperText="Enter a valid username"
                  fullWidth
                  InputLabelProps={{
                    shrink: true,
                  }}
                  style={{ marginTop: 8, marginBottom: 8 }}
                /><br />
                <TextField
                  id="fullname"
                  label="Full Name"
                  value={this.state.fullname}
                  onChange={this.handleChange}
                  variant="outlined"
                  helperText="Provide your full name"
                  fullWidth
                  InputLabelProps={{
                    shrink: true,
                  }}
                  style={{ marginTop: 8, marginBottom: 8 }}
                /><br />
                <TextField
                  id="password"
                  label="Password"
                  type="password"
                  autoComplete="current-password"
                  margin="normal"
                  variant="outlined"
                  helperText="Enter a valid password"
                  value={this.state.password}
                  onChange={this.handleChange}
                  fullWidth
                  InputLabelProps={{
                    shrink: true,
                  }}
                  style={{ marginTop: 8, marginBottom: 8 }}
                />
                <br />
                <FormControlLabel
                  control={
                    <Switch
                      checked={this.state.active}
                      onChange={this.handleChange}
                      value="active"
                    />
                  }
                  label="Active?"
                />
                <br />
                <b>Groups</b>
                <GroupSelection editObject={this.props.editObject} handleGroups={this.handleGroups} id={this.state.id} suggestions={this.state.suggestions} />
                <br />
              </div>
            }
            <br />
          </CardContent>
          <CardActions>
            {this.props.editObject ?
              <div style={{ marginLeft: 350, marginBottom: 5 }}>
                <Button style={{ marginRight: 5 }} variant="contained" onClick={this.props.handleClose} className={classes.button}>
                  Cancel
              </Button>
                <Button variant="contained" color="secondary" onClick={this.handlePUT} className={classes.button}>
                  Submit
              </Button>
              </div> :
              <div style={{ marginLeft: 350, marginBottom: 5 }}>
                <Button style={{ marginRight: 5 }} variant="contained" onClick={this.props.handleClose} className={classes.button}>
                  Cancel
              </Button>
                <Button variant="contained" color="secondary" onClick={this.handlePOST} className={classes.button}>
                  Submit
                </Button>
              </div>
            }
          </CardActions>
        </Card>
      </div>
    );
  }
}


class GroupSelectionComponent extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      groups: [],
    };

  }

  componentDidMount() {
    if (this.props.editObject) {
      let usersgroups = [];
      this.props.editObject.groups.forEach(function (element) {
        let group = {};
        group['id'] = element
        group['text'] = element;
        usersgroups.push(group)
      })
      this.setState({ groups: usersgroups });
    }

  }

  shouldComponentUpdate(nextProps, nextState) {
    if (this.state !== nextState) {
      this.props.handleGroups(nextState.groups)
      return true
    } else {
      return false
    }
  }

  mapUsersGroupsToTags = () => {
    axios.get(`/scot/api/v2/user?id=${this.props.id}`)
      .then(response => {
        const usersgroups = [];
        if (response.data.totalRecordCount > 0) {
          response.data.records.forEach(function (element) {
            let group = {};
            group['id'] = element.name
            group['text'] = element.name;
            usersgroups.push(group)
          })
          this.setState({ groups: usersgroups });
        } else {
        }
      })
  }

  handleDelete = (i) => {
    const { groups } = this.state;
    this.setState({
      groups: groups.filter((tag, index) => index !== i),
    });
  }

  handleAddition = (tag) => {
    const { enqueueSnackbar } = this.props;
    if (this.checkValidGroup(tag['id'])) {
      let newgroups = this.state.groups;
      newgroups.push(tag);
      this.setState({ groups: newgroups });
      this.props.handleGroups(this.state.groups)
    }
    else {
      enqueueSnackbar(`Invalid group. Please add an existing group`);
    }
  }

  checkValidGroup(group) {
    const { suggestions } = this.props;
    var found = suggestions.some(function (el) {
      return el.id === group;
    });
    if (found) {
      return true
    } else {
      return false;
    }
  }


  render() {
    const { groups } = this.state;
    const { suggestions } = this.props;
    const { classes } = this.props;
    return (
      <div>
        <ReactTags
          classNames={{
            tagInput: 'tagInputClass',
            tagInputField: 'tagInputFieldClass',
          }}
          placeholder={"Add a new group"}
          inline={false}
          tags={groups}
          suggestions={suggestions}
          handleDelete={this.handleDelete}
          handleAddition={this.handleAddition}
        />
      </div>
    );
  }
}

const GroupSelection = withStyles(styles)(GroupSelectionComponent)
const UserGroupForm = withSnackbar(withStyles(styles)(UserGroupFormComponent));
export { GroupSelection, UserGroupForm }
