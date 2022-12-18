#!/usr/bin/env perl
use Mojolicious::Lite -signatures;
use Mojo::JSON;

use Graph::Undirected::Hamiltonicity;

$Graph::Undirected::Hamiltonicity::json = Mojo::JSON->new;

get '/' => sub ($c) {
  $c->render(template => 'index');
};

# WebSocket service used by the template to extract the title from a web site
websocket '/detect' => sub ($c) {
    $c->on(message => sub ($c, $msg) {
	my $g = Graph::Undirected::Hamiltonicity->new(graph_text => $msg // "",
						      mojo => $c,
						      output_format => 'json',
						      json => $json );
	my ( $is_hamiltonian, $reason, $params ) = $g->graph_is_hamiltonian();
	my $modal_id;
	if ( $is_hamiltonian == $Graph::Undirected::Hamiltonicity::GRAPH_IS_HAMILTONIAN ) {
	    $modal_id = '#ham';
	} else {
	    $modal_id = '#non';
	}
	### my $message = qq{<script>jQuery('$modal_id').modal("show");</script>\n};
	my $message = {
	    op => 'eval',
	    args=> [ qq{alert('$modal_id');} ]
	};
	$c->send($Graph::Undirected::Hamiltonicity::json->encode($message));
  });

};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome to Hamitonia';
% my $url = 'ws://173.255.210.224:3000/detect';

<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/jquery-modal/0.8.0/jquery.modal.min.css" integrity="sha256-rll6wTV76AvdluCY5Pzv2xJfw2x7UXnK+fGfj9tQocc=" crossorigin="anonymous" />

<script src="/js/p5.min.js"></script>
<script src="/js/graph.js"></script>
<script src="/js/node_modules/bootstrap/dist/js/bootstrap.bundle.min.js"></script>
<script src="/js/node_modules/bootstrap/dist/js/bootstrap.bundle.min.js.map"></script>

<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery-modal/0.8.0/jquery.modal.min.js" integrity="sha256-UeH9wuUY83m/pXN4vx0NI5R6rxttIW73OhV0fE0p/Ac=" crossorigin="anonymous"></script>

<style>

 #form_div {
    background-color: #DDD;
    padding-top: 10px;
    padding-bottom: 10px;
  }
</style>

<script>
function looseJsonParse(obj) {
  return eval?.(`"use strict";(${obj})`);
}
////////////////////////////////////////////////////
// A $( document ).ready() block.
jQuery( document ).ready(function() {
    console.log( "ready!" );
    const ws = new WebSocket('<%= $url %>');
    ws.onmessage = function (event) {
        let x = JSON.parse(event.data);

       if ( x.op === 'text' ) {
        for (let k in x.args) {
          let message = x.args[k];
          console.log(k + ": message=[" + message + "]");
          document.body.innerHTML += message + "\n"
         }
        } else if ( x.op === 'graph' ) {
           let message = "op=[graph]";
           console.log(message);
           let g = x.args[0];
           window.g = g;
           output_graph(g);
        } else if ( x.op === "eval" ) {
           let message = "op=[eval]";
           console.log(message);
           looseJsonParse(x.args[0]);
        } else {
           let message = "op=[" + x.op + "]";
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
<div class="col" id="graph_div">
</div>
<div class="col" id="text_div">
</div>
</div>

        <DIV class="row" id="form_div"  >
            <div class="col" style="padding-top: 10px; padding-bottom: 10px; padding-left: 20px;">
                <textarea id="graph_text" name="graph_text"  rows="3" cols="100" placeholder="Example: 0=1,0=2,1=2,2=3" style="font-family: monospace;"></textarea>
            </div>
            <div class="col" style="padding-top: 10px; padding-bottom: 10px; padding-left: 20px; padding-right: 10px;">
            <input type="submit" id="detect_button" name=".submit" value="Is this graph, Hamiltonian or not?" class="btn btn-primary">
            <input type="button" id="spoof_button" value="Spoof a Graph!" class="btn btn-primary">
            </div>
        </DIV>


 <!-- Hamiltonian modal -->
  <div id="ham" style="display:none; overflow: visible;" class="modal">
    <H1>The graph is Hamiltonian!</H1>
  </div>

 <!-- Non-Hamiltonian modal -->
  <div id="non" style="display:none; overflow: visible;" class="modal">
    <H1>The graph is <u>not</u> Hamiltonian!</H1>
  </div>


@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body class="container-fluid"><%= content %></body>
</html>
