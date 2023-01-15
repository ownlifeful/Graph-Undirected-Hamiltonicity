
=encoding utf-8

=head1 NAME

Graph::Undirected::Hamiltonicity - decide whether a given Graph::Undirected
    contains a Hamiltonian Cycle.

=head1 VERSION

Version 0.18

=head1 LICENSE

Copyright (C) Ashwin Dixit.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ashwin Dixit, C<< <ashwin at CPAN dot org> >>

=cut


use Modern::Perl;
use lib 'local/lib/perl5';

package Graph::Undirected::Hamiltonicity;

$Graph::Undirected::Hamiltonicity::DONT_KNOW                = 0;
$Graph::Undirected::Hamiltonicity::GRAPH_IS_HAMILTONIAN     = 1;
$Graph::Undirected::Hamiltonicity::GRAPH_IS_NOT_HAMILTONIAN = 2;

# ABSTRACT: decide whether a given Graph::Undirected contains a Hamiltonian Cycle.

# You can get documentation for this module with this command:
#    perldoc Graph::Undirected::Hamiltonicity

use Graph::Undirected::Hamiltonicity::Output;
use Graph::Undirected::Hamiltonicity::Tests;
use Graph::Undirected::Hamiltonicity::Transforms;

use Exporter qw(import);

our $VERSION     = '0.18';
our @EXPORT      = qw(graph_is_hamiltonian);    # exported by default
our @EXPORT_OK   = qw(graph_is_hamiltonian);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

our $calls = 0; ### Number of calls to is_hamiltonian()

$Graph::Undirected::Hamiltonicity::mojo = '';

##########################################################################

sub new {
    my $class = shift;
    my ( %params ) = @_;
   
    my $self = {};

    $self->{output_format} //= $params{output_format} // $ENV{HC_OUTPUT_FORMAT} // 'none';

    if ( $params{graph} ) {
	$self->{g} = $params{graph};
	bless $self, $class;
	return $self;
    }

    $params{graph_text} //= '';
    $params{graph_text} =~ s/[^0-9=,]+//g;
    $params{graph_text} =~ s/([=,])\D+/$1/g;
    $params{graph_text} =~ s/^\D+|\D+$//g;

    my $g;
    if ( $params{graph_text} =~ /\d/ ) {
	eval { $g = Graph::Undirected::Hamiltonicity::string_to_graph($params{graph_text}); };
	if ( my $exception = $@ ) {
	    say "That was not a valid graph, ";
	    say "according to the Graph::Undirected module.<BR/>";
	    say "[", $params{graph_text}, "][$exception]<BR/>";
	    die;
	} else {
	    $self->{g} = $g;
	}
    } else {
	die "Could not create a graph. graph_text=[", $params{graph_text}  ,"]\n";
    }

   bless $self, $class;
   return $self;
}


####################################################################################


# graph_is_hamiltonian()
#
# Takes a Graph::Undirected object.
#
# Returns
#         1 if the given graph contains a Hamiltonian Cycle.
#         0 otherwise.
#

sub graph_is_hamiltonian {
    my ($self) = @_;

    $calls = 0;
    my ( $is_hamiltonian, $reason );
    my $time_begin = time;
    my @once_only_tests = qw( test_trivial test_dirac );
    foreach my $test_sub (@once_only_tests) {
        ( $is_hamiltonian, $reason ) = $self->$test_sub();
        last unless $is_hamiltonian == $Graph::Undirected::Hamiltonicity::DONT_KNOW;
    }

    my $params = {
        transformed => 0,
        tentative   => 0,
    };
    
    if ( $is_hamiltonian == $Graph::Undirected::Hamiltonicity::DONT_KNOW ) {
        ( $is_hamiltonian, $reason, $params ) = $self->is_hamiltonian($params);
    } else {
        my $spaced_string = $self->{g}->stringify();
        $spaced_string =~ s/\,/, /g;
        $self->output("<HR NOSHADE>");
        $self->output("In graph_is_hamiltonian($spaced_string)");
        $self->output();
    }
    my $time_end = time;

    $params->{time_elapsed} = int($time_end - $time_begin);
    $params->{calls}        = $calls;

    my $final_bit = ( $is_hamiltonian == $Graph::Undirected::Hamiltonicity::GRAPH_IS_HAMILTONIAN ) ? 1 : 0;
    return wantarray ? ( $final_bit, $reason, $params ) : $final_bit;
}

##########################################################################

# is_hamiltonian()
#
# Takes a Graph::Undirected object.
#
# Returns a result ( $is_hamiltonian, $reason )
# indicating whether the given graph contains a Hamiltonian Cycle.
#
#

sub is_hamiltonian {
    my ($self, $params) = @_;
    $calls++;

    my $spaced_string = $self->{g}->stringify();
    $spaced_string =~ s/\,/, /g;
    $self->output("<HR NOSHADE>");
    $self->output("Calling is_hamiltonian($spaced_string)");
    $self->output();

    my ( $is_hamiltonian, $reason );
    my @tests_1 = qw(
        test_ore
        test_min_degree
        test_articulation_vertex
        test_graph_bridge
    );

    foreach my $test_sub (@tests_1) {
        ( $is_hamiltonian, $reason ) = $self->$test_sub($params);
        return ( $is_hamiltonian, $reason, $params )
            unless $is_hamiltonian == $Graph::Undirected::Hamiltonicity::DONT_KNOW;
    }

    ### Create a graph made of only required edges.
    $self->create_required_graph();

    if ( $self->{required_graph}->edges() ) {
        my @tests_2 = qw(
            test_required_max_degree
            test_required_connected
            test_required_cyclic );
        foreach my $test_sub (@tests_2) {
            ( $is_hamiltonian, $reason, $params ) = $self->$test_sub($params);
            return ( $is_hamiltonian, $reason, $params )
                unless $is_hamiltonian == $Graph::Undirected::Hamiltonicity::DONT_KNOW;
        }

        ### Delete edges that can be safely eliminated so far.
        my $deleted_edges = $self->delete_cycle_closing_edges();
        my $deleted_edges2 = $self->delete_non_required_neighbors();
        if ($deleted_edges || $deleted_edges2) {
            $params->{transformed} = 1;
	    return $self->is_hamiltonian($params);
        }
    }

    ### If there are undecided vrtices, choose between them recursively.
    my @undecided_vertices = grep { $self->{g}->degree($_) > 2 } $self->{g}->vertices();
    if (@undecided_vertices) {
        unless ( $params->{tentative} ) {
            $self->output(  "Now running an exhaustive, recursive,"
                     . " and conclusive search,"
                     . " only slightly better than brute force.<BR/>" );
        }

        my $vertex =
            $self->get_chosen_vertex( \@undecided_vertices );

        my $tentative_combinations =
            $self->get_tentative_combinations( $vertex );

        foreach my $tentative_edge_pair (@$tentative_combinations) {
	    my $g1 = Graph::Undirected::Hamiltonicity->new( graph => $self->{g}->deep_copy_graph() );
            $self->output("For vertex: $vertex, protecting " .
                    ( join ',', map {"$vertex=$_"} @$tentative_edge_pair ) .
                   "<BR/>" );
            foreach my $neighbor ( $g1->{g}->neighbors($vertex) ) {
                next if $neighbor == $tentative_edge_pair->[0];
                next if $neighbor == $tentative_edge_pair->[1];
                $self->output("Deleting edge: $vertex=$neighbor<BR/>");
                $g1->{g}->delete_edge( $vertex, $neighbor );
            }

            $self->output(   "The Graph with $vertex=" . $tentative_edge_pair->[0]
                    . ", $vertex=" . $tentative_edge_pair->[1]
                    . " protected:<BR/>" );
            $g1->output();

            $params->{tentative} = 1;
            ( $is_hamiltonian, $reason, $params ) = $g1->is_hamiltonian($params);
            if ( $is_hamiltonian == $Graph::Undirected::Hamiltonicity::GRAPH_IS_HAMILTONIAN ) {
                return ( $is_hamiltonian, $reason, $params );
            }
            $self->output("...backtracking.<BR/>");
        }
    }

    return ( $Graph::Undirected::Hamiltonicity::GRAPH_IS_NOT_HAMILTONIAN,
             "The graph passed through an exhaustive search " .
             "for Hamiltonian Cycles.", $params );

}

##########################################################################

sub get_tentative_combinations {

    # Generate all allowable combinations of 2 edges,
    # incident on a given vertex.

    my ( $self, $vertex ) = @_;
    my @tentative_combinations;
    my @neighbors = sort { $a <=> $b } $self->{g}->neighbors($vertex);
    if ( $self->{required_graph}->degree($vertex) == 1 ) {
        my ($fixed_neighbor) = $self->{required_graph}->neighbors($vertex);
        foreach my $tentative_neighbor (@neighbors) {
            next if $fixed_neighbor == $tentative_neighbor;
            push @tentative_combinations,
                [ $fixed_neighbor, $tentative_neighbor ];
        }
    } else {
        for ( my $i = 0; $i < scalar(@neighbors) - 1; $i++ ) {
            for ( my $j = $i + 1; $j < scalar(@neighbors); $j++ ) {
                push @tentative_combinations,
                    [ $neighbors[$i], $neighbors[$j] ];
            }
        }
    }

    return \@tentative_combinations;
}

##########################################################################

sub get_chosen_vertex {
    my ( $self, $undecided_vertices ) = @_;

    # 1. Choose the vertex with the highest degree first.
    #
    # 2. If degrees are equal, prefer vertices which already have
    #    a required edge incident on them.
    #
    # 3. Break a tie from rules 1 & 2, by picking the lowest
    #    numbered vertex first.

    my $chosen_vertex;
    my $chosen_vertex_degree;
    my $chosen_vertex_required_degree;
    foreach my $vertex (@$undecided_vertices) {
        my $degree          = $self->{g}->degree($vertex);
        my $required_degree = $self->{required_graph}->degree($vertex);
        if (   ( !defined $chosen_vertex_degree )
            or ( $degree > $chosen_vertex_degree )
            or (    ( $degree == $chosen_vertex_degree )
                and ( $required_degree > $chosen_vertex_required_degree ) )
            or (    ( $degree == $chosen_vertex_degree )
                and ( $required_degree == $chosen_vertex_required_degree )
                and ( $vertex < $chosen_vertex ) )
            )
        {
            $chosen_vertex                 = $vertex;
            $chosen_vertex_degree          = $degree;
            $chosen_vertex_required_degree = $required_degree;
        }
    }

    return $chosen_vertex;
}

##########################################################################

1;    # End of Graph::Undirected::Hamiltonicity
