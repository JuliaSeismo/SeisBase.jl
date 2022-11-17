# Working with Data
This section is a tutorial for tracking and managing SeisBase data.

## Creating Data Containers
Create a new, empty object using any of the following commands:

| Object        | Purpose |
| ------------- | --------------------------------------------------------------- |
| SeisChannel() | A single channel of univariate (usually time-series) data       |
| SeisData()    | Multichannel univariate (usually time-series) data              |
| SeisHdr()     | Header structure for discrete seismic events                    |
| SeisEvent()   | Discrete seismic events; includes SeisHdr and SeisData objects  |

## Acquiring Data
* Read files with `read_data<readdata>`
* Make web requets with `get_data<getdata>`
* Initiate real-time streaming sessions to SeisData objects with `seedlink<seedlink-section>`

## Keeping Track
A number of auxiliary functions exist to keep track of channels:

```@docs
findchan
findid
namestrip
```
| Convention | Characters Removed:sup:`¹`                 |
| ---------- | ------------------------------------------ | 
| "File"     | `"$*/:<>?@\^\|~DEL`                        |
| "HTML"     | `"&';<>©DEL`                               |
| "Julia"    | `$\DEL`                                    |
| "Markdown" | ```!#()*+-.[\]_`{}```                      |
| "SEED"     | `.DEL`                                     |
| "Strict"   | ```!"#$%&'()*+,-./:;<=>?@[\]^`{\|}~DEL```  |

`¹` `DEL` here is \\x7f (ASCII/Unicode U+007f).

```@docs
timestamp
track_off!
track_on!
```

### Source Logging
The :src field records the *last* data source used to populate each channel;
usually a file name or URL.

When a data source is added to a channel, including the first time data are
added, it's also recorded in the *:notes* field. Use *show_src(S, i)* to print
all data sources for channel *S[i]* to stdout (see below for details).


## Channel Maintenance
A few functions exist specifically to simplify data maintenance:

```@docs
prune!
pull
```


## Taking Notes
Functions that add and process data note these operations in the :notes field
of each object affected. One can also add custom notes with the note! command:

```@docs
note!
clear_notes!
```

## Checking Your Work
If you need to check what's been done to a channel, or the sources present in the channel data, these commands are helpful:

```@docs
show_processing
show_src
show_writes
```
