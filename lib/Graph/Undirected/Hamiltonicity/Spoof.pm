package Graph::Undirected::Hamiltonicity::Spoof;

use 5.006;
use strict;
use warnings;

use Carp;
use Graph::Undirected;
use Graph::Undirected::Hamiltonicity::Transforms qw(&add_random_edges &get_random_isomorph);

use Exporter qw(import);

our @EXPORT_OK = qw(
    &spoof_canonical_hamiltonian_graph
    &spoof_known_hamiltonian_graph
    &spoof_random_graph
    &spoof_randomish_graph
);

our %EXPORT_TAGS = ( all => \@EXPORT_OK, );

our $VERSION = '0.01';

##############################################################################

sub spoof_canonical_hamiltonian_graph {
    my ($v) = @_;

    my $last_vertex = $v - 1;
    my @vertices    = ( 0 .. $last_vertex );

    my $g = Graph::Undirected->new( vertices => \@vertices );
    $g->add_edge( 0, $last_vertex );

    for ( my $i = 0; $i < $last_vertex; $i++ ) {
        $g->add_edge( $i, $i + 1 );
    }

    return $g;
}

##############################################################################

sub spoof_known_hamiltonian_graph {
    my ( $v, $e ) = @_;

    croak "Please provide the number of vertices." unless defined $v and $v;
    croak "A graph with 2 vertices cannot be Hamiltonian." if $v == 2;

    $e ||= get_random_edge_count($v);

    croak "The number of edges must be >= number of vertices." if $e < $v;

    my $g = spoof_canonical_hamiltonian_graph($v);
    $g = get_random_isomorph($g);
    $g = add_random_edges( $g, $e - $v );

    return $g;
}

##############################################################################

sub spoof_random_graph {

    my ( $v, $e ) = @_;
    $e ||= get_random_edge_count($v);

    my $g = Graph::Undirected->new( vertices => [ 0 .. $v-1 ] );
    $g = add_random_edges( $g, $e );

    return $g;
}

##############################################################################

sub spoof_randomish_graph {

    my ( $v, $e ) = @_;
    $e ||= get_random_edge_count($v);

    my $g = spoof_random_graph( $v, $e );

    ### Seek out vertices with degree < 2
    ### and add random edges to them.
    my $edges_to_remove = 0;
    foreach my $vertex1 ( $g->vertices() ) {
        next if $g->degree($vertex1) > 1;
        my $added_edge = 0;
        while ( ! $added_edge ) {
            my $vertex2 = int( rand($v) );
            next if $vertex1 == $vertex2;
            next if $g->has_edge($vertex1, $vertex2);
            $g->add_edge($vertex1,$vertex2);
            $added_edge = 1;
            $edges_to_remove++;
        }
    }

    ### Seek out vertices with degree > 2
    ### with neighbor of degree < 3
    ### and delete edges.
    ### Delete the same number of edges,
    ### as the random edges added.
    while ( $edges_to_remove ) {
      LOOP:
        foreach my $vertex1 ( $g->vertices() ) {
            next if $g->degree($vertex1) < 3;

            foreach my $vertex2 ( $g->neighbors($vertex1) ) {
                next if $g->degree($vertex2) < 3;
                $g->delete_edge($vertex1,$vertex2);
                $edges_to_remove--;
                last LOOP;
            }
        }
    }

    return $g;
}

##############################################################################

sub get_random_edge_count {
    my ( $v ) = @_;
    my $max_edges = ( $v * $v - $v ) / 2;
    my $e = int( rand( $max_edges - 2 * $v + 2 ) ) + $v;
    return $e;
}

##############################################################################

1;    # End of Graph::Undirected::Hamiltonicity::Spoof
