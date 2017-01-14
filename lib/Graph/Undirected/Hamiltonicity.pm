package Graph::Undirected::Hamiltonicity;

# You can get documentation for this module with this command:
#    perldoc Graph::Undirected::Hamiltonicity

use 5.006;
use strict;
use warnings;
no warnings 'recursion';

use Graph::Undirected::Hamiltonicity::Output qw(&output);
use Graph::Undirected::Hamiltonicity::Tests qw(:all);
use Graph::Undirected::Hamiltonicity::Transforms qw(:all);

use Exporter qw(import);

# Graph::Undirected::Hamiltonicity - decide whether a given Graph::Undirected 
# contains a Hamiltonian Cycle.

our $VERSION     = '0.01';
our @EXPORT      = qw(graph_is_hamiltonian);    # exported by default
our @EXPORT_OK   = qw(graph_is_hamiltonian);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );


##########################################################################

# Takes a Graph::Undirected object.
#
# Returns 
#         1 if the given graph contains a Hamiltonian Cycle.
#         0 otherwise.
#

sub graph_is_hamiltonian {
    my ($g) = @_;
    my ( $is_hamiltonian, $reason ) = is_hamiltonian($g);
    my $final_bit = ( $is_hamiltonian == $GRAPH_IS_HAMILTONIAN ) ? 1 : 0;
    return wantarray ? ( $final_bit, $reason ) : $final_bit;
}

##########################################################################

# is_hamiltonian()
#
# Takes a Graph::Undirected object.
#
# Returns a result ( $is_hamiltonian, $reason )
# indicating whether the given graph contains a Hamiltonian Cycle.
#
# This subroutine implements the core of the algorithm.
# Its time complexity is still being calculated.
# If P=NP, then by adding enough polynomial time tests to this subroutine,
# its time complexity can be made polynomial time as well.
#

sub is_hamiltonian {
    my ($g) = @_;

    my $spaced_string = "$g";
    $spaced_string =~ s/\,/, /g;
    output("<HR NOSHADE>");
    output("Calling is_hamiltonian($spaced_string)");
    output($g);

    my ( $is_hamiltonian, $reason );

    my @tests_1 = (
        \&test_trivial,
        \&test_min_degree,
        \&test_dirac,
        \&test_articulation_vertex,
        \&test_graph_bridge,
    );

    foreach my $test_sub (@tests_1) {
        ( $is_hamiltonian, $reason ) = &$test_sub($g);
        return ( $is_hamiltonian, $reason )
            unless $is_hamiltonian == $DONT_KNOW;
    }

    ### Create a graph made of only required edges.
    my $required_graph;
    ( $required_graph, $g ) = get_required_graph($g);

    if ( scalar( $required_graph->edges() ) ) {
        output("required graph:");
        output( $required_graph, { required => 1 } );
    } else {
        output("required graph has no edges.<BR/>");
    }

    ( $is_hamiltonian, $reason ) = test_required($required_graph);
    return ( $is_hamiltonian, $reason ) unless $is_hamiltonian == $DONT_KNOW;

    my $deleted_edges;
    ( $deleted_edges, $g ) = delete_unusable_edges($g);
    if ($deleted_edges) {
        @_ = ($g);
        goto &is_hamiltonian;
    }

    if ( $required_graph->edges() ) {
        output("Now calling test_required_cyclic()<BR/>");
        ( $is_hamiltonian, $reason ) = test_required_cyclic($required_graph);
        return ( $is_hamiltonian, $reason )
            unless $is_hamiltonian == $DONT_KNOW;

        output("Now calling deleted_non_required_neighbors()<BR/>");
        ( $deleted_edges, $g ) =
            delete_non_required_neighbors( $g, $required_graph );
        if ($deleted_edges) {
            my $s = $deleted_edges == 1 ? '' : 's';
            output("Shrank the graph by removing " . 
                   "$deleted_edges"edge$s.<BR/>");
            @_ = ($g);
            goto &is_hamiltonian;
        }

        ( $deleted_edges, $g ) =
            shrink_required_walks_longer_than_2_edges( $g, $required_graph );
        if ($deleted_edges) {
            if ( $deleted_edges == 1 ) {
                output("Shrank the graph by removing 1 vertex " .
                       "and 1 edge.<BR/>");
            } else {
                output(   "Shrank the graph by removing "
                        . "$deleted_edges edges and vertices.<BR/>" );
            }

            @_ = ($g);
            goto &is_hamiltonian;
        }
    }

    output(   "Now running an exhaustive, recursive, and conclusive search, "
            . "only slightly better than brute force.<BR/>" );
    my @undecided_vertices = grep { $g->degree($_) > 2 } $g->vertices();
    if (@undecided_vertices) {
        my $vertex =
            get_chosen_vertex( $g, $required_graph, \@undecided_vertices );

        my $tentative_combinations =
            get_tentative_combinations( $g, $required_graph, $vertex );

        foreach my $tentative_edge_pair (@$tentative_combinations) {
            my $g1 = $g->deep_copy_graph();
            output(   "For vertex: $vertex, protecting "
                    . ( join ',', map {"$vertex=$_"} @$tentative_edge_pair )
                    . "<BR/>" );
            foreach my $neighbor ( $g1->neighbors($vertex) ) {
                next if $neighbor == $tentative_edge_pair->[0];
                next if $neighbor == $tentative_edge_pair->[1];
                output("Deleting edge: $vertex=$neighbor<BR/>");
                $g1->delete_edge( $vertex, $neighbor );
            }

            output(   "The Graph with $vertex="
                    . $tentative_edge_pair->[0]
                    . ", $vertex="
                    . $tentative_edge_pair->[1]
                    . " protected:<BR/>" );
            output($g1);

            ( $is_hamiltonian, $reason ) = is_hamiltonian($g1);
            if ( $is_hamiltonian == $GRAPH_IS_HAMILTONIAN ) {
                return ( $is_hamiltonian, $reason );
            }
        }
    }

    return ( $GRAPH_IS_NOT_HAMILTONIAN,
        "The graph did not pass any tests for Hamiltonicity." );

}

##########################################################################

sub get_tentative_combinations {
    my ( $g, $required_graph, $vertex ) = @_;
    my @tentative_combinations;
    my @neighbors = $g->neighbors($vertex);
    if ( $required_graph->degree($vertex) == 1 ) {
        my ($fixed_neighbor) = $required_graph->neighbors($vertex);

        foreach my $tentative_neighbor (@neighbors) {
            next if $fixed_neighbor == $tentative_neighbor;
            push @tentative_combinations,
                [ $fixed_neighbor, $tentative_neighbor ];
        }

    } else {
        for ( my $i = 0; $i < scalar(@neighbors) - 1; $i++ ) {
            for ( my $j = $i + 1; $j < scalar(@neighbors); $j++ ) {
                push @tentative_combinations,
                    [ $neighbors[$i], $neighbors[$j] ];
            }
        }
    }

    return \@tentative_combinations;
}

##########################################################################

sub get_chosen_vertex {
    my ( $g, $required_graph, $undecided_vertices ) = @_;

    ### Choose the vertex with the highest degree first
    my $chosen_vertex;
    my $chosen_vertex_degree;
    my $chosen_vertex_required_degree;
    foreach my $vertex (@$undecided_vertices) {
        my $degree          = $g->degree($vertex);
        my $required_degree = $required_graph->degree($vertex);
        if (   ( !defined $chosen_vertex_degree )
            or ( $degree > $chosen_vertex_degree )
            or (    ( $degree == $chosen_vertex_degree )
                and ( $required_degree > $chosen_vertex_required_degree ) )
            or (    ( $degree == $chosen_vertex_degree )
                and ( $required_degree == $chosen_vertex_required_degree )
                and ( $vertex < $chosen_vertex ) )
            )
        {
            $chosen_vertex                 = $vertex;
            $chosen_vertex_degree          = $degree;
            $chosen_vertex_required_degree = $required_degree;
        }
    }

    return $chosen_vertex;
}

##########################################################################


1;    # End of Graph::Undirected::Hamiltonicity
