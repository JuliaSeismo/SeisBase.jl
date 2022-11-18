# Nodal
The Nodal submodule is intended to handle data from nodal arrays. Nodal arrays
differ from standard seismic data in that the start and end times of data
segments are usually synchronized.

## Reading Nodal Data Files
```@docs
SeisBase.Nodal.read_nodal
```

### Working with NodalData objects
NodalData objects have one major structural difference from SeisData objects:
the usual data field *:x* is a set of views to an Array{Float32, 2} (equivalent
to a Matrix{Float32}) stored in field *:data*. This allows the user to apply
two-dimensional data processing operations directly to the data matrix.

#### NodalData Assumptions
* `S.t[i]` is the same for all *i*.
* `S.fs[i]` is constant for all *i*.
* `length(S.x[i])` is constant for all *i*.

### Other Differences from SeisData objects
* Operations like *push!* and *append!* must regenerate `:data` using `hcat()`, and therefore consume a lot of memory.
* Attempting to *push!* or *append!* channels of unequal length throws an error.
* Attempting to *push!* or *append!* same-length channels with different `:t` or `:fs` won't synchronize them! You will instead have columns in `:data` that aren't time-aligned.
* Irregularly-sampled data (`:fs = 0.0`) are not supported.

## Types

```@docs
SeisBase.Nodal.NodalLoc
SeisBase.Nodal.NodalData
SeisBase.Nodal.NodalChannel
```
