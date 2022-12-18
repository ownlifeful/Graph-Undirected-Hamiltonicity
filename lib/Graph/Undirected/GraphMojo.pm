#!/usr/bin/env perl

use Modern::Perl;
use Graph::Undirected::Hamiltonicity;

package GraphMojo;

##########################################################################

sub new {
    my $class = shift;
    my ( $graph_text, $mojo ) = @_;
    $graph_text //= '';

    my $self = {};
    $self->{mojo} = $mojo if $mojo;

    if ( ref $graph_text ) {
	$self->{g} = $graph_text;
	bless $self, $class;
	return $self;
    }
    
    $graph_text =~ s/[^0-9=,]+//g;
    $graph_text =~ s/([=,])\D+/$1/g;
    $graph_text =~ s/^\D+|\D+$//g;

    my $g;
    if ( $graph_text =~ /\d/ ) {
	eval { $g = Graph::Undirected::Hamiltonicity::string_to_graph($graph_text); };
	if ( my $exception = $@ ) {
	    say "That was not a valid graph, ";
	    say "according to the Graph::Undirected module.<BR/>";
	    say "[$graph_text][$exception]<BR/>";
	    die;
	} else {
	    $self->{g} = $g;
	}
    } else {
	die "Could not create a graph.\n";
    }

   bless $self, $class;
   return $self;
}




####################################################################################

sub graph_is_hamiltonian {
    my ( $self ) = @_;
    $self->{g}->graph_is_hamiltonian();
}

####################################################################################

sub output {
    my ( $g ) = shift;
    foreach my $message ( @_ ) {
	$g->{mojo}->send($message);
    }
}

####################################################################################

1;
