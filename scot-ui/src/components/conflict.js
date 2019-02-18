import React from 'react'
import Typography from '@material-ui/core/Typography';
import { withSnackbar } from 'notistack';
import { withStyles } from '@material-ui/core/styles';
import axios from 'axios'
import Button from '@material-ui/core/Button';
import Card from '@material-ui/core/Card';
import CardContent from '@material-ui/core/CardContent';

import { Editor } from '@tinymce/tinymce-react';

const styles = theme => ({
  card: {
    minWidth: 700,
    marginBottom: 20
  },
});

class Conflict extends React.Component {

  constructor(props) {
    super(props);
    this.state = {

      editedtext: ""
    }
  }

  componentDidMount() {
    this.setState({ editedtext: this.props.localconflict })
  }

  handlePUT = () => {
    const { enqueueSnackbar, id } = this.props;
    let data = {
      body: this.state.editedtext,
      target_id: this.props.targetid,
      parent: this.props.parent,
      target_type: this.props.type,
      parsed: 0
    }
    let url = `/scot/api/v2/entry/${id}`;
    axios.put(url, data)
      .then(function () {
        enqueueSnackbar(`Successfully updated entry`, { variant: 'success' });
        this.props.handleClose();
        this.props.addedEntry();
      }.bind(this))
      .catch(function (error) {
        console.log(error);
        enqueueSnackbar(`Failed updated entry.`, { variant: 'error' });
        this.props.handleClose();
      });
  }
  handleEditorChange = (e) => {
    this.setState({ editedtext: e })
    console.log(`State is now: ${this.state.editedtext}`)
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
              <div id='remote' className='remote'>
                <b>Changes on server: </b>
                <Editor
                  className="remote"
                  initialValue={this.props.remoteconflict}
                  disabled={true}
                />
              </div>
              <br />
              <div id='local' className='local'>
                <b>Your changes: </b>
                <Editor
                  initialValue={this.state.editedtext}
                  plugins={'advlist lists link image charmap print preview hr anchor pagebreak searchreplace wordcount visualblocks visualchars code fullscreen insertdatetime media nonbreaking save table directionality emoticons template paste textcolor colorpicker textpattern imagetools'}
                  onEditorChange={this.handleEditorChange}
                  value={this.state.editedtext}
                  init={{
                    selector: "textarea",
                    plugins:
                      "advlist lists link image charmap print preview hr anchor pagebreak searchreplace wordcount visualblocks visualchars code fullscreen insertdatetime media nonbreaking save table directionality emoticons template paste textcolor colorpicker textpattern imagetools",
                    table_clone_elements:
                      "strong em b i font h1 h2 h3 h4 h5 h6 p div",
                    paste_retain_style_properties: "all",
                    paste_data_images: true,
                    paste_preprocess: function (plugin, args) {
                      function replaceA(string) {
                        return string.replace(/<(\/)?a([^>]*)>/g, "<$1span$2>");
                      }
                      args.content = replaceA(args.content) + " ";
                    },
                    relative_urls: false,
                    remove_script_host: false,
                    link_assume_external_targets: true,
                    toolbar1:
                      "full screen spellchecker | undo redo | bold italic | alignleft aligncenter alignright | bullist numlist | forecolor backcolor fontsizeselect fontselect formatselect | blockquote code link image insertdatetime | customBlockquote",
                    theme: "modern",
                    content_css: "/css/entryeditor.css",
                    height: 250,
                    verify_html: false,
                    setup: function (editor) {
                      function blockquote() {
                        return "<blockquote><p><br></p></blockquote>";
                      }

                      function insertBlockquote() {
                        let html = blockquote();
                        editor.insertContent(html);
                      }

                      editor.addButton("customBlockquote", {
                        text: "500px max-height blockquote",
                        //image: 'http://p.yusukekamiyamane.com/icons/search/fugue/icons/calendar-blue.png',
                        tooltip: "Insert a 500px max-height div (blockquote)",
                        onclick: insertBlockquote
                      });
                    }
                  }}
                />
              </div>
            </div>
            <div>
              <br />
              <Button style={{ marginLeft: 5, backgroundColor: 'red', color: 'white' }} onClick={this.handlePUT} variant="contained" >Send Update to Server</Button>
              <Button style={{ marginLeft: 5 }} onClick={this.props.handleClose} variant="contained" >Cancel</Button>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }
}

export default withSnackbar(withStyles(styles)(Conflict));