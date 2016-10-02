package Graph::Undirected::Hamiltonicity::Spoof;

use 5.006;
use strict;
use warnings;

use Graph::Undirected;
use Graph::Undirected::Hamiltonicity::Transforms qw(add_random_edges shuffle);

use Exporter qw(import);

our @EXPORT_OK =  qw(
                     &spoof_canonical_hamiltonian_graph
                     &spoof_known_hamiltonian_graph
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


    use Graph::Undirected::Hamiltonicity::Spoof qw(&spoof_known_hamiltonian_graph);

    my $v = 30;
    my $e = 50;
    my $G = spoof_known_hamiltonian_graph($v,$e);

    ### $G is an instance of Graph::Undirected
    ### $G is a random Hamiltonian graph with $v vertices and $e edges.

=head1 EXPORT

No symbols are exported by default.

You can load all the subroutines of this package as shown:

    use Graph::Undirected::Hamiltonicity::Spoof qw(:all);

The subroutines that can be imported individually, by name, are:

=over 4

=item * &spoof_canonical_hamiltonian_graph

=item * &spoof_known_hamiltonian_graph

=back

=head1 SUBROUTINES

=cut

##############################################################################

=head2 spoof_canonical_hamiltonian_graph

Takes: $v, the number of vertices desired.

Returns: a Graph::Undirected with $v vertices, and $v edges.
         This graph is not random, but the canonical,
         ( regular-polygon-shaped ) Hamiltonian Cycle.
=cut

sub spoof_canonical_hamiltonian_graph {
    my ( $v ) = @_;

    my $last_vertex = $v - 1;
    my @vertices = ( 0 .. $last_vertex );

    my $G = new Graph::Undirected( vertices => \@vertices );
    $G->add_edge( 0, $last_vertex );

    for ( my $i = 0; $i < $last_vertex; $i++ ) {
	$G->add_edge( $i, $i + 1 );
    }

    return $G;
}

##############################################################################


=head2 spoof_known_hamiltonian_graph

Spoof a randomized Hamiltonian graph with the specified number of vertices
and edges.

Takes: $v, the number of vertices desired.
       $e, the number of edges desired. ( optional )

Returns: a Graph::Undirected with $v vertices, and $e edges.
         This graph is random, and Hamiltonian.

=cut

sub spoof_known_hamiltonian_graph {

    my ( $v, $e ) = @_;

    $v =~ s/\D+//g;
    die "Please provide the number of vertices\n" unless $v > 0;

    if ( defined( $e ) and ( $e > 0 ) ) {
	# Sanitize
	$e =~ s/\D+//g;
    }

    # Generate random
    my $max_edges = ( $v * $v - $v ) / 2;
    $e ||= int( rand( $max_edges - 2 * $v + 2  )  ) + $v;

    my $G = spoof_canonical_hamiltonian_graph($v);
    $G = shuffle( $G );
    $G = add_random_edges($G, $e - $v);

    return $G;
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
