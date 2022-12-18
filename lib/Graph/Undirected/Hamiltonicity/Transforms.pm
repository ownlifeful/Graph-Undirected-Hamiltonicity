use Graph::Undirected;
use Carp qw(croak);

use Modern::Perl;
package Graph::Undirected::Hamiltonicity;

##########################################################################

# The "required graph" contains the same vertices as the original graph,
# but with only the edges incident on vertices of degree == 2.

sub get_required_graph {
    my ($self) = @_;

    $self->output(   "Beginning a sweep to mark all edges adjacent to degree 2 "
            . "vertices as required:<BR/>" );

    my @vertices = $self->{g}->vertices();
    my $required_graph = Graph::Undirected->new( vertices => \@vertices );

    foreach my $vertex (@vertices) {
        my $degree = $self->{g}->degree($vertex);
        if ( $degree != 2 ) {
            $self->output("Vertex $vertex : Degree=[$degree] ...skipping.<BR/>");
            next;
        }

        $self->output("Vertex $vertex : Degree=[$degree] ");
        $self->output("<UL>");
        foreach my $neighbor_vertex ( $self->{g}->neighbors($vertex) ) {
            $required_graph->add_edge( $vertex, $neighbor_vertex );

            if ( $self->{g}->get_edge_attribute( $vertex, $neighbor_vertex,
                                          'required') ) {
                $self->output( "<LI>$vertex=$neighbor_vertex is already "
                        . "marked required</LI>" );
                next;
            }

            $self->{g}->set_edge_attribute($vertex, $neighbor_vertex,
                                    'required', 1);
            $self->output( "<LI>Marking $vertex=$neighbor_vertex "
                    . "as required</LI>" );
        }
        $self->output("</UL>");
    }

    $self->{required_graph} = $required_graph;
    if ( $required_graph->edges() ) {
        $self->output("required graph:");
        $self->output( { required => 1 } );
    } else {
        $self->output("The required graph has no edges.<BR/>");
    }
}

##########################################################################

# For each required walk, delete the edge connecting its endpoints,
# as such an edge would make the graph non-Hamiltonian, and therefore
# the edge can never be part of a Hamiltonian cycle.

sub delete_cycle_closing_edges {
    my ($self) = @_;
    $self->output("Entering delete_cycle_closing_edges()<BR/>");
    my $deleted_edges = 0;
    my %eliminated;

    foreach my $vertex ( $self->{required_graph}->vertices() ) {
        next unless $self->{required_graph}->degree($vertex) == 1;
        next if $eliminated{$vertex}++;

        my @reachable = $self->{required_graph}->all_reachable($vertex);

        my ( $other_vertex ) = grep { $self->{required_graph}->degree($_) == 1 } @reachable;
        next unless $self->{g}->has_edge($vertex, $other_vertex);
        $self->{g}->delete_edge($vertex, $other_vertex);
        $self->{required_graph}->delete_edge($vertex, $other_vertex);
        $deleted_edges++;

        output( "Deleted edge $vertex=$other_vertex"
                . ", between endpoints of a required walk.<BR/>" );
    }

    if ( $deleted_edges ) {
        my $s = $deleted_edges == 1 ? '' : 's';
        $self->output("Shrank the graph by removing $deleted_edges edge$s.<BR/>");
    } else {
        $self->output("Did not shrink the graph.<BR/>");
    }
    return $deleted_edges;
}

##########################################################################

sub delete_non_required_neighbors {
    my ( $self ) = @_;
    $self->output("Entering delete_non_required_neighbors()<BR/>");
    my $deleted_edges = 0;


    use Data::Dump qw(dump);
    my $x = dump($self->{required_graph});
#    $self->output("==========BEGIN========");
#    $self->output($x);
###    Test::More::diag($x);
#    $self->output("==========END===========");

    foreach my $required_vertex ( $self->{required_graph}->vertices() ) {
        next if $self->{required_graph}->degree($required_vertex) != 2;
        foreach my $neighbor_vertex ( $self->{g}->neighbors($required_vertex) ) {
            my $required =
                $self->{g}->get_edge_attribute( $required_vertex,
                                        $neighbor_vertex, 'required' );
            next if $required;
            next
                unless $self->{g}->has_edge(
                    $required_vertex, $neighbor_vertex );

            $self->{g}->delete_edge( $required_vertex, $neighbor_vertex );
            $deleted_edges++;
            $self->output( "Deleted edge $required_vertex=$neighbor_vertex "
                    . "because vertex $required_vertex has degree==2 "
                    . "in the required graph.<BR/>" );
        }
    }

    if ( $deleted_edges ) {
        my $s = $deleted_edges == 1 ? '' : 's';
        output("Shrank the graph by removing $deleted_edges edge$s.<BR/>");
    } else {
        output("Did not shrink the graph.<BR/>");
    }
    return $deleted_edges;
}

##########################################################################

sub swap_vertices {
    my ( $self, $vertex_1, $vertex_2 ) = @_;

    my %common_neighbors = $self->get_common_neighbors( $vertex_1, $vertex_2 );
    my @vertex_1_neighbors =
        grep { $_ != $vertex_2 } $self->{g}->neighbors($vertex_1);
    my @vertex_2_neighbors =
        grep { $_ != $vertex_1 } $self->{g}->neighbors($vertex_2);

    foreach my $neighbor_vertex (@vertex_1_neighbors) {
        next if $common_neighbors{$neighbor_vertex};
        $self->{g}->delete_edge( $neighbor_vertex, $vertex_1 );
        $self->{g}->add_edge( $neighbor_vertex, $vertex_2 );
    }

    foreach my $neighbor_vertex (@vertex_2_neighbors) {
        next if $common_neighbors{$neighbor_vertex};
        $self->{g}->delete_edge( $neighbor_vertex, $vertex_2 );
        $self->{g}->add_edge( $neighbor_vertex, $vertex_1 );
    }
}

##########################################################################

sub get_common_neighbors {
    my ( $self, $vertex_1, $vertex_2 ) = @_;
    my %common_neighbors;
    my %vertex_1_neighbors;
    
    foreach my $neighbor_vertex ( $self->{g}->neighbors($vertex_1) ) {
        $vertex_1_neighbors{$neighbor_vertex} = 1;
    }

    foreach my $neighbor_vertex ( $self->{g}->neighbors($vertex_2) ) {
        next unless $vertex_1_neighbors{$neighbor_vertex};
        $common_neighbors{$neighbor_vertex} = 1;
    }

    return %common_neighbors;
}

##########################################################################

# Takes a string representation of a Graph::Undirected
# The string is the same format as the result of calling the stringify()
# method on a Graph::Undirected object.
#
# Returns a Graph::Undirected object, constructed from its string form.

sub string_to_graph {
    my ($string) = @_;
    my %vertices;
    my @edges;

    foreach my $chunk ( split( /\,/, $string ) ) {
        if ( $chunk =~ /=/ ) {
            my @endpoints = map {s/\b0+([1-9])/$1/gr}
                split( /=/, $chunk );

            next if $endpoints[0] == $endpoints[1];
            push @edges, \@endpoints;
            $vertices{ $endpoints[0] } = 1;
            $vertices{ $endpoints[1] } = 1;
        } else {
            $vertices{$chunk} = 1;
        }
    }

    my @vertices = keys %vertices;
    my $g = Graph::Undirected->new( vertices => \@vertices );

    foreach my $edge_ref (@edges) {
        $g->add_edge(@$edge_ref) unless $g->has_edge(@$edge_ref);
    }

    return $g;
}

##########################################################################

# Takes a Graph::Undirected ( $self )
#
# Returns a Graph::Undirected  ( $self1 ) which is an isomorph of $self

sub get_random_isomorph {
    my ($self) = @_;

    # everyday i'm shufflin'
    my $v  = scalar( $self->{g}->vertices() );
    my $max_times_to_shuffle = $v * $v;
    my $shuffles             = 0;
    while ( $shuffles < $max_times_to_shuffle ) {
        my $v1 = int( rand($v) );
        my $v2 = int( rand($v) );

        next if $v1 == $v2;

        $self->swap_vertices( $v1, $v2 );
        $shuffles++;
    }
}

##############################################################################

sub add_random_edges {
    my ( $self, $edges_to_add ) = @_;

=back    
    use Data::Dump qw(dump);
    my $x = dump($self->{g});
    Test::More::diag("==========BEGIN3===========");
    Test::More::diag($x);
    Test::More::diag("==========END3===========");
=cut
    
    my $e  = scalar( $self->{g}->edges() );
    my $v  = scalar( $self->{g}->vertices() );
    my $max_edges = ( $v * $v - $v ) / 2;

    if ( ($e + $edges_to_add) > $max_edges ) {
        croak( "Can only add up to: ", $max_edges - $e, " edges. NOT [$edges_to_add]; e=[$e]\n" );
    }

    my $added_edges = 0;
    while ( $added_edges < $edges_to_add ) {
        my $v1 = int( rand($v) );
        my $v2 = int( rand($v) );

        next if $v1 == $v2;
        next if $self->{g}->has_edge( $v1, $v2 );

        $self->{g}->add_edge( $v1, $v2 );
        $added_edges++;
    }

}

##############################################################################


1;    # End of Graph::Undirected::Hamiltonicity::Transforms
