package Graph::Undirected::Hamiltonicity::Transforms;

# You can get documentation for this module with this command:
#    perldoc Graph::Undirected::Hamiltonicity::Transforms

use 5.006;
use strict;
use warnings;

use Carp;

use Graph::Undirected;
use Graph::Undirected::Hamiltonicity::Output qw(:all);

use Exporter qw(import);

our @EXPORT_OK = qw(
    &add_random_edges
    &delete_cycle_closing_edges
    &delete_non_required_neighbors
    &delete_unusable_edges
    &get_common_neighbors
    &get_required_graph
    &shrink_required_walks_longer_than_2_edges
    &get_random_isomorph
    &string_to_graph
    &swap_vertices
);

our %EXPORT_TAGS = ( all => \@EXPORT_OK );

our $VERSION = '0.01';


#####################################################

sub get_required_graph {

    my ($g) = @_;

    output(   "Beginning a sweep to mark all edges adjacent to degree 2 "
            . "vertices as required:<BR/>" );

    my $g1 = $g->deep_copy_graph();
    output($g1);

    my @vertices = $g1->vertices();
    my $required_graph = Graph::Undirected->new( vertices => \@vertices );

    foreach my $vertex (@vertices) {
        my $degree = $g1->degree($vertex);
        output("Vertex $vertex : Degree=[$degree] ");

        if ( $degree == 2 ) {
            output("<UL>");
            foreach my $neighbor_vertex ( $g1->neighbors($vertex) ) {

                $required_graph->add_edge( $vertex, $neighbor_vertex );

                if ( $g1->get_edge_attribute(
                                              $vertex,
                                              $neighbor_vertex,
                                              'required'
                                            )
                    )
                {
                    output(   "<LI>$vertex=$neighbor_vertex is already "
                            . "marked required</LI>" );
                    next;
                }

                $g1->set_edge_attribute(
                    $vertex, $neighbor_vertex,
                    'required', 1
                    );
                output(   "<LI>Marking $vertex=$neighbor_vertex "
                        . "as required</LI>" );
            }
            output("</UL>");
        } else {
            output(" ...skipping.<BR/>");
        }
    }

    if ( scalar( $required_graph->edges() ) ) {
        output("required graph:");
        output( $required_graph, { required => 1 } );
    } else {
        output("required graph has no edges.<BR/>");
    }

    return ( $required_graph, $g1 );
}

##########################################################################

sub delete_unusable_edges {
    my ($g) = @_;
    my $deleted_edges = 0;
    my $g1;
    foreach my $vertex ( $g->vertices() ) {
        next if $g->degree($vertex) != 2;
        my @neighbors = $g->neighbors($vertex);

        if ( $g->has_edge(@neighbors) ) {

            ### Clone graph lazily
            $g1 //= $g->deep_copy_graph();

            next unless $g1->has_edge(@neighbors);
            $g1->delete_edge(@neighbors);
            $deleted_edges++;
            output(   "Deleted edge "
                    . ( join '=', @neighbors )
                    . ", between neighbors of a degree 2 vertex ($vertex)<BR/>"
            );
        }
    }

    return ( $deleted_edges, $deleted_edges ? $g1 : $g );
}

##########################################################################

# For each required walk, delete the edge connecting its endpoints,
# as such an edge would make the graph non-Hamiltonian, and therefore
# the edge can never be part of a Hamiltonian cycle.

sub delete_cycle_closing_edges {
    my ($g, $required_graph) = @_;
    my $deleted_edges = 0;
    my $g1;
    my %eliminated;

    print "Line: ", __LINE__, " g=($g)\n"; ### DEBUG
    print "Line: ", __LINE__, " required_graph=($required_graph)\n"; ### DEBUG

    foreach my $vertex ( $required_graph->vertices() ) {
        print "Line: ", __LINE__, " vertex=$vertex\n"; ### DEBUG
        next if $required_graph->degree($vertex) != 1;
        print "Line: ", __LINE__, " vertex=$vertex; degree=", $required_graph->degree($vertex)  ,"\n"; ### DEBUG
        next if $eliminated{$vertex}++;
        print "Line: ", __LINE__, " vertex=$vertex has not been eliminated.\n"; ### DEBUG

        my $first_vertex = $vertex;
        my ( $current_vertex ) = $required_graph->neighbors($vertex);

        print "Line: ", __LINE__, " vertex ( $vertex ) is a neighbor of current_vertex ($current_vertex)\n"; ### DEBUG

        my $loops = 0;
        my $length = 1;
        my $found_last_vertex = 0;
        while ( ! $found_last_vertex ) {
            print "Line: ", __LINE__, " current_vertex=$current_vertex\n"; ### DEBUG

            my ( $next_vertex ) = 
                grep { ! $eliminated{$_} }
                $required_graph->neighbors($current_vertex);

            unless ( defined $next_vertex ) {
                print "next_vertex not defined. (((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((\n"; ### DEBUG
            }

            print "Line: ", __LINE__, " next_vertex=$next_vertex\n"; ### DEBUG

            ### die "Seppuku ----------------------------\n" if $loops++ == 10; ### DEBUG

            $eliminated{$next_vertex} = 1;

            my $required_degree = $required_graph->degree($next_vertex);

            unless ( defined $required_degree ) {
                print "required_degree not defined. )))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))\n"; ### DEBUG
            }


            if ( $required_degree == 1 ) {
                $found_last_vertex = 1;
                $g1 //= $g->deep_copy_graph();

                if ( $length == $required_graph->vertices() ) {
                    output("Found a Hamiltonian Cycle<BR/>");
                }

                if ( $g1->has_edge($first_vertex, $next_vertex) ) {
                    $g1->delete_edge($first_vertex, $next_vertex);
                    $required_graph->delete_edge($first_vertex, $next_vertex);
                    $deleted_edges++;

                    print "Line: ", __LINE__, " Deleted edge $first_vertex=$next_vertex, between endpoints of a required walk.\n"; ### DEBUG

                    output( "Deleted edge $first_vertex=$next_vertex"
                            . ", between endpoints of a required walk.<BR/>" );
                } else {
                    print "Line: ", __LINE__, " The edge $first_vertex=$next_vertex, doesn't exist.\n"; ### DEBUG
                }
            }

            $eliminated{$current_vertex} = 1;
            $length++;
            $current_vertex = $next_vertex;
        }
    }

    return ( $deleted_edges, $deleted_edges ? $g1 : $g );
}

##########################################################################

sub delete_non_required_neighbors {
    output("Entering deleted_non_required_neighbors()<BR/>");

    my ( $g, $required_graph ) = @_;
    my $g1;
    my $deleted_edges = 0;
    foreach my $required_vertex ( $required_graph->vertices() ) {
        next if $required_graph->degree($required_vertex) != 2;
        foreach my $neighbor_vertex ( $g->neighbors($required_vertex) ) {
            my $required =
                $g->get_edge_attribute( $required_vertex,
                $neighbor_vertex, 'required' );
            unless ($required) {

                ### Clone graph lazily
                $g1 //= $g->deep_copy_graph();

                next
                    unless $g1->has_edge(
                        $required_vertex, $neighbor_vertex );

                $g1->delete_edge( $required_vertex, $neighbor_vertex );
                $deleted_edges++;
                output(   "Deleted edge $required_vertex=$neighbor_vertex "
                        . "because vertex $required_vertex has degree==2 "
                        . "in the required graph.<BR/>" );
            }
        }
    }

    my $s = $deleted_edges == 1 ? '' : 's';
    output("Shrank the graph by removing " . 
           "$deleted_edges edge$s.<BR/>");

    return ( $deleted_edges, $deleted_edges ? $g1 : $g );
}

##########################################################################

sub shrink_required_walks_longer_than_2_edges {
    my ( $g, $required_graph ) = @_;

    my $g1;
    my $deleted_edges = 0;

    foreach my $vertex ( sort { $a <=> $b } $required_graph->vertices() ) {
        next unless $required_graph->degree($vertex) == 2;

        my @neighbors = $required_graph->neighbors($vertex);
        next
            if (( $required_graph->degree( $neighbors[0] ) == 1 )
            and ( $required_graph->degree( $neighbors[1] ) == 1 ) );

        ### Clone graph lazily
        $g1 //= $g->deep_copy_graph();

        unless ( $g1->has_edge(@neighbors) ) {
            $required_graph->add_edge(@neighbors);
            $g1->add_edge(@neighbors);
            output("Added edge $neighbors[0]=$neighbors[1] and ");
        }

        output(   "deleted vertex $vertex because it was part of a "
                . "long required walk.<BR/>" );
        $g1->set_edge_attribute( @neighbors, 'required', 1 );
        $required_graph->delete_vertex($vertex);
        $g1->delete_vertex($vertex);
        $deleted_edges++;
    }


    if ( $deleted_edges ) {
        if ( $deleted_edges == 1 ) {
            output("Shrank the graph by removing 1 vertex " .
                   "and 1 edge.<BR/>");
        } else {
            output("Shrank the graph by removing " .
                   "$deleted_edges edges and vertices.<BR/>" );
        }
    }

    return ( $deleted_edges, $deleted_edges ? $g1 : $g );
}

##########################################################################

sub swap_vertices {
    my ( $g, $vertex_1, $vertex_2 ) = @_;

    my $g1 = $g->deep_copy_graph();

    my %common_neighbors =
        %{ get_common_neighbors( $g1, $vertex_1, $vertex_2 ) };

    my @vertex_1_neighbors =
        grep { $_ != $vertex_2 } $g1->neighbors($vertex_1);
    my @vertex_2_neighbors =
        grep { $_ != $vertex_1 } $g1->neighbors($vertex_2);

    foreach my $neighbor_vertex (@vertex_1_neighbors) {
        next if $common_neighbors{$neighbor_vertex};
        $g1->delete_edge( $neighbor_vertex, $vertex_1 );
        $g1->add_edge( $neighbor_vertex, $vertex_2 );
    }

    foreach my $neighbor_vertex (@vertex_2_neighbors) {
        next if $common_neighbors{$neighbor_vertex};
        $g1->delete_edge( $neighbor_vertex, $vertex_2 );
        $g1->add_edge( $neighbor_vertex, $vertex_1 );
    }

    return $g1;
}

##########################################################################

sub get_common_neighbors {
    my ( $g, $vertex_1, $vertex_2 ) = @_;

    my %common_neighbors;
    my %vertex_1_neighbors;
    foreach my $neighbor_vertex ( $g->neighbors($vertex_1) ) {
        $vertex_1_neighbors{$neighbor_vertex} = 1;
    }

    foreach my $neighbor_vertex ( $g->neighbors($vertex_2) ) {
        next unless $vertex_1_neighbors{$neighbor_vertex};
        $common_neighbors{$neighbor_vertex} = 1;
    }

    return \%common_neighbors;
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

# Takes a Graph::Undirected ( $g )
#
# Returns a Graph::Undirected  ( $g1 ) which is an isomorph of $g

sub get_random_isomorph {
    my ($g) = @_;

    # everyday i'm shufflin'

    my $g1 = $g->deep_copy_graph();
    my $v  = scalar( $g1->vertices() );

    my $max_times_to_shuffle = $v * $v;
    my $shuffles             = 0;
    while ( $shuffles < $max_times_to_shuffle ) {
        my $v1 = int( rand($v) );
        my $v2 = int( rand($v) );

        next if $v1 == $v2;

        $g1 = swap_vertices( $g1, $v1, $v2 );
        $shuffles++;
    }

    return $g1;
}

##############################################################################

sub add_random_edges {
    my ( $g, $edges_to_add ) = @_;

    my $e  = scalar( $g->edges() );
    my $v  = scalar( $g->vertices() );
    my $max_edges = ( $v * $v - $v ) / 2;

    if ( ($e + $edges_to_add) > $max_edges ) {
        croak "Can only add up to: ", $max_edges - $e, 
              " edges. NOT [$edges_to_add]; e=[$e]\n";
    }

    my $g1 = $g->deep_copy_graph();
    my $added_edges = 0;
    while ( $added_edges < $edges_to_add ) {
        my $v1 = int( rand($v) );
        my $v2 = int( rand($v) );

        next if $v1 == $v2;
        next if $g1->has_edge( $v1, $v2 );

        $g1->add_edge( $v1, $v2 );
        $added_edges++;
    }

    return $g1;
}

##############################################################################


1;    # End of Graph::Undirected::Hamiltonicity::Transforms
