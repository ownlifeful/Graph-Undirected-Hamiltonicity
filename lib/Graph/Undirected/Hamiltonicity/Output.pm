package Graph::Undirected::Hamiltonicity::Output;

use 5.006;
use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK =  qw(
                     &output
                     &output_image_svg
                     &output_adjacency_matrix_svg
        );

our %EXPORT_TAGS = (
    all       =>  \@EXPORT_OK,
);


=head1 NAME

Graph::Undirected::Hamiltonicity::Output - The great new Graph::Undirected::Hamiltonicity::Output!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Graph::Undirected::Hamiltonicity::Output;

    my $foo = Graph::Undirected::Hamiltonicity::Output->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES


=cut

##############################################################################

=head2 output

This subroutine examines an environment variable called HC_OUTPUT_FORMAT
to determine the output format. The output format can be one of:

=over 4

=item * 'html' : output in HTML form, with graphs embedded as inline SVG.

=item * 'text' : output in text form, with graphs converted to edge-lists.

=item * 'none' : do no generate any output.

=back

=cut

sub output {
    my ( $input ) = @_;

    my $format = $ENV{HC_OUTPUT_FORMAT} || 'none';

    return if $format eq 'none';

    if ( $format eq 'html' ) {
        if ( ref $input ) {
            output_image_svg(@_);
        } else {
            print $input, "\n";
        }

    } elsif ( $format eq 'text' ) {
        if ( ref $input ) {
            ### Print the edge-list as a string.
            print "$input\n";
        } else {
            ### Strip out HTML
            $input =~ s@<LI>@* @gi;
            $input =~ s@<BR/>@@gi;
            $input =~ s@</?(LI|UL|OL|CODE|TT)>@@gi;
            $input =~ s@<HR\s+NOSHADE>@=================@gi;
            print $input, "\n";
        }
    } else {
        die "Environment variable HC_OUTPUT_FORMAT should be " . 
            "one of: 'html', 'text', or 'none'\n";
    }

}

##########################################################################

sub output_image_svg {
    my ( $G, $hash_ref ) = @_;

    my %params =
        ( ( defined $hash_ref ) && ( ref $hash_ref ) ) ? %{$hash_ref} : ();

    my $image_size = $params{'size'} || 600;

    print qq{<div style="height: 600px; width: 1500px;">\n};

    ### Output image
    print qq{<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" 
"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">

<svg width="100%" height="100%" version="1.1"
xmlns="http://www.w3.org/2000/svg">

};

    output_graph_svg( $G, { %params, image_size => $image_size } );
    output_adjacency_matrix_svg( $G, { %params, image_size => $image_size } );
    print qq{</svg>\n};
    print qq{</div>\n\n};
}

##########################################################################

sub output_graph_svg {
    my ( $G, $hash_ref ) = @_;

    my %params =
        ( ( defined $hash_ref ) && ( ref $hash_ref ) ) ? %{$hash_ref} : ();

    my $Pi = 4 * atan2 1, 1;
    my $v = scalar( $G->vertices() );

    ### Compute angle between vertices
    my $angle_between_vertices = 2 * $Pi / $v;

    my $image_size = $params{'size'} || 600;

    ### Compute Center of image
    my $x_center = $image_size / 2;
    my $y_center = $x_center;
    my $border   = int( $image_size / 25 );    ### cellpadding in the image

    ### Compute vertex coordinates
    my $radius   = ( $image_size / 2 ) - $border;
    my $angle    = $Pi * ( 0.5 - ( 1 / $v ) );
    my @vertices = $G->vertices();

    @vertices = sort { $a <=> $b } @vertices;
    my $text_xml     = '';
    my $vertices_xml = '';
    my @vertex_coordinates;
    ### Draw vertices ( and include text labels )
    for my $vertex (@vertices) {

        my $x = ( $radius * cos($angle) ) + $x_center;
        my $y = ( $radius * sin($angle) ) + $y_center;

        $vertices_xml .= qq{<circle cx="$x" cy="$y" id="$vertex" r="10" />\n};
        $text_xml     .= q{<text x="};
        $text_xml     .= $x - 5;
        $text_xml     .= q{" y="};
        $text_xml     .= $y + 5;
        $text_xml     .= qq{">$vertex</text>\n};

        $vertex_coordinates[$vertex] = [ $x, $y ];
        $angle += $angle_between_vertices;
    }

    my $edges_xml = '';
    ### Draw edges
    foreach my $edge_ref ( $G->edges() ) {
        my ( $orig, $dest ) = @$edge_ref;

        if ( $orig > $dest ) {
            my $temp = $orig;
            $orig = $dest;
            $dest = $temp;
        }

        my $required = $params{'required'}
            || $G->get_edge_attribute( $orig, $dest, 'required' );
        my $stroke_width = $required ? 3         : 1;
        my $color        = $required ? '#FF0000' : '#000000';

        $edges_xml .= qq{<line id="${orig}_${dest}};
        $edges_xml .= q{" x1="};
        $edges_xml .= $vertex_coordinates[$orig]->[0];
        $edges_xml .= q{" y1="};
        $edges_xml .= $vertex_coordinates[$orig]->[1];
        $edges_xml .= q{" x2="};
        $edges_xml .= $vertex_coordinates[$dest]->[0];
        $edges_xml .= q{" y2="};
        $edges_xml .= $vertex_coordinates[$dest]->[1];
        $edges_xml .= qq{" stroke-width="$stroke_width" stroke="$color" />};
        $edges_xml .= "\n";
    }


    ### Output image
    print qq{<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" 
"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">

<svg width="100%" height="100%" version="1.1"
xmlns="http://www.w3.org/2000/svg">

<g id="edges" style="opacity:1; stroke: black; stroke-opacity: 1">
$edges_xml</g>

<g id="vertices" 
 style="opacity: 1; fill: blue; fill-opacity: 1; stroke: black; stroke-opacity: 1">
$vertices_xml</g>

<g id="text_labels" 
 style="opacity: 1; fill: yellow; fill-opacity: 1; stroke: yellow; stroke-opacity: 1">

$text_xml</g>

};

}

##########################################################################

sub output_adjacency_matrix_svg {

    my ( $G, $hash_ref ) = @_;

    my %params =
        ( ( defined $hash_ref ) && ( ref $hash_ref ) ) ? %{$hash_ref} : ();
    my $randomish = $$ . time . int(rand(1000));

    print qq{<?xml version="1.0" standalone="no"?>

<g id="adjacency_matrix_$randomish" 
 style="opacity:1; stroke: black; stroke-opacity: 1">
};

    my $square_size = 30;
    my @vertices = sort { $a <=> $b } $G->vertices();

    my $image_size = $params{image_size} || 600;

    my $x_init = $image_size + 60;
    my $y_init = $image_size - $square_size * scalar(@vertices);

    my $x       = $x_init;
    my $y       = $y_init;
    my $counter = 0;

    foreach my $i (@vertices) {
        if ($counter) {
            print q{<text x="};
            print $x - 25;
            print q{" y="};
            print $y + $square_size - 10;
            print qq{">$i</text>\n};    ### vertex label
        }

        print q{<text x="};
        print $x + 10 + ( $square_size * $counter++ );
        print q{" y="};
        print $y + 20;
        print qq{">$i</text>\n};        ### vertex label

        foreach my $j (@vertices) {

            last if $i == $j;

            my $fill_color;
            if ( $G->has_edge( $i, $j ) ) {
                $fill_color = $params{'required'}
                    || $G->get_edge_attribute( $i, $j, 'required' )
                    ? '#FF0000'
                    : '#000000';
            }
            else {
                $fill_color = '#FFFFFF';
            }
            print qq{<rect x="$x" y="$y" width="$square_size" };
            print qq{height="$square_size" fill="$fill_color" />\n};

            $x += $square_size;
        }
        $y += $square_size;
        $x = $x_init;
    }

    print qq{\n</g>\n};

}

##########################################################################


=head1 AUTHOR

Ashwin Dixit, C<< <ashwin at ownlifeful dot com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-graph-undirected-hamiltonicity at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Undirected-Hamiltonicity>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Graph::Undirected::Hamiltonicity::Output


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Graph-Undirected-Hamiltonicity>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Graph-Undirected-Hamiltonicity>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Graph-Undirected-Hamiltonicity>

=item * Search CPAN

L<http://search.cpan.org/dist/Graph-Undirected-Hamiltonicity/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Ashwin Dixit.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>


=cut

1; # End of Graph::Undirected::Hamiltonicity::Output
