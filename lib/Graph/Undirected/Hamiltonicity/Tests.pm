package Graph::Undirected::Hamiltonicity::Tests;

use 5.006;
use strict;
use warnings;
no warnings 'recursion';

use Exporter qw(import);

use Graph::Undirected::Hamiltonicity::Transforms qw(:all);
use Graph::Undirected::Hamiltonicity::Output qw(:all);

our $DONT_KNOW                = 0;
our $GRAPH_IS_HAMILTONIAN     = 1;
our $GRAPH_IS_NOT_HAMILTONIAN = 2;

our @EXPORT = qw($DONT_KNOW $GRAPH_IS_HAMILTONIAN $GRAPH_IS_NOT_HAMILTONIAN);

our @EXPORT_OK = (
    @EXPORT, qw(
        &test_articulation_vertex
        &test_canonical
        &test_dirac
        &test_graph_bridge
        &test_min_degree
        &test_ore
        &test_required
        &test_required_cyclic
        &test_trivial
        )
);

our %EXPORT_TAGS = ( all => \@EXPORT_OK );


our $VERSION = '0.01';


##########################################################################

sub test_trivial {
    my ($g) = @_;

    my $e         = scalar( $g->edges );
    my $v         = scalar( $g->vertices );
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

sub test_canonical {
    my ($g) = @_;
    my @vertices = sort { $a <=> $b } $g->vertices();
    my $v = scalar(@vertices);

    if ( $g->has_edge( $vertices[0], $vertices[-1] ) ) {
        for ( my $counter = 0; $counter < $v - 1; $counter++ ) {
            unless (
                $g->has_edge(
                    $vertices[$counter], $vertices[ $counter + 1 ]
                )
                )
            {
                return ( $DONT_KNOW,
                          "This graph is not a supergraph of "
                        . "the canonical Hamiltonian Cycle." );
            }
        }
        return ( $GRAPH_IS_HAMILTONIAN,
                  "This graph is a supergraph of "
                . "the canonical Hamiltonian Cycle." );
    } else {
        return ( $DONT_KNOW,
                  "This graph is not a supergraph of "
                . "the canonical Hamiltonian Cycle." );
    }
}

##########################################################################


sub test_min_degree {
    my ($g, $params) = @_;

    foreach my $vertex ( $g->vertices ) {
        if ( $g->degree($vertex) < 2 ) {

            my $reason = $params->{transformed} 
            ? "After removing edges according to constraints, this graph " 
                . "was found to have a vertex ($vertex) with degree < 2"
                : "This graph has a vertex ($vertex) with degree < 2";

            return ( $GRAPH_IS_NOT_HAMILTONIAN, $reason, $params );
        }
    }

    return $DONT_KNOW;
}

##########################################################################

sub test_articulation_vertex {
    my ($g, $params) = @_;

    return $DONT_KNOW if $g->is_biconnected();


    my $reason = $params->{transformed}
    ? "After removing edges according to constraints, the graph was no" .
        " longer biconnected, therefore not Hamiltonian."
        : "This graph is not biconnected, therefore not Hamiltonian. ";
    
    return ( $GRAPH_IS_NOT_HAMILTONIAN, $reason, $params );

#    my $vertices_string = join ',', $g->articulation_points();
#
#    return ( $GRAPH_IS_NOT_HAMILTONIAN,
#              "This graph is not biconnected, therefore not Hamiltonian. "
#            . "It contains the following articulation vertices: "
#            . "($vertices_string)" );

}

##########################################################################

sub test_graph_bridge {
    my ($g, $params) = @_;

    return $DONT_KNOW if $g->is_edge_connected();


    my $reason = $params->{transformed}
    ? "After removing edges according to constraints, the graph was " . 
        "found to have a bridge, and is therefore, not Hamiltonian."
        : "This graph has a bridge, and is therefore not Hamiltonian.";

    return ( $GRAPH_IS_NOT_HAMILTONIAN, $reason, $params );

#   my $bridge_string = join ',', map { sprintf "%d=%d", @$_ } $g->bridges();
#
#   return ( $GRAPH_IS_NOT_HAMILTONIAN,
#            "This graph is not edge-connected, therefore not Hamiltonian. "
#          . " It contains the following bridges ($bridge_string)." );

}

##########################################################################

### A simple graph with n vertices (n >= 3) is Hamiltonian if every vertex 
### has degree n / 2 or greater. -- Dirac (1952)
### https://en.wikipedia.org/wiki/Hamiltonian_path

sub test_dirac {
    my ($g) = @_;
    my $v = $g->vertices();
    return $DONT_KNOW if $v < 3;

    my $half_v = $v / 2;

    foreach my $vertex ( $g->vertices() ) {
        if ( $g->degree($vertex) < $half_v ) {
            return $DONT_KNOW;
        }
    }

    return ($GRAPH_IS_HAMILTONIAN,
            "Every vertex has degree $half_v or more.");

}

##########################################################################

### A graph with n vertices (n >= 3) is Hamiltonian if, 
### for every pair of non-adjacent vertices, the sum of their degrees 
### is n or greater (see Ore's theorem).
### https://en.wikipedia.org/wiki/Ore%27s_theorem

sub test_ore {
    my ($g, $params) = @_;
    my $v = $g->vertices();
    return $DONT_KNOW if $v < 3;

    foreach my $vertex1 ( $g->vertices() ) {
        foreach my $vertex2 ( $g->vertices() ) {
            next if $vertex1 == $vertex2;
            next if $g->has_edge($vertex1, $vertex2);
            my $sum_of_degrees = $g->degree($vertex1) + $g->degree($vertex2);
            return $DONT_KNOW if $sum_of_degrees < $v;
        }
    }

    my $reason = "The sum of degrees of each pair of non-adjacent vertices";
    $reason .= " >= v.";
    $reason .= " ( Ore's Theorem. )";

    return ($GRAPH_IS_HAMILTONIAN, $reason, $params);

}

##########################################################################

sub test_required {
    my ($required_graph, $params) = @_;

    foreach my $vertex ( $required_graph->vertices() ) {
        my $degree = $required_graph->degree($vertex);
        if ( $degree > 2 ) {
            my $reason = $params->{transformed}
            ? "After removing edges according to rules, the vertex $vertex "
                . "was found to be required by $degree edges."
                : "Vertex $vertex is required by $degree edges.";

            $reason .= " It can only be required by upto 2 edges.";

            return ( $GRAPH_IS_NOT_HAMILTONIAN, $reason );
        }
    }

    return $DONT_KNOW;
}

##########################################################################

sub test_required_cyclic {

    my ($required_graph) = @_;
    my %eliminated;
    my %connected_vertices;

    output("Entering test_required_cyclic()<BR/>");

    foreach my $edge_ref ( $required_graph->edges() ) {
        foreach my $connected_vertex ( @$edge_ref ) {
            $connected_vertices{ $connected_vertex } = 1;
        }
    }

    foreach my $vertex ( $required_graph->vertices() ) {
        next if $required_graph->degree($vertex) != 1;
        next if $eliminated{$vertex}++;

        my ( $current_vertex ) = $required_graph->neighbors($vertex);
        my $found_last_vertex = 0;
        while ( ! $found_last_vertex ) {

            my ( $next_vertex ) = 
                grep { ! $eliminated{$_} }
                $required_graph->neighbors($current_vertex);

            $eliminated{$next_vertex} = 1;
            my $required_degree = $required_graph->degree($next_vertex);
            $found_last_vertex = 1 if $required_degree == 1;
            $eliminated{$current_vertex} = 1;
            $current_vertex = $next_vertex;
        }
    }

    if ( scalar( keys %connected_vertices ) == scalar( keys %eliminated ) ) {
        ### Eliminated all connected vertices.
        ### The required graph is acyclic.
        return $DONT_KNOW;
    }

    ### The required graph is cyclic.
    my @cycle        = $required_graph->find_a_cycle();
    my $cycle_string = join ', ', @cycle;
    output( $required_graph, { required => 1 } );
    output("cycle_string=[$cycle_string]<BR/>");    ### DEBUG

    if ( $required_graph->is_connected() ) {
        return ( $GRAPH_IS_HAMILTONIAN,
                 "The required graph is cyclic, and connected." );
    } else {
        return ( $GRAPH_IS_NOT_HAMILTONIAN,
                 "The required graph is cyclic, but not connected." );
    }
}

##########################################################################


1;    # End of Graph::Undirected::Hamiltonicity::Tests
