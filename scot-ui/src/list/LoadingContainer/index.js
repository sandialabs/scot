import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';
import CircularProgress from '@material-ui/core/CircularProgress';
import { withStyles } from '@material-ui/core/styles';

const styles = theme => ({
  progress: {
    margin: theme.spacing.unit * 2,
  },
});
function LoadingContainer(props) {
  const { classes, loading } = props;
  return (
    <div className='LoadingContainer'>
      {loading &&
        <CircularProgress className={classes.progress} />
      }
    </div>
  );
}

LoadingContainer.propTypes = {
  classes: PropTypes.object.isRequired,
};
export default withStyles(styles)(LoadingContainer);

