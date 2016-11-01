package Graph::Undirected::Hamiltonicity::Transforms;

use 5.006;
use strict;
use warnings;

use Graph::Undirected;
use Graph::Undirected::Hamiltonicity::Output qw(:all);

use Exporter qw(import);

our @EXPORT_OK =  qw(
                     &add_random_edges
                     &delete_non_required_neighbors
                     &delete_unusable_edges
                     &get_common_neighbors
                     &get_required_graph
                     &shrink_required_walks_longer_than_2_edges
                     &shuffle
                     &string_to_graph
                     &swap_vertices
        );

our %EXPORT_TAGS = (
    all       =>  \@EXPORT_OK,
);


=head1 NAME

Graph::Undirected::Hamiltonicity::Transforms - subroutines that apply transformations to undirected graphs.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SUBROUTINES

=cut

##################################################### BEGIN subs

=head2 get_required_graph

For each vertex in the graph that has degree == 2,
mark the edges adjacent to the vertex as "required".

Create a graph that has the same edges as the input graph,
but only the edges marked "required".

Return the "required" graph, and also a copy of the original graph,
with the required edges marked.

     use Graph::Undirected::Hamiltonicity::Transforms qw(&get_required_graph);

     my ( $required_graph, $G1 ) = get_required_graph( $G );

=cut

sub get_required_graph {

    my ($G) = @_;

    output("Beginning a sweep to mark all edges adjacent to degree 2 "
           . "vertices as required:<BR/>");

    my $G1 = $G->deep_copy_graph();
    output($G1);

    my @vertices = $G1->vertices();
    my $required_graph = new Graph::Undirected( vertices => \@vertices );

    foreach my $vertex ( @vertices ) {
        my $degree = $G1->degree($vertex);
        output("Vertex $vertex : Degree=[$degree] ");

        if ( $degree == 2 ) {
            output("<UL>");
            foreach my $neighbor_vertex ( $G1->neighbors($vertex) ) {

                $required_graph->add_edge($vertex, $neighbor_vertex);

                if ($G1->get_edge_attribute(
                        $vertex, $neighbor_vertex, 'required'
                    )
                    )
                {
                    output("<LI>$vertex=$neighbor_vertex is already " .
                           "marked required</LI>");
                    next;
                }

                $G1->set_edge_attribute( $vertex, $neighbor_vertex,
                    'required', 1 );
                output("<LI>Marking $vertex=$neighbor_vertex " . 
                       "as required</LI>");
            }
            output("</UL>");
        }
        else {
            output(" ...skipping.<BR/>");
        }
    }

    return ( $required_graph, $G1 );
}

##########################################################################

=head2 delete_unusable_edges

Delete edges connecting neighbors of vertices with degree 2.

     use Graph::Undirected::Hamiltonicity::Transforms qw(&delete_unusable_edges);

     my $G1 = delete_unusable_edges( $G );

=cut

sub delete_unusable_edges {

    my ( $G ) = @_;
    my $deleted_edges = 0;
    my $G1;
    foreach my $vertex ( $G->vertices() ) {
        next if $G->degree($vertex) != 2;
        my @neighbors = $G->neighbors($vertex);
            
        if ( $G->has_edge(@neighbors) ) {

            ### Clone graph lazily
            $G1 //= $G->deep_copy_graph();

            next unless $G1->has_edge(@neighbors);
            $G1->delete_edge(@neighbors);
            $deleted_edges++;
            output("Deleted edge " . ( join '=', @neighbors ) .
                   ", between neighbors of a degree 2 vertex ($vertex)<BR/>");
        }
    }

    return ( $deleted_edges, $deleted_edges ? $G1 : $G );
}

##########################################################################

=head2 delete_non_required_neighbors

Delete all non-required edges adjacent to vertices adjacent to 
2 required edges.

Return the graph with the edges deleted, and also the number of edges deleted.

     use Graph::Undirected::Hamiltonicity::Transforms qw(&delete_non_required_neighbors);

     my ($deleted_edges, $G1) = delete_non_required_neighbors( $G );

=cut

sub delete_non_required_neighbors {
    my ( $required_graph, $G ) = @_;
    my $G1;
    my $deleted_edges = 0;
    foreach my $required_vertex ( $required_graph->vertices() ) {
        next if $required_graph->degree($required_vertex) != 2;
        foreach my $neighbor_vertex ( $G->neighbors($required_vertex) ) {
            my $required =
                $G->get_edge_attribute( $required_vertex,
                                        $neighbor_vertex, 'required' );
            unless ($required) {

                ### Clone graph lazily
                $G1 //= $G->deep_copy_graph();

                next unless $G1->has_edge( $required_vertex, $neighbor_vertex );

                $G1->delete_edge( $required_vertex, $neighbor_vertex );
                $deleted_edges++;
                output("Deleted edge $required_vertex=$neighbor_vertex " .
                       "because vertex $required_vertex has degree==2 " .
                       "in the required graph.<BR/>");
            }
        }
    }

    return ( $deleted_edges, $deleted_edges ? $G1 : $G );
}

##########################################################################

=head2 shrink_required_walks_longer_than_2_edges

Shrink all required walks longer than 2 edges.

Return the graph with the edges deleted, and also the number of edges deleted.

     use Graph::Undirected::Hamiltonicity::Transforms qw(&shrink_required_walks_longer_than_2_edges);

     my ($deleted_edges, $G1) = shrink_required_walks_longer_than_2_edges( $G );

=cut

sub shrink_required_walks_longer_than_2_edges {
    my ( $G, $required_graph ) = @_;

    my $G1;
    my $deleted_edges = 0;

    foreach my $vertex ( sort { $a <=> $b } $required_graph->vertices() ) {
        next unless $required_graph->degree($vertex) == 2;

        my @neighbors = $required_graph->neighbors($vertex);
        next
            if (( $required_graph->degree( $neighbors[0] ) == 1 )
            and ( $required_graph->degree( $neighbors[1] ) == 1 ) );

        ### Clone graph lazily
        $G1 //= $G->deep_copy_graph();

        unless ( $G1->has_edge(@neighbors) ) {
            $required_graph->add_edge(@neighbors);
            $G1->add_edge(@neighbors);
            output("Added edge $neighbors[0]=$neighbors[1] and ");
        }

        output("deleted vertex $vertex because it was part of a " .
               "long required walk.<BR/>");
        $G1->set_edge_attribute( @neighbors, 'required', 1 );
        $required_graph->delete_vertex($vertex);
        $G1->delete_vertex($vertex);
        $deleted_edges++;
    }

    output("Deleted $deleted_edges edges to shrink the graph.") if $deleted_edges;

    return ( $deleted_edges, $deleted_edges ? $G1 : $G );
}

##########################################################################

=head2 swap_vertices

For a given graph, and two specified vertices, modify the graph so that 
the neighbors of vertex1 become the neighbors of vertex2 and vice versa.

     use Graph::Undirected::Hamiltonicity::Transforms qw(&swap_vertices);

     my $G1 = swap_vertices( $G, 3, 7 );

     # $G1 is like $G, with vertices 3 and 7 swapped.

=cut

sub swap_vertices {
    my ( $G, $vertex_1, $vertex_2 ) = @_;

    my $G1 = $G->deep_copy_graph();

    my %common_neighbors =
      get_common_neighbors( $G1, $vertex_1, $vertex_2 );

    my @vertex_1_neighbors = grep { $_ != $vertex_2 } $G1->neighbors($vertex_1);
    my @vertex_2_neighbors = grep { $_ != $vertex_1 } $G1->neighbors($vertex_2);

    foreach my $neighbor_vertex ( @vertex_1_neighbors ) {
      next if $common_neighbors{$neighbor_vertex};
      $G1->delete_edge($neighbor_vertex, $vertex_1);
      $G1->add_edge($neighbor_vertex, $vertex_2);
    }

    foreach my $neighbor_vertex ( @vertex_2_neighbors ) {
      next if $common_neighbors{$neighbor_vertex};
      $G1->delete_edge($neighbor_vertex, $vertex_2);
      $G1->add_edge($neighbor_vertex, $vertex_1);
    }

    return $G1;
}

##########################################################################


=head2 get_common_neighbors

For a given graph, and two specified vertices, return a hash
whose keys are all the vertices that vertex1 and vertex2 share.

     use Graph::Undirected::Hamiltonicity::Transforms qw(&get_common_neighbors);

     my %common_neighbors = get_common_neighbors( $G, 3, 7 );

=cut


sub get_common_neighbors {
    my ( $G, $vertex_1, $vertex_2 ) = @_;

    my %common_neighbors;
    my %vertex_1_neighbors;
    foreach my $neighbor_vertex ( $G->neighbors($vertex_1) ) {
        $vertex_1_neighbors{$neighbor_vertex}++;
    }

    foreach my $neighbor_vertex ( $G->neighbors($vertex_2) ) {
        next unless $vertex_1_neighbors{$neighbor_vertex};
        $common_neighbors{$neighbor_vertex} = 1;
    }

    return %common_neighbors;
}

##########################################################################

=head2 string_to_graph

Take a string and convert it to an undirected graph.
The string should be in the same format as the output of
Graph::Undirected::stringify()

     use Graph::Undirected::Hamiltonicity::Transforms qw(&string_to_graph);

     my $G = string_to_graph('0=1,0=2,0=6,1=3,1=7,2=3,2=4,3=5,4=5,4=6,5=7,6=7');

=cut

sub string_to_graph {
    my ($string) = @_;
    my %vertices;
    my @edges;

    foreach my $chunk ( split ( /\,/, $string ) ) {
        if ( $chunk =~ /=/ ) {
            my @endpoints = map { s/^0+([1-9])/$1/; $_ } ( split ( /=/, $chunk ) );
            next if $endpoints[0] == $endpoints[1];
            push @edges, \@endpoints;
            $vertices{ $endpoints[0] } = 1;
            $vertices{ $endpoints[1] } = 1;
        } else {
            $vertices{$chunk} = 1;
        }
    }

    my @vertices = keys %vertices;
    my $G = new Graph::Undirected( vertices => \@vertices );

    foreach my $edge_ref ( @edges ) {
        $G->add_edge(@$edge_ref) unless $G->has_edge(@$edge_ref);
    }

    return $G;
 }

##########################################################################

=head2 shuffle

Takes an input graph, and swaps its vertices randomly, so that the
resultant graph is an isomorph of the input graph, but probably not
identical to the original graph.

     use Graph::Undirected::Hamiltonicity::Transforms qw(&shuffle);

     my $G1 = shuffle( $G );

=cut


sub shuffle {
    my ( $G ) = @_;

    # everyday i'm shufflin'

    my $G1 = $G->deep_copy_graph();
    my $v = scalar($G1->vertices());

    my $max_times_to_shuffle = $v * $v;
    my $shuffles = 0;
    while ( $shuffles < $max_times_to_shuffle ) {

	my $v1 = int ( rand($v) );
	my $v2 = int ( rand($v) );

	next if $v1 == $v2;
			    
	$G1 = swap_vertices($G1, $v1,$v2);
	$shuffles++;
    }

    return $G1;
}

##############################################################################

=head2 add_random_edges

Add random edges to a given graph.

     use Graph::Undirected::Hamiltonicity::Transforms qw(&add_random_edges);

     my $G1 = add_random_edges( $G, 7 );

     # $G1 is like $G, but with 7 extra edges.

=cut

sub add_random_edges {
    my ( $G, $edges_to_add ) = @_;

    my $G1 = $G->deep_copy_graph();
    my $v = scalar($G1->vertices());

    my $added_edges = 0;
    while ( $added_edges < $edges_to_add ) {

	my $v1 = int ( rand($v) );
	my $v2 = int ( rand($v) );

	next if $v1 == $v2;
	next if $G1->has_edge($v1,$v2);
			    
	$G1->add_edge($v1,$v2);
	$added_edges++;
    }


    return $G1;
}

##############################################################################

=head1 AUTHOR

Ashwin Dixit, C<< <ashwin at ownlifeful dot com> >>

=cut

1; # End of Graph::Undirected::Hamiltonicity::Transforms
