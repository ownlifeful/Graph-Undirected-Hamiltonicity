#!perl
use Modern::Perl;

use Graph::Undirected::Hamiltonicity::Spoof
    qw(&spoof_random_graph);

use Test::More;

plan tests => 33;

$ENV{HC_OUTPUT_FORMAT} = 'none';

for my $v ( 3 .. 13 ) {
    my $self = Graph::Undirected::Hamiltonicity::Spoof::spoof_random_graph($v);
    is( scalar( $self->{g}->vertices() ), $v, "Spoofed random graph has $v vertices." );
}

for my $v ( 10 .. 20 ) {
    my $max_edges = ( $v * $v - $v ) / 2;
    my $e = int( rand( $max_edges ) );
    my $self = Graph::Undirected::Hamiltonicity::Spoof::spoof_random_graph( $v, $e );
    is( scalar( $self->{g}->vertices() ), $v, "Spoofed random graph has $v vertices." );
    is( scalar( $self->{g}->edges() ),    $e, "Spoofed random graph has $e edges." );
}

