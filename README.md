# Graph-Undirected-Hamiltonicity
Set of Perl modules to determine the Hamiltonicity of a given undirected graph.

To install:


    perl Makefile.PL
    make
    make test
    make install


To test whether a given graph is Hamiltonian:


    perl bin/hamilton.pl --graph_text 0=1,0=2,1=2


To test multiple graphs:


    perl bin/hamilton.pl --graph_file list_of_graphs.txt


To spoof a random Hamiltonian graph with 42 vertices:


    perl bin/hamilton.pl --v 42



To get more detailed help:


    perl bin/hamilton.pl --help



To get per-module help:


    perldoc Graph::Undirected::Hamiltonicity
    perldoc Graph::Undirected::Hamiltonicity::Tests
    perldoc Graph::Undirected::Hamiltonicity::Spoof
    perldoc Graph::Undirected::Hamiltonicity::Transforms
    perldoc Graph::Undirected::Hamiltonicity::Output
