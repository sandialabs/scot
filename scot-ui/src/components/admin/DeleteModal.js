import React from 'react'
import Typography from '@material-ui/core/Typography';
import { withSnackbar } from 'notistack';
import { withStyles } from '@material-ui/core/styles';
import axios from 'axios'
import Button from '@material-ui/core/Button';
import Card from '@material-ui/core/Card';
import CardContent from '@material-ui/core/CardContent';

const styles = theme => ({
  card: {
    minWidth: 400,
    marginBottom: 20
  },
});

class DeleteModal extends React.Component {

  constructor(props) {
    super(props);
  }

  deleteException = (id) => {
    const { enqueueSnackbar } = this.props;
    let url = `/vast/api/v2/user/${id}`;
    axios.delete(url)
      .then(function () {
        enqueueSnackbar('Successfully deleted user.', { variant: 'success' });
        this.props.getExceptionData();
        this.props.onClose();
      }.bind(this))
      .catch(function (error) {
        console.log(error);
        enqueueSnackbar('Failed deleting user.', { variant: 'error' });
        this.props.onClose();
      });
  }

  render() {
    const { classes } = this.props;
    return (
      <div>
        <Card className={classes.card}>
          <CardContent>
            <Typography variant="h5" component="h2">Are you sure you want to delete {this.props.type} {this.props.user}?</Typography>
            <br />
            <div>
              <Button style={{ marginLeft: 5, backgroundColor: 'red', color: 'white' }} onClick={() => this.deleteException(this.props.id)} variant="contained" >Yes</Button>
              <Button style={{ marginLeft: 5 }} onClick={this.props.onClose} variant="contained" >Cancel</Button>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }
}

export default withSnackbar(withStyles(styles)(DeleteModal));
