#!/usr/bin/perl env

use Modern::Perl;

my $DEBUG = 1;

use lib qw(/vagrant/GitHub/Graph-Undirected-Hamiltonicity/lib);

use Graph::Undirected;
use Graph::Undirected::Hamiltonicity;

my $board_size = 8; # 8x8 board






my ( @vertices, @edges, @A, %H );

my $i = 0;

for my $x ( 1 .. $board_size ) {
    for my $y ( 1 .. $board_size ) {
        my $v = $x . $y;
        push @A, $v;
        $H{$v} =  $v; # $i;
        $i++;
    }
}


for my $x ( 1 .. $board_size ) {
    for my $y ( 1 .. $board_size ) {
        my $v = $x . $y;
        
        push @vertices, $H{$v};

        say "v=$v" if $DEBUG;
        
        if ( $x > 2 ) {
            if ( $y > 1 ) {
                push @edges, [ $H{$v}, $H{ ($x - 2) . ($y - 1) } ];
            }
            if ( ( $y + 1 ) <= $board_size ) {
                push @edges, [ $H{$v}, $H{  ($x - 2) . ($y + 1) } ];
            }
        }

        if ( $x + 2 <= $board_size ) {
            if ( $y > 1 ) {
                push @edges, [ $H{$v}, $H{ ($x + 2) . ($y - 1) } ];
            }
            if ( ( $y + 1 ) <= $board_size ) {
                push @edges, [ $H{$v}, $H{ ($x + 2) . ($y + 1) } ];
            }
        }


        if ( $y > 2 ) {
            if ( $x > 1 ) {
                push @edges, [ $H{$v}, $H{ ($x - 1) . ($y - 2) } ];
            }
            if ( ( $x + 1 ) <= $board_size ) {
                push @edges, [ $H{$v}, $H{ ($x + 1) . ($y - 2) } ];
            }
        }


        if ( $y + 2 <= $board_size ) {
            if ( $x > 1 ) {
                push @edges, [ $H{$v}, $H{ ($x - 1) . ($y + 2) } ];
            }
            if ( ( $x + 1 ) <= $board_size ) {
                push @edges, [ $H{$v}, $H{ ($x + 1) . ($y + 2) } ];
            }
        }

    }
}

if ( $DEBUG ) {
    print join ",", sort { $a <=> $b } @vertices;
    print "\n\n";
    print scalar(@vertices);
    print "\n\n";    
}



my $chessboard = new Graph::Undirected(
    vertices => \@vertices,
    edges => \@edges
);



my ( $is_hamiltonian, $reason, $params ) = graph_is_hamiltonian( $chessboard );

if ( $is_hamiltonian ) {
    print "The graph contains a Hamiltonian Cycle.\n";
} else {
    print "The graph does not contain a Hamiltonian Cycle.\n";
}

print "REASON: ( $reason )\n";




say $chessboard;


