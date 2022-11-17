# Introduction

SeisBase is a framework for working with univariate geophysical data on 64-bit systems.
SeisBase is designed around three basic principles:

* Ease of use: one shouldn't need a PhD to understand command syntax.
* Fluidity: working with data shouldn't feel *clumsy*.
* Performance: speed and efficient memory usage *matter*.

The project is home to an expanding set of web clients, file format readers,
and analysis utilities.


## Overview

SeisBase stores data in minimalist containers that track the bare necessities for
analysis. New data are easily added with basic operators like *+*. Unwanted
channels can be removed just as easily. Data can be written to a number of
file formats.


## Installation

From the Julia prompt: press `]` to enter the Pkg environment, then type

```julia
pkg> add SeisBase; build; precompile
```

Dependencies should install automatically. To verify that everything works
correctly, type

```julia
test SeisBase
```

and allow 10-20 minutes for tests to complete. Exit the Pkg environment by pressing Backspace or Control + C.


## Getting Started
At the Julia prompt, type

```julia
using SeisBase
```

You'll need to repeat this step whenever you restart Julia, as with any
command-line interpreter (CLI) language.


## Learning SeisBase
An interactive tutorial using Jupyter notebooks in a web browser can be accessed
from the Julia prompt with these commands:

```julia
julia> p = pathof(SeisBase);

julia> d = dirname(realpath(p));

julia> cd(d);

julia> include("../tutorial/install.jl");
```

SeisBase also has an `online tutorial guide<tutorial>`, intended as a gentle
introduction for people less familiar with the Julia language. The two are
intentionally redundant; Jupyter isn't compatible with all systems and browsers.

For a faster start, skip to any of these topics:

* `Working with Data<wwd>`: learn how to manage data using SeisBase
* `Reading Data<readdata>`: learn how to read data from file
* `Web Requests<getdata>`: learn how to download data


## Updating
From the Julia prompt: press `]` to enter the Pkg environment, then type
`update`. Once package updates finish, restart Julia to use them.
