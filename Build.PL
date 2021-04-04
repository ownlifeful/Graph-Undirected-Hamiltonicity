#!/usr/bin/env perl

use strict;
use warnings;

# This file is used by http://travis-ci.com/
# to generate and test a Build file

my $file = "./Build";

open(my $fh, ">", $file) or die $!;

say $fh "cpanm Dist::Zilla";
say $fh "/usr/bin/dzil authordeps | cpanm";
say $fh "/usr/bin/dzil listdeps | cpanm";

if ( $ARGV[0] ) {
    say $fh "/usr/bin/dzil install";
} else {
    say $fh "/usr/bin/dzil test";
}
say $fh '=' x 40, '[', `which dzil` , "]"; ### DEBUG
close($fh);

chmod (0755, $file) or exit(1);
