#!/usr/bin/env perl

use FindBin qw($Bin);

use strict;
use warnings;

# This file is used by http://travis-ci.com/
# to generate and test a Build file

my $file = "./Build";

open(my $fh, ">", $file) or die $!;

say $fh "cpanm Dist::Zilla";

my $prefix = $Bin/../../../perl5/perlbrew/perls/" . $ENV{TRAVIS_PERL_VERSION} . "/bin";
say $fh "$prefix/dzil authordeps | cpanm";
say $fh "$prefix/dzil listdeps | cpanm";

if ( $ARGV[0] ) {
    say $fh "$prefix/dzil install";
} else {
    say $fh "$prefix/dzil test";
}
say $fh 'echo dzil', '=' x 40, '[', `which dzil` , "]"; ### DEBUG
say $fh 'echo pwd', '=' x 40, '[', `pwd` , "]"; ### DEBUG
say $fh 'echo PATH=[', $ENV{PATH}, ']'; ### DEBUG
say $fh "echo \$Bin=[$Bin]"; ### DEBUG
say $fh "echo TRAVIS_PERL_VERSIONn=\[$ENV{TRAVIS_PERL_VERSION}\]"; ### DEBUG

close($fh);


chmod (0755, $file) or exit(1);
