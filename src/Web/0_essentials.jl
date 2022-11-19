export web_chanspec, seis_www, track_on!, track_off!

# Generic handler for getting data by HTTP
# Returns:
#   R::Array{UInt8,1}, either request body or error data
#   parsable::Bool, whether or not R is parsable
function get_http_req(url::String, req_info_str::String, to::Int; status_exception::Bool=false)
  (R::Array{UInt8,1}, parsable::Bool) = try
    req = request(  "GET", url, webhdr,
                    readtimeout = to,
                    status_exception = status_exception  )
    if req.status == 200
      (req.body, true)

    else
      @warn(string("Request failed", req_info_str,
      "\nRESPONSE = ", req.status, " (", statustext(req.status), ")",
      "\n\nHTTP response is in misc[\"data\"]"))
      (Array{UInt8,1}(string(req)), false)
    end

  catch err
    T = typeof(err)
    @warn(  string( "Error thrown", req_info_str,
                    "\n\nERROR = ", T,
                    "\n\nTrying to store error message in misc[\"data\"]"
                    )
          )
    msg_data::Array{UInt8,1} = Array{UInt8,1}( try; string(getfield(err, :response)); catch; try; string(getfield(err, :msg));  catch; ""; end; end )
    (msg_data, false)
  end

  return R, parsable
end

function get_http_post(url::String, body::String, to::Int; status_exception::Bool=false)
  try
    req = request(  "POST", url, webhdr, body,
                    readtimeout = to,
                    status_exception = status_exception)
    if req.status == 200
      return (req.body, true)
    else
      @warn(string( "Request failed!\nURL: ", url, "\nPOST BODY: \n", body, "\n",
                    "RESPONSE: ", req.status, " (", statustext(req.status), ")\n" ) )
      return (Array{UInt8,1}(string(req)), false)
    end

  catch err
    @warn(string( "Error thrown:\nURL: ", url, "\nPOST BODY: \n", body, "\n",
                  "ERROR TYPE: ", typeof(err), "\n" ) )
    msg_data::Array{UInt8,1} = Array{UInt8,1}( try; string(getfield(err, :response)); catch; try; string(getfield(err, :msg));  catch; ""; end; end )
    return (msg_data, false)
  end
end

datareq_summ(src::String, ID::String, d0::String, d1::String) = ("\n" * src *
  " query:\nID = " * ID * "\nSTART = " * d0 * "\nEND = " * d1)

# ============================================================================
# Utility functions not for export
hashfname(str::Array{String,1}, ext::String) = string(hash(str), ".", ext)

# Start tracking channel IDs and data lengths
"""
    track_on!(S::SeisData)

Track changes to S.id, changes to channel structure of S, and the sizes of data
vectors in S.x. Does not track data processing operations to any channel i
unless length(S.x[i]) changes for channel i.

**Warning**: If you have or suspect gapped data in any channel, do not use
ungap! while tracking is active.
"""
function track_on!(S::SeisData)
  if S.n > 0
    ids = unique(getfield(S, :id))
    nxs = zeros(Int64, S.n)
    for i = 1:S.n
      nxs[i] = length(S.x[i])
    end
    S.misc[1]["track"] = (ids, nxs)
  end
  return nothing
end

# Stop tracking channel IDs and data lengths; report which have changed
"""
    u = track_off!(S::SeisData)

Turn off tracking in S and return a boolean vector of which channels have been added or altered significantly.
"""
function track_off!(S::SeisData)
  k = findfirst([haskey(S.misc[i],"track") for i = 1:S.n])
  if S.n == 0
    return nothing
  elseif k == nothing
    return trues(S.n)
  end
  u = falses(S.n)
  (ids, nxs) = S.misc[k]["track"]
  for (n, id) in enumerate(S.id)
    j = findfirst(x -> x == id, ids)
    if j == nothing
      u[n] = true
    else
      if nxs[j] != length(S.x[n])
        u[n] = true
      end
    end
  end
  delete!(S.misc[k], "track")
  return u
end

function savereq(D::Array{UInt8,1}, ext::String, id::String, s::String)
  if ext == "miniseed"
    ext = "mseed"
  elseif occursin("sac", ext)
    ext = "SAC"
  end
  s_str = int2tstr(tstr2int(s))
  yy = s_str[1:4]
  mm = s_str[6:7]
  dd = s_str[9:10]
  HH = s_str[12:13]
  MM = s_str[15:16]
  SS = s_str[18:19]
  nn = lpad(div(parse(Int64, s_str[21:26]), 1000), 3, '0')
  jj = lpad(md2j(yy, mm, dd), 3, '0')
  fname = join([yy, jj, HH, MM, SS, nn, id, "R", ext], '.')
  safe_isfile(fname) && @warn(string("File ", fname, " contains an identical request; overwriting."))
  f = open(fname, "w")
  write(f, D)
  close(f)
  return fname
end

"""
| String | Source             |
|:------:|:-------------------|
|BGR    | http://eida.bgr.de |
|EMSC   | http://www.seismicportal.eu |
|ETH    | http://eida.ethz.ch |
|GEONET | http://service.geonet.org.nz |
|GFZ    | http://geofon.gfz-potsdam.de |
|ICGC   | http://ws.icgc.cat |
|INGV   | http://webservices.ingv.it |
|IPGP   | http://eida.ipgp.fr |
|IRIS   | http://service.iris.edu |
|IRISPH5| http://service.iris.edu/ph5ws/ |
|ISC    | http://isc-mirror.iris.washington.edu |
|KOERI  | http://eida.koeri.boun.edu.tr |
|LMU    | http://erde.geophysik.uni-muenchen.de |
|NCEDC  | http://service.ncedc.org |
|NIEP   | http://eida-sc3.infp.ro |
|NOA    | http://eida.gein.noa.gr |
|ORFEUS | http://www.orfeus-eu.org |
|RESIF  | http://ws.resif.fr |
|SCEDC  | http://service.scedc.caltech.edu |
|TEXNET | http://rtserve.beg.utexas.edu |
|USGS   | http://earthquake.usgs.gov |
|USP    | http://sismo.iag.usp.br |
"""
seis_www = Dict(
    "BGR" => "http://eida.bgr.de",
    "EMSC" => "http://www.seismicportal.eu",
    "ETH" => "http://eida.ethz.ch",
    "GEONET" => "http://service.geonet.org.nz",
    "GFZ" => "http://geofon.gfz-potsdam.de",
    "ICGC" => "http://ws.icgc.cat",
    "INGV" => "http://webservices.ingv.it",
    "IPGP" => "http://eida.ipgp.fr",
    "IRIS" => "http://service.iris.edu",
    "ISC" => "http://isc-mirror.iris.washington.edu",
    "KOERI" => "http://eida.koeri.boun.edu.tr",
    "LMU" => "http://erde.geophysik.uni-muenchen.de",
    "NCEDC" => "http://service.ncedc.org",
    "NIEP" => "http://eida-sc3.infp.ro",
    "NOA" => "http://eida.gein.noa.gr",
    "ODC" => "http://www.orfeus-eu.org",
    "ORFEUS" => "http://www.orfeus-eu.org",
    "RESIF" => "http://ws.resif.fr",
    "SCEDC" => "http://service.scedc.caltech.edu",
    "TEXNET" => "http://rtserve.beg.utexas.edu",
    "USGS" => "http://earthquake.usgs.gov",
    "USP" => "http://sismo.iag.usp.br",
)
ph5_www = Dict("IRISPH5" => "http://service.iris.edu")

function fdsn_uhead(src::String)
  if !occursin("PH5",src)
    return haskey(seis_www, src) ? seis_www[src] * "/fdsnws/" : src
  else
    return haskey(ph5_www, src) ? ph5_www[src] * "/ph5ws/" : src
  end
end

"""
    web_chanspec

## Specifying Channel IDs in Web Requests
| Str | L  | Meaning              | Example |
|:--- |:---|:-----                |:-----   |
| NET | 2  | Network code         | "IU"    |
| STA | 5  | Station code         | "ANMO"  |
| LOC | 2  | Location identifier  | "00"    |
| CHA | 3  | Channel code         | "BHZ"   |

A channel is uniquely specified by four substrings (NET, STA, LOC, CHA), which
can be formatted as a String or a String array. Each substring has a maximum
safe length of `L` characters (column 2 in the table).

### Acceptable Channel ID Formats
| Type              | Example                                           |
|:-----             |:-----                                             |
| String            | "PB.B004.01.BS1, PB.B004.01.BS2"                  |
| Array{String, 1}  | ["PB.B004.01.BS1","PB.B004.01.BS2"]               |
| Array{String, 2}  | ["PB" "B004" "01" "BS?"; "PB" "B001" "01" "BS?"]  |

The `LOC` field can be blank in FDSN requests with get_data; for example,
`chans="UW.ELK..EHZ"; get_data("FDSN", chans)`.

#### SeedLink only
For SeedLink functions (`seedlink!`, `has_stream`, etc.), channel IDs can
include a fifth field (i.e. NET.STA.LOC.CHA.T) to set the "type" flag (one of
DECOTL, for Data, Event, Calibration, blOckette, Timing, or Logs). Note that
SeedLink calibration, timing, and logs are not in the scope of SeisBase.

See also: `get_data`, `seedlink`
"""
function web_chanspec()
  return nothing
end
