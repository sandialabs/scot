import React from 'react'
import Typography from '@material-ui/core/Typography';
import { withSnackbar } from 'notistack';
import { withStyles } from '@material-ui/core/styles';
import axios from 'axios'
import Button from '@material-ui/core/Button';
import Card from '@material-ui/core/Card';
import CardContent from '@material-ui/core/CardContent';
import List from '@material-ui/core/List';
import ListItem from '@material-ui/core/ListItem';
import ListItemText from '@material-ui/core/ListItemText';


const styles = theme => ({
  card: {
    minWidth: 400,
    marginBottom: 20
  },
});

class Conflict extends React.Component {

  constructor(props) {
    super(props);
    this.state = {

    }
  }

  handleDelete = () => {
    const { enqueueSnackbar, type, id } = this.props;
    let url = `/scot/api/v2/${type}/${id}`;
    axios.delete(url)
      .then(function () {
        enqueueSnackbar(`Successfully deleted ${type}.`, { variant: 'success' });
        this.props.fetchData(type)
        this.props.handleClose();
      }.bind(this))
      .catch(function (error) {
        console.log(error);
        enqueueSnackbar(`Failed deleting ${type}.`, { variant: 'error' });
        this.props.handleClose();
      });
  }

  render() {
    const { classes } = this.props;
    return (
      <div>
        <Card className={classes.card}>
          <CardContent>
            <Typography variant="h5" component="h2">Uh-oh! It looks like there was a conflict between your {this.props.type} and the one cached saved on server.</Typography>
            <br />
            <div>
              <List component="nav">
                <ListItem button>
                  <ListItemText primary={"Data from server : "} secondary={this.props.server} />
                </ListItem>
                <ListItem href="#simple-list">
                  <ListItemText primary={"Your change : "} secondary={this.props.ours} />
                </ListItem>
              </List>
            </div>
            <div>
              <Button style={{ marginLeft: 5, backgroundColor: 'red', color: 'white' }} onClick={() => this.handleDelete(this.props.id)} variant="contained" >Yes</Button>
              <Button style={{ marginLeft: 5 }} onClick={this.props.toggleConfirm} variant="contained" >Cancel</Button>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }
}

export default withSnackbar(withStyles(styles)(Conflict));