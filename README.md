# Graph::Undirected::Hamiltonicity
Set of Perl modules to determine the Hamiltonicity of a given undirected graph.

## INSTALLATION

To install the core module:


    perl Makefile.PL
    make
    make test
    make install




To install the optional CGI script, simply copy the script to the appropriate location for your web server. For example, on macOS:


    sudo cp cgi-bin/hc.cgi /Library/WebServer/CGI-Executables/


## USAGE


### Programmatic interface:

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


To get per-module help:


    perldoc Graph::Undirected::Hamiltonicity
    perldoc Graph::Undirected::Hamiltonicity::Tests
    perldoc Graph::Undirected::Hamiltonicity::Spoof
    perldoc Graph::Undirected::Hamiltonicity::Transforms
    perldoc Graph::Undirected::Hamiltonicity::Output


## AUTHOR


Ashwin Dixit &lt;ashwin at ownlifeful dot com&gt;


## COPYRIGHT AND LICENSE


This software is copyright (c) 2016 by Ashwin Dixit.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself. See LICENSE.