import React from 'react'
import ReactTable from 'react-table'
import Button from '@material-ui/core/Button';
import axios from 'axios'
import AddIcon from '@material-ui/icons/Add';
import { withStyles } from '@material-ui/core/styles';
import Typography from '@material-ui/core/Typography';
import Grid from '@material-ui/core/Grid';
import UserGroupDialog from './addusergroupdialog'
import { Person, Group } from '@material-ui/icons'

const usercolumns = [
  {
    Header: 'ID',
    accessor: 'id',
    width: 50
  },
  {
    Header: 'Full Name',
    accessor: 'fullname',
    width: 70
  },
  {
    Header: 'Username',
    accessor: 'username',
    width: 70
  },
]

const groupcolumns = [
  {
    Header: 'ID',
    accessor: 'id',
    width: 50
  },
  {
    Header: 'Group Name',
    accessor: 'name',
    width: 70
  },
  {
    Header: 'Group Description',
    accessor: 'description',
    width: 70
  },

]

const styles = theme => ({
  button: {
    margin: theme.spacing.unit,
  },
  extendedIcon: {
    marginRight: theme.spacing.unit,
  },
  paper: {
    position: 'absolute',
    width: theme.spacing.unit * 50,
    backgroundColor: theme.palette.background.paper,
    boxShadow: theme.shadows[5],
    padding: theme.spacing.unit * 4,
  },
});

class UserGroupContainer extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      userdata: [],
      groupdata: [],
      useraddopen: false,
      groupaddopen: false,
    }
  }

  handleUserAdd = () => {
    this.setState({
      useraddopen: true,
    });
  };

  handleGroupAdd = () => {
    this.setState({
      groupaddopen: true,
    });
  };

  handleUserClose = () => {
    this.setState({ useraddopen: false });
  };

  handleGroupClose = () => {
    this.setState({ groupaddopen: false });
  };

  componentDidMount() {
    this.fetchUsers()
    this.fetchGroup();
  }

  fetchUsers = () => {
    axios.get(`/scot/api/v2/user?limit=0`)
      .then(({ data }) => (
        this.setState({ userdata: data.records })
      ));
  }

  fetchGroup = () => {
    axios.get(`/scot/api/v2/group?limit=0`)
      .then(({ data }) => (
        this.setState({ groupdata: data.records })
      ));
  }

  render() {
    const { classes } = this.props;
    return (
      <div>
        <Grid container className={classes.root} spacing={24}>
          <Grid item xs={12} sm={6}>
            <Typography variant="h4" gutterBottom>
              Users <Person />
            </Typography>
            <Typography variant="h5" gutterBottom>
              Add User
            </Typography><Button onClick={this.handleClickOpen} variant="fab" color="secondary" aria-label="Add" className={classes.button}><AddIcon /></Button>
            <ReactTable
              data={this.state.userdata}
              columns={usercolumns}
            />
          </Grid>
          <Grid item xs={12} sm={6}>
            <Typography variant="h4" gutterBottom>
              Groups  <Group />
            </Typography>
            <Typography variant="h5" gutterBottom>
              Add Group
            </Typography><Button variant="fab" color="secondary" aria-label="Add" className={classes.button}><AddIcon /></Button>
            <ReactTable
              data={this.state.groupdata}
              columns={groupcolumns}
            />
          </Grid>
        </Grid>
        <UserGroupDialog key='1' type='user' open={this.state.useraddopen} onClose={this.handleUserClose} ></UserGroupDialog>
        <UserGroupDialog key='2' type='group' open={this.state.groupaddopen} onClose={this.handleGroupClose} ></UserGroupDialog>
      </div>
    )
  }
}

export default withStyles(styles)(UserGroupContainer);