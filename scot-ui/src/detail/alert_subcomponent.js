import React, { useEffect, useState } from "react";
import AddEntry from "../components/add_entry.js";
import SelectedEntry from "./selected_entry";
import Button from "@material-ui/core/Button";

function AddEntryToAlert({ ...props }) {
  const [visible, setVisibility] = useState(true);

  function toggleVisibility() {
    setVisibility(!visible);
    props.updated();
  }

  return (
    <div>
      {!visible ? (
        <div style={{ justifyContent: "center", padding: 5, display: "flex" }}>
          <br />

          <Button
            style={{ backgroundColor: "#5bc0de", color: "white" }}
            onClick={toggleVisibility}
            variant="contained"
          >
            Add Entry
          </Button>
          <br />
        </div>
      ) : null}
      {visible ? (
        <AddEntry
          entryAction={"Add"}
          type="alert"
          targetid={props.row.id}
          id={"add_entry"}
          addedentry={setVisibility}
          errorToggle={props.errorToggle}
          toggleVisibility={toggleVisibility}
        />
      ) : null}
      {props.entryData.length > 0 ? (
        <SelectedEntry
          entryData={props.entryData}
          type="alert"
          id={props.row.id}
          showEntryData={props.showEntryData}
          errorToggle={props.errorToggle}
          createCallback={props.createCallback}
          removeCallback={props.removeCallback}
          entityData={props.entityData}
          addFlair={props.addFlair}
        />
      ) : null}
    </div>
  );
}
export default AddEntryToAlert;
