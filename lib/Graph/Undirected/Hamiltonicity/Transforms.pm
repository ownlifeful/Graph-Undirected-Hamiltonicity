package Graph::Undirected::Hamiltonicity::Transforms;

use 5.006;
use strict;
use warnings;

use Graph::Undirected::Hamiltonicity::Output qw(:all);

use Exporter qw(import);

our @EXPORT_OK =  qw(
                     &common_neighbors
                     &delete_non_required_neighbors
                     &delete_unusable_edges
                     &get_required_graph
                     &graph_to_bitvector
                     &graphs_are_identical
                     &mark_required_edges
                     &maximize
                     &rotate
                     &shrink_required_walks_longer_than_2_edges
                     &shuffle
                     &string_to_graph
                     &swap_vertices
        );

our %EXPORT_TAGS = (
    all       =>  \@EXPORT_OK,
);


=head1 NAME

Graph::Undirected::Hamiltonicity::Transforms - The great new Graph::Undirected::Hamiltonicity::Transforms!

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

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

##################################################### BEGIN subs


sub mark_required_edges {
    ### For each vertex in the graph that has degree == 2,
    ### mark the edges adjacent to the vertex as "required".

    my ($G1) = @_;

    Graph::Undirected::Hamiltonicity::output("Beginning a sweep to mark all edges adjacent to degree 2 "
        . "vertices as required:<BR/>");


    output($G1); ### DEBUG: REMOVE THIS!!!!!!!!!!!!!!

    foreach my $vertex ( sort { $a <=> $b } $G1->vertices() ) {
        my $degree = $G1->degree($vertex);
        output("Vertex $vertex : Degree=[$degree]<BR/>");

        if ( $degree == 2 ) {
            output("<UL>");
            foreach my $neighbor_vertex ( $G1->neighbors($vertex) ) {

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

}

##########################################################################

sub get_required_graph {
    ### Return a graph with all the vertices of the original graph,
    ### but only the edges marked "required".

    my ($G1) = @_;

    my @vertices = $G1->vertices;

    ### Create a graph made of only required edges.
    my $required_graph = new Graph::Undirected( vertices => \@vertices );
    my @E1 = $G1->edges();
    foreach my $edge_ref (@E1) {
        if ( $G1->get_edge_attribute( @$edge_ref, 'required' ) ) {
            ### Construct the graph of required edges.
            unless ( $required_graph->has_edge(@$edge_ref) ) {
                $required_graph->add_edge(@$edge_ref);
            }
        }
    }

    return $required_graph;
}

##########################################################################

sub delete_unusable_edges {

    ### Delete edge connecting neighbors of degree 2 vertex.
    my ( $required_graph, $G1 ) = @_;
    my $deleted_edges = 0;

    foreach my $vertex ( $G1->vertices() ) {
        if ( $G1->degree($vertex) == 2 ) {
            my @neighbors =
                $G1->neighbors($vertex);    ### There are only two neighbors.
            if ( $G1->has_edge(@neighbors) ) {
                $G1->delete_edge(@neighbors);
                $deleted_edges++;
                output("Deleted edge " . ( join '=', @neighbors ) .
                    ", between neighbors of a degree 2 vertex ($vertex)<BR/>");
            }
        }
    }

    return $deleted_edges;
}

##########################################################################

sub delete_non_required_neighbors {
    my ( $required_graph, $G1 ) = @_;

    ### Delete all non-required edges adjacent to vertices adjacent 
    ### to 2 required edges.

    my $deleted_edges;
    foreach my $required_vertex ( $required_graph->vertices() ) {
        if ( 2 == $required_graph->degree($required_vertex) ) {
            foreach my $neighbor_vertex ( $G1->neighbors($required_vertex) ) {
                my $required =
                    $G1->get_edge_attribute( $required_vertex,
                    $neighbor_vertex, 'required' );
                unless ($required) {
                    $G1->delete_edge( $required_vertex, $neighbor_vertex );
                    $deleted_edges++;
                    output("Deleted edge $required_vertex=$neighbor_vertex " .
                      "because vertex $required_vertex has degree==2 in the " .
                      "required graph.<BR/>");
                }
            }
        }
    }

    if ($deleted_edges) {
        output("Here is the graph of required edges:<BR/>");
        output( $required_graph, { required => 1 } );
    }

    return $deleted_edges;
}

##########################################################################

sub shrink_required_walks_longer_than_2_edges {
    my ( $required_graph, $G ) = @_;

    my $G1 = $G->deep_copy_graph();
    my $deleted_edges = 0;

    foreach my $vertex ( $required_graph->vertices() ) {
        next unless $required_graph->degree($vertex) == 2;

        my @neighbors = $required_graph->neighbors($vertex);
        next
            if (( $required_graph->degree( $neighbors[0] ) == 1 )
            and ( $required_graph->degree( $neighbors[1] ) == 1 ) );

        unless ( $G1->has_edge(@neighbors) ) {
            $required_graph->add_edge(@neighbors);
            $G1->add_edge(@neighbors);
            $G1->set_edge_attribute( @neighbors, 'required', 1 );
            output("Added edge $neighbors[0]=$neighbors[1] and ");
        }

        output("deleted vertex $vertex because it was part of a " .
               "long required walk.<BR/>");
        $required_graph->delete_vertex($vertex);
        $G1->delete_vertex($vertex);
        $deleted_edges++;
    }

    return ( $deleted_edges, $G1 );
}

##########################################################################

sub swap_vertices {
    my ( $G1, $vertex_1, $vertex_2 ) = @_;

    my $G = $G1->deep_copy_graph();

    my %common_neighbors =
      common_neighbors( $G, $vertex_1, $vertex_2 );

    my @vertex_1_neighbors = grep { $_ != $vertex_2 } $G->neighbors($vertex_1);
    my @vertex_2_neighbors = grep { $_ != $vertex_1 } $G->neighbors($vertex_2);

    foreach my $neighbor_vertex ( @vertex_1_neighbors ) {
      next if $common_neighbors{$neighbor_vertex};
      $G->delete_edge($neighbor_vertex, $vertex_1);
      $G->add_edge($neighbor_vertex, $vertex_2);
    }

    foreach my $neighbor_vertex ( @vertex_2_neighbors ) {
      next if $common_neighbors{$neighbor_vertex};
      $G->delete_edge($neighbor_vertex, $vertex_2);
      $G->add_edge($neighbor_vertex, $vertex_1);
    }

    return $G;
}

##########################################################################

sub common_neighbors {
    my ( $G, $vertex_1, $vertex_2 ) = @_;

    my %common_neighbors;
    my %vertex_1_neighbors;
    foreach my $neighbor_vertex ( $G->neighbors($vertex_1) ) {
        $vertex_1_neighbors{$neighbor_vertex}++;
        ###    unless $neighbor_vertex == $vertex_2;
    }

    foreach my $neighbor_vertex ( $G->neighbors($vertex_2) ) {
        next unless $vertex_1_neighbors{$neighbor_vertex};
        $common_neighbors{$neighbor_vertex} = 1;
    }

    return %common_neighbors;

}

##########################################################################

sub graph_to_bitvector {
   ### return a Bitvector derived from a given graph

    my ( $G ) = @_;
    my @vertices = sort { $a <=> $b } $G->vertices();
    my $v = scalar(@vertices);
    my $max_edges = ( $v * $v - $v ) / 2;
    my $bitvector = Bit::Vector->new( $max_edges );
    my $bit_index = $max_edges - 1;

    my $y1 = $vertices[1];
    my $y2 = scalar(@vertices) - 1; # $#vertices is deprecated.

    while ( $y1 < $y2 ) {
        my $y = $y2;
        for (my $x = 0; $x < $v - 1; $x++ ) {
            last if $y == $v;
            if ( $G->has_edge( $vertices[$x], $vertices[$y] ) ) {
                $bitvector->Bit_On( $bit_index );
            }

            $bit_index--;
            $y++;
        }

        $y = $y1;
        for (my $x = 0; $x < $v - 1; $x++ ) {
            last if $y == $v;
            if ( $G->has_edge( $vertices[$x], $vertices[$y] ) ) {
                $bitvector->Bit_On( $bit_index );
            }

            $bit_index--;
            $y++;
        }

        $y1++;
        $y2--;
    }

    return $bitvector;
}

##########################################################################


sub maximize {
    my ( $G, @maximization_steps ) = @_;
    my @vertices = sort { $a <=> $b } $G->vertices();

    output("Now trying to maximize the graph value.<BR/>");
    output($G);

    my $binary_string = graph_to_bitvector($G)->to_Bin();

    my %isomorphs;
    foreach my $i ( @vertices ) {
        foreach my $j ( @vertices ) {
            last if $i == $j;
            my $G2 = swap_vertices($G, $i, $j);

            ### Reconsider this.
#           my ( $is_hamiltonian, $reason ) = test_canonical($G2);
#           if ( $is_hamiltonian == $GRAPH_IS_HAMILTONIAN ) {
#               return $G2;
#           }

            my $swapped_binary_string = graph_to_bitvector($G2)->to_Bin();
            if ( $swapped_binary_string > $binary_string ) {
                $isomorphs{ "$i=$j" } = $swapped_binary_string;
            }
        }
    }

    my @sorted_isomorphs = sort {
        $isomorphs{$b} <=> $isomorphs{$a}
    } keys %isomorphs;

    if ( scalar(@sorted_isomorphs) > 0 ) {
        my ( $i, $j ) = split ( /=/, $sorted_isomorphs[ 0 ] ); # -1 means greedy, 0 means non-greedy    
        my $next_highest_graph = swap_vertices($G, $i, $j );

        push @maximization_steps, $i, $j;

        output("Swapped vertices $i and $j<BR/>");
        output("<CODE>$binary_string</CODE><BR/>");
        output("<CODE>" . ( graph_to_bitvector($next_highest_graph)->to_Bin() ) .
               "</CODE><BR/>");
        return maximize($next_highest_graph, @maximization_steps);
    }

    output("The maximized graph is:");
    output($G);

    return ( $G, @maximization_steps );

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

    my @vertices = sort { $a <=> $b } keys %vertices;
    my $G = new Graph::Undirected( vertices => \@vertices );

    foreach my $edge_ref ( @edges ) {
        $G->add_edge(@$edge_ref) unless $G->has_edge(@$edge_ref);
    }

    return $G;
 }

##########################################################################

sub rotate {
    my ( $G ) = @_;
    my @vertices = sort { $a <=> $b } $G->vertices();
    my $v = scalar(@vertices);

    my $rotated_graph = new Graph::Undirected( vertices => \@vertices );

    my @E = $G->edges();
    foreach my $edge_ref (@E) { 
        $rotated_graph->add_edge( map { ( $_ + 1 ) % $v  } @$edge_ref );
    }

    output("The rotated graph is: ($rotated_graph)<BR/>");
    mark_required_edges($rotated_graph);
    output($rotated_graph);

    return $rotated_graph;
}

##########################################################################

=head2 graphs_are_identical

Takes two Graph::Undirected objects and compares them for equality.

Returns 1 if graphs are identical, 0 otherwise.

=cut

sub graphs_are_identical {
    my ( $G1, $G2 ) = @_;

    ### Commpare number of vertices
    my $vertices_1 = scalar( $G1->vertices() );
    my $vertices_2 = scalar( $G2->vertices() );
    return 0 if $vertices_1 != $vertices_2;

    ### Commpare number of edges
    my $edges_1 = scalar( $G1->edges() );
    my $edges_2 = scalar( $G2->edges() );
    return 0 if $edges_1 != $edges_2;


    ### Compare each edge
    my @edges_1 = $G1->edges();
    foreach my $edge_ref_1 ( @edges_1 ) {       
        return 0 unless $G2->has_edge( @$edge_ref_1 );
    }

    return 1;
}


##########################################################################

sub shuffle {
    # everyday i'm shufflin'

    my ( $G ) = @_;

    print "G=[$G] on line: ", __LINE__, "\n"; ### DEBUG

    my $G1 = $G->deep_copy_graph();

    my @vertices = $G1->vertices();
    my $v = scalar(@vertices);

    my $max_times_to_shuffle = rand ( $v * $v );
    my $shuffles = 0;
    while ( $shuffles < $max_times_to_shuffle ) {

	my $v1 = int ( rand($v) );
	my $v2 = int ( rand($v) );

	print "v1=$v1;\tv2=$v2 on line:", __LINE__, "\n"; ### DEBUG

	next if $v1 == $v2;
			    
	$G1 = swap_vertices($G1, $v1,$v2);
	$shuffles++;
    }

    print "G1=[$G1] on line: ", __LINE__, "\n"; ### DEBUG

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
