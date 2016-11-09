#!perl
use 5.006;
use strict;
use warnings;

use Graph::Undirected::Hamiltonicity::Transforms
    qw(&string_to_graph &shrink_required_walks_longer_than_2_edges);

use Test::More;

plan tests => 20;

my $herschel_graph_text =
    '0=1,0=10,0=3,0=9,10=6,10=8,1=2,1=4,2=5,2=9,3=4,3=6,4=5,4=7,5=8,6=7,7=8,8=9';
my $squares_graph_text = '0=1,0=2,0=6,1=3,1=7,2=3,2=4,3=5,4=5,5=7,6=7';

my @tests = (
    {   input_graph_text           => $herschel_graph_text,
        input_required_graph_text  => '0=1,0=3,5=8,7=8',
        expected_deleted_edges     => 0,
        expected_output_graph_text => $herschel_graph_text
    },
    {   input_graph_text           => '0=1,0=2,1=2,1=3,2=3',
        input_required_graph_text  => '0=1,0=2',
        expected_deleted_edges     => 0,
        expected_output_graph_text => '0=1,0=2,1=2,1=3,2=3'
    },
    {   input_graph_text           => '0=1,0=2,1=2,1=3,2=3',
        input_required_graph_text  => '0=1,0=2,2=3',
        expected_deleted_edges     => 1,
        expected_output_graph_text => '1=2,1=3,2=3'
    },
    {   input_graph_text           => '0=1,0=2,1=2,1=3,2=3',
        input_required_graph_text  => '0=1,1=2,2=3',
        expected_deleted_edges     => 1,
        expected_output_graph_text => '0=2,2=3'
    },
    {   input_graph_text          => $herschel_graph_text,
        input_required_graph_text => '2=5,5=8,6=10,8=10',
        expected_deleted_edges    => 2,
        expected_output_graph_text =>
            '0=1,0=10,0=3,0=9,10=2,10=6,1=2,1=4,2=9,3=4,3=6,4=7,6=7'
    },
    {   input_graph_text           => $squares_graph_text,
        input_required_graph_text  => '0=2,2=4,4=5',
        expected_deleted_edges     => 1,
        expected_output_graph_text => '0=1,0=4,0=6,1=3,1=7,3=5,4=5,5=7,6=7'
    },
    {   input_graph_text           => $squares_graph_text,
        input_required_graph_text  => '0=2,2=4,4=5,5=7',
        expected_deleted_edges     => 2,
        expected_output_graph_text => '0=1,0=5,0=6,1=3,1=7,3=5,5=7,6=7'
    },
    {   input_graph_text           => $squares_graph_text,
        input_required_graph_text  => '0=2,2=4,4=5,5=7,7=1',
        expected_deleted_edges     => 3,
        expected_output_graph_text => '0=1,0=6,0=7,1=3,1=7,6=7'
    },
    {   input_graph_text           => $squares_graph_text,
        input_required_graph_text  => '0=2,2=3,3=1,6=4,4=5,5=7',
        expected_deleted_edges     => 2,
        expected_output_graph_text => '0=1,0=3,0=6,1=3,1=7,3=5,5=6,5=7,6=7'
    },
    {   input_graph_text           => $squares_graph_text,
        input_required_graph_text  => '0=2,2=4,4=6,6=7,7=5,5=3,3=1',
        expected_deleted_edges     => 4,
        expected_output_graph_text => '0=1,0=6,1=7,6=7'
    },

);

foreach my $test (@tests) {

    my $required_graph =
        string_to_graph( $test->{input_required_graph_text} );

    my $G = string_to_graph( $test->{input_graph_text} );
    foreach my $edge_ref ( $required_graph->edges() ) {
        $G->set_edge_attribute( @$edge_ref, 'required', 1 );
    }

    my ( $deleted_edges, $output_graph ) =
        shrink_required_walks_longer_than_2_edges( $G, $required_graph );

    is( $deleted_edges,
        $test->{expected_deleted_edges},
        "Deleted the expected number of edges."
    );
    is( "$output_graph",
        $test->{expected_output_graph_text},
        "Resulting graph is as expected."
    );
}

