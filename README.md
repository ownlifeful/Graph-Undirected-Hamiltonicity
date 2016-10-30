# NAME

Graph::Undirected::Hamiltonicity - determine the Hamiltonicity of a given undirected graph.

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


This module is dedicated to the Quixotic quest of determining whether "[P=NP](https://en.wikipedia.org/wiki/P_versus_NP_problem "P versus NP")".
It attempts to decide whether a given `Graph::Undirected` contains a Hamiltonian Cycle, using a series of polynomial time tests.

The non-deterministic algorithm systematically simplifies and traverses the input graph in a series of recursive tests. This module is not object-oriented, though once work on it is sufficiently advanced, it could be rolled up into an `is_hamiltonian()` method in `Graph::Undirected`. For now, it serves as a framework for explorers of this frontier of Computer Science.

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




To install the optional CGI script, copy the script to the appropriate location for your web server.


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

# SUPPORT

RT, CPAN's request tracker ([report bugs here](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Graph-Undirected-Hamiltonicity))

# SEE ALSO

1. [Graph](http://search.cpan.org/perldoc?Graph "Graph module")
2. [Hamiltonian Cycle](http://mathworld.wolfram.com/HamiltonianCycle.html "Hamiltonian Cycle")
3. [P versus NP](https://en.wikipedia.org/wiki/P_versus_NP_problem "P versus NP")


# REPOSITORY

[https://github.com/ownlifeful/Graph-Undirected-Hamiltonicity](https://github.com/ownlifeful/Graph-Undirected-Hamiltonicity "github repository")

# AUTHOR


Ashwin Dixit &lt;ashwin at ownlifeful dot com&gt;


# COPYRIGHT AND LICENSE


This software is copyright (c) 2016 by Ashwin Dixit.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
