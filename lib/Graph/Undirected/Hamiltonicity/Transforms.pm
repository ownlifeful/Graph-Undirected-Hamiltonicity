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

Graph::Undirected::Hamiltonicity::Transforms - subroutines related to transformations on undirected graphs.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Graph::Undirected::Hamiltonicity::Transforms;

    my $foo = Graph::Undirected::Hamiltonicity::Transforms->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES

=head2 function1

=cut

sub function1 {
}

##################################################### BEGIN subs


sub get_required_graph {
    ### For each vertex in the graph that has degree == 2,
    ### mark the edges adjacent to the vertex as "required".

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

sub delete_unusable_edges {

    ### Delete edge connecting neighbors of degree 2 vertex.
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

sub delete_non_required_neighbors {
    my ( $required_graph, $G ) = @_;

    ### Delete all non-required edges adjacent to vertices adjacent 
    ### to 2 required edges.

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

sub shuffle {
    # everyday i'm shufflin'

    my ( $G ) = @_;
    my $G1 = $G->deep_copy_graph();
    my $v = scalar($G1->vertices());

    my $max_times_to_shuffle = int( rand ( $v * $v ) );
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

Add random edges to a given Graph::Undirected

Takes:
       $G, a Graph::Undirected
       $edges_to_add, the number of random edges to add to the original graph.

Returns:
       $G1, a copy of $G with $edges_to_add random edges added.

=cut

sub add_random_edges {
    my ( $G, $edges_to_add ) = @_;

    my $G1 = $G->deep_copy_graph();

    my @vertices = $G1->vertices();
    my $v = scalar(@vertices);

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

##################################################### END subs


=head1 AUTHOR

Ashwin Dixit, C<< <ashwin at ownlifeful dot com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-graph-undirected-hamiltonicity at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Undirected-Hamiltonicity>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Ashwin Dixit.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1; # End of Graph::Undirected::Hamiltonicity::Transforms
