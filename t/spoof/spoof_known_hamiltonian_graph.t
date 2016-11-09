#!perl
use 5.006;
use strict;
use warnings;

use Graph::Undirected::Hamiltonicity qw(:all);
use Graph::Undirected::Hamiltonicity::Spoof qw(&spoof_known_hamiltonian_graph);

use Test::More;

plan tests => 22;

$ENV{HC_OUTPUT_FORMAT} = 'none';

for my $v ( 3 .. 13 ) {
    my $G = spoof_known_hamiltonian_graph($v);
    is( scalar( $G->vertices() ), $v, "Spoofed graph has $v vertices.");
    my $result = graph_is_hamiltonian( $G );
    is( $result->{is_hamiltonian}, 1,  "Spoofed graph is Hamiltonian");
}
