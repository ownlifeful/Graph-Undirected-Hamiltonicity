package Graph::Undirected::Hamiltonicity::Wolfram;

use 5.006;
use strict;
use warnings;

use Config::INI::Reader;
use LWP::UserAgent;

use Exporter qw(import);

our @EXPORT_OK =  qw(&is_hamiltonian_per_wolfram
                     &get_url_from_config);
our @EXPORT =  qw(&is_hamiltonian_per_wolfram);

our %EXPORT_TAGS = (
    all       =>  \@EXPORT_OK,
);


=head1 NAME

Graph::Undirected::Hamiltonicity::Wolfram - determine the Hamiltonicity of a given graph using the Wolfram Cloud.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use Graph::Undirected::Hamiltonicity::Wolfram;

    my $result;
    eval {
        # $G is a Graph::Undirected
        $result = is_hamiltonian_per_wolfram( $G );
    };
    warn $@ if $@;

   if ( $result ) {
       print "Graph is Hamiltonian.\n";
   } else {
       print "Graph is not Hamiltonian.\n";
   }


=head1 EXPORT

The is_hamiltonian_per_wolfram() subroutine is exported by default.

=back

=head1 SUBROUTINES

=cut

##############################################################################

=head2 is_hamiltonian_per_wolfram

Takes: a Graph::Undirected

Returns: 1     if the graph is Hamiltonian
         0     if the graph is non-Hamiltonian

Throws: an exception if an error is encountered.

=cut

sub is_hamiltonian_per_wolfram {
    my ( $G ) = @_;

    ### Create a user agent object
    my $ua = LWP::UserAgent->new;
    $ua->agent("HamiltonCycleFinder/0.1 ");

    my $url = get_url_from_config();

    ### Create a request
    my $req = HTTP::Request->new(POST => $url);
    $req->content_type('application/x-www-form-urlencoded');
    $req->content("x=$G");

    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);

    # Check the outcome of the response
    if ($res->is_success) {
        my $output = $res->content;
        return $output;
    }
    else {
        my $message = "ERROR:" . $res->status_line;
        die $message;
    }

}

##############################################################################

sub get_url_from_config {
    my $file = $ENV{HOME} . '/hamilton.ini';
    return unless ( -e $file && -f _ && -r _ );

    my $hash = Config::INI::Reader->read_file($file);
    my $url = $hash->{wolfram}->{url};

    if ( $url =~ /^http/ ) {
        $url =~ s{^https://}{http://};
        return $url;
    }

    return undef;
}

##############################################################################
##############################################################################


=head1 AUTHOR

Ashwin Dixit, C<< <ashwin at ownlifeful dot com> >>



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Graph::Undirected::Hamiltonicity::Wolfram

=cut

1; # End of Graph::Undirected::Hamiltonicity::Wolfram
