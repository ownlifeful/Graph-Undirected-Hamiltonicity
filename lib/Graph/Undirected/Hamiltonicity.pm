package Graph::Undirected::Hamiltonicity;

use 5.006;
use strict;
use warnings;

use Graph::Undirected::Hamiltonicity::Output qw(output);
use Graph::Undirected::Hamiltonicity::Tests qw(:all);
use Graph::Undirected::Hamiltonicity::Transforms qw(:all);

use Exporter qw(import);

=head1 NAME

Graph::Undirected::Hamiltonicity - Decide, in Polynomial Time, whether a given Graph::Undirected contains a Hamiltonian Cycle.

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


This module, which is mostly of esoteric interest, is dedicated to the Quixotic quest of determining whether "P=NP". 
It attempts to decide whether a given Graph::Undirected contains a Hamiltonian Cycle.

    use Graph::Undirected;
    use Graph::Undirected::Hamiltonicity;

    ### Create and initialize a Graph::Undirected
    my $graph = new Graph::Undirected( vertices => [ 1..4 ] );
    $graph->add_edge(1,2);
    $graph->add_edge(2,3);
    $graph->add_edge(3,4);
    $graph->add_edge(1,4);
    $graph->add_edge(1,3);

    my $result = graph_is_hamiltonian( $graph );

    print $result->{is_hamiltonian}, "\n";
    # prints 1 if the graph contains a Hamiltonian Cycle, 0 otherwise.

    print $result->{reason}, "\n";
    # prints a brief reason for the conclusion.

    # if graph is hamiltonian, a solution Hamiltonian Cycle is returned.
    if ( $result->{is_hamiltonian} ) {
        foreach my $solution_ref ( @{ $result->{solutions} } ) {
            print join ",", @$solution_ref;
            print "\n";
        }
    }


=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.


=cut

########################################################################## the BEGIN

our $DEBUG = 0;

##########################################################################

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

    if ( $result->{is_hamiltonian} ) {
        $result->{solutions} = [];
    }

    return $result;
}


##########################################################################

=head2 is_hamiltonian

Takes a Graph::Undirected object.

Returns a result ( is_hamiltonian, reason ) indicating whether the given graph
contains a Hamiltonian Cycle.

=cut

sub is_hamiltonian {
    my ($G) = @_;

    output("<HR NOSHADE>");
    output("Calling is_hamiltonian($G)");
    output($G);

    my $G1        = $G->deep_copy_graph();
    my $e         = scalar( $G1->edges() );
    my @vertices  = $G1->vertices;
    my $v         = @vertices;
    my $max_edges = ( $v * $v - $v ) / 2;
    my ( $is_hamiltonian, $reason );

    my @tests_1 = (
        \&test_trivial,      \&test_min_degree,
        \&test_connected,    \&test_articulation_vertex,
        \&test_graph_bridge, \&test_canonical
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
    return is_hamiltonian($G1) if $deleted_edges;

    if ( $required_graph->edges() ) {
        output("Now calling test_required_cyclic()<BR/>"); ### DEBUG

        ( $is_hamiltonian, $reason ) = test_required_cyclic($required_graph);
        return ( $is_hamiltonian, $reason ) unless $is_hamiltonian == $DONT_KNOW;

        output("Now calling deleted_non_required_neighbors()<BR/>"); ### DEBUG
        ( $deleted_edges, $G1 ) = delete_non_required_neighbors( $required_graph, $G1 );
        if ($deleted_edges) {
            my $s = $deleted_edges == 1 ? '' : 's';
            output("Shrank the graph by removing $deleted_edges edge$s.<BR/>");
            return is_hamiltonian($G1);
        }

        my ( $shrank_graph, $G1 ) =
            shrink_required_walks_longer_than_2_edges( $required_graph, $G1 );
        if ($shrank_graph) {
            if ( $shrank_graph == 1 ) {
                output("Shrank the graph by removing one vertex and one edge.<BR/>");
            }
            else {
                output("Shrank the graph by removing $shrank_graph edges and vertices.<BR/>");
            }

            return is_hamiltonian($G1);
        }

    }
    
    output("Now running an exhaustive, recursive, and conclusive search, only slightly better than brute force.<BR/>"); ### DEBUG

    ####################################### BEGIN 2

    use Data::Dumper; ### DEBUG


    my @undecided_vertices = grep { $G1->degree($_) > 2 } $G1->vertices();

    if ( @undecided_vertices ) {

        ### Choose the vertex with the highest degree first
        my ( $chosen_vertex, $chosen_vertex_degree, $chosen_vertex_required_degree );
        foreach my $vertex ( @undecided_vertices ) {
            my $degree = $G1->degree($vertex);
            my $required_degree = $required_graph->degree($vertex);
            if ( ( ! defined $chosen_vertex_degree ) or 
                 ( $degree > $chosen_vertex_degree ) or
                 ( ($degree == $chosen_vertex_degree) and ( $required_degree > $chosen_vertex_required_degree ) ) or
                 ( ($degree == $chosen_vertex_degree) and ( $required_degree == $chosen_vertex_required_degree ) and ( $vertex < $chosen_vertex ) )
                ) {
                $chosen_vertex = $vertex;
                $chosen_vertex_degree = $degree;
                $chosen_vertex_required_degree = $required_degree;
            }
        }

        my $vertex = $chosen_vertex;
        my @tentative_combinations = get_tentative_combinations($G1, $required_graph, $vertex);

        foreach my $tentative_edge_pair ( @tentative_combinations ) {

            my $G2 = $G1->deep_copy_graph();

            foreach my $i ( 0 .. 1 ) {
                unless ( $G2->has_edge($vertex, $tentative_edge_pair->[$i] ) ) {
                    output("<h2>Assertion failed. Missing edge. $vertex=" . $tentative_edge_pair->[$i] ."</h2>\n")  ### DEBUG
                }
            }

            output("For vertex=$vertex <PRE>" . Dumper(\@tentative_combinations) . "</PRE><BR/>"); ### DEBUG

            output("For vertex: $vertex, protecting " . ( join ',', map { "$vertex=$_"  } @$tentative_edge_pair ) . "<BR/>"); ### DEBUG

            foreach my $neighbor ( $G2->neighbors($vertex) ) {
                next if $neighbor == $tentative_edge_pair->[0];
                next if $neighbor == $tentative_edge_pair->[1];
                output("Deleting edge: $vertex=$neighbor<BR/>");
                $G2->delete_edge($vertex, $neighbor);
            }

            output("The Graph with $vertex=" . $tentative_edge_pair->[0] . 
                   ", $vertex=" . $tentative_edge_pair->[1] . " protected:<BR/>");
            output($G2);


            ( $is_hamiltonian, $reason ) = is_hamiltonian($G2);
            if ( $is_hamiltonian == $GRAPH_IS_HAMILTONIAN ) {
                return ( $is_hamiltonian, $reason );
            }
        }

    }
    ####################################### END 2


    return ( $GRAPH_IS_NOT_HAMILTONIAN, "The graph did not pass any tests for Hamiltonicity." );

}

##########################################################################
sub get_tentative_combinations {
    my ($G, $required_graph, $vertex) = @_;
    my @tentative_combinations;
    if ( $required_graph->degree($vertex) == 1 ) {
        my ( $fixed_neighbor ) = $required_graph->neighbors($vertex);

        foreach my $tentative_neighbor ( $G->neighbors($vertex) ) {
            next if $fixed_neighbor == $tentative_neighbor;
            push @tentative_combinations, [$fixed_neighbor, $tentative_neighbor];
        }

    } else {
        my @neighbors = $G->neighbors($vertex);
        for ( my $i = 0; $i < scalar(@neighbors) - 1; $i++ ) {
            for ( my $j = $i + 1; $j < scalar(@neighbors); $j++ ) {
                push @tentative_combinations, [ $neighbors[$i], $neighbors[$j] ];
            }
        }
    }

    return @tentative_combinations;
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
