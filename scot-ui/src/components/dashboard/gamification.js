import React, { PureComponent } from "react";
import { Well, Panel, Badge } from "react-bootstrap";
import Emoji from './emoji'
import $ from "jquery";
const titleCase = str => str.charAt(0).toUpperCase() + str.slice(1);
const CATEGORY_INTERVAL = 5000;

class Gamification extends PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      gameData: [],
      gameCategories: [],
      categoryIndex: 0,
      error: null
    };
  }

  componentDidMount() {
    this._isMounted = true;
    $.ajax({
      type: "get",
      url: "/scot/api/v2/game",
      success: this.updateData,
      error: this.fetchError
    });
    this.categoryInterval = setInterval(this.updateCategory, CATEGORY_INTERVAL);
  }

  componentWillUnmount() {
    this._isMounted = false;
    if (this.categoryInterval) {
      clearInterval(this.categoryInterval);
    }
    this._isMounted = false;
  }

  updateCategory = () => {
    let nextIndex =
      (this.state.categoryIndex + 1) % this.state.gameCategories.length;
    if (this._isMounted) {
      this.setState({
        categoryIndex: nextIndex
      });
    }
  }

  updateData = (data) => {
    let categories = [];
    for (let category in data) {
      if (category !== null) {
        console.log(`${titleCase(category)}`);
        categories.push(<Category category={category} data={data[category]} />);
      }
    }
    if (this._isMounted) {
      this.setState({ gameData: data, gameCategories: categories });
    }
  }

  fetchError = (error) => {
    if (this._isMounted) {
      this.setState({ error: error });
    }
  }

  render() {
    return (
      <Well className="Gamification">
        <h3>Leaders</h3>
        {this.state.error && (
          <Panel bsStyle="danger" header="Error">
            {this.state.error}
          </Panel>
        )}
        {this.state.gameCategories[this.state.categoryIndex]}
      </Well>
    );
  }
}

const Category = ({ category, data }) => (
  <Panel
    className="category"
  >
    <Panel.Title><b>{`${titleCase(category)} - ${data[0].tooltip}`}</b></Panel.Title>
    <Panel.Body>
      <div>
        {data[0].username !== "" && data[0].username !== null && data[0].count != null && data[0].count !== "" ?
          <div>
            <Emoji symbol="🥇" /> {data[0].username} <Badge>{data[0].count}</Badge>
          </div> : null
        }
        {data[1].username !== "" && data[1].username != null && data[1].count != null && data[1].count !== "" ?
          <div>
            <Emoji symbol="🥈" /> {data[1].username} <Badge>{data[1].count}</Badge>
          </div> : null
        }
        {data[2].username !== "" && data[2].username != null && data[2].count != null && data[2].count !== "" ?
          <div>
            <Emoji symbol="🥉" /> {data[2].username} <Badge>{data[2].count}</Badge>
          </div> : null
        }
      </div>
    </Panel.Body>
  </Panel>
);

export default Gamification;
