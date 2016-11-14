package Graph::Undirected::Hamiltonicity::Spoof;

use 5.006;
use strict;
use warnings;

use Carp;
use Graph::Undirected;
use Graph::Undirected::Hamiltonicity::Transforms qw(add_random_edges shuffle);

use Exporter qw(import);

our @EXPORT_OK = qw(
    &spoof_canonical_hamiltonian_graph
    &spoof_known_hamiltonian_graph
    &spoof_random_graph
    &spoof_randomish_graph
);

our %EXPORT_TAGS = ( all => \@EXPORT_OK, );

=head1 NAME

Graph::Undirected::Hamiltonicity::Spoof - spoof undirected graphs.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Graph::Undirected::Hamiltonicity::Spoof qw(&spoof_known_hamiltonian_graph);

    my $v = 30;
    my $e = 50;
    my $g = spoof_known_hamiltonian_graph($v,$e);

    ### $g is an instance of Graph::Undirected
    ### $g is a random Hamiltonian graph with $v vertices and $e edges.

=head1 EXPORT

No symbols are exported by default.

To load all the subroutines of this package:

    use Graph::Undirected::Hamiltonicity::Spoof qw(:all);

The subroutines that can be imported individually, by name, are:

=over 4

=item * &spoof_canonical_hamiltonian_graph

=item * &spoof_known_hamiltonian_graph

=item * &spoof_random_graph

=back

=head1 SUBROUTINES

=cut

##############################################################################

=head2 spoof_canonical_hamiltonian_graph

Takes: $v, the number of vertices desired.

Returns: a Graph::Undirected with $v vertices, and $v edges.
         This graph is not random, but the canonical,
         ( regular-polygon-shaped ) Hamiltonian Cycle.
=cut

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

=head2 spoof_known_hamiltonian_graph

Spoof a randomized Hamiltonian graph with the specified number of vertices
and edges.

Takes: $v, the number of vertices desired.
       $e, the number of edges desired. ( optional )

Returns: a Graph::Undirected with $v vertices, and $e edges.
         This graph is random, and Hamiltonian.

=cut

sub spoof_known_hamiltonian_graph {

    my ( $v, $e ) = @_;

    croak "Please provide the number of vertices." unless defined $v and $v;
    croak "A graph with 2 vertices cannot be Hamiltonian." if $v == 2;

    $e ||= get_random_edge_count($v);

    croak "The number of edges must be >= number of vertices." if $e < $v;

    my $g = spoof_canonical_hamiltonian_graph($v);
    $g = shuffle($g);
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
    ### add random edges to them.
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

=head1 AUTHOR

Ashwin Dixit, C<< <ashwin at ownlifeful dot com> >>



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Graph::Undirected::Hamiltonicity::Spoof

=cut

1;    # End of Graph::Undirected::Hamiltonicity::Spoof
