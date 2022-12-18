package Graph::Undirected::Hamiltonicity;

$Graph::Undirected::Hamiltonicity::DONT_KNOW                = 0;
$Graph::Undirected::Hamiltonicity::GRAPH_IS_HAMILTONIAN     = 1;
$Graph::Undirected::Hamiltonicity::GRAPH_IS_NOT_HAMILTONIAN = 2;

use Modern::Perl;

##########################################################################

sub test_trivial {
    my ($self) = @_;
    $self->output("Entering test_trivial()<BR/>");
    my $e         = scalar( $self->{g}->edges );
    my $v         = scalar( $self->{g}->vertices );
    my $max_edges = ( $v * $v - $v ) / 2;

    if ( $v == 1 ) {
        return ( $Graph::Undirected::Hamiltonicity::GRAPH_IS_HAMILTONIAN,
                  "By convention, a graph with a single vertex is "
                . "considered to be Hamiltonian." );
    }

    if ( $v < 3 ) {
        return ( $Graph::Undirected::Hamiltonicity::GRAPH_IS_NOT_HAMILTONIAN,
            "A graph with 0 or 2 vertices cannot be Hamiltonian." );
    }

    if ( $e < $v ) {
        foreach my $vertex ( $self->{g}->vertices ) {
            say "vertex=[$vertex]"; ### DEBUG: REMOVE!
        }

        
        return ( $Graph::Undirected::Hamiltonicity::GRAPH_IS_NOT_HAMILTONIAN,
            "e < v, therefore the graph is not Hamiltonian. e=$e, v=$v" );
    }

    ### If e > ( ( v * ( v - 1 ) / 2 ) - ( v - 2 ) )
    ### the graph definitely has an HC.
    if ( $e > ( $max_edges - $v + 2 ) ) {
        my $reason = "If e > ( (v*(v-1)/2)-(v-2)), the graph is Hamiltonian.";
        $reason .= " For v=$v, e > ";
        $reason .= $max_edges - $v + 2;
        return ( $Graph::Undirected::Hamiltonicity::GRAPH_IS_HAMILTONIAN, $reason );
    }

    return $Graph::Undirected::Hamiltonicity::DONT_KNOW;

}

##########################################################################

sub test_canonical {
    my ($self) = @_;
    $self->output("Entering test_canonical()<BR/>");

    my @vertices = sort { $a <=> $b } $self->{g}->vertices();
    my $v = scalar(@vertices);

    if ( $self->{g}->has_edge( $vertices[0], $vertices[-1] ) ) {
        for ( my $counter = 0; $counter < $v - 1; $counter++ ) {
            unless (
                $self->{g}->has_edge(
                    $vertices[$counter], $vertices[ $counter + 1 ]
                )
                )
            {
                return ( $Graph::Undirected::Hamiltonicity::DONT_KNOW,
                          "This graph is not a supergraph of "
                        . "the canonical Hamiltonian Cycle." );
            }
        }
        return ( $Graph::Undirected::Hamiltonicity::GRAPH_IS_HAMILTONIAN,
                  "This graph is a supergraph of "
                . "the canonical Hamiltonian Cycle." );
    } else {
        return ( $Graph::Undirected::Hamiltonicity::DONT_KNOW,
                  "This graph is not a supergraph of "
                . "the canonical Hamiltonian Cycle." );
    }
}

##########################################################################

sub test_min_degree {

    my ($self, $params) = @_;
    $self->output("Entering test_min_degree()<BR/>");
 
    foreach my $vertex ( $self->{g}->vertices ) {
        if ( $self->{g}->degree($vertex) < 2 ) {

            my $reason = $params->{transformed} 
            ? "After removing edges according to constraints, this graph " 
                . "was found to have a vertex ($vertex) with degree < 2"
                : "This graph has a vertex ($vertex) with degree < 2";

            return ( $Graph::Undirected::Hamiltonicity::GRAPH_IS_NOT_HAMILTONIAN, $reason, $params );
        }
    }

    return $Graph::Undirected::Hamiltonicity::DONT_KNOW;
}

##########################################################################

sub test_articulation_vertex {
    my ($self, $params) = @_;
    $self->output("Entering test_articulation_vertex()<BR/>");
    return $Graph::Undirected::Hamiltonicity::DONT_KNOW if $self->{g}->is_biconnected();

    my $reason = $params->{transformed}
    ? "After removing edges according to constraints, the graph was no" .
        " longer biconnected, therefore not Hamiltonian."
        : "This graph is not biconnected, therefore not Hamiltonian. ";
    
    return ( $Graph::Undirected::Hamiltonicity::GRAPH_IS_NOT_HAMILTONIAN, $reason, $params );

#    my $vertices_string = join ',', $self->{g}->articulation_points();
#
#    return ( $Graph::Undirected::Hamiltonicity::GRAPH_IS_NOT_HAMILTONIAN,
#              "This graph is not biconnected, therefore not Hamiltonian. "
#            . "It contains the following articulation vertices: "
#            . "($vertices_string)" );

}

##########################################################################

sub test_graph_bridge {
    my ($self, $params) = @_;
    $self->output("Entering test_graph_bridge()<BR/>");
    return $Graph::Undirected::Hamiltonicity::DONT_KNOW if $self->{g}->is_edge_connected();

    my $reason = $params->{transformed}
    ? "After removing edges according to constraints, the graph was " . 
        "found to have a bridge, and is therefore, not Hamiltonian."
        : "This graph has a bridge, and is therefore not Hamiltonian.";

    return ( $Graph::Undirected::Hamiltonicity::GRAPH_IS_NOT_HAMILTONIAN, $reason, $params );

#   my $bridge_string = join ',', map { sprintf "%d=%d", @$_ } $self->{g}->bridges();
#
#   return ( $Graph::Undirected::Hamiltonicity::GRAPH_IS_NOT_HAMILTONIAN,
#            "This graph is not edge-connected, therefore not Hamiltonian. "
#          . " It contains the following bridges ($bridge_string)." );

}

##########################################################################

### A simple graph with n vertices (n >= 3) is Hamiltonian if every vertex 
### has degree n / 2 or greater. -- Dirac (1952)
### https://en.wikipedia.org/wiki/Hamiltonian_path

sub test_dirac {
    my ($self) = @_;

    $self->output("Entering test_dirac()<BR/>");

    my $v = $self->{g}->vertices();
    return $Graph::Undirected::Hamiltonicity::DONT_KNOW if $v < 3;

    my $half_v = $v / 2;

    foreach my $vertex ( $self->{g}->vertices() ) {
        if ( $self->{g}->degree($vertex) < $half_v ) {
            return $Graph::Undirected::Hamiltonicity::DONT_KNOW;
        }
    }

    return ($Graph::Undirected::Hamiltonicity::GRAPH_IS_HAMILTONIAN,
            "Every vertex has degree $half_v or more.");

}

##########################################################################

### A graph with n vertices (n >= 3) is Hamiltonian if, 
### for every pair of non-adjacent vertices, the sum of their degrees 
### is n or greater (see Ore's theorem).
### https://en.wikipedia.org/wiki/Ore%27s_theorem

sub test_ore {
    my ($self, $params) = @_;
    $self->output("Entering test_ore()<BR/>");
    my $v = $self->{g}->vertices();
    return $Graph::Undirected::Hamiltonicity::DONT_KNOW if $v < 3;

    foreach my $vertex1 ( $self->{g}->vertices() ) {
        foreach my $vertex2 ( $self->{g}->vertices() ) {
            last if $vertex1 == $vertex2;
            next if $self->{g}->has_edge($vertex1, $vertex2);
            my $sum_of_degrees = $self->{g}->degree($vertex1) + $self->{g}->degree($vertex2);
            return $Graph::Undirected::Hamiltonicity::DONT_KNOW if $sum_of_degrees < $v;
        }
    }

    my $reason = "The sum of degrees of each pair of non-adjacent vertices";
    $reason .= " >= v.";
    $reason .= " ( Ore's Theorem. )";

    return ($Graph::Undirected::Hamiltonicity::GRAPH_IS_HAMILTONIAN, $reason, $params);

}

##########################################################################

sub test_required_max_degree {
    my ($self, $params) = @_;
    $self->output("Entering test_required_max_degree()<BR/>");

    foreach my $vertex ( $self->{required_graph}->vertices() ) {
        my $degree = $self->{required_graph}->degree($vertex);
        if ( $degree > 2 ) {
            my $reason = $params->{transformed}
            ? "After removing edges according to rules, the vertex $vertex "
                . "was found to be required by $degree edges."
                : "Vertex $vertex is required by $degree edges.";

            $reason .= " It can only be required by upto 2 edges.";

            return ( $Graph::Undirected::Hamiltonicity::GRAPH_IS_NOT_HAMILTONIAN, $reason, $params );
        }
    }

    return $Graph::Undirected::Hamiltonicity::DONT_KNOW;
}

##########################################################################

sub test_required_connected {
    my ($self, $params) = @_;
    $self->output("Entering test_required_connected()<BR/>");

    if ( $self->{required_graph}->is_connected() ) {
        my @degree1_vertices =
            grep
                 { $self->{required_graph}->degree($_) == 1 }
                 $self->{required_graph}->vertices();

        unless ( @degree1_vertices ) {
            $self->_output_cycle();
            my $reason = $params->{transformed}
            ? "After removing edges according to rules, the required graph was "
                . "found to be connected, with no vertices of degree 1."
                : "The required graph is connected, and has no vertices with degree 1.";

            return ( $Graph::Undirected::Hamiltonicity::GRAPH_IS_HAMILTONIAN, $reason, $params );
        }

        if ( $self->{g}->has_edge( @degree1_vertices ) ) {
            unless ( $self->{required_graph}->has_edge(@degree1_vertices) ) {
                $self->{required_graph}->add_edge(@degree1_vertices);
            }
            $self->_output_cycle();

            my $reason = $params->{transformed}
            ? "After removing edges according to rules, the required graph was "
                . "found to contain a Hamiltonian Cycle."
                : "The required graph contains a Hamiltonian Cycle";

            return ( $Graph::Undirected::Hamiltonicity::GRAPH_IS_HAMILTONIAN, $reason, $params );
        } else {
            my $reason = $params->{transformed}
            ? "After removing edges according to rules, the required graph was "
                . "found to be connected, but not cyclic."
                : "The required graph is connected, but not cyclic";
            return ( $Graph::Undirected::Hamiltonicity::GRAPH_IS_NOT_HAMILTONIAN, $reason, $params );
        }
    }

    return $Graph::Undirected::Hamiltonicity::DONT_KNOW;

}

##########################################################################

sub test_required_cyclic {
    my ($self, $params) = @_;
    $self->output("Entering test_required_cyclic()<BR/>");

    if ( $self->{required_graph}->has_a_cycle ) {
        my $reason = $params->{transformed}
        ? "After removing edges according to rules, the required graph was "
            . "found to be cyclic, but not connected."
            : "The required graph is cyclic, but not connected.";
        return ( $Graph::Undirected::Hamiltonicity::GRAPH_IS_NOT_HAMILTONIAN, $reason, $params );
    }

    return $Graph::Undirected::Hamiltonicity::DONT_KNOW;    
}

##########################################################################

sub _output_cycle {
    my ($self) = @_;
    my @cycle        = $self->{required_graph}->find_a_cycle();
    my $cycle_string = join ', ', @cycle;
    $self->output();
    $self->output("Found a cycle: [$cycle_string]<BR/>");
}

##########################################################################

1;    # End of Graph::Undirected::Hamiltonicity::Tests
