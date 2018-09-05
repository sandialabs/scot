let network = {};
let nodes   = {};
let edges   = {};
let maxi    = 0;

function buildGraph() {
    document.getElementById("status").innerHTML = "Processing data...";
    let data = JSON.parse(this.responseText);
    maxi = data.maxindex;
    nodes = new vis.DataSet(data.nodes);
    edges = new vis.DataSet(data.edges);
    let container = document.getElementById('mynetwork');
    let d = {
        nodes: nodes,
        edges: edges
    };
    console.log(d);
    let options = {
        nodes: {
            shape: 'circle',
            shadow: true
        },
        edges: {
            shadow: true
        },
        layout: {
            improvedLayout: false
        },
        physics: {
            barnesHut: {
                gravitationalConstant: -20000,
                damping: 0.8,
                avoidOverlap: 0.9
            }
        },
        interaction: { hover: true },
        manipulation: { enabled: true }
    };
    document.getElementById("status").innerHTML = "Buiding network...";
    network = new vis.Network(container, d, options);
    document.getElementById("status").innerHTML = "Stabilizing network...";
    network.stabilize();
    document.getElementById("status").innerHTML = "";
    network.on("click", function(params) {
        let thing = nodes.get(params.nodes[0]);
        console.log("selected");
    });
    network.on("doubleClick", function (params) {
        let thing = nodes.get(params.nodes[0]);
        let tarray  = thing.title.split(' ');
        let type    = tarray[0];
        let id      = tarray[1];
        let url     = "/scot/api/v2/graph/"+type+"/"+id+"/1?maxindex="+maxi;
        console.log('getting '+url);
        document.getElementById("status").innerHTML = "requesting more nodes...";
        let req     = new XMLHttpRequest();
        req.addEventListener("load", addNodes);
        req.open("GET", url);
        req.send();
    });
}

function addNodes() {
    console.log("adding data to dataset");
    let add_data = JSON.parse(this.responseText);
    document.getElementById("status").innerHTML = "filtering nodes...";
    add_data.nodes.forEach(function (n) {
        let adid = n.id;
        console.log("seeinf if node "+adid+" is already here");
        if (adid in nodes._data) {
            nodes.remove(n.id);
        }
    });
    document.getElementById("status").innerHTML = "filtering edges...";
    add_data.edges.forEach(function (n) {
        let adid = n.id;
        console.log("seeinf if edge "+adid+" is already here");
        if (adid in edges._data) {
            edges.remove(n.id);
        }
        else {
            console.log("Adding edge "+adid);
        }
    });

    nodes.add(add_data.nodes);
    edges.add(add_data.edges);
    document.getElementById("status").innerHTML = "building network...";
    network.setData({nodes: nodes, edges: edges});
    // network.stabilize();
    document.getElementById("status").innerHTML = "";
}

function removeNode () {
    network.deleteSelected();
}

function newgraph() {
    var request = new XMLHttpRequest();
    var start_thing = document.getElementById("thing").value;
    var start_id    = document.getElementById("id").value;
    var start_depth = document.getElementById("depth").value;
    var url         = "/scot/api/v2/graph/" + start_thing +
                      "/" + start_id + "/" + start_depth;
    document.getElementById("status").innerHTML = "Loading data...";
    request.addEventListener("load", buildGraph);
    request.open("GET", url);
    request.send();
}

