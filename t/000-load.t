#!perl -T
use 5.006;
use strict;
use warnings;
use perl5lib;
use Test::More;

plan tests => 5;

BEGIN {
    use_ok( 'Graph::Undirected::Hamiltonicity' ) || print "Bail out Hamiltonicity!\n";
    use_ok( 'Graph::Undirected::Hamiltonicity::Output' ) || print "Bail out Output!\n";
    use_ok( 'Graph::Undirected::Hamiltonicity::Spoof' ) || print "Bail out Spoof!\n";
    use_ok( 'Graph::Undirected::Hamiltonicity::Transforms' ) || print "Bail out Transforms!\n";
    use_ok( 'Graph::Undirected::Hamiltonicity::Tests' ) || print "Bail out Tests!\n";
}

diag( "Testing Graph::Undirected::Hamiltonicity $Graph::Undirected::Hamiltonicity::VERSION, Perl $], $^X" );
