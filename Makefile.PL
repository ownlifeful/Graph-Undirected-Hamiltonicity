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
        'Graph'               => '0.9',   # '0.9704',
        'Exporter'            => '5',     # '5.68',
        'CGI'                 => '4',     # '4.31',
        'LWP::UserAgent'      => '6',     # '6.15'
        'Config::INI::Reader' => '0.025',
        'Carp'                => '1.29',
        'Test::More'          => '0.98',
        'Test::Exception'     => '0',     # '0.43',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Graph-Undirected-Hamiltonicity-*' },
    test => { TESTS => join ' ', map { glob } qw( t/*.t t/*/*.t ) },
);
