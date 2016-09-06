#!/usr/bin/env perl

use Getopt::Long;

use Graph::Undirected;
use Graph::Undirected::Hamiltonicity qw(:all);
use Graph::Undirected::Hamiltonicity::Transforms qw(string_to_graph);
use Graph::Undirected::Hamiltonicity::Spoof qw(get_known_hamiltonian_graph);

use warnings;
use strict;

=head2
--graph_text=
--graph_file=
--vertices=
--edges=
--count=
--output_format=
=cut

my $graph_file = '';
my $graph_text = '';
my $v = 0;
my $e = 0;
my $count = 1;
my $output_format = 'none';
my @G = ();


GetOptions ("graph_file|f=s"     => \$graph_file,
	    "graph_text|t=s"     => \$graph_text,
	    "vertices|v=i"       => \$v,
	    "edges|e=i"          => \$e,
	    "count|c=i"          => \$count,
	    "output_format|o=s"  => \$output_format
	    )
    or die("Error in command line arguments\n");

if ( $graph_file )  {
    open ( my $fh, "<", $graph_file ) or die "Could not open [$graph_file][$!]\n";
    while ( defined ( my $line = <$fh> ) ) {
	chomp $line;
	next if $line =~ /^\s*#/; ### allow comments
	$line =~ s/[^0-9,=]+//g;
	next unless $line;
	push @G, string_to_graph($line);
    }
    close($fh);

} elsif ( $graph_text ) {
    push @G, string_to_graph($graph_text);
} elsif ( $v ) {
    $count ||= 1;
    for ( my $i = 0; $i < $count; $i++ ) {
	push @G, get_known_hamiltonian_graph($v, $e);
    }

} else {
    die "Show instructions here.\n"; ### DEBUG
}

$ENV{HC_OUTPUT_FORMAT} = ( $output_format =~ /^(html|text|none)$/ ) ? $output_format : 'none';

foreach my $G ( @G ) {
    my $result = graph_is_hamiltonian($G);

    print "graph=($G)\n";
    print "Conclusion:\n";
    if ( $result->{is_hamiltonian} ) {
	print "The graph is Hamiltonian.\n";
    } else {
	print "The graph is not Hamiltonian.\n";
    }

    print "(", $result->{reason}, ")\n" if defined $result->{reason};

    print "\n\n";
}

##############################################################################
