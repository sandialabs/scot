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


const styles = theme => ({
  textField: {
    marginLeft: '-8px',
    marginRight: theme.spacing.unit,
  },
});

const initstate = {
  // ischecked: false,
  username: "",
  fullname: "",
  password: "",
  description: "",
  name: "",
  id: null,
}


class UserGroupForm extends React.Component {

  constructor(props) {
    super(props);
    this.state = initstate;
  }

  componentDidMount() {
    if (this.props.editObject) {
      if (this.props.type === 'user') {
        this.setState(
          {
            username: this.props.editObject.username,
            fullname: this.props.editObject.fullname,
            password: this.props.editObject.password,
            id: this.props.editObject.id,
            ischecked: this.props.editObject.isChecked,
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
    } else if (type === 'group') {
      obj['name'] = this.state.name;
      obj['description'] = this.state.description
    }
    return obj
  }


  handlePUT = () => {
    const { enqueueSnackbar, type } = this.props;
    let obj = this.buildDataObj(type);
    if (this.checkBlankInputs(type)) {
      axios.put(`/scot/api/v2/${type}/${this.state.id}`, obj)
        .then(function (response) {
          console.log(response);
          enqueueSnackbar(`Successfully updated ${type}.`, { variant: 'success' })
          this.resetState();
          this.props.fetchData(type)
          this.props.handleClose();
        }.bind(this))
        .catch(function (error) {
          // handle error
          enqueueSnackbar(`Failed updating ${type}`, { variant: 'error' });
          console.log(error);
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
                {/* Activate? <Checkbox
                  checked={this.state.ischecked}
                  onChange={this.handleChange}
                  value="ischecked"
                  color="primary"
                  label="Activate?"
                /> <br /> */}
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
                /><br />
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
export default withSnackbar(withStyles(styles)(UserGroupForm));
