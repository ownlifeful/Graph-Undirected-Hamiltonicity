package Graph::Undirected::Hamiltonicity;

use 5.006;
use strict;
use warnings;
no warnings 'recursion';

use Graph::Undirected::Hamiltonicity::Output qw(&output);
use Graph::Undirected::Hamiltonicity::Tests qw(:all);
use Graph::Undirected::Hamiltonicity::Transforms qw(:all);

use Exporter qw(import);

=head1 NAME

Graph::Undirected::Hamiltonicity - decide whether a given Graph::Undirected contains a Hamiltonian Cycle.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

our @EXPORT = qw(graph_is_hamiltonian); # exported by default

our @EXPORT_OK = qw(graph_is_hamiltonian);

our %EXPORT_TAGS = (
    all       =>  \@EXPORT_OK,
);



=head1 SYNOPSIS


This module decides whether a given Graph::Undirected contains a Hamiltonian Cycle.

    use Graph::Undirected;
    use Graph::Undirected::Hamiltonicity;

    ### Create and initialize an undirected graph
    my $graph = new Graph::Undirected( vertices => [ 0..3 ] );
    $graph->add_edge(0,1);
    $graph->add_edge(0,3);
    $graph->add_edge(1,2);
    $graph->add_edge(1,3);
    $graph->add_edge(2,3);

    my $result = graph_is_hamiltonian( $graph );

    print $result->{is_hamiltonian}, "\n";
    # prints 1 if the graph contains a Hamiltonian Cycle, 0 otherwise.

    print $result->{reason}, "\n";
    # prints a brief reason for the conclusion.

=head1 EXPORT

This module exports only one subroutine -- graph_is_hamiltonian()

=head1 SUBROUTINES



=cut

##########################################################################

=head2 graph_is_hamiltonian

Takes a Graph::Undirected object.

Returns a result ( hashref ) indicating whether the given graph
contains a Hamiltonian Cycle.

=cut

sub graph_is_hamiltonian {
    my ($G) = @_;

    my ( $is_hamiltonian, $reason ) = is_hamiltonian( $G );

    my $result = {
        is_hamiltonian => ( ( $is_hamiltonian == $GRAPH_IS_HAMILTONIAN ) ? 1 : 0 ),
        reason         => $reason,
    };

    return $result;
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
    my ($G1) = @_;

    output("<HR NOSHADE>");
    output("Calling is_hamiltonian($G1)");
    output($G1);

    my ( $is_hamiltonian, $reason );

    my @tests_1 = (
        \&test_trivial,      \&test_min_degree,
        \&test_connected,    \&test_articulation_vertex,
        \&test_graph_bridge, # \&test_canonical
    );

    foreach my $test_sub (@tests_1) {
        ( $is_hamiltonian, $reason ) = &$test_sub($G1);
        return ( $is_hamiltonian, $reason )
            unless $is_hamiltonian == $DONT_KNOW;
    }

    ### Create a graph made of only required edges.
    my $required_graph;
    ( $required_graph, $G1 ) = get_required_graph($G1);

    if ( scalar( $required_graph->edges() ) ) {
        output("required graph:");
        output( $required_graph, { required => 1 } );
    } else {
        output("required graph has no edges.<BR/>");        
    }

    ( $is_hamiltonian, $reason ) = test_required($required_graph);
    return ( $is_hamiltonian, $reason ) unless $is_hamiltonian == $DONT_KNOW;

    my $deleted_edges;
    ( $deleted_edges, $G1 ) = delete_unusable_edges($G1);
    if ( $deleted_edges ) {
        # The following is equivalent to:
        # return is_hamiltonian($G1);
        @_ = ( $G1 );
        goto &is_hamiltonian;
    }


    if ( $required_graph->edges() ) {
        output("Now calling test_required_cyclic()<BR/>");
        ( $is_hamiltonian, $reason ) = test_required_cyclic($required_graph);
        return ( $is_hamiltonian, $reason ) unless $is_hamiltonian == $DONT_KNOW;

        output("Now calling deleted_non_required_neighbors()<BR/>");
        ( $deleted_edges, $G1 ) = delete_non_required_neighbors( $required_graph, $G1 );
        if ($deleted_edges) {
            my $s = $deleted_edges == 1 ? '' : 's';
            output("Shrank the graph by removing $deleted_edges edge$s.<BR/>");
            @_ = ( $G1 );
            goto &is_hamiltonian;
        }

        ( $deleted_edges, $G1 ) =
            shrink_required_walks_longer_than_2_edges( $G1, $required_graph );
        if ($deleted_edges) {
            if ( $deleted_edges == 1 ) {
                output("Shrank the graph by removing one vertex and one edge.<BR/>");
            }
            else {
                output("Shrank the graph by removing $deleted_edges edges and vertices.<BR/>");
            }

            @_ = ( $G1 );
            goto &is_hamiltonian;
        }
    }
    
    output("Now running an exhaustive, recursive, and conclusive search, " . 
           "only slightly better than brute force.<BR/>");
    my @undecided_vertices = grep { $G1->degree($_) > 2 } $G1->vertices();
    if ( @undecided_vertices ) {
        my $vertex = 
            get_chosen_vertex($G1, $required_graph, \@undecided_vertices);
        my $tentative_combinations = 
            get_tentative_combinations($G1, $required_graph, $vertex);
        foreach my $tentative_edge_pair ( @$tentative_combinations ) {
            my $G2 = $G1->deep_copy_graph();
            output("For vertex: $vertex, protecting " . 
                   ( join ',', map { "$vertex=$_"  } @$tentative_edge_pair ) .
                   "<BR/>");
            foreach my $neighbor ( $G2->neighbors($vertex) ) {
                next if $neighbor == $tentative_edge_pair->[0];
                next if $neighbor == $tentative_edge_pair->[1];
                output("Deleting edge: $vertex=$neighbor<BR/>");
                $G2->delete_edge($vertex, $neighbor);
            }

            output("The Graph with $vertex=" . $tentative_edge_pair->[0] . 
                   ", $vertex=" . $tentative_edge_pair->[1] . 
                   " protected:<BR/>");
            output($G2);

            ( $is_hamiltonian, $reason ) = is_hamiltonian($G2);
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
    my ($G, $required_graph, $vertex) = @_;
    my @tentative_combinations;
    my @neighbors = $G->neighbors($vertex);
    if ( $required_graph->degree($vertex) == 1 ) {
        my ( $fixed_neighbor ) = $required_graph->neighbors($vertex);

        foreach my $tentative_neighbor ( @neighbors ) {
            next if $fixed_neighbor == $tentative_neighbor;
            push @tentative_combinations,
                [$fixed_neighbor, $tentative_neighbor];
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

sub get_undecided_count {
    my ($G, $required_graph, $vertex) = @_;
    my $count;
    if ( $required_graph->degree($vertex) == 1 ) {
        $count = $G->degree($vertex) - 1;
    } else {
        my $neighbor_count = scalar( $G->neighbors($vertex) );
        $count = $neighbor_count * ( $neighbor_count - 1 ) / 2;
    }

    return $count;
}


##########################################################################

sub get_chosen_vertex {
    my ( $G, $required_graph, $undecided_vertices ) = @_;

    ### Choose the vertex with the highest degree first
    my $chosen_vertex;
    my $chosen_vertex_degree;
    my $chosen_vertex_required_degree;
    foreach my $vertex ( @$undecided_vertices ) {
        my $degree = $G->degree($vertex);
        my $required_degree = $required_graph->degree($vertex);
        if ( ( ! defined $chosen_vertex_degree ) or 
             ( $degree > $chosen_vertex_degree ) or
             ( ($degree == $chosen_vertex_degree) 
               and
               ( $required_degree > $chosen_vertex_required_degree ) ) or
             ( ($degree == $chosen_vertex_degree)
               and
               ( $required_degree == $chosen_vertex_required_degree )
               and ( $vertex < $chosen_vertex ) )
            ) {
            $chosen_vertex = $vertex;
            $chosen_vertex_degree = $degree;
            $chosen_vertex_required_degree = $required_degree;
        }
    }

    return $chosen_vertex;
}

##########################################################################

########################################################################## the END

=head1 AUTHOR

Ashwin Dixit, C<< <ashwin at ownlifeful dot com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-graph-undirected-hamiltonicity at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Undirected-Hamiltonicity>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Graph::Undirected::Hamiltonicity


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Graph-Undirected-Hamiltonicity>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Graph-Undirected-Hamiltonicity>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Graph-Undirected-Hamiltonicity>

=item * Search CPAN

L<http://search.cpan.org/dist/Graph-Undirected-Hamiltonicity/>

=back

=cut

1; # End of Graph::Undirected::Hamiltonicity
