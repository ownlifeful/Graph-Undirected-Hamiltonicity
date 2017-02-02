#!/usr/bin/env perl

#
# This script demonstrates the functionality of the
# Graph::Undirected::Hamiltonicity module.
#
# It uses CGI::Minimal to keep it fairly portable.
#

use CGI::Minimal;
use Graph::Undirected;
use Graph::Undirected::Hamiltonicity;
use Graph::Undirected::Hamiltonicity::Transforms qw(&string_to_graph);

use warnings;
use strict;

$ENV{HC_OUTPUT_FORMAT} = 'html';
$| = 1;


my ( $self_url ) = split /\?/, $ENV{REQUEST_URI};

print qq{Content-Type: text/html\n\n};

print <<'END_OF_HEADER';
<!DOCTYPE html
    PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">
<head>
<title>Hamiltonian Cycle Detector</title>

<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<meta name="viewport" content="width=device-width, initial-scale=1">

<link rel="stylesheet" href="http://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/jquery-modal/0.8.0/jquery.modal.min.css" integrity="sha256-rll6wTV76AvdluCY5Pzv2xJfw2x7UXnK+fGfj9tQocc=" crossorigin="anonymous" />

<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>
<script src="http://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery-modal/0.8.0/jquery.modal.min.js" integrity="sha256-UeH9wuUY83m/pXN4vx0NI5R6rxttIW73OhV0fE0p/Ac=" crossorigin="anonymous"></script>

<script>
    $(document).ready(function(){

       if (typeof window.is_hamiltonian !== 'undefined') {
           var modal_to_open = window.is_hamiltonian ? '#ham' : '#non';
           $( modal_to_open ).modal();
       }

    });
</script>

</head>
<body bgcolor="white">
<div class="container">
<br/><br/>


END_OF_HEADER

print qq{<form method="post" action="$self_url" enctype="multipart/form-data">\n};

my $cgi = CGI::Minimal->new;
if ($cgi->truncated) {
    print qq{<H2>There was an error. The input size might be too big.</H2>\n};
    print get_textarea();
    print qq{</form></div></body></html>\n};
    exit;
}

my $graph_text = $cgi->param('graph_text') // '';
$graph_text =~ s/[^0-9=,]+//g;
$graph_text =~ s/([=,])\D+/$1/g;
$graph_text =~ s/^\D+|\D+$//g;

my $g;
if ( $graph_text =~ /\d/ ) {
    eval { $g = string_to_graph($graph_text); };
    if ( my $exception = $@ ) {
        print "That was not a valid graph, ";
        print "according to the Graph::Undirected module.<BR/>\n";
        print "[$graph_text][$exception]<BR/>\n";
        print_instructions();
    }
} else {
    if ( $ENV{QUERY_STRING} =~ /\bgraph_text=/ ) {
        print "Here is the Null Graph <TT>K<sub>0</sub></TT>. ";
        print "It is not Hamiltonian.\n<BR/><P/>\n";
    }
    print_instructions();
}

print get_textarea($g);
print qq{</form>\n};;
print "<br/><br/>\n";

if ( $graph_text =~ /\d/ ) {

    print qq{<h2>Here is the program's trace output:</h2><BR/>\n};

    my ( $is_hamiltonian, $reason ) = graph_is_hamiltonian($g);
    print qq{<BR/>\n};
    print qq{<A NAME="conclusion"></A><B>Conclusion:</B>\n};
    print qq{<span style="background: yellow;">\n};
    if ( $is_hamiltonian ) {
        print qq{The graph is Hamiltonian.\n};
        print qq{<script>window.is_hamiltonian = true;</script>\n};
    } else {
        print qq{The graph is not Hamiltonian.\n};
        print qq{<script>window.is_hamiltonian = false;</script>\n};
    }
    print qq{</span>\n};
    print qq{($reason)\n};
    print qq{<BR/><P/>\n};
}

print q{
 <!-- Hamiltonian modal -->
  <div id="ham" style="display:none; overflow: visible;">
    <H1>The graph is Hamiltonian!</H1>
  </div>

 <!-- Non-Hamiltonian modal -->
  <div id="non" style="display:none; overflow: visible;">
    <H1>The graph is <u>not</u> Hamiltonian!</H1>
  </div>
</div>

<BR/><P/>
</BODY></HTML>
};

### print qq{<a href="#" rel="modal:close">Close</a> or press ESC};

############################################################

sub get_textarea {
    my $g = $_[0];
    my $printable_string = defined $g ? $g->stringify() : '';
    my $result = <<END_OF_TEXTAREA;
        <DIV style="background-color: #DDD; padding-top: 10px; padding-bottom: 10px;">
            <div style="padding-top: 10px; padding-bottom: 10px; padding-left: 20px;">
                <textarea name="graph_text"  rows="3" cols="100" placeholder="Example: 0=1,0=2,1=2,2=3" style="font-family: monospace;">$printable_string</textarea>
            </div>
            <div style="padding-top: 10px; padding-bottom: 10px; padding-left: 20px; padding-right: 10px;">
            <input type="submit" name=".submit" value="Is this graph, Hamiltonian or not?" class="btn btn-primary">
            </div>
        </DIV>
END_OF_TEXTAREA

    return $result;

}

##########################################################################

sub print_instructions {
    print "Please enter an undirected graph's edge list.\n";
    print "e.g., <TT>0=1,1=2,0=2</TT><BR/>\n";
    print "Each vertex should be 0, or a positive integer.<BR/>\n";
}

__END__

