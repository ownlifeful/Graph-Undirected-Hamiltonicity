#!/usr/bin/perl

#
# This script demonstrates the functionality of the
# Graph::Undirected::Hamiltonicity module.
#
# I have added all the CSS inline, as CGI.pm has limited support for CSS.
# As a result, this script is fairly portable.
#

use CGI qw(:standard);
use CGI::Carp;
use Graph::Undirected;
use Graph::Undirected::Hamiltonicity;
use Graph::Undirected::Hamiltonicity::Transforms qw(&string_to_graph);

use warnings;
use strict;

our $DEBUG = 0;
our ( $e, %config );

$ENV{HC_OUTPUT_FORMAT} = 'html';
$| = 1;


print header;
print start_html(
    -title => 'Hamiltonian Graph Detector',
    -bgcolor => 'white',
    -style => { -verbatim => 'body {font: 15px arial, sans-serif;}' }
 );
print "<br/><br/>\n";
print start_form( -name => 'mainForm', -action => url( -absolute => 1, -path_info => 0 ) );

my $graph_text = param('graph_text');
$graph_text =~ s/[^0-9=,]+//g;
$graph_text =~ s/([=,])\D+/$1/g;
$graph_text =~ s/^\D+|\D+$//g;

my $G;
if ( $graph_text =~ /\d/ ) {
    if ( $graph_text =~ /=/ ) {
        eval { $G = string_to_graph($graph_text); };
        if ($@) {
            print "That was not a valid graph, ";
            print "according to the Graph::Undirected module.<BR/>\n";
	    print "[", $graph_text, "][$@]<BR/>\n"; 
            print_instructions();
        }
    }
    else {
        print "<TT>$graph_text</TT> is not a valid graph.\n";
        print "If the graph contains a single vertex of degree 0 or 1 ";
        print "it is non-Hamiltonian.<BR/>\n";
        print_instructions();
    }
}
else {
    print
        "Here is the Null Graph K<sub>0</sub>. It is not Hamiltonian.\n<BR/><P/>\n";
    print_instructions();
}

print get_textarea($G);
print end_form;
print "<br/><br/>\n";

if ( $graph_text =~ /\d=\d/ ) {

    print qq{You can read the program's trace output below, or jump to the <A HREF="#conclusion">conclusion</A>.<BR/>\n};

    my $result = graph_is_hamiltonian($G);
    print qq{<BR/>\n};
    print qq{<A NAME="conclusion"><B>Conclusion:</B></A>\n};
    print qq{<span style="background: yellow;">\n};
    if ( $result->{is_hamiltonian} ) {
        print "The graph is Hamiltonian.\n";
    } else {
        print "The graph is not Hamiltonian.\n";
    }
    print qq{</span>\n};
    print "(", $result->{reason}, ")\n" if defined $result->{reason};

}

print end_html;

############################################################

sub get_textarea {
    my $G = $_[0];

    my $printable_string = defined $G ? $G->stringify() : '';

    Delete('graph_text');

    my $result = '';
    $result .= qq{<DIV style="background-color: #DDD; padding-top: 10px; padding-bottom: 10px;">\n};
    $result .= qq{<div style="padding-top: 10px; padding-bottom: 10px; padding-left: 20px;">\n};
    $result .= textarea(
        -name  => 'graph_text',
        -value => $printable_string,
        -placeholder => 'Example: 0=1,0=2,1=2,2=3',
        -rows  => 3,
        -cols  => 150,
        -style => 'font-family: monospace;'
    );
    $result .= qq{</div>};

    $result .= qq{<div style="padding-top: 10px; padding-bottom: 10px; padding-left: 20px; padding-right: 10px;">\n};
    $result .= submit(
        -style => q{
                   color: #fff;
                   background-color: #337ab7;
                   border-color: #2e6da4;
                   padding: 6px 12px;
                   font-size: 14px;
                   font-weight: 400;
                   line-height: 1.42857143;
                   text-align: center;
                   white-space: nowrap;
                   vertical-align: middle;
                   border: 1px solid transparent;
                   border-radius: 4px;
                 },
        -value => 'Is this graph, Hamiltonian or not?',
        );
    $result .= qq{</div>};

    $result .= "</DIV>\n";
    return $result;

}


##########################################################################

sub print_instructions {
    print "Please enter an undirected graph's edge list.\n";
    print "e.g., <TT>0=1,1=2,0=2</TT><BR/>\n";
    print "Each vertex should be 0, or a positive integer.<BR/>\n";
}

__END__

