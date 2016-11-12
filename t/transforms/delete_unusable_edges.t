#!perl
use 5.006;
use strict;
use warnings;

use Graph::Undirected::Hamiltonicity::Transforms
    qw(&string_to_graph &delete_unusable_edges);

use Test::More;

plan tests => 6;

my $herschel_graph_text =
    '0=1,0=10,0=3,0=9,10=6,10=8,1=2,1=4,2=5,2=9,3=4,3=6,4=5,4=7,5=8,6=7,7=8,8=9';

my @tests = (
    {   input_graph_text           => $herschel_graph_text,
        expected_deleted_edges     => 0,
        expected_output_graph_text => $herschel_graph_text
    },
    {   input_graph_text           => '0=1,0=2,1=2,1=3,2=3',
        expected_deleted_edges     => 1,
        expected_output_graph_text => '0=1,0=2,1=3,2=3'
    },
    {   input_graph_text =>
            '0=1,0=4,1=2,1=4,2=3,2=5,3=5,4=6,5=7,6=8,6=9,7=10,7=11,8=9,9=10,10=11',
        expected_deleted_edges => 4,
        expected_output_graph_text =>
            '0=1,0=4,10=11,10=9,11=7,1=2,2=3,3=5,4=6,5=7,6=8,8=9',
    },

);

foreach my $test (@tests) {
    my $g = string_to_graph( $test->{input_graph_text} );

    my ( $deleted_edges, $output_graph ) = delete_unusable_edges($g);

    is( $deleted_edges,
        $test->{expected_deleted_edges},
        "Deleted the expected number of unusable edges."
    );
    is( "$output_graph",
        $test->{expected_output_graph_text},
        "Deleted all the unusable edges expected."
    );
}

