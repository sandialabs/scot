import React from 'react';
import PropTypes from 'prop-types';
import { withStyles } from '@material-ui/core/styles';
import DialogTitle from '@material-ui/core/DialogTitle';
import Dialog from '@material-ui/core/Dialog';
import Checkbox from '@material-ui/core/Checkbox';
import TextField from '@material-ui/core/TextField'
import DialogContentText from '@material-ui/core/DialogContentText';
import DialogContent from '@material-ui/core/DialogContent';
import { Person, Group } from '@material-ui/icons'
import Button from '@material-ui/core/Button';


const styles = theme => ({
  textField: {
    marginLeft: '-8px',
    marginRight: theme.spacing.unit,
  },
});

class UserGroupDialog extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      ischecked: false,
      username: "",
      fullname: "",
      password: "",
      groupname: "",
      groupdescription: "",
    }
  }

  handleChange = name => event => {
    this.setState({
      [name]: event.target.value,
    });
  };

  handleClose = () => {
    this.props.onClose(this.props.selectedValue);
  };

  handleListItemClick = value => {
    this.props.onClose(value);
  };

  render() {
    const { classes, onClose, selectedValue, type, ...other } = this.props;

    return (
      <div>
        <Dialog onClose={this.handleClose} aria-labelledby="simple-dialog-title" {...other}>
          <DialogTitle id="simple-dialog-title">Add a {this.props.type} <Person /></DialogTitle>
          {this.props.type === 'user' ?
            <DialogContent>
              <DialogContentText id="alert-dialog-description">
                To create a user account, please enter a username,
                fullname, choose to activate the account or not, and provide a
                password.
              <div>
                  <TextField
                    id="outlined-name"
                    label="Group Name"
                    value={this.state.username}
                    onChange={this.handleChange('groupname')}
                    margin="normal"
                    variant="outlined"
                    helperText="Enter name of group"
                    fullWidth
                    style={{ marginTop: 8, marginBottom: 8 }}
                  /><br />
                  <TextField
                    id="outlined-description"
                    label="Description"
                    value={this.state.groupdescription}
                    onChange={this.handleChange('groupdescription')}
                    margin="normal"
                    variant="outlined"
                    helperText="Provide a description for the group"
                    fullWidth
                    style={{ marginTop: 8, marginBottom: 8 }}
                  /><br />
                  <br />
                  <Button variant="contained" color="secondary" className={classes.button}>
                    Submit
                </Button>
                </div>
              </DialogContentText>
            </DialogContent>
            :
            <DialogContent>
              <DialogContentText id="alert-dialog-description">
                To create a new group, please enter a group name and description.
              <div>
                  <TextField
                    id="outlined-name"
                    label="Username"
                    value={this.state.name}
                    onChange={this.handleChange('username')}
                    margin="normal"
                    variant="outlined"
                    helperText="Enter a valid username"
                    fullWidth
                    style={{ marginTop: 8, marginBottom: 8 }}
                  /><br />
                  <TextField
                    id="outlined-name"
                    label="Full Name"
                    value={this.state.fullname}
                    onChange={this.handleChange('fullname')}
                    margin="normal"
                    variant="outlined"
                    helperText="Provide your full name"
                    fullWidth
                    style={{ marginTop: 8, marginBottom: 8 }}
                  /><br />
                  Activate? <Checkbox
                    checked={this.state.ischecked}
                    onChange={this.handleChange('ischecked')}
                    value="ischecked"
                    color="primary"
                    label="Activate?"
                  /> <br />
                  <TextField
                    id="outlined-password-input"
                    label="Password"
                    type="password"
                    autoComplete="current-password"
                    margin="normal"
                    variant="outlined"
                    helperText="Enter a valid password"
                    fullWidth
                    style={{ marginTop: 8, marginBottom: 8 }}
                  /><br />
                  <br />
                  <Button variant="contained" color="secondary" className={classes.button}>
                    Submit
                </Button>
                </div>
              </DialogContentText>
            </DialogContent>}
        </Dialog>
      </div>
    );
  }
}

UserGroupDialog.propTypes = {
  classes: PropTypes.object.isRequired,
  onClose: PropTypes.func,
  selectedValue: PropTypes.string,
};

export default withStyles(styles)(UserGroupDialog);