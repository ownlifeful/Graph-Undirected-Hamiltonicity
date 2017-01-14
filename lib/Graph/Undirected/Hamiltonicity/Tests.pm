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

    my @edges     = $g->edges;
    my $e         = @edges;
    my @vertices  = $g->vertices;
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
    my ($g) = @_;

    foreach my $vertex ( $g->vertices ) {
        if ( $g->degree($vertex) < 2 ) {
            return ( $GRAPH_IS_NOT_HAMILTONIAN,
                "This graph has a vertex ($vertex) with degree < 2" );
        }
    }

    return $DONT_KNOW;
}

##########################################################################

sub test_articulation_vertex {
    my ($g) = @_;

    return $DONT_KNOW if $g->is_biconnected();


    return ( $GRAPH_IS_NOT_HAMILTONIAN,
             "This graph is not biconnected, therefore not Hamiltonian. ");

#    my $vertices_string = join ',', $g->articulation_points();
#
#    return ( $GRAPH_IS_NOT_HAMILTONIAN,
#              "This graph is not biconnected, therefore not Hamiltonian. "
#            . "It contains the following articulation vertices: "
#            . "($vertices_string)" );

}

##########################################################################

sub test_graph_bridge {
    my ($g) = @_;

    return $DONT_KNOW if $g->is_edge_connected();

   return ( $GRAPH_IS_NOT_HAMILTONIAN,
            "This graph has a bridge, and is therefore not Hamiltonian.");

#    my $bridge_string = join ',', map { sprintf "%d=%d", @$_ } $g->bridges();
#
#    return ( $GRAPH_IS_NOT_HAMILTONIAN,
#              "This graph is not edge-connected, therefore not Hamiltonian. "
#            . " It contains the following bridges ($bridge_string)." );

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

sub test_required {
    my ($required_graph) = @_;

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

sub test_required_cyclic {

    my ($required_graph) = @_;

    return $DONT_KNOW if $required_graph->is_acyclic();

    my $v                           = scalar( $required_graph->vertices() );
    my @cycle                       = $required_graph->find_a_cycle();
    my $number_of_vertices_in_cycle = scalar(@cycle);

    my $cycle_string = join ', ', @cycle;
    output( $required_graph, { required => 1 } );
    output("cycle_string=[$cycle_string]<BR/>");    ### DEBUG

    if ( $number_of_vertices_in_cycle < $v ) {
        output( "GRAPH_IS_NOT_HAMILTONIAN for v=$v; " .        
                "vertices in cycle=$number_of_vertices_in_cycle;<BR/>");
        return ( $GRAPH_IS_NOT_HAMILTONIAN,
                  "The sub-graph of required edges has a cycle "
                . "[$cycle_string] with fewer than $v vertices." );
    } else {
        # found a cycle with $v vertices.
        output( "GRAPH_IS_HAMILTONIAN for v=$v; " . 
                "vertices in cycle=$number_of_vertices_in_cycle;<BR/>");
        return ( $GRAPH_IS_HAMILTONIAN,
                  "The sub-graph of required edges has a cycle "
                . "[$cycle_string] with $v vertices." );
    }
}

##########################################################################


1;    # End of Graph::Undirected::Hamiltonicity::Tests
