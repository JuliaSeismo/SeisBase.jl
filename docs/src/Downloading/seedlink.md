# SeedLink

[SeedLink](https://www.seiscomp3.org/wiki/doc/applications/seedlink) is a TCP/IP-based data transmission protocol that allows near-real-time access to data from thousands of geophysical monitoring instruments. See :ref:`data keywords list <dkw>` and :ref:`channel id syntax <cid>` for options.

```@docs
seedlink
seedlink!
```

Initiate a SeedLink session in DATA mode to feed data from channels `chans` with selection patterns `patts` to SeisData structure `S`. A handle to a TCP connection is appended to `S.c`. Data are periodically parsed until the connection is closed. One SeisData object can support multiple connections, provided that each connection's streams feed unique channels.

**mode**
SeedLink mode ("DATA", "FETCH", or "TIME"; case-sensitive).

**chans**
Channel specification can use any of the following options:

1. A comma-separated String where each pattern follows the syntax NET.STA.LOC.CHA.DFLAG, e.g. UW.TDH..EHZ.D. Use "?" to match any single character.
2. An Array{String,1} with one pattern per entry, following the above syntax.
3. The name of a configuration text file, with one channel pattern per line; see :ref:`Channel Configuration File syntax<ccfg>`.

**patts**
Data selection patterns. See official SeedLink documentation; syntax is identical.

## Keywords
:ref:`Shared Keywords<dkw>`

* v, w

**SeedLink Keywords**

| kw          | def          | type          | meaning  |
| --------- | ---------     | ---------     |   -----------        |
|  gap      | 3600      | R      | a stream with no data in >gap seconds is considered offline      |
|  kai      | 600      | R      | keepalive interval (s)      |
|  port      | 18000      | I      | port number      |
|  refresh      | 20      | R      | base refresh interval (s) [`1`]      |
|  seq      | ""      | S      | Starting sequence hex value, like "5BE37A"      |
|  u      | "rtserve.iris.washington.edu"      | S      | base SeedLink service URL, no "http://"    |
|  x\_on\_err      | true      | Bool      | exit on error?      |

Table Footnotes

* [`1`] This value is a base value; a small amount is added to this number by each new SeedLink session to minimize the risk of congestion

Change these with `SeisBase.KW.SL.[key] = value`, e.g., `SeisBase.KW.SL.refresh = 30`.

## Special Behavior

1. SeedLink follows unusual rules for wild cards in `sta` and `patts`:
    a. `*` is not a valid SeedLink wild card.
    b. The LOC and CHA fields can be left blank in `sta` to select all locations and channels.
2. **DO NOT** feed one data channel from multiple SeedLink connections. This leads to TCP congestion on your computer, which can have *severe* consequences:
    a. A channel fed by multiple SeedLink connections will have many small segments, all out of order. *merge!* might fix this if caught quickly, but with hundreds of disjoint segments, expect memory and CPU issues.
    b. Your SeedLink connection will probably reset.
    c. Julia may freeze, requiring `kill -9`. To the best of our knowledge Julia has no special handling to mitigate TCP congestion.
    d. Your data may be corrupted, including disk writes from *w=true*.

### Special Methods
* `close(S.c[i])` ends SeedLink connection `i`.
* `!deleteat(S.c, i)` removes a handle to closed SeedLink connection `i`.


## SeedLink Utilities

```@docs
sl_info
has_sta
has_stream
```
