import React from 'react';
import classNames from 'classnames';
import PropTypes from 'prop-types';
import { withStyles } from '@material-ui/core/styles';
import AppBar from '@material-ui/core/AppBar';
import Tabs from '@material-ui/core/Tabs';
import Tab from '@material-ui/core/Tab';
import Typography from '@material-ui/core/Typography';
import { createMuiTheme, MuiThemeProvider } from '@material-ui/core/styles';
import ScotForceGraph from './ScotForceGraph';
//import SFG3d from './SFG3d';
import SFG from './SFG';

function TabContainer(props) {
  return (
    <Typography component="div" style={{ padding: 8 * 3 }}>
      {props.children}
    </Typography>
  );
}

const theme = createMuiTheme({
  typography: {
    // Tell Material-UI what the font-size on the html element is.
    fontSize: 20,
  },
});


const styles = theme => ({
  root: {
    flexGrow: 1,
    // backgroundColor: theme.palette.background.paper,
  },
  appBar: {
    backgroundColor: '#2196f3',
  },
  typography: {
    // Tell Material-UI what the font-size on the html element is.
    fontSize: 20,
  }
  // didnt work
  //ScotForceGraphDisplay: {
  //  "display": "flex",
  //  "flex-direction": "row"
  //}
});

class GraphView extends React.Component {

  state = {
    value: 0,
    threed: 1,
  };

  handleChange = (event, value) => {
    this.setState({ value });
  };

  render() {
    const { classes } = this.props;
    const { value } = this.state;

    return (
      <MuiThemeProvider theme={theme}>
        <div className={classes.root}>
            { this.state.threed === 1 ?
                <SFG/>
            :
                <ScotForceGraph/>
            }
        </div>
      </MuiThemeProvider>
    );
  }
}

export default withStyles(styles)(GraphView);
