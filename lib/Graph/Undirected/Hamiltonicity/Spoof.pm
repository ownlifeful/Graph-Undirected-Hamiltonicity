package Graph::Undirected::Hamiltonicity::Spoof;

use 5.006;
use strict;
use warnings;

use Graph::Undirected::Hamiltonicity::Transforms qw(shuffle);

use Exporter qw(import);

our @EXPORT_OK =  qw(
                     &get_canonical_hamiltonian_graph
                     &get_known_hamiltonian_graph
                     &add_random_edges
        );

our %EXPORT_TAGS = (
    all       =>  \@EXPORT_OK,
);


=head1 NAME

Graph::Undirected::Hamiltonicity::Spoof - Set of functions to spoof undirected graphs.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This module is a collection of subroutines for spoofing random graphs with given
properties.


    use Graph::Undirected::Hamiltonicity::Spoof qw(&get_known_hamiltonian_graph);

    my $v = 30;
    my $e = 50;
    my $G = get_known_hamiltonian_graph($v,$e);

    ### $G is an instance of Graph::Undirected
    ### $G is a random Hamiltonian graph with $v vertices and $e edges.

=head1 EXPORT

No symbols are exported by default.

You can load all the subroutines of this package as shown:

    use Graph::Undirected::Hamiltonicity::Spoof qw(:all);

The subroutines that can be imported individually, by name, are:

=over 4

=item * &get_canonical_hamiltonian_graph

=item * &get_known_hamiltonian_graph

=item * &add_random_edges

=back

=head1 SUBROUTINES

=cut

##############################################################################

=head2 get_canonical_hamiltonian_graph

Takes: $v, the number of vertices desired.

Returns: a Graph::Undirected with $v vertices, and $v edges.
         This graph is not random, but the canonical,
         ( regular-polygon-shaped ) Hamiltonian Cycle.
=cut

sub get_canonical_hamiltonian_graph {
    my ( $v ) = @_;

    my $last_vertex = $v - 1;
    my @vertices = ( 0 .. $last_vertex );
    my $G = new Graph::Undirected( vertices => \@vertices );
    $G->add_edge( 0, $last_vertex );

    for ( my $i = 0; $i < $last_vertex; $i++ ) {
	$G->add_edge( $i, $i + 1 );
    }

    print "G=[$G] on line: ", __LINE__, "\n"; ### DEBUG

    return $G;
}

##############################################################################


=head2 get_known_hamiltonian_graph

Spoof a randomized Hamiltonian graph with the specified number of vertices
and edges.

Takes: $v, the number of vertices desired.
       $e, the number of edges desired. ( optional )

Returns: a Graph::Undirected with $v vertices, and $e edges.
         This graph is random, and Hamiltonian.

=cut

sub get_known_hamiltonian_graph {

    my ( $v, $e ) = @_;

    $v =~ s/\D+//g;
    die "Please provide the number of vertices\n" unless $v > 0;

    if ( defined( $e ) and ( $e > 0 ) ) {
	# Sanitize
	$e =~ s/\D+//g;
    } else {
	# Generate random
	$e = int( rand( 2 - 2 * $v + ($v * $v - $v)/2 ) ) - $v;
    }

    my $G = get_canonical_hamiltonian_graph($v);

    $G = shuffle( $G );

    $G = add_random_edges($G, $e - $v);

    print "G=[$G] on line: ", __LINE__, "\n"; ### DEBUG

    return $G;
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

	print "v1=$v1;\tv2=$v2;\tv=$v;\tadded_edges=$added_edges;\tG1=[$G1] on line:", __LINE__, "\n"; ### DEBUG

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

=head1 BUGS

Please report any bugs or feature requests to C<bug-graph-undirected-hamiltonicity at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Undirected-Hamiltonicity>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Graph::Undirected::Hamiltonicity::Spoof


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

1; # End of Graph::Undirected::Hamiltonicity::Spoof
