
# Verification via the Wolfram Cloud

## Description

The optional module, `Graph::Undirected::Hamiltonicity::Wolfram` lets you determine
the Hamiltonicity of a given undirected graph, by evaluating the graph in the
Wolfram Open Cloud, using a built-in function of the Wolfram Programming Language.
This feature is quite useful in cross-checking the result you get from the algorithm 
implemented in this Perl distribution.



## Installation

**Step 1:** Copy the `hamilton.ini` file to your home directory.

    cp hamilton.ini $HOME

**Step 2:** Go to the [Wolfram Programming Lab](https://lab.wolframcloud.com/app/ "Wolfram Programming Lab").

**Step 3:** Create a Wolfram ID ( if you don't have one ).

**Step 4:** Sign in, and click "Create a New Notebook"

**Step 5:** In the Wolfram notebook, paste in the following code and evaluate it:

    CloudDeploy[ APIFunction[ {"x" -> "String"}, ( Length[ FindHamiltonianCycle[ Graph[ ToExpression[ StringSplit[ StringReplace[ #x, "=" -> "<->" ], "," ]]], 1 ]]  & ), "JSON"]]

**Step 6:** The output will be a cloud object with a URL. Copy just the URL.

    CloudObject[https://www.wolframcloud.com/objects/194a2864-c60b-4925-9ec0-1c51c2b64984]

**Step 7:** Edit the copy of `hamilton.ini` you made in your home directory. ( `$HOME/hamilton.ini` )

**Step 8:** Find the `[wolfram]` section and paste in the URL copied from the Wolfram notebook:

Before:

    [wolfram]
    url =

After:

    [wolfram]
    url = https://www.wolframcloud.com/objects/194a2864-c60b-4925-9ec0-1c51c2b64984

