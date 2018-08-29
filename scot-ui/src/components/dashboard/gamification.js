import React, { PureComponent } from "react";
import { Well, Panel, Badge } from "react-bootstrap";
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
      error: null,
      _isMounted: false
    };

    this.updateData = this.updateData.bind(this);
    this.fetchError = this.fetchError.bind(this);
    this.updateCategory = this.updateCategory.bind(this);
  }

  componentDidMount() {
    $.ajax({
      type: "get",
      url: "/scot/api/v2/game",
      success: this.updateData,
      error: this.fetchError
    });
    this.setState({ _isMounted: true });
    this.categoryInterval = setInterval(this.updateCategory, CATEGORY_INTERVAL);
  }

  componentWillUnmount() {
    if (this.categoryInterval) {
      clearInterval(this.categoryInterval);
    }
    this.setState({ _isMounted: false });
  }

  updateCategory() {
    let nextIndex =
      (this.state.categoryIndex + 1) % this.state.gameCategories.length;
    if (this.state._isMounted) {
      this.setState({
        categoryIndex: nextIndex
      });
    }
  }

  updateData(data) {
    let categories = [];
    for (let category in data) {
      categories.push(<Category category={category} data={data[category]} />);
    }
    if (this.state._isMounted) {
      this.setState({
        gameData: data,
        gameCategories: categories
      });
    }
  }

  fetchError(error) {
    if (this.state._isMounted) {
      this.setState({
        error: error
      });
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
    header={`${titleCase(category)} - ${data[0].tooltip.toString()}`}
    className="category"
  >
    <div>
      <div>
        {data[0].username.toString()} <Badge>{data[0].count.toString()}</Badge>
      </div>
      <div>
        {data[1].username.toString()} <Badge>{data[1].count.toString()}</Badge>
      </div>
      <div>
        {data[2].username.toString()} <Badge>{data[2].count.toString()}</Badge>
      </div>
    </div>
  </Panel>
);

export default Gamification;
