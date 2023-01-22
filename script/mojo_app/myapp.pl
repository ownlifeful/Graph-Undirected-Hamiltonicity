#!/usr/bin/env perl
use Mojolicious::Lite -signatures;
use Mojo::JSON qw(encode_json);
use Graph::Undirected::Hamiltonicity;

$| = 1;

get '/' => sub ($c) {
    my $host_port = $c->req->url->to_abs->host_port;
    my $ws_url = "ws://$host_port/detect";
    $c->render(template => 'index', ws_url => $ws_url);
};

get '/graph.js' => sub ($c) {
  $c->render(template => 'graph', format => 'js');
};


get '/text' => sub ($c) {
  $c->render(template => 'text');
};


#get '/js/:id' => sub ($c) {
#    my $file = $c->stash("id");
#    $c->reply->static($file);
#};


# WebSocket service used by the template to extract the title from a web site
websocket '/detect' => sub ($c) {

    
    $c->on(message => sub ($c, $msg) {
	$Graph::Undirected::Hamiltonicity::mojo = $c;
	my $g = Graph::Undirected::Hamiltonicity->new(graph_text => $msg // "",
						      output_format => 'json');

	my ( $is_hamiltonian, $reason, $params ) = $g->graph_is_hamiltonian();
	my $modal_id;
	if ( $is_hamiltonian == $Graph::Undirected::Hamiltonicity::GRAPH_IS_HAMILTONIAN ) {
	    $modal_id = '#ham';
	} else {
	    $modal_id = '#non';
	}
	my $message = {
	    op => 'eval',
	    args => [ qq< jQuery('.reason').html('$reason'); jQuery('$modal_id').modal({ fadeDuration: 1000, fadeDelay: 0.50 }); > ]
###	    args => [ $modal_id ]
	};
	$c->send( encode_json($message) );
  });

};

app->start;
__DATA__


@@ text.html.ep
% layout 'default';
% title 'Text Output';
<pre id="text_div" style="background-color: #000000; color: #00FF00;">
Output goes here...
</pre>

@@ index.html.ep
% layout 'default';
% title 'Welcome to Hamitonia';

<script src="https://bhopal.art/js/p5.min.js"></script>
<script src="/graph.js"></script>

<!-- Remember to include jQuery :) -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.0.0/jquery.min.js"></script>

<!-- jQuery Modal -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery-modal/0.9.1/jquery.modal.min.js"></script>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/jquery-modal/0.9.1/jquery.modal.min.css" />

<style>

 #form_div {
    background-color: #DDD;
    height: 10vw;
    display: flex;
    position: --webkit-sticky;
    position: sticky;
  }
</style>

<script>
function looseJsonParse(obj) {
  return eval?.(`"use strict";(${obj})`);
}
////////////////////////////////////////////////////
// A $( document ).ready() block.
jQuery( document ).ready(function() {
    jQuery.noConflict();
    console.log( "ready!" );
    const ws = new WebSocket('<%= $ws_url %>');
    ws.onmessage = function (event) {
        let x = JSON.parse(event.data);

       if ( x.op === 'text' ) {
        for (let k in x.args) {
          let message = x.args[k];
          console.log(k + ": message=[" + message + "]");
          // jQuery('#text_div').append( message );
        var myFrame = jQuery("#my_frame").contents().find('#text_div');
        myFrame.append(message);

         }
        } else if ( x.op === 'graph' ) {
           let message = "op=[graph]";
           console.log(message);
           let g = x.args;
           if (g !== window.g) {
               // clear();
               // alert("graph=[" + g  + "]");
               window.g = g;
           }
           console.log("graph=[" + g + "]");
           // output_graph(g);
        } else if ( x.op === "eval" ) {
           let message = "op=[eval]";
           console.log(message);
           console.log(arg="[" + x.args[0] + "]");
           eval(x.args[0]);
        } else {
           let message = "unknown op=[" + x.op + "]";
           console.log(message);
        }
    };
    jQuery("#detect_button").click(function(){
        console.log( "[" + jQuery('#graph_text').val() + "]" );
        ws.send( jQuery('#graph_text').val()  );
    });
});

</script>
<div class="row">
<div class="col">
<h1>Welcome to the Hamiltonicity Detection module!</h1>
</div>
</div>

<div class="row">
<span class="col-6" id="graph_div">
</span>
<span class="col-6">
<iframe id="my_frame" src="/text" height="500" width="500">
</iframe>
</span>
</div>

        <DIV class="row" id="form_div"  >
            <div class="col col-4" style="padding-top: 10px; padding-bottom: 10px; padding-left: 20px;">
                <textarea id="graph_text" name="graph_text"  rows="3" cols="100" placeholder="Example: 0=1,0=2,1=2,2=3" style="font-family: monospace;"></textarea>
            </div>
            <div class="col col-4" style="padding-top: 10px; padding-bottom: 10px; padding-left: 20px; padding-right: 10px;">
            <input type="submit" id="detect_button" name=".submit" value="Is this graph, Hamiltonian or not?" class="btn btn-primary">
            <input type="button" id="spoof_button" value="Spoof a Graph!" class="btn btn-primary">
            </div>
        </DIV>


 <!-- Hamiltonian modal -->
<div class="modal" id="ham">
  <p>The Graph is Hamiltonian.</p>
  <p class="reason"></p>
</div>


 <!-- Non-Hamiltonian modal -->
<div class="modal" id="non">
  <p>The graph is <U>not</U> Hamiltonian.</p>
  <p class="reason"></p>
</div>


@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body class="container-fluid">

<%= content %>

</body>
</html>

@@ graph.js.ep

let radius = 16;
let vertex_radius = 16;
let image_size = 500;

let edge_color = [];

// -----------------------------------------------------------------------

function setup() {
    let myCanvas = createCanvas(image_size, image_size);
    myCanvas.parent('graph_div');
    background(255);
    textSize(image_size / 25);
    textAlign(CENTER, CENTER);
}

// -----------------------------------------------------------------------

function draw() {
    main();
}

// -----------------------------------------------------------------------

function main() {
    g = window.g;
    if ( g != null ) {
	output_graph(g);
    }
    window.g = null;
}
// -----------------------------------------------------------------------

function random_color() {
    return [ random(255), random(255), random(255) ];
}
// -----------------------------------------------------------------------

function onlyUnique(value, index, self) {
    return self.indexOf(value) === index;
}

// -----------------------------------------------------------------------

function output_graph(g) {
    let edge_refs = g.split(',');
    let vertex_refs = g.split(/\D+/);
    let uniq_vertices = vertex_refs.filter(onlyUnique);
    let v = uniq_vertices.length;

    // Compute angle between vertices
    let angle_between_vertices = PI * 2 / v;

    // Compute Center of image
    let x_center = image_size / 2;
    let y_center = x_center;
    let border   = 0; //parseInt( image_size / 25 );  // cellpadding in the image

    // Compute vertex coordinates
    let radius   = ( image_size / 2 ) - border;
    let angle    = Math.PI * ( 0.5 - ( 1 / v ) );
    let vertices = uniq_vertices.sort();

    let vertex_coordinates = [];
    for ( let i = 0; i < v; i++ ) {
	let vertex = vertices[i];
	let x = ( radius * cos(angle) ) + x_center;
	let y = ( radius * sin(angle) ) + y_center;
	vertex_coordinates[vertex] = { "x": x, "y": y };
	angle += angle_between_vertices;
    }

    draw_edges(vertex_coordinates,edge_refs);
    draw_vertices(vertex_coordinates,vertices);

}

// -----------------------------------------------------------------------
function draw_vertices(vertex_coordinates, vertices) {
    for ( let i in vertices ) {
	let vertex = vertices[i];
	draw_vertex(vertex, vertex_coordinates[vertex]["x"], vertex_coordinates[vertex]["y"]);
    }
}

// -----------------------------------------------------------------------

function draw_edges(vertex_coordinates,edge_refs) {

  for( let j = 0; j < edge_refs.length; j++ ) {

    let edge_ref = edge_refs[j].split('=');

    let v1 = edge_ref[0];
    let v2 = edge_ref[1];

    let x1 = vertex_coordinates[ v1 ].x;
    let y1 = vertex_coordinates[ v1 ].y;
    let x2 = vertex_coordinates[ v2 ].x;
    let y2 = vertex_coordinates[ v2 ].y;

    let e_color = [0, 0, 0];
    stroke( e_color );
    line( x1, y1, x2, y2 );
  }

}

// -----------------------------------------------------------------------

function get_edge_color(v1,v2) {
  let e_color = random_color();
  if ( (edge_color === undefined) || (edge_color[ v1 ] === undefined )) {
    edge_color[ v1 ] = [];
  }
  edge_color[ v1 ][ v2 ] = e_color;
  return e_color;
}


// -----------------------------------------------------------------------

function draw_vertex(vertex, x,y) {
    // TODO: Add vertex labels
    // Draw vertex
    stroke(0);
    fill(0, 0, 216);
    ellipse(x,y,vertex_radius,vertex_radius);
    fill(255);
    text(vertex,x,y);
}

// -----------------------------------------------------------------------
