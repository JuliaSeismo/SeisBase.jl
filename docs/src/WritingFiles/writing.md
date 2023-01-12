# [Write Suppport](@id write_support)
The table below sumamrizes the current write options for SeisBase. Each function is described in detail in this chapter.

| Structure/Description                 | Output Format         | Function      |
| ------------------------------------- | --------------------- | ------------- |
| GphysChannel                          | ASDF                  | write_hdf5    |
| GphysChannel                          | SAC timeseries        | writesac      |
| GphysChannel channel metadata         | StationXML            | write_sxml    |
| GphysChannel instrument response      | SAC polezero          | writesacpz    |
| GphysData                             | ASDF                  | write_hdf5    |
| GphysData                             | SAC timeseries        | writesac      |
| GphysData channel metadata            | StationXML            | write_sxml    |
| GphysData instrument response         | SAC polezero          | writesacpz    |
| SeisEvent                             | ASDF                  | write_hdf5    |
| SeisEvent header and source info      | ASDF QuakeML          | asdf_wqml     |
| SeisEvent header and source info      | QuakeML               | write_qml     |
| SeisEvent trace data only             | SAC timeseries        | writesac      |
| Array{SeisEvent, 1}                   | ASDF QuakeML          | asdf_wqml     |
| Array{SeisHdr, 1}                     | QuakeML               | write_qml     |
| Array{SeisHdr, 1}, Array{SeisSrc, 1}  | ASDF QuakeML          | asdf_wqml     |
| Array{SeisHdr, 1}, Array{SeisSrc, 1}  | QuakeML               | write_qml     |
| SeisHdr                               | QuakeML               | write_qml     |
| SeisHdr, SeisSrc                      | ASDF QuakeML          | asdf_wqml     |
| SeisHdr, SeisSrc                      | QuakeML               | wqml          |
| any SeisBase structure                | SeisBase file         | wseis         |
| primitive data type or array          | ASDF AuxiliaryData    | asdf_waux     |

Methods for SeisEvent, SeisHdr, or SeisSrc are part of submodule SeisBase.Quake. *asdf_waux* and *asdf_wqml* are part of [SeisBase.SeisHDF](@ref seishdf).


## Write Functions
Functions are organized by file format.

### HDF5/ASDF
```@docs
write_hdf5
```

## [QuakeML](@id write_qml)

```@docs
SeisBase.Quake.write_qml
```

## SAC

```@docs
writesac
writesacpz
```

## SeisBase Native

```@docs
wseis
```

## Station XML

```@docs
write_sxml
```
