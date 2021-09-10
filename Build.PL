#!/usr/bin/env perl                                                                                                                                                             

use strict;
use warnings;

# This file is used by http://travis-ci.com/
# to generate and test a Build file

my $file = "./Build";

open(my $fh, ">", $file) or die $!;

my $dzil = 'dzil';
my $cpanm = get_cpanm();
print $fh  $cpanm, " Dist::Zilla\n";
print $fh "$dzil authordeps | $cpanm\n";
print $fh "$dzil listdeps | $cpanm\n";
print $fh "$dzil install\n";

close($fh);

chmod (0755, $file) or exit(1);


#####################################################################

sub get_cpanm {
    my $cpanm = find_cpanm();
    if ( $cpanm ) {
	### Found cpanm already installed.
	print "Found cpanm at [$cpanm]\n";
    } else {
	print qq{No cpanm found!\n};
	### Install it.
	my $install = qx( curl -L https://cpanmin.us | perl - App::cpanminus );
	$cpanm = find_cpanm();
    }

    return $cpanm;
}

#####################################################################

sub find_cpanm {
    my $cmd = q( which cpanm );
    my $cpanm = qx( $cmd );
    chomp $cpanm;
    return $cpanm;
}

#####################################################################

1;
