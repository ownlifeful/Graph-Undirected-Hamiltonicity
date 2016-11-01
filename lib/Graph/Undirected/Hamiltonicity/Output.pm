package Graph::Undirected::Hamiltonicity::Output;

use 5.006;
use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK =  qw(
                     &output
                     &output_graph_svg
                     &output_image_svg
                     &output_adjacency_matrix_svg
        );

our %EXPORT_TAGS = (
    all       =>  \@EXPORT_OK,
);


=head1 NAME

Graph::Undirected::Hamiltonicity::Output - convenience subroutines for printing output
in various formats.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

The output() subroutine examines an environment variable called HC_OUTPUT_FORMAT
to determine the output format. The output format can be one of:

=over 4

=item * 'html' : output in HTML form, with graphs embedded as inline SVG.

=item * 'text' : output in text form, with graphs converted to edge-lists.

=item * 'none' : do no generate any output.

=back

    use Graph::Undirected::Hamiltonicity::Output;

    output("Foo<BR/>");
    # in html mode, print "Foo<BR/>", "\n"
    # in text mode, print "Foo", "\n"
    # in none mode, print nothing.

    output($G); # $G is a Graph::Undirected
    # in html mode, print the SVG to draw this graph
    # in text mode, print the adjacency-list of this graph
    # in none mode, print nothing.


    output($G, { required => 1 });
    # Indicates that the graph should be formatted
    # as a graph of "required" edges only.


=head1 EXPORT

Exports the output() subroutine by default.

=head1 SUBROUTINES


=cut

##############################################################################

=head2 output

This subroutine produces output polymorphically, based on the state of the
HC_OUTPUT_FORMAT environment variable, and on the input.

It is overloaded to output literal HTML, text stripped from HTML, and 
SVG embedded inline.

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
            ### Print the graph's edge-list as a string.
            print "$input\n";
        } else {
            ### Strip out HTML
            $input =~ s@<LI>@* @gi;
            $input =~ s@<BR/>@@gi;
            $input =~ s@</?(LI|UL|OL|CODE|TT|PRE|H[1-6])>@@gi;
            $input =~ s@<HR[^>]*?>@=================@gi;
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
        $text_xml     .= $x - ( length("$vertex") == 1 ? 4 : 9 );
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
 style="opacity: 1; fill: lightgreen; fill-opacity: 1; stroke: lightgreen; stroke-opacity: 1">

$text_xml</g>

};

}

##########################################################################

sub output_adjacency_matrix_svg {

    my ( $G, $hash_ref ) = @_;

    my %params =
        ( ( defined $hash_ref ) && ( ref $hash_ref ) ) ? %{$hash_ref} : ();

    print qq{<?xml version="1.0" standalone="no"?>\n};
    print qq{<g style="opacity:1; stroke: black; stroke-opacity: 1">\n};

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

=cut

1; # End of Graph::Undirected::Hamiltonicity::Output
