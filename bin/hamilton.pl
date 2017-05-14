#!/usr/bin/env perl

use Carp;
use Getopt::Long;

use Graph::Undirected::Hamiltonicity;
use Graph::Undirected::Hamiltonicity::Transforms qw(string_to_graph);
use Graph::Undirected::Hamiltonicity::Spoof qw(&spoof_known_hamiltonian_graph
&spoof_randomish_graph
);
use Graph::Undirected::Hamiltonicity::Wolfram qw(:all);

use warnings;
use strict;

$| = 1;    # piping hot pipes

my $graph_file    = '';
my $graph_text    = '';
my $v             = 0;
my $e             = 0;
my $count         = 1;
my $output_format = 'none';
my $help          = 0;
my @G             = ();

GetOptions(
    "graph_file|f=s"    => \$graph_file,
    "graph_text|t=s"    => \$graph_text,
    "vertices|v=i"      => \$v,
    "edges|e=i"         => \$e,
    "count|c=i"         => \$count,
    "output_format|o=s" => \$output_format,
    "help|h"            => \$help
) or show_usage_and_exit("Error in command line arguments\n");

show_usage_and_exit() if $help;

if ($graph_file) {
    open( my $fh, "<", $graph_file )
        or croak "Could not open [$graph_file][$!]\n";
    while ( defined( my $line = <$fh> ) ) {
        chomp $line;
        next if $line =~ /^\s*#/;    ### allow comments
        $line =~ s/[^0-9,=]+//g;
        next unless $line;
        push @G, string_to_graph($line);
    }
    close($fh);

} elsif ($graph_text) {
    push @G, string_to_graph($graph_text);
} elsif ($v) {
    $count ||= 1;
    for ( my $i = 0; $i < $count; $i++ ) {
        push @G, spoof_randomish_graph( $v, $e );
    }

} else {
    show_usage_and_exit("Please provide --f, or --t, or --v");
}

$ENV{HC_OUTPUT_FORMAT} =
    ( $output_format =~ /^(html|text|none)$/ ) ? $output_format : 'none';

my $url = get_url_from_config();

foreach my $g (@G) {
    print "graph=($g)\n";

    my ( $is_hamiltonian, $reason, $params ) = graph_is_hamiltonian($g);

    print "\n\n";
    print "Conclusion: ";
    if ( $is_hamiltonian ) {
        print "The graph is Hamiltonian.\n";
    } else {
        print "The graph is not Hamiltonian.\n";
    }

    print "($reason)\n";

    my $s;
    $s = $params->{calls} == 1 ? "" : "s";
    print qq{It took }, $params->{calls}, qq{ call$s, and };
    $s = $params->{time_elapsed} == 1 ? "" : "s";
    print $params->{time_elapsed}, qq{ second$s.\n\n};

    if ($url) {
        my $is_hamiltonian_per_wolfram = is_hamiltonian_per_wolfram($g);
        if ( $is_hamiltonian != $is_hamiltonian_per_wolfram ) {
            print '<' x 60, " WOLFRAM DIFFERS!\n";
            print "is_hamiltonian=$is_hamiltonian\n";
            print "is_hamiltonian_per_wolfram=$is_hamiltonian_per_wolfram\n";
            print "\n\n";
        } else {
            print '>' x 60, " WOLFRAM CONCURS!\n";
        }
    } else {
        print "...skipped Wolfram cross-check.\n";
    }

    print "\n\n";

}

##############################################################################

sub show_usage_and_exit {

    my $exit_code = 0;
    if ( $_[0] ) {
        print "ERROR: ", $_[0], "\n\n";
        $exit_code = 1;
    }

    print <<END_OF_USAGE_INSTRUCTIONS;

USAGE INSTRUCTIONS:

    perl $0 --help
    or
    perl $0 --h

    Show these usage instructions.



    perl $0 --graph_text <graph_text>
    or
    perl $0 --t <graph_text>

    where <graph_text> is the string representation of a graph whose
    Hamiltonicity is to be tested.
    Example: perl $0 --t 0=1,0=2,1=2



    perl $0 --graph_file <graph_filename>
    or
    perl $0 --f <graph_filename>

    where <graph_filename> is the name of a file containing
    multiple text reprentations of graphs, whose hamiltonicity
    is to be tested.
    Example: perl $0 --f list_of_graphs.txt


    perl $0 --vertices V [ --edges E ] [ --count C ]
    or
    perl $0 --v V [ --e E ] [ --c C ]

    where
    V is the number of vertices in a random Hamiltonian graph
    to be spoofed, and then analyzed for Hamiltonicity.
    E is the number of edges in the spoofed graph. E is optional.
    C is count of times to repeat the spoof and analyze cycle.
    Example: perl $0 --v 20



    You can optionally specify the trace output format with the 
    --output_format or --o command-line option.
    Example: perl $0 --v 42 --o text

    The --o option can be one of 'none', 'text', 'html'
    none: means that the core algorithm is run without any output trace.
          This is the fastest option, and is also the default.
    text: means that the core algorithm should dump a text trace during execution.
          This trace can be redirected to a file, and can provide insight into
          the algorithm. Graphs are represented in text format.
    html: means that the algorithm will dump an HTML trace of its execution.
          Graphs will be represented as inline SVG.
          This is the most computationally intensive choice.



END_OF_USAGE_INSTRUCTIONS

    exit($exit_code);

}

##############################################################################

