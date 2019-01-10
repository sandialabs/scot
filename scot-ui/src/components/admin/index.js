import React from 'react';
import classNames from 'classnames';
import PropTypes from 'prop-types';
import { withStyles } from '@material-ui/core/styles';
import AppBar from '@material-ui/core/AppBar';
import Tabs from '@material-ui/core/Tabs';
import Tab from '@material-ui/core/Tab';
import Typography from '@material-ui/core/Typography';
import { createMuiTheme, MuiThemeProvider } from '@material-ui/core/styles';
import UserGroupContainer from './usergroupcontainer'
import { Api } from './api'
import { Undelete } from './undelete'


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
  },
});

class Admin extends React.Component {
  state = {
    value: 0,
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
          <AppBar className={classNames(classes.appBar, classes.typography)} position="static">
            <Tabs value={value} indicatorColor="primary" centered onChange={this.handleChange}>
              <Tab label="Users / Groups" />
              <Tab label="API" />
              <Tab label="Undelete" />
            </Tabs>
          </AppBar>
          {value === 0 &&
            <TabContainer>
              <UserGroupContainer></UserGroupContainer>
            </TabContainer>}
          {value === 1 &&
            <TabContainer>
              <Api></Api>
            </TabContainer>}
          {value === 2 &&
            <TabContainer>
              <Undelete></Undelete>
            </TabContainer>}
        </div>
      </MuiThemeProvider>
    );
  }
}
Admin.propTypes = {
  classes: PropTypes.object.isRequired,
};

export default withStyles(styles)(Admin);