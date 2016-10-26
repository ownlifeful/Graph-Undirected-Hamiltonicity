#!perl
use 5.006;
use strict;
use warnings;

use Graph::Undirected::Hamiltonicity::Tests qw(:all);
use Graph::Undirected::Hamiltonicity::Transforms qw(string_to_graph);

use Test::More;

plan tests => 15;

while ( defined ( my $line = <DATA> ) ) {
    next if $line =~ /^\s*#/; ### skip comments
    chomp $line;

    if ( $line =~ /^([^|]+)\|([012])\|([^|]+)\|(\d+=\d+(,\d+=\d+)*)$/ ) {
        my ($test_sub_name, $expected_result, $label, $graph_text ) = ($1, $2, $3, $4);
        my $G = string_to_graph($graph_text);
        no strict 'refs';
        my ( $is_hamiltonian, $reason ) = &$test_sub_name($G);
        use strict 'refs';
        is( $is_hamiltonian, $expected_result, "$test_sub_name: $label");
    }
}

1;



__DATA__
###
### This is where test cases for the subroutines in Graph::Undirected::Hamiltonicity::Tests
### are written, one per line,
### in the format: test_sub_name|expected_result|label|graph_text
###
###
###    test_sub_name: can be one of the many test subroutines
###                   from Graph::Undirected::Hamiltonicity::Tests
###
###    expected_result: can be 0, 1, or 2.
###                     where 0 means DONT_KNOW
###                           1 means GRAPH_IS_HAMILTONIAN
###                           2 means GRAPH_IS_NOT_HAMILTONIAN
###
###    label: can be any string that doesn't contain a pipe ( '|' ) character.
###
###    graph_text: is a string representation of the graph.
###
### Note: Every time you add a test case, remember to update the "plan tests => NUMBER";

# Here are some test cases:
test_connected|0|a simple 3 vertex, 3 edge graph|0=1,0=2,1=2

test_connected|2|a 6 vertex, 6 edge non-connected graph|0=1,0=2,1=2,3=4,3=5,4=5

test_connected|0|Herschel Graph|0=1,0=10,0=3,0=9,10=2,10=8,1=2,1=4,2=5,3=4,3=6,4=5,4=7,5=8,6=7,6=9,7=8,8=9

test_articulation_vertex|0|Herschel Graph|0=1,0=10,0=3,0=9,10=2,10=8,1=2,1=4,2=5,3=4,3=6,4=5,4=7,5=8,6=7,6=9,7=8,8=9

test_articulation_vertex|0|a medium sized graph|0=11,0=6,10=12,10=2,11=13,11=14,11=15,11=9,12=14,12=16,12=19,13=16,13=18,14=5,14=6,15=16,15=2,16=4,16=5,17=18,17=5,17=9,19=2,19=7,1=4,1=8,2=3,3=4,3=5,7=8

test_articulation_vertex|0|a simple 3 vertex, 3 edge graph|0=1,0=2,1=2

test_graph_bridge|0|Herschel Graph|0=1,0=10,0=3,0=9,10=2,10=8,1=2,1=4,2=5,3=4,3=6,4=5,4=7,5=8,6=7,6=9,7=8,8=9

test_graph_bridge|0|a simple 3 vertex, 3 edge graph|0=1,0=2,1=2

test_graph_bridge|0|a medium sized graph|0=11,0=6,10=12,10=2,11=13,11=14,11=15,11=9,12=14,12=16,12=19,13=16,13=18,14=5,14=6,15=16,15=2,16=4,16=5,17=18,17=5,17=9,19=2,19=7,1=4,1=8,2=3,3=4,3=5,7=8

test_canonical|0|Herschel Graph|0=1,0=10,0=3,0=9,10=2,10=8,1=2,1=4,2=5,3=4,3=6,4=5,4=7,5=8,6=7,6=9,7=8,8=9

test_canonical|1|a simple 3 vertex, 3 edge graph|0=1,0=2,1=2

test_canonical|0|a 6 vertex, 6 edge non-connected graph|0=1,0=2,1=2,3=4,3=5,4=5

test_canonical|0|a medium sized graph|0=11,0=6,10=12,10=2,11=13,11=14,11=15,11=9,12=14,12=16,12=19,13=16,13=18,14=5,14=6,15=16,15=2,16=4,16=5,17=18,17=5,17=9,19=2,19=7,1=4,1=8,2=3,3=4,3=5,7=8

test_required_cyclic|2|a 6 vertex, 6 edge non-connected graph|0=1,0=2,1=2,3=4,3=5,4=5

test_required_cyclic|1|a simple 3 vertex, 3 edge graph|0=1,0=2,1=2
