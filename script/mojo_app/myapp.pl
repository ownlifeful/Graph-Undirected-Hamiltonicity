#!/usr/bin/env perl
use Mojolicious::Lite -signatures;
use Graph::Undirected::GraphMojo;

get '/' => sub ($c) {
  $c->render(template => 'index');
};

# WebSocket service used by the template to extract the title from a web site
websocket '/detect' => sub ($c) {
    $c->on(message => sub ($c, $msg) {
	$ENV{HC_OUTPUT_FORMAT} = 'json';
	my $g = Graph::Undirected::Hamiltonicity->new(graph_text => $msg // "", mojo => $c);
	my ( $is_hamiltonian, $reason, $params ) = $g->graph_is_hamiltonian();
  });

};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome to Hamitonia';
% my $url = 'ws://173.255.210.224:3000/detect';


<link rel="stylesheet" href="http://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/jquery-modal/0.8.0/jquery.modal.min.css" integrity="sha256-rll6wTV76AvdluCY5Pzv2xJfw2x7UXnK+fGfj9tQocc=" crossorigin="anonymous" />

<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>
<script src="http://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery-modal/0.8.0/jquery.modal.min.js" integrity="sha256-UeH9wuUY83m/pXN4vx0NI5R6rxttIW73OhV0fE0p/Ac=" crossorigin="anonymous"></script>


<script>
// A $( document ).ready() block.
jQuery( document ).ready(function() {
    console.log( "ready!" );
    const ws = new WebSocket('<%= $url %>');
    ws.onmessage = function (event) { document.body.innerHTML += event.data + "<BR/>\n" };
    ws.onopen    = function (event) { ws.send('https://mojolicious.org') };
    jQuery("#detect_button").click(function(){
        console.log( "[" + jQuery('#graph_text').val() + "]" );
        ws.send( jQuery('#graph_text').val()  );
    });
});

</script>
<h1>Welcome to the Hamiltonicity Detection module!</h1>

        <DIV style="background-color: #DDD; padding-top: 10px; padding-bottom: 10px;">
            <div style="padding-top: 10px; padding-bottom: 10px; padding-left: 20px;">
                <textarea id="graph_text" name="graph_text"  rows="3" cols="100" placeholder="Example: 0=1,0=2,1=2,2=3" style="font-family: monospace;"></textarea>
            </div>
            <div style="padding-top: 10px; padding-bottom: 10px; padding-left: 20px; padding-right: 10px;">
            <input type="submit" id="detect_button" name=".submit" value="Is this graph, Hamiltonian or not?" class="btn btn-primary">
            <input type="button" id="spoof_button" value="Spoof a Graph!" class="btn btn-primary">
            </div>
        </DIV>

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>
