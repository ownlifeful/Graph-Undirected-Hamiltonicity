#!/usr/bin/env perl

use FindBin qw($Bin);

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
say $fh 'echo dzil', '=' x 40, '[', `which dzil` , "]"; ### DEBUG
say $fh 'echo pwd', '=' x 40, '[', `pwd` , "]"; ### DEBUG
say $fh 'echo PATH=[', $ENV{PATH}, ']'; ### DEBUG
say $fh "echo \$Bin=[$Bin]"; ### DEBUG
close($fh);


chmod (0755, $file) or exit(1);
