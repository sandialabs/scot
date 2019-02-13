import React from 'react'
import ReactTable from 'react-table'
import Button from '@material-ui/core/Button';
import axios from 'axios'
import AddIcon from '@material-ui/icons/Add';
import { withStyles } from '@material-ui/core/styles';
import Grid from '@material-ui/core/Grid';
import { UserGroupForm } from './usergroupform'
import { Person, Group } from '@material-ui/icons'
import DeleteRoundedIcon from '@material-ui/icons/DeleteRounded';
import Dialog from '@material-ui/core/Dialog';
import Typography from '@material-ui/core/Typography';
import Fab from '@material-ui/core/Fab';
import AreYouSure from './areyousure'


const styles = theme => ({
  root: {
    flexGrow: 1,
  },
});

class UserGroupContainer extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      userdata: [],
      groupdata: [],
      showModal: false,
      editObject: null,
      id: null,
      type: "",
      areYouSure: false,
    }
  }

  edit = (type, id) => {
    let url = `/scot/api/v2/${type}?id=${id}`;
    axios.get(url)
      .then(function (response) {
        this.setState({ editObject: response.data.records[0], type: type, showModal: true });
      }.bind(this))
      .catch(function (error) {
        console.log(error);
      });
  }

  showUserDialog = () => {
    this.setState({ showModal: true, type: 'user' })
  }

  showGroupDialog = () => {
    this.setState({ showModal: true, type: 'group' })
  }

  handleUserClose = () => {
    this.setState({ showModal: false });
  };

  componentDidMount() {
    this.fetchData('user')
    this.fetchData('group')
  }

  handleClose = (type) => {
    this.setState({ showModal: false, id: null, type: "", editObject: null });
  };

  handleListItemClick = value => {
    this.props.onClose(value);
  };

  getColumns = (type) => {
    let columns = []
    if (type === 'user') {
      columns = [
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
        {
          Header: 'Edit / Delete',
          id: 'edit',
          accessor: row => (
            <center>
              <Button size="small" style={{ marginLeft: 5 }} onClick={() => this.edit(type, row.id)} variant="contained">Edit</Button>
              <Button size="small" style={{ marginLeft: 5 }} onClick={() => this.toggleAreYouSure(row.id, type)} color="secondary" variant="contained" ><DeleteRoundedIcon /></Button>
            </center>),
          width: 200
        },

      ]
    } else if (type === 'group') {
      columns = [
        {
          Header: 'ID',
          accessor: 'id',
          width: 50
        },
        {
          Header: 'Group Name',
          accessor: 'name',
          width: 100
        },
        {
          Header: 'Group Description',
          accessor: 'description',
          width: 100
        },
        {
          Header: 'Edit / Delete',
          id: 'edit',
          accessor: row => (
            <center>
              <Button size="small" style={{ marginLeft: 5 }} onClick={() => this.edit(type, row.id)} variant="contained">Edit</Button>
              <Button size="small" style={{ marginLeft: 5 }} onClick={() => this.toggleAreYouSure(row.id, type)} color="secondary" variant="contained" ><DeleteRoundedIcon /></Button>
            </center>),
          width: 200
        },
      ]
    }
    return columns
  }

  setUserGroupResults = (type, data) => {
    if (type === 'user') {
      this.setState({ userdata: data.records })
    } else if (type === 'group') {
      this.setState({ groupdata: data.records })
    }
  }

  toggleAreYouSure = (id, type) => {
    this.setState({ areYouSure: true, id: id, type: type })
  }

  handleAreYouSureClose = () => {
    this.setState({ areYouSure: false });
  }

  fetchData = (type) => {
    axios.get(`/scot/api/v2/${type}?limit=0`)
      .then(({ data }) => (
        this.setUserGroupResults(type, data)
      ));
  }

  render() {
    const { classes, ...other } = this.props;
    return (
      <div className={classes.root}>
        <Grid container spacing={8}>
          <Grid item xs={12} sm={6}>
            <Typography variant="h4" gutterBottom>
              Users <Person />
            </Typography>
            <div style={{ display: 'flex', flexDirection: 'row' }}>
              <Typography variant="h5" gutterBottom>
                Add User
              </Typography>
              <Fab style={{ marginLeft: 5, marginBottom: 10, marginTop: -6 }} size="small" onClick={this.showUserDialog} color="secondary" aria-label="Add" >
                <AddIcon />
              </Fab>
            </div>
            <ReactTable
              data={this.state.userdata}
              columns={this.getColumns('user')}
            />
          </Grid>
          <Grid item xs={12} sm={6}>
            <Typography variant="h4" gutterBottom>
              Groups <Group />
            </Typography>
            <div style={{ display: 'flex', flexDirection: 'row' }}>
              <Typography variant="h5" gutterBottom>
                Add Group
            </Typography>
              <Fab style={{ marginLeft: 5, marginBottom: 10, marginTop: -6 }} size="small" onClick={this.showGroupDialog} color="secondary" aria-label="Add" >
                <AddIcon />
              </Fab>
            </div>
            <ReactTable
              data={this.state.groupdata}
              columns={this.getColumns('group')}
            />
          </Grid>
        </Grid>
        <Dialog open={this.state.showModal} onClose={this.handleClose} aria-labelledby="simple-dialog-title" >
          <UserGroupForm id={this.state.id} groups={this.state.groupdata} type={this.state.type} editObject={this.state.editObject} handleClose={this.handleClose} fetchData={(type) => { this.fetchData(type) }} />
        </Dialog>
        {this.state.areYouSure ?
          <Dialog open={this.state.areYouSure} onClose={this.handleAreYouSureClose} aria-labelledby="simple-dialog-title" {...other}>
            <AreYouSure type={this.state.type} fetchData={(type) => { this.fetchData(type) }} handleClose={this.handleAreYouSureClose} id={this.state.id}></AreYouSure>
          </Dialog> : null
        }
      </div>
    )
  }
}

export default withStyles(styles)(UserGroupContainer);