package Graph::Undirected::Hamiltonicity;

use 5.006;
use strict;
use warnings;

use Graph::Undirected;
use Graph::Undirected::Hamiltonicity::Output qw(output);
use Graph::Undirected::Hamiltonicity::Tests qw(:all);
use Graph::Undirected::Hamiltonicity::Transforms qw(:all);
use Bit::Vector;
use Data::Dumper;
use Exporter qw(import);

=head1 NAME

Graph::Undirected::Hamiltonicity - Decide, in Polynomial Time, whether a given Graph::Undirected contains a Hamiltonian Cycle.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

our @EXPORT = qw(graph_is_hamiltonian); # exported by default

our @EXPORT_OK = qw(
                graph_is_hamiltonian
                );

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

    mark_required_edges($G1);

    ### Create a graph made of only required edges.
    my $required_graph = get_required_graph($G1);

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

        ( $deleted_edges, $G1 ) = delete_non_required_neighbors( $required_graph, $G1 );
        if ($deleted_edges) {
            my $s = $deleted_edges == 1 ? '' : 's';
            output("Shrank the graph by removing $deleted_edges edge$s.<BR/>");
            return is_hamiltonian($G1);
        }

        my ( $shrank_graph, $G2 ) =
            shrink_required_walks_longer_than_2_edges( $required_graph, $G1 );
        if ($shrank_graph) {
            if ( $shrank_graph == 1 ) {
                output("Shrank the graph by removing one vertex and one edge.<BR/>");
            }
            else {
                output("Shrank the graph by removing $shrank_graph edges and vertices.<BR/>");
            }

            return is_hamiltonian($G2);
        }

        ####################### BEGIN
#        my @maximization_steps;
#        ( $required_graph, @maximization_steps ) = maximize($required_graph);
#
#        output("The maximized required graph is as shown below:<BR/>");
#        output("$required_graph<BR/>" );
#        output( $required_graph, { required => 1 } );
#
#        my $maximized_flag = scalar(@maximization_steps) ? 1 : 0;
#
#        while ( scalar(@maximization_steps) ) {
#            my $i = shift @maximization_steps;
#            my $j = shift @maximization_steps;
#            $G1 = swap_vertices($G1, $i, $j);
#        }
#
#        if ( $maximized_flag ) {
#            mark_required_edges($G1);
#            output("The graph with the same transforms applied, is as shown below:<BR/>");
#            output($G1);
#        }
#
        ####################### END

    }

    ( $is_hamiltonian, $reason ) = test_canonical($G1);
    return ( $is_hamiltonian, $reason ) unless $is_hamiltonian == $DONT_KNOW;
    
    ### zzz
    output("Now running an exhaustive, recursive, and conclusive search, only slightly better than brute force.<BR/>"); ### DEBUG

    my %gain;
    foreach my $vertex ( @vertices ) {
        $gain{$vertex} = $G1->degree($vertex) - $required_graph->degree($vertex);
    }

    my @sorted_vertices = sort {
        $gain{$b} <=> $gain{$a}
        ||
        $a <=> $b
    } 
    grep {
        $G1->degree($_) > 2
    } @vertices;

    foreach my $vertex ( @sorted_vertices ) {
        my $G3 = $G1->deep_copy_graph();
        my @neighbors = $G3->neighbors($vertex);

        output("vertex=$vertex<BR/>"); ### DEBUG
        output("...has degree=" . $required_graph->degree($vertex) . "; in the required graph<BR/>"); ### DEBUG
        output("...has neighbors=( " . ( join ", ", @neighbors ) . " )<BR/>"); ### DEBUG

        my @selected_neighbors = ( 1 == $required_graph->degree($vertex) ) 
            ? ( $required_graph->neighbors($vertex) )
            : @neighbors;

        output("selected_neighbors=(" . (join ",", @selected_neighbors) . ")<BR/>"); ### DEBUG

        foreach my $protected_vertex_1 ( @selected_neighbors ) {
            unless ( $G3->has_edge($vertex, $protected_vertex_1) ) {
                output("<h2>Assertion on line:" . __LINE__ . " failed for $vertex=$protected_vertex_1</h2>"); ### DEBUG
            }

            foreach my $protected_vertex_2 ( @neighbors ) {
                next if $protected_vertex_2 == $protected_vertex_1;
                unless ( $G3->has_edge($vertex, $protected_vertex_2) ) {
                    output("<h2>Assertion on line:" . __LINE__ . " failed for $vertex=$protected_vertex_2</h2>"); ### DEBUG
                }
                output("Protecting edges: $vertex=$protected_vertex_1, $vertex=$protected_vertex_2<BR/>");
                foreach my $neighbor ( @neighbors ) {
                    next if $neighbor == $protected_vertex_1;
                    next if $neighbor == $protected_vertex_2;
                    output("Deleting edge: $vertex=$neighbor<BR/>");
                    $G3->delete_edge($vertex, $neighbor);
                }

                output("The Graph with $vertex=$protected_vertex_1, $vertex=$protected_vertex_2 protected:<BR/>");
                output($G3);

                ( $is_hamiltonian, $reason ) = is_hamiltonian($G3);
                return ( $is_hamiltonian, $reason )
                    if $is_hamiltonian == $GRAPH_IS_HAMILTONIAN;

            }
        }
    }


    return ( $GRAPH_IS_NOT_HAMILTONIAN, "The graph passed all tests." );

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


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Ashwin Dixit.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Graph::Undirected::Hamiltonicity
