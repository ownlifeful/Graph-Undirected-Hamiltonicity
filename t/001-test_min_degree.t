#!perl
use 5.006;
use strict;
use warnings;

use Graph::Undirected;
use Graph::Undirected::Hamiltonicity::Tests qw(:all);

use Test::More;

plan tests => 6;

subtest "A 2 vertex, 1 edge graph" => sub {
    my $G = Graph::Undirected->new( vertices => [ 0, 1 ] );
    $G->add_edge(0,1);
    my ( $is_hamiltonian, $reason ) = test_min_degree($G);
    is( $is_hamiltonian, $GRAPH_IS_NOT_HAMILTONIAN, "A 2 vertex, 1 edge graph is not Hamiltonian.");
};

subtest "A 3 vertex, 2 edge graph" => sub {
    my $G = Graph::Undirected->new( vertices => [ 0 .. 2 ] );
    $G->add_edge(0,1);
    $G->add_edge(0,2);
    my ( $is_hamiltonian, $reason ) = test_min_degree($G);
    is( $is_hamiltonian, $GRAPH_IS_NOT_HAMILTONIAN, "A 3 vertex, 2 edge graph is not Hamiltonian.");
};

subtest "A 3 vertex, 3 edge graph" => sub {
    my $G = Graph::Undirected->new( vertices => [ 0 .. 2 ] );
    $G->add_edge(0,1);
    $G->add_edge(0,2);
    $G->add_edge(1,2);
    my ( $is_hamiltonian, $reason ) = test_min_degree($G);
    is( $is_hamiltonian, $DONT_KNOW, "A 3 vertex, 3 edge graph doesn't get test_min_degree() to a conclusion.");
};

subtest "A 4 vertex, 5 edge graph" => sub {
    my $G = Graph::Undirected->new( vertices => [ 0 .. 3 ] );
    $G->add_edge(0,1);
    $G->add_edge(0,2);
    $G->add_edge(1,2);
    $G->add_edge(1,3);
    $G->add_edge(2,3);
    my ( $is_hamiltonian, $reason ) = test_min_degree($G);
    is( $is_hamiltonian, $DONT_KNOW, "this 4 vertex, 5 edge graph doesn't get test_min_degree() to a conclusion.");
};

subtest "A 4 vertex, 4 edge graph" => sub {
    my $G = Graph::Undirected->new( vertices => [ 0 .. 3 ] );
    $G->add_edge(0,1);
    $G->add_edge(0,2);
    $G->add_edge(0,3);
    $G->add_edge(1,2);

    my ( $is_hamiltonian, $reason ) = test_min_degree($G);
    is( $is_hamiltonian, $GRAPH_IS_NOT_HAMILTONIAN, "this 4 vertex, 4 edge graph is not Hamiltonian.");
};


subtest "A slightly more complex graph" => sub {
    my $G = Graph::Undirected->new( vertices => [ 0 .. 4 ] );
    $G->add_edge(0,1);
    $G->add_edge(0,4);
    $G->add_edge(1,2);
    $G->add_edge(1,3);
    $G->add_edge(2,3);
    $G->add_edge(2,4);
    $G->add_edge(3,4);
    my ( $is_hamiltonian, $reason ) = test_min_degree($G);
    is( $is_hamiltonian, $DONT_KNOW, "this graph doesn't let test_min_degree() reach a conclusion.");
};


1;

