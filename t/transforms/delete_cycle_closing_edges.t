#!perl
use 5.006;
use strict;
use warnings;

use Graph::Undirected::Hamiltonicity::Transforms
    qw(
       &get_required_graph
       &delete_cycle_closing_edges
       &string_to_graph
    );

use Test::More;

plan tests => 3;

my $herschel_graph_text =
    '0=1,0=10,0=3,0=9,10=6,10=8,1=2,1=4,2=5,2=9,3=4,3=6,4=5,4=7,5=8,6=7,7=8,8=9';

my @tests = (
    {   input_graph_text           => $herschel_graph_text,
        expected_deleted_edges     => 0,
        expected_output_graph_text => $herschel_graph_text
    },
    {   input_graph_text           => '0=1,0=3,1=2,2=3,2=8,3=4,3=5,3=7,4=6,4=7,4=8,5=6,5=7,6=7,6=8',
        expected_deleted_edges     => 1,
        expected_output_graph_text => '0=1,0=3,1=2,2=8,3=4,3=5,3=7,4=6,4=7,4=8,5=6,5=7,6=7,6=8' ## delete 2=3
    },
);

foreach my $test (@tests) {
    my $g = string_to_graph( $test->{input_graph_text} );

    my ( $required_graph, $g1 ) = get_required_graph($g);

    my ( $deleted_edges, $output_graph ) = delete_cycle_closing_edges($g, $required_graph);

    is( $deleted_edges,
        $test->{expected_deleted_edges},
        "Deleted the expected number of cycle closing edges."
    );

    if ( $deleted_edges ) {
        is( "$output_graph",
            $test->{expected_output_graph_text},
            "Deleted all the cycle closing edges expected."
            );
    }

}

