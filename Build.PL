#!/usr/bin/env perl

# This file is used by http://travis-ci.com/
# to generate and test a Build file

use Modern::Perl;

my $file = "./Build";

open(my $fh, ">", $file) or die $!;

print $fh "dzil test\n";

close($fh);

chmod (0755, $file) or exit(1);

