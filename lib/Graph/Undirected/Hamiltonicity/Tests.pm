package Graph::Undirected::Hamiltonicity::Tests;

use 5.006;
use strict;
use warnings;

use Exporter qw(import);

use Graph::Undirected::Hamiltonicity::Transforms qw(:all);
use Graph::Undirected::Hamiltonicity::Output qw(:all);

our $DONT_KNOW                = 0;
our $GRAPH_IS_HAMILTONIAN     = 1;
our $GRAPH_IS_NOT_HAMILTONIAN = 2;

our @EXPORT = qw($DONT_KNOW $GRAPH_IS_HAMILTONIAN $GRAPH_IS_NOT_HAMILTONIAN);

our @EXPORT_OK =  qw(
           $DONT_KNOW
           $GRAPH_IS_HAMILTONIAN
           $GRAPH_IS_NOT_HAMILTONIAN
           &test_articulation_vertex
           &test_canonical
           &test_connected
           &test_graph_bridge
           &test_min_degree
           &test_required
           &test_required_cyclic
           &test_required_cyclic_new
           &test_trivial
        );

our %EXPORT_TAGS = (
    all       =>  [ @EXPORT, @EXPORT_OK ],
);


=head1 NAME

Graph::Undirected::Hamiltonicity::Tests - a collection of subroutines that try to 
detect whether the input Graph::Undirected is Hamiltonian.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Each subroutine in this module:

Takes: a Graph::Undirected

Returns: ($is_hamilton, $reason)

    $is_hamilton can be one of: $DONT_KNOW, $GRAPH_IS_HAMILTONIAN, $GRAPH_IS_NOT_HAMILTONIAN

    $reason is a string describing the reason for the test conclusion, if any.


Here is an example:

    use Graph::Undirected::Hamiltonicity::Tests qw(test_trivial);
    use Graph::Undirected::Hamiltonicity::Spoof qw(spoof_known_hamiltonian_graph);

    my $G = spoof_known_hamiltonian_graph(30, 50); ### 30 vertices, 50 edges

    my ( $is_hamiltonian, $reason ) = test_trivial($G);
    ...

=head1 EXPORT

Symbols exported by default are:

=over 4

=item * $DONT_KNOW

=item * $GRAPH_IS_HAMILTONIAN

=item * $GRAPH_IS_NOT_HAMILTONIAN

=back

All subroutines can be loaded with the qw(:all) tag.

    use Graph::Undirected::Hamiltonicity::Tests qw(:all);

The subroutines that can be imported individually, by name, are:

=over 4

=item * &test_articulation_vertex

=item * &test_canonical

=item * &test_connected

=item * &test_graph_bridge

=item * &test_min_degree

=item * &test_required

=item * &test_required_cyclic

=item * &test_required_cyclic_new

=item * &test_trivial

=back

=head1 SUBROUTINES


=cut

##########################################################################

=head2 test_trivial

Takes a Graph::Undirected and applies some constant-time tests
for Hamiltonicity.

=cut

sub test_trivial {
    my ($G) = @_;

    my @edges     = $G->edges;
    my $e         = @edges;
    my @vertices  = $G->vertices;
    my $v         = @vertices;
    my $max_edges = ( $v * $v - $v ) / 2;

    if ( $v == 1 ) {
        return ( $GRAPH_IS_HAMILTONIAN,
                  "By convention, a graph with a single vertex is "
                . "considered to be Hamiltonian." );
    }

    if ( $v < 3 ) {
        return ( $GRAPH_IS_NOT_HAMILTONIAN,
            "A graph with 0 or 2 vertices cannot be Hamiltonian." );
    }

    if ( $e < $v ) {
        return ( $GRAPH_IS_NOT_HAMILTONIAN,
            "e < v, therefore the graph is not Hamiltonian. e=$e, v=$v" );
    }

    ### If e > ( ( v * ( v - 1 ) / 2 ) - ( v - 2 ) )
    ### the graph definitely has an HC.
    if ( $e > ( $max_edges - $v + 2 ) ) {
        my $reason = "If e > ( (v*(v-1)/2)-(v-2)), the graph is Hamiltonian.";
        $reason .= " For v=$v, e > ";
        $reason .= $max_edges - $v + 2;
        return ( $GRAPH_IS_HAMILTONIAN, $reason );
    }

    return $DONT_KNOW;

}

##########################################################################

=head2 test_canonical

Tests to see if the input Graph::Undirected is a super-graph of the
"canonical" Hamiltonian Cycle.

The "canonical" Hamiltonian Cycle is an isomorph of a graph
in which all the edges can be arranged into a regular polygon.

=cut

sub test_canonical {
    my ( $G ) = @_;
    my @vertices  = sort { $a <=> $b } $G->vertices();
    my $v         = scalar(@vertices);

    if ( $G->has_edge( $vertices[0] , $vertices[-1] ) ) {
        for (my $counter = 0; $counter < $v - 1; $counter++ ) {
            unless ( $G->has_edge( $vertices[$counter] , 
                                    $vertices[ $counter + 1 ] ) ) {
                return ( $DONT_KNOW,
                         "This graph is not a supergraph of " . 
                         "the canonical Hamiltonian Cycle." );
            }
        }
        return ( $GRAPH_IS_HAMILTONIAN,
                 "This graph is a supergraph of " . 
                 "the canonical Hamiltonian Cycle." );               
    } else {
        return ( $DONT_KNOW,
                 "This graph is not a supergraph of " . 
                 "the canonical Hamiltonian Cycle." );
    }
}

##########################################################################

=head2 test_min_degree

If the graph has a vertex with degree < 2, the graph does not have a
Hamiltonian Cycle.

=cut

sub test_min_degree {
    my ($G) = @_;

    foreach my $vertex ( $G->vertices ) {
        if ( $G->degree($vertex) < 2 ) {
            return ( $GRAPH_IS_NOT_HAMILTONIAN,
                "This graph has a vertex ($vertex) with degree < 2" );
        }
    }

    return $DONT_KNOW;
}

##########################################################################


=head2 test_connected

If the graph is not connected, it does not contain a Hamiltonian Cycle.

=cut

### Implented this subroutine to allow for a different implementation
### of is_connected(), in the future.

sub test_connected {
    my ($G) = @_;
    unless ( $G->is_connected() ) {
        return ( $GRAPH_IS_NOT_HAMILTONIAN,
            "This graph is not connected, therefore not Hamiltonian" );
    }

    return $DONT_KNOW;
}

##########################################################################

=head2 test_articulation_vertex

If the graph contains a vertex, removing which would make the graph
unconnected, the graph is not Hamiltonian.

Such a vertex is called an Articulation Vertex.

=cut

sub test_articulation_vertex {
    my ($G) = @_;

    foreach my $vertex ( $G->vertices() ) {
        my $G1 = $G->deep_copy_graph;
        $G1->delete_vertex($vertex);
        unless ( $G1->is_connected() ) {
            return ( $GRAPH_IS_NOT_HAMILTONIAN,
                      "This graph contains a vertex ( $vertex ), "
                    . "removing which would make it not connected." );
        }
    }

    return $DONT_KNOW;
}

##########################################################################


=head2 test_graph_bridge

If the graph contains an edge, removing which would make the graph
unconnected, the graph is not Hamiltonian.

Such an edge is called a Graph Bridge.

=cut

sub test_graph_bridge {
    my ($G) = @_;

    foreach my $edge ( $G->edges() ) {
        my $G1 = $G->deep_copy_graph;
        $G1->delete_edge($edge);

        unless ( $G1->is_connected() ) {
            output($G1);    ### DEBUG
            my $edge_string = sprintf "%d=%d", @$edge;
            return ( $GRAPH_IS_NOT_HAMILTONIAN,
                      "This graph contains an edge ($edge_string), "
                    . "removing which would make it not connected." );
        }
    }

    return $DONT_KNOW;
}

##########################################################################

=head2 test_required

Takes a Graph::Undirected, which is the "required graph" of the input.
The "required graph" contains the same vertices as the input graph, but
only the edges that the algorithm has marked "required".

If any vertex in the "required graph" has a degree of more than 2,
then the input graph cannot be Hamiltonian.

=cut

sub test_required {
    my ( $required_graph ) = @_;

    foreach my $vertex ( $required_graph->vertices() ) {
        my $degree = $required_graph->degree($vertex);
        if ( $degree > 2 ) {
            return ( $GRAPH_IS_NOT_HAMILTONIAN,
                      "Vertex $vertex is required by $degree edges. "
                    . "It can only be required by upto 2 edges." );
        }
    }

    return $DONT_KNOW;
}

##########################################################################

=head2 test_required_cyclic

If the "required graph" contains a cycle with fewer than v vertices,
then the input graph is not Hamiltonian.

=cut

sub test_required_cyclic {
    test_required_cyclic_old(@_);
    ### test_required_cyclic_new(@_);
}

##########################################################################

sub test_required_cyclic_old {

    ### Test: If the graph of required edges only has a cycle consisting
    ### of < v vertices, the graph is not Hamiltonian.

    my ($required_graph) = @_;

    return $DONT_KNOW if $required_graph->is_acyclic();

    my $v = scalar( $required_graph->vertices() );

    my @cycle                       = $required_graph->find_a_cycle();
    my $number_of_vertices_in_cycle = scalar(@cycle);
    if ( $number_of_vertices_in_cycle > 0 ) {
        my $cycle_string = join ', ', @cycle;
        output( $required_graph, { required => 1 } );

        if ( $number_of_vertices_in_cycle < $v ) {
            return ( $GRAPH_IS_NOT_HAMILTONIAN,
                      "The sub-graph of required edges has a cycle "
                    . "[$cycle_string] with fewer than $v vertices." );
        }
        elsif ( $number_of_vertices_in_cycle == $v ) {
            return ( $GRAPH_IS_HAMILTONIAN,
                      "The sub-graph of required edges has a cycle "
                    . "[$cycle_string] with $v vertices." );
        }
    }

    return $DONT_KNOW;
}

##########################################################################


sub test_required_cyclic_new {

    ### Test: If the graph of required edges only, has a cycle consisting
    ### of < v vertices, the graph is not Hamiltonian.

    my ($required_graph) = @_;

    return $DONT_KNOW if $required_graph->is_acyclic();

    my %potential_cycles;

    foreach my $vertex ( $required_graph->vertices() ) {
        next unless $required_graph->degree($vertex) == 2;
        $potential_cycles{$vertex} = 1;
    }

    foreach my $vertex ( sort { $a <=> $b } ( keys %potential_cycles ) ) {
        my (@neighbors) =
            sort { $a <=> $b } ( $required_graph->neighbors($vertex) );
        my ( %visited, @cycle );

        $visited{$vertex} = 1;
        push @cycle, $vertex;

        foreach my $neighbor (@neighbors) {
            ### First, check to see if we have already
            ### visited this vertex. If so, we have found
            ### a cycle.
            if ( $visited{$neighbor} ) {
                last;
            }

            if ( $required_graph->degree($neighbor) == 2 ) {
                ### Store this neighbor in a cycle.
                push @cycle, $neighbor;
                $visited{$neighbor} = 1;
            }
            else {
                ### A degree 1 neighbor. Abandon this walk.
                ### This set of vertices does not form a cycle.
                @cycle   = ();
                %visited = ();
            }
        }

        my $number_of_vertices_in_cycle = scalar(@cycle);
        my $v = scalar( $required_graph->vertices() );
        if ( $number_of_vertices_in_cycle > 2 ) {
            my $cycle_string = join ', ', @cycle;
            if ( $number_of_vertices_in_cycle < $v ) {
                output( $required_graph, { required => 1 } );
                return ( $GRAPH_IS_NOT_HAMILTONIAN,
                          "The sub-graph of required edges has a cycle "
                        . "[$cycle_string] with fewer than $v vertices." );
            }
            elsif ( $number_of_vertices_in_cycle == $v ) {
                return ( $GRAPH_IS_HAMILTONIAN,
                          "The sub-graph of required edges has a cycle "
                        . "[$cycle_string] which covers all $v vertices." );
            }
        }

    }

    return $DONT_KNOW;
}

##########################################################################

=head1 AUTHOR

Ashwin Dixit, C<< <ashwin at ownlifeful dot com> >>

=head1 BUGS

No open bugs as of this writing.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Graph::Undirected::Hamiltonicity::Tests


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

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Ashwin Dixit.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1; # End of Graph::Undirected::Hamiltonicity::Tests
