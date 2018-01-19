#!/usr/bin/env perl

use strict;
use warnings;

# This file is used by http://travis-ci.com/
# to generate and test a Build file

my $file = "./Build";

open(my $fh, ">", $file) or die $!;

say $fh "cpanm Dist::Zilla";
say $fh "dzil authordeps | cpanm";
say $fh "dzil listdeps | cpanm";

if ( $ARGV[0] ) {
    say $fh "dzil install";
} else {
    say $fh "dzil test";
}

close($fh);

chmod (0755, $file) or exit(1);
