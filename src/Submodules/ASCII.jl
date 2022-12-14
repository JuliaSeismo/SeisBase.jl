module ASCII
using Dates, Mmap, Printf, SeisBase, SeisBase.FastIO, SeisBase.Formats

# imports
include("ASCII/imports.jl")
include("ASCII/GeoCSV.jl")
include("ASCII/SLIST.jl")

# exports
export  formats,
        read_geocsv_file!,
        read_geocsv_slist!,
        read_geocsv_tspair!,
        read_slist!
end
