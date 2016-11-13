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

print <<"END_OF_HEADER";
<!DOCTYPE html
    PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">
<head>
<title>Hamiltonian Cycle Detector</title>

<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="stylesheet" href="http://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css">
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>
<script src="http://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js"></script>

</head>
<body bgcolor="white">
<div class="container">
<br/><br/>

<form method="post" action="$self_url" enctype="multipart/form-data">

END_OF_HEADER


my $cgi = CGI::Minimal->new;
if ($cgi->truncated) {
    print qq{There was an error. The input size might be too big.\n};
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
    print "Here is the Null Graph <TT>K<sub>0</sub></TT>. ";
    print "It is not Hamiltonian.\n<BR/><P/>\n";        
    print_instructions();
}

print get_textarea($g);
print qq{</form>\n};;
print "<br/><br/>\n";

if ( $graph_text =~ /\d=\d/ ) {

    print qq{You can read the program's trace output below, };
    print qq{or jump to the <A HREF="#conclusion">conclusion</A>.<BR/>\n};

    my ( $is_hamiltonian, $reason ) = graph_is_hamiltonian($g);
    print qq{<BR/>\n};
    print qq{<A NAME="conclusion"></A><B>Conclusion:</B>\n};
    print qq{<span style="background: yellow;">\n};
    if ( $is_hamiltonian ) {
        print "The graph is Hamiltonian.\n";
    } else {
        print "The graph is not Hamiltonian.\n";
    }
    print qq{</span>\n};
    print "($reason)\n";

}

print qq{</div></BODY></HTML>\n};

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

