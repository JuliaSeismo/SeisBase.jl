# Getting Help
In addition to the Juypter notebooks and :ref:`online tutorial guide<tutorial>`,
other sources of help are available:

* [Examples](@ref)
* [Tests](@ref)
* [Command-Line Help](@ref)

## Examples

Several worked examples exist throughout these documents, in addition to *examples.jl* and the interactive tutorial.

Invoke the command-prompt examples with the following command sequence:

```julia
p = pathof(SeisBase)
d = dirname(realpath(p))
cd(d)
include("../test/examples.jl")
```

## Tests
The commands in *tests/* can be used as templates; to install test data and run all tests, execute these commands:

```julia
using Pkg
Pkg.test("SeisBase")      # lunch break recommended. Tests can take 20 minutes.
                        # 99.5% code coverage wasn't an accident...
p = pathof(SeisBase)
cd(realpath(dirname(p) * "/../test/"))
```

## Command-Line Help
A great deal of additional help functions are available at the Julia command prompt. All SeisBase functions and structures have their own docstrings. For example, typing `?SeisData` at the Julia prompt produces the following:

```@docs
SeisData
```

### Dedicated Help Functions
These functions take no arguments and dump information to stdout.

#### Submodule SEED

```@docs
SeisBase.SEED.dataless_support
mseed_support
SeisBase.SEED.resp_wont_read
seed_support
```

#### Submodule SUDS

```@docs
SeisBase.SUDS.suds_support
```

#### Formats Guide
**formats** is a constant static dictionary with descriptive entries of each data format. Access the list of formats with `sort(keys(formats))`. Then try a command like `formats["slist"]` for detailed info. on the slist format.


#### Help-Only Functions
These functions contain help docstrings but execute nothing. They exist to answer common questions.

```@docs
web_chanspec
```

Answers: how do I specify channels in a web request? Outputs :ref:`channel id syntax <cid>` to stdout.

```@docs
seis_www
```
Answers: which servers are available for FDSN queries? Outputs :ref:`the FDSN server list<servers>` to stdout.

```@docs
TimeSpec
```

All About Keywords
==================
Invoke keywords help with **?SeisBase.KW** for complete information on SeisBase shared keywords and meanings.
