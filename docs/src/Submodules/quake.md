# Quake

The Quake submodule was introduced in SeisBase v0.3.0 to isolate handling of discrete earthquake events from handling of continuous geophysical data. While the channel data are similar, fully describing an earthquake event requires many additional Types (objects) and more information (fields) in channel descriptors.

## Types

```@docs
SeisBase.Quake.EQMag
SeisBase.Quake.EQLoc
SeisBase.Quake.EventChannel
SeisBase.Quake.EventTraceData
SeisBase.Quake.SeisEvent
SeisBase.Quake.SeisHdr
SeisBase.Quake.SeisPha
SeisBase.Quake.SeisSrc
SeisBase.Quake.SourceTime
```

## Web Queries
Keyword descriptions for web queries appear at the end of this section.

```@docs
SeisBase.Quake.FDSNevq
SeisBase.Quake.FDSNevt
SeisBase.Quake.get_pha!
```

### Web Query Keywords

| KW     | Default        | T [1] | Meaning                                   |
| :----- | :------------- | :----- | :----------------------------------------|
| evw    | [600.0, 600.0] | A{F,1} | search window in seconds [2]             |
| fmt    | "miniseed"     | S      | request data format                      |
| len    | 120.0          | I      | desired trace length [s]                 |
| mag    | [6.0, 9.9]     | A{F,1} | magnitude range for queries              |
| model  | "iasp91"       | S      | Earth velocity model for phase times     |
| nd     | 1              | I      | number of days per subrequest            |
| nev    | 0              | I      | number of events returned per query [3]  |
| opts   | ""             | S      | user-specified options [4]               |
| pha    | "P"            | S      | phases to get [5]                        |
| rad    | []             | A{F,1} | radial search region [6]                 |
| reg    | []             | A{F,1} | rectangular search region [7]            |
| src    | "IRIS"         | S      |  data source; type *?seis_www* for list  |
| to     | 30             | I      | read timeout for web requests [s]        |
| v      | 0              | I      | verbosity                                |
| w      | false          | B      | write requests to disk? [8]              |

**Table Footnotes**
1. Types: A = Array, B = Boolean, C = Char, DT = DateTime, F = Float, I = Integer, S = String, U8 = Unsigned 8-bit integer (UInt8)
2. search range is always ``ot-|evw[1]| ≤ t ≤ ot+|evw[2]|``
3. nev=0 returns all events in the query
4. String is passed as-is, e.g. "szsrecs=true&repo=realtime" for FDSN. String should not begin with an ampersand.
5. Comma-separated String, like `"P, pP"`; use `"ttall"` for all phases
6. Specify region **[center_lat, center_lon, min_radius, max_radius, dep_min, dep_max]**, with lat, lon, and radius in decimal degrees (°) and depth in km with + = down. Depths are only used for earthquake searches.
7. Specify region **[lat_min, lat_max, lon_min, lon_max, dep_min, dep_max]**, with lat, lon in decimal degrees (°) and depth in km with + = down. Depths are only used for earthquake searches.
8. If **w=true**, a file name is automatically generated from the request parameters, in addition to parsing data to a SeisData structure. Files are created from the raw download even if data processing fails, in contrast to get_data(... wsac=true).

### Example
Get seismic and strainmeter records for the P-wave of the Tohoku-Oki great earthquake on two borehole stations and write to native SeisData format:
```julia
S = FDSNevt("201103110547", "PB.B004..EH?,PB.B004..BS?,PB.B001..BS?,PB.B001..EH?")
wseis("201103110547_evt.seis", S)
```

### Utility Functions

```@docs
SeisBase.Quake.distaz!
SeisBase.Quake.gcdist
SeisBase.Quake.show_phases
SeisBase.Quake.fill_sac_evh!
```


## Reading Earthquake Data Files

```@docs
SeisBase.Quake.read_quake
```


### QuakeML

* [`read_qml`](@ref quakeml)
* [`write_qml`](@ref write_qml)
