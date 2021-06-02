#!/usr/bin/env perl

require v5.6.0;

use FindBin qw($Bin);

use strict;
use warnings;

# This file is used by http://travis-ci.com/
# to generate and test a Build file

my $file = "./Build";

open(my $fh, ">", $file) or die $!;

say $fh "cpanm Dist::Zilla";

my $perl_version = $ENV{TRAVIS_PERL_VERSION} || $^V || die "Could not determine perl version.\n";

my @prefixes;
push @prefixes, $Bin . '/../../../perl5/perlbrew/perls/perl-' . $perl_version . '/bin';
push @prefixes, $Bin . '/../../../perl5/perlbrew/perls/'      . $perl_version . '/bin';
push @prefixes, '~/perl5/perlbrew/perls/perl-' . $perl_version . '/bin';
push @prefixes, '~/perl5/perlbrew/perls/' . $perl_version . '/bin';

my $prefix = ( grep { -e $_ } @prefixes ) [0];

die "FOUND NO PREFIX\n" unless $prefix;

say $fh "$prefix/dzil authordeps | cpanm";
say $fh "$prefix/dzil listdeps | cpanm";

if ( $ARGV[0] ) {
    say $fh "$prefix/dzil install";
} else {
    say $fh "$prefix/dzil test";
}

close($fh);

chmod (0755, $file) or exit(1);
