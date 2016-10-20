#!perl
use 5.006;
use strict;
use warnings;

use Graph::Undirected::Hamiltonicity;
use Graph::Undirected::Hamiltonicity::Transforms qw(&string_to_graph &shuffle);

use Test::More;

plan tests => 9;

while ( defined ( my $line = <DATA> ) ) {
    next if $line =~ /^\s*#/; ### skip comments
    chomp $line;

    if ( $line =~ /^([^|]+)\|(\d+=\d+(,\d+=\d+)*)$/ ) {
        my ( $label, $graph_text ) = ($1, $2);

        ### A shuffled graph is very likely to be different from the original, but it's not 100% guaranteed.
        my $before_graph = string_to_graph($graph_text);
        my $after_graph = shuffle($before_graph);
        isnt( "$before_graph", "$after_graph", "[$label] probably different after shuffle()");

        ### The distribution of degrees in the graph remains unchanged after shuffle.
        my %before_degree_hash = get_degree_hash($before_graph);
        my %after_degree_hash = get_degree_hash($after_graph);
        is_deeply( \%before_degree_hash, \%after_degree_hash, "[$label] degree hash unchanged after shuffle()");

        ### The Hamiltonicity of the graphj remains unchanged after shuffle
        my $before_result = graph_is_hamiltonian($before_graph);
        my $after_result = graph_is_hamiltonian($after_graph);
        is( $before_result->{is_hamiltonian}, $after_result->{is_hamiltonian}, "[$label] Hamiltonicity unchanged after shuffle()" );
    }
}

##########################################################################

sub get_degree_hash {
    my ( $G ) = @_;

    my %degree_hash;
    foreach my $vertex ( $G->vertices() ) {
        $degree_hash{ $G->degree( $vertex ) }++;
    }

    return %degree_hash;
}

##########################################################################

__DATA__
###
### This is where test cases for the subroutines in Graph::Undirected::Hamiltonicity::Transforms::shuffle()
### are written, one per line,
### in the format: label|graph_text
###
###
###    label: can be any string that doesn't contain a pipe ( '|' ) character.
###
###    graph_text: is a string representation of the graph.
###
### Note: Every time you add a test case, remember to update the "plan tests => NUMBER";

# Here are some test cases:
Herschel Graph|0=1,0=10,0=3,0=9,10=6,10=8,1=2,1=4,2=5,2=9,3=4,3=6,4=5,4=7,5=8,6=7,7=8,8=9

Nested Square Frames Graph|0=1,0=2,0=6,1=3,1=7,2=3,2=4,3=5,4=5,5=7

Octagon in Square Graph|0=1,0=4,1=2,1=4,2=3,2=5,3=5,4=6,5=7,6=8,6=9,7=10,7=11,8=9,9=10,10=11

#Tiny Square Graph|0=1,0=2,1=2,1=3,2=3

#Some graph|0=1,3=4,0=6,2=4,3=5
