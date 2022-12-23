#!/usr/bin/env perl
use Mojolicious::Lite -signatures;
use Mojo::JSON qw(encode_json);


$| = 1;

use Mojolicious::Static;
my $static = Mojolicious::Static->new;

my $js_dir = '/root/Documents/code/Perl/HC6/Graph-Undirected-Hamiltonicity/script/mojo_app/js';
$static = $static->asset_dir('js');
push @{$static->paths}, $js_dir;

foreach ( qw ( p5.min.js graph.js ) ) {
    $static = $static->extra({ $_ => "$js_dir/$_" });
}


use Graph::Undirected::Hamiltonicity;

get '/' => sub ($c) {
  $c->render(template => 'index');
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
	my $g = Graph::Undirected::Hamiltonicity->new(graph_text => $msg // "",
						      mojo => $c,
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
###	    args => [ qq{jQuery('$modal_id').modal("show")} ]
	    args => [ $modal_id ]
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
% my $url = 'ws://173.255.210.224:3000/detect';

<!--
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/jquery-modal/0.8.0/jquery.modal.min.css" integrity="sha256-rll6wTV76AvdluCY5Pzv2xJfw2x7UXnK+fGfj9tQocc=" crossorigin="anonymous" />
-->

<script src="https://bhopal.art/js/p5.min.js"></script>
<script src="https://bhopal.art/js/graph.js"></script>
<script src="https://bhopal.art/js/node_modules/bootstrap/dist/js/bootstrap.bundle.min.js"></script>

<!-- Remember to include jQuery :) -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.0.0/jquery.min.js"></script>

<!-- jQuery Modal -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery-modal/0.9.1/jquery.modal.min.js"></script>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/jquery-modal/0.9.1/jquery.modal.min.css" />

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
          // jQuery('#text_div').append( message );
        var myFrame = jQuery("#my_frame").contents().find('#text_div');
        myFrame.append(message);

         }
        } else if ( x.op === 'graph' ) {
           let message = "op=[graph]";
           console.log(message);
           let g = x.args;
           if (g !== window.g) {
               clear();
               window.g = g;
           }
           console.log("graph=[" + g + "]");
           // output_graph(g);
        } else if ( x.op === "eval" ) {
           let message = "op=[eval]";
           console.log(message);
           console.log(arg="[" + x.args[0] + "]");
           jQuery.noConflict();
           jQuery( x.args[0] ).modal("show");
           // looseJsonParse(x.args[0]);
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
<span class="col-6" id="graph_div">
</span>
<span class="col-6">
<iframe id="my_frame" src="/text" height="1000" width="500">
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
</div>


 <!-- Non-Hamiltonian modal -->
<div class="modal" id="non">
  <p>The graph is <U>not</U> Hamiltonian.</p>
</div>


@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body class="container-fluid">

<%= content %>




</body>
</html>
