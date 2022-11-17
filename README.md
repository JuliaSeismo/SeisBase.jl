# SeisBase.jl

[![Build Status](https://github.com/SeismoJulia/SeisBase.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/SeismoJulia/SeisBase.jl/actions/workflows/ci.yml)  

<!-- [![codecov](https://codecov.io/gh/jpjones76/SeisBase.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/jpjones76/SeisBase.jl)[![Coverage Status](https://coveralls.io/repos/github/jpjones76/SeisBase.jl/badge.svg?branch=master)](https://coveralls.io/github/jpjones76/SeisBase.jl?branch=master) [![Documentation Status](https://readthedocs.org/projects/SeisBase/badge/?version=latest)](https://SeisBase.readthedocs.io/en/latest/?badge=latest) -->
[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)

A minimalist, platform-agnostic package for univariate geophysical data.
This version is a follow up from SeisIO.jl (https://github.com/jpjones76/SeisIO.jl). It is intended to be an stable community maintained package.

## Installation | [Documentation](http://SeisBase.readthedocs.org)
From the Julia prompt, type: `] add SeisBase`; (Backspace); `using SeisBase`

## Summary | [Collaboration](docs/CONTRIBUTE.md)
Designed for speed, efficiency, and ease of use. Includes web clients, readers for common seismic data formats, and fast file writers. Utility functions allow time synchronization, data merging, padding time gaps, and other basic data processing.

* Web clients: SeedLink, FDSN (dataselect, event, station), IRIS (TauP, timeseries)
* File formats: ASDF (r/w), Bottles, GeoCSV (slist, tspair), QuakeML (r/w), SAC (r/w), SEED (dataless, mini-SEED, resp), SEG Y (rev 0, rev 1, PASSCAL), SLIST, SUDS, StationXML (r/w), Win32, UW

## Getting Started | [Formats](docs/FORMATS.md) | [Web Clients](docs/WEB.md)
Start the tutorials in your browser from the Julia prompt with

```julia
using SeisBase
cd(dirname(pathof(SeisBase)))
include("../tutorial/install.jl")
```

To run SeisBase package tests and download sample data, execute

```julia
using Pkg, SeisBase; Pkg.test("SeisBase")
```

Sample data downloaded for the tests can be found thereafter at

```julia
cd(dirname(pathof(SeisBase))) 
sfdir = realpath("../test/SampleFiles/")
```

## Publications | [Changelog](docs/CHANGELOG.md) | [Issues](docs/ISSUES.md)
Jones, J.P.,  Okubo, K., Clements. T., \& Denolle, M. (2020). SeisBase: a fast, efficient geophysical data architecture for the Julia language. *Seismological Research Letters* doi: https://doi.org/10.1785/0220190295

This work has been partially supported by a grant from the Packard Foundation.

## Notes on Code Test
The data used in the test comes from a [repository](!https://github.com/jpjones76/SeisBase-TestData) that does not have a license.

