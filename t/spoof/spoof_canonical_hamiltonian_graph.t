#!perl
use Modern::Perl;

use Graph::Undirected::Hamiltonicity;
use Graph::Undirected::Hamiltonicity::Spoof;
use Graph::Undirected::Hamiltonicity::Tests;

use Test::More;

plan tests => 30;

$ENV{HC_OUTPUT_FORMAT} = 'none';

for my $v ( 1 .. 10 ) {
    my $g = Graph::Undirected::Hamiltonicity::Spoof::spoof_canonical_hamiltonian_graph($v);
    is( scalar( $g->vertices() ), $v, "Spoofed graph has $v vertices." );
    my $g1g = Graph::Undirected::Hamiltonicity->new(graph=>$g);
    my ( $is_hamiltonian, $reason ) = $g1g->test_canonical();

    if ( $v == 2 ) {
        is( scalar( $g->edges() ), 1, "Spoofed graph has 1 edge." );
    } else {
        is( scalar( $g->edges() ), $v, "Spoofed graph has $v edges." );
    }

    ### The result is counter-intuitive, for v == 2, but it makes sense in context.
    is( $is_hamiltonian, $Graph::Undirected::Hamiltonicity::GRAPH_IS_HAMILTONIAN,
        "Spoofed graph is a canonical Hamiltonian Cycle." );

}
