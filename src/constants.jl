export TimeSpec

# Most constants are defined here, except:
#
# BUF           src/Types/SeisIOBuf.jl
# KW            src/Types/KWDefs.jl
# PhaseCat      src/Types/Quake/PhaseCat.jl
# flat_resp     src/Types/InstResp.jl
# RespStage     src/Types/InstResp.jl
# type_codes    src/Types/Methods/0_type_codes.jl
#
# ...and submodule-specific constants, which are in the submodule declaration files (e.g. SEED.jl)

# Type aliases
const ChanSpec    = Union{Integer, UnitRange, Array{Int64, 1}}
const FloatArray  = Union{AbstractArray{Float64, 1}, AbstractArray{Float32, 1}}

@doc """
    TimeSpec = Union{Real, DateTime, String}

# Time Specification
Most functions that allow time specification use two reserved keywords to track
time: `s` (start/begin) time and `t` (termination/end) time. Exact behavior
of each is given in the table below.

* Real numbers are interpreted as seconds
* DateTime values are as in the Dates package
* Strings should use ISO 8601 *without* time zone (`YYYY-MM-DDThh:mm:ss.s`); UTC is assumed. Equivalent Unix `strftime` format codes are `%Y-%m-%dT%H:%M:%S` or `%FT%T`.

## **parsetimewin Behavior**
In all cases, parsetimewin outputs a pair of strings, sorted so that the first string corresponds to the earlier start time.

| typeof(s) | typeof(t) | Behavior                                          |
|:------    |:------    |:-------------------------------------             |
| DateTime  | DateTime  | sort                                              |
| DateTime  | Real      | add *t* seconds to *s*, then sort                 |
| DateTime  | String    | convert *t* => DateTime, then sort                |
| DateTime  | String    | convert *t* => DateTime, then sort                |
| Real      | DateTime  | add *s* seconds to *t*, then sort                 |
| Real      | Real      | treat *s*, *t* as seconds from current time; sort |
| String    | DateTime  | convert *s* => DateTime, then sort                |
| String    | Real      | convert *s* => DateTime, then sort                |

Special behavior with (Real, Real): *s* and *t* are converted to seconds from
the start of the current minute. Thus, for `s=0` (the default), the data request
begins (or ends) at the start of the minute in which the request is submitted.

See also: `Dates.DateTime`
""" TimeSpec
const TimeSpec    = Union{Real, DateTime, String}
const ChanOpts    = Union{String, Array{String, 1}, Array{String, 2}}
const bad_chars = Dict{String, Any}(
  "File" => (0x22, 0x24, 0x2a, 0x2f, 0x3a, 0x3c, 0x3e, 0x3f, 0x40, 0x5c, 0x5e, 0x7c, 0x7e, 0x7f),
  "HTML" => (0x22, 0x26, 0x27, 0x3b, 0x3c, 0x3e, 0xa9, 0x7f),
  "Julia" => (0x24, 0x5c, 0x7f),
  "Markdown" => (0x21, 0x23, 0x28, 0x29, 0x2a, 0x2b, 0x2d, 0x2e, 0x5b, 0x5c, 0x5d, 0x5f, 0x60, 0x7b, 0x7d),
  "SEED" => (0x2e, 0x7f),
  "Strict" => (0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a,
               0x2b, 0x2c, 0x2d, 0x2e, 0x2f, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f,
               0x40, 0x5b, 0x5c, 0x5d, 0x5e, 0x60, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f) )
const datafields = (:id, :name, :loc, :fs, :gain, :resp, :units, :src, :notes, :misc, :t, :x)
const days_per_month = Int32[31,28,31,30,31,30,31,31,30,31,30,31]
const default_fs    = zero(Float64)
const default_gain  = one(Float64)
const dtchars = (0x2d, 0x2e, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x54)
const dtconst = 62135683200000000
const regex_chars = String[Sys.iswindows() ? "/" : "\\", "\$", "(", ")", "+", "?", "[", "\\0",
"\\A", "\\B", "\\D", "\\E", "\\G", "\\N", "\\P", "\\Q", "\\S", "\\U", "\\U",
"\\W", "\\X", "\\Z", "\\a", "\\b", "\\c", "\\d", "\\e", "\\f", "\\n", "\\n",
"\\p", "\\r", "\\s", "\\t", "\\w", "\\x", "\\x", "\\z", "]", "^", "{", "|", "}"]
const show_os = 8
const sac_float_k = String[ "delta", "depmin", "depmax", "scale", "odelta",
                            "b", "e", "o", "a", "internal1",
                            "t0", "t1", "t2", "t3", "t4",
                            "t5", "t6", "t7", "t8", "t9",
                            "f", "resp0", "resp1", "resp2", "resp3",
                            "resp4", "resp5", "resp6", "resp7", "resp8",
                            "resp9", "stla", "stlo", "stel", "stdp",
                            "evla", "evlo", "evel", "evdp", "mag",
                            "user0", "user1", "user2", "user3", "user4",
                            "user5", "user6", "user7", "user8", "user9",
                            "dist", "az", "baz", "gcarc", "sb",
                            "sdelta", "depmen", "cmpaz", "cmpinc", "xminimum",
                            "xmaximum", "yminimum", "ymaximum", "adjtm", "unused2",
                            "unused3", "unused4", "unused5", "unused6", "unused7" ]
# was:                      "dist", "az", "baz", "gcarc", "internal2",
#                           "internal3", "depmen", "cmpaz", "cmpinc", "xminimum",
#                           "xmaximum", "yminimum", "ymaximum", "unused1", "unused2",
#                           "unused3", "unused4", "unused5", "unused6", "unused7" ]
const sac_int_k = String[   "nzyear", "nzjday", "nzhour", "nzmin", "nzsec",
                            "nzmsec", "nvhdr", "norid", "nevid", "npts",
                            "internal4", "nwfid", "nxsize", "nysize", "unused8",
                            "iftype", "idep", "iztype", "unused9", "iinst",
                            "istreg", "ievreg", "ievtyp", "iqual", "isynth",
                            "imagtyp", "imagsrc", "unused10", "unused11", "unused12",
                            "unused13", "unused14", "unused15", "unused16", "unused17",
                            "leven", "lpspol", "lovrok", "lcalda", "unused18" ]
const sac_string_k = String["kstnm", "kevnm", "khole", "ko", "ka", "kt0", "kt1", "kt2",
                            "kt3", "kt4", "kt5", "kt6", "kt7", "kt8", "kt9", "kf", "kuser0",
                            "kuser1", "kuser2", "kcmpnm", "knetwk", "kdatrd", "kinst" ]
const sac_double_k = String[  "delta", "b", "e", "o", "a",
                              "t0", "t1", "t2", "t3", "t4",
                              "t5", "t6", "t7", "t8", "t9",
                              "f", "evlo", "evla", "stlo", "stla", "sb", "sdelta"]
const sac_nul_c = UInt8[0x2d, 0x31, 0x32, 0x33, 0x34, 0x35, 0x20, 0x20]
const sac_nul_f = -12345.0f0
const sac_nul_d = -12345.0
const sac_nul_i = Int32(-12345)
const sac_nul_start = 0x2d
const sac_nul_Int8 = UInt8[0x31, 0x32, 0x33, 0x34, 0x35]
const segy_ftypes  = Array{DataType, 1}([UInt32, Int32, Int16, Any, Float32, Any, Any, Int8]) # Note: type 1 is IBM Float32
const segy_units = Dict{Int16, String}(0 => "unknown", 1 => "Pa", 2 => "V", 3 => "mV", 4 => "A", 5 => "m", 6 => "m/s", 7 => "m/s2", 8 => "N", 9 => "W")
const seis_inst_codes = ('H', 'J', 'L', 'M', 'N', 'P', 'Z')
const seisio_file_begin = UInt8[0x53, 0x45, 0x49, 0x53, 0x49, 0x4f]
const sμ = 1000000.0
const vSeisIO = Float32(0.54)
const unindexed_fields = (:c, :n)
const webhdr = Dict("User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Safari/537.36") # lol
const xml_endtime = 19880899199000000
const μs = 1.0e-6
