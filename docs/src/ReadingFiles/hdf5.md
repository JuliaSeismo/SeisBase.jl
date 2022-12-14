# HDF5 Files
Of the increasingly popular HDF5-based formats for geophysical data, only ASDF
is supported at present. Support for other (sub)formats is planned.

```julia
S = read_hdf5(fname::String, s::TimeSpec, t::TimeSpec, [, KWs])
read_hdf5!(S::GphysData, fname::String, s::TimeSpec, t::TimeSpec, [, KWs])
```

Read data in seismic HDF5 file format from file **fname** into S.
**KWs**
Keyword arguments; see also [Shared Keywords](@ref seisbase_std_keyword) or type `?SeisBase.KW`.

This has one fundamental design difference from [read_data](@ref time_series_file):
HDF5 archives are assumed to be large files with data from multiple channels;
they are scanned selectively for data of interest to read, rather than read
into memory in their entirety.

## Supported Keywords

| KW     | Type      | Default    | Meaning                                                   |
| ------ | --------- | ---------- | --------------------------------------------------------- |
|  id    | String    | \"*.*..*\" | id pattern, formated nn.sss.ll.ccc                        |
|        |           |            |  (net.sta.loc.cha); FDSN-style wildcards [1]             |
|  msr   | Bool      | true       | read full (MultiStageResp) instrument resp?               |
|  v     | Integer   | 0          | verbosity                                                 |

1. A question mark ('?') is a wildcard for a single character (exactly one); an asterisk ('*') is a wildcard for zero or more characters.

Writing to HDF5 volumes is supported through *write_hdf5*, described in [Writing to File](@ref write_support).
