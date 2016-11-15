#!perl
use 5.006;
use strict;
use warnings;

use Graph::Undirected::Hamiltonicity::Spoof
    qw(&spoof_random_graph);

use Test::More;

plan tests => 33;

$ENV{HC_OUTPUT_FORMAT} = 'none';

for my $v ( 3 .. 13 ) {
    my $g = spoof_random_graph($v);
    is( scalar( $g->vertices() ), $v, "Spoofed random graph has $v vertices." );
}

for my $v ( 10 .. 20 ) {
    my $e = 2 * $v;
    my $g = spoof_random_graph( $v, $e );
    is( scalar( $g->vertices() ), $v, "Spoofed random graph has $v vertices." );
    is( scalar( $g->edges() ),    $e, "Spoofed random graph has $e edges." );
}

