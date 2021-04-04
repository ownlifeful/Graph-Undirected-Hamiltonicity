#!/usr/bin/env perl

use FindBin qw($Bin);

use strict;
use warnings;

# This file is used by http://travis-ci.com/
# to generate and test a Build file

my $file = "./Build";

open(my $fh, ">", $file) or die $!;

say $fh "cpanm Dist::Zilla";

my $prefix = $Bin . '/../../../perl5/perlbrew/perls/' . $ENV{TRAVIS_PERL_VERSION} . '/bin';
say $fh "$prefix/dzil authordeps | cpanm";
say $fh "$prefix/dzil listdeps | cpanm";

if ( $ARGV[0] ) {
    say $fh "$prefix/dzil install";
} else {
    say $fh "$prefix/dzil test";
}

close($fh);

chmod (0755, $file) or exit(1);
