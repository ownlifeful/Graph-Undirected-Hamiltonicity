# NAME

Graph::Undirected::Hamiltonicity - set of Perl modules to determine the Hamiltonicity of a given undirected graph.

# VERSION

version 0.01


# SYNOPSIS


    use Graph::Undirected;
    use Graph::Undirected::Hamiltonicity;

    ### Create and initialize an undirected graph
    my $graph = new Graph::Undirected( vertices => [ 0..3 ] );
    $graph->add_edge(0,1);
    $graph->add_edge(0,3);
    $graph->add_edge(1,2);
    $graph->add_edge(1,3);
    $graph->add_edge(2,3);

    ### Test whether the graph is Hamiltonian
    my $result = graph_is_hamiltonian( $graph );

    print $result->{is_hamiltonian}, "\n";
    # prints 1 if the graph contains a Hamiltonian Cycle, 0 otherwise.

    print $result->{reason}, "\n";
    # prints a brief reason for the conclusion.

# DESCRIPTION


This module is dedicated to the Quixotic quest of determining whether "P=NP".
It attempts to decide whether a given `Graph::Undirected` contains a Hamiltonian Cycle,
using a series of polynomial time tests.

The input graph is systematically simplified and traversed in a series of recursive tests.
The underlying algorithm is non-deterministic. This module is not object-oriented, though once work on it is sufficiently advanced, it could be rolled up into an `is_hamiltonian()` method in `Graph::Undirected`. For now, it serves as a framework for explorers of this frontier of thought.

The module includes several utility subroutines which might be generally useful in spoofing or transforming graphs. These subroutines are organized by broad functional area into submodules, and can be imported individually by name.

To get per-module help:


    perldoc Graph::Undirected::Hamiltonicity
    perldoc Graph::Undirected::Hamiltonicity::Tests
    perldoc Graph::Undirected::Hamiltonicity::Spoof
    perldoc Graph::Undirected::Hamiltonicity::Transforms
    perldoc Graph::Undirected::Hamiltonicity::Output

## INSTALLATION

To install the core module:


    perl Makefile.PL
    make
    make test
    make install




To install the optional CGI script, simply copy the script to the appropriate location for your web server.


On macOS:


    sudo cp cgi-bin/hc.cgi /Library/WebServer/CGI-Executables/

On CentOS ( and presumably RHEL and Fedora Linux ):

    sudo cp cgi-bin/hc.cgi /var/www/cgi-bin/


## USAGE

### CGI script:
The included CGI script ( `cgi-bin/hc.cgi` ) lets you visualize and edit graphs through a browser. It draws graphs using inline SVG.
A demo of this script is hosted [here](http://ownlifeful.com/hamilton.html "Hamiltonian Cycle Detector" ).


### Command-line tool:

To test whether a given graph is Hamiltonian:


    perl bin/hamilton.pl --graph_text 0=1,0=2,1=2


To test multiple graphs:


    perl bin/hamilton.pl --graph_file list_of_graphs.txt


To spoof a random Hamiltonian graph with 42 vertices and test it for Hamiltonicity:


    perl bin/hamilton.pl --vertices 42



To get more detailed help:


    perl bin/hamilton.pl --help




# AUTHOR


Ashwin Dixit &lt;ashwin at ownlifeful dot com&gt;


# COPYRIGHT AND LICENSE


This software is copyright (c) 2016 by Ashwin Dixit.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself. See LICENSE.