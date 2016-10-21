use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Graph::Undirected::Hamiltonicity',
    AUTHOR           => q{Ashwin Dixit <ashwin at ownlifeful dot com>},
    VERSION_FROM     => 'lib/Graph/Undirected/Hamiltonicity.pm',
    ABSTRACT_FROM    => 'lib/Graph/Undirected/Hamiltonicity.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Graph'              => '0', # '0.9704',
        'Exporter'           => '0', # '5.68',
#        'Bit::Vector'        => '0', # '7.4',
#        'Data::Dumper'       => '0', # '2.145',
#        'CGI'                => '0', # '4.31',
#	 'Readonly'           => '0', # '2.05',
#	 'LWP'                => '0', # '6.05',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Graph-Undirected-Hamiltonicity-*' },
);
