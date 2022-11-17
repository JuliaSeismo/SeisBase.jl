module Quake
using Blosc, Dates, DSP, LightXML, LinearAlgebra, Printf, SeisBase, SeisBase.FastIO, Sockets
using HTTP: request, Messages.statustext
Blosc.set_compressor("lz4")
Blosc.set_num_threads(Sys.CPU_THREADS)
path = Base.source_dir()

const tracefields = (:az, :baz, :dist, :id, :loc, :fs, :gain, :misc, :name, :notes, :pha, :resp, :src, :t, :units, :x)
const loc_qual_fields = (:se, :gap, :dmin, :dmax)
const loc_qual_names = ("standardError", "azimuthalGap", "minimumDistance", "maximumDistance")

# imports
include("Quake/imports.jl")

# types for earthquake data
include("Quake/Types/EQLoc.jl")
include("Quake/Types/EQMag.jl")
include("Quake/Types/SourceTime.jl")
include("Quake/Types/SeisSrc.jl")
include("Quake/Types/SeisPha.jl")
include("Quake/Types/PhaseCat.jl")
include("Quake/Types/SeisHdr.jl")
include("Quake/Types/EventTraceData.jl")
include("Quake/Types/EventChannel.jl")
include("Quake/Types/SeisEvent.jl")

# formats
for i in ls(path*"/Quake/Formats/")
  if endswith(i, ".jl")
    include(i)
  end
end

# processing
for i in ls(path*"/Quake/Processing/")
  if endswith(i, ".jl")
    include(i)
  end
end

# utilities
for i in ls(path*"/Quake/Utils/")
  if endswith(i, ".jl")
    include(i)
  end
end

# web
for i in ls(path*"/Quake/Web/")
  if endswith(i, ".jl")
    include(i)
  end
end

# exports
include("Quake/exports.jl")

end
