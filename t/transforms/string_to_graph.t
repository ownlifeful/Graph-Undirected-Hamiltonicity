#!perl
use 5.006;
use strict;
use warnings;

use Graph::Undirected::Hamiltonicity::Transforms qw(&string_to_graph);

use Test::More;

plan tests => 21;

my $herschel_graph_text = '0=1,0=10,0=3,0=9,10=6,10=8,1=2,1=4,2=5,2=9,3=4,3=6,4=5,4=7,5=8,6=7,7=8,8=9';

my @tests = (
    {
        input_graph_text => $herschel_graph_text,
        expected_edge_count => 18,
        expected_vertex_count => 11
    },
    {
        input_graph_text => '0=1,0=2,1=2,1=3,2=3',
        expected_edge_count => 5,
        expected_vertex_count => 4
    },
    {
        input_graph_text => '0=1,0=4,10=11,10=7,10=9,11=7,1=2,1=4,2=3,2=5,3=5,4=6,5=7,6=8,6=9,8=9',
        expected_edge_count => 16,
        expected_vertex_count => 12
    },
    {
        input_graph_text => '0=1,0=2,0=6,1=3,1=7,2=3,2=4,3=5,4=5,5=7',
        expected_edge_count => 10,
        expected_vertex_count => 8
    },
    {
        input_graph_text => '0=1,0=4,10=11,10=7,10=9,11=7,1=2,1=4,2=3,2=5,3=5,4=6,5=7,6=8,6=9,8=9',
        expected_edge_count => 16,
        expected_vertex_count => 12
    },
    {
        input_graph_text => '0=1,0=2,1=2,1=3,2=3',
        expected_edge_count => 5,
        expected_vertex_count => 4
    },
    {
        input_graph_text => '0=1,0=6,2=4,3=4,3=5',
        expected_edge_count => 5,
        expected_vertex_count => 7
    },

    );

foreach my $test ( @tests ) {
    my $G = string_to_graph($test->{input_graph_text});

    is( scalar( $G->vertices() ), $test->{expected_vertex_count}, "Preserved number of vertices.");
    is( scalar( $G->edges() ), $test->{expected_edge_count}, "Preserved number of edges.");
    is( "$G", $test->{input_graph_text}, "Graph to string is the same as string to graph.");
}
