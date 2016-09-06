#!perl
use 5.006;
use strict;
use warnings;

use Graph::Undirected;
use Graph::Undirected::Hamiltonicity::Tests qw(:all);
use Graph::Undirected::Hamiltonicity::Transforms qw(string_to_graph);

use Test::More;

plan tests => 3;

while ( defined ( my $line = <DATA> ) ) {
    next if $line =~ /^\s*#/; ### skip comments
    chomp $line;

    if ( $line =~ /^([^|]+)\|([012])\|(\d+=\d+(,\d+=\d+)*)$/ ) {
        my ($label, $expected_result, $graph_text ) = ($1, $2, $3);
        my $G = string_to_graph($graph_text);
        my ( $is_hamiltonian, $reason ) = test_connected($G);
        is( $is_hamiltonian, $expected_result, $label);
    }
}

1;



__DATA__
###
### This is where test cases are written, one per line,
### in the format: label|test_result|graph_text
###
###     label: can be any string.
###
###     test_result: can be 0, 1, or 2.
###                  where 0 means DONT_KNOW
###                        1 means GRAPH_IS_HAMILTONIAN
###                        2 means GRAPH_IS_NOT_HAMILTONIAN
###
###     graph_text: is a string representation of the graph.
###                 examples are included below.
###
### Note: Every time you add a test case, remember to update the "plan tests => NUMBER";

# Here is a test case:
a simple 3 vertex, 3 edge graph|0|0=1,0=2,1=2

a 6 vertex, 6 edge non-connected graph|2|0=1,0=2,1=2,3=4,3=5,4=5

Herschel Graph|0|0=1,0=10,0=3,0=9,10=2,10=8,1=2,1=4,2=5,3=4,3=6,4=5,4=7,5=8,6=7,6=9,7=8,8=9
