function nextline(pf::IO, c::Char)
    eof(pf) && return "-1"
    s = "\0"
    while s[1] != c
        eof(pf) && return "-1"
        s = chomp(readline(pf))
    end
    return s
end

@doc """
    H, R = uwpf(pf[, v])

Read UW-format seismic pick file `pf` into SeisHdr object `H`, with seismic
source description (focal mechanism) returned in SeisSrc object `R`.

    uwpf!(W, pf[, v::Integer=KW.v])

Read UW-format seismic pick info from pickfile `f` into SeisEvent object `W`.
Overwrites W.source and W.hdr with pickfile information. Keyword `v` controls
verbosity.

!!! caution

    Reader has no safety check to guarantee that `pf` is from the same event.

""" uwpf
function uwpf(pickfile::String; v::Integer=KW.v)
  # Initialize variables that will fill SeisHdr structure
  D   = Dict{String, Any}()
  MAG = -5.0f0
  ID  = ""
  OT  = zero(Float64)
  loc = zeros(Float64, 12)
  sig = ""
  locflags = Array{Char, 1}(undef,8)
  R = SeisSrc()
  fill!(locflags, '0')

  # Read begins
  pf = open(pickfile, "r")

  # ========================================================================
  # Acard line
  A = nextline(pf, 'A')
  (v > 1)  && println(stdout, A)
  c = 0
  if length(A) == 75 || length(A) == 12
    y = zero(Int8)
    c = 1900
  else
    y = Int8(2)
  end
  D["type"] = getindex(A, 2)

  # ACard indices
  #
  # Crosson's notes:
  # Type, Year, Month,  Day,  Hour, Min,  Sec,  LatDeg, NS, Latmin*100, LongDeg,  EW, Lonmin*100, Depth, Fix, Magnitude, Numsta, numphase, Gap, Mindelta, RMS, ERR, Q1, Q2, Velmodel
  # ATYYYYMMDDHHMM SS.SS LLNMMMM LLLWMMMM DD.DD* M.M NN/0NN GGG DD R.RR EE.EQQ VV
  # AF200206291436  4.79 45N2009 121W4118  6.20* 4.5 41/041  37  9 0.27  0.1BB O0
  #
  #        Sec,Lat,Lon,Dep,Fix,Mag,Nst,Nph,Gap, d0,RMS,ERR, Q, mod
  si = Int8[13, 19, 27, 36, 42, 43, 47, 51, 54, 58, 61, 66, 71, 74] .+ y
  ei = Int8[18, 26, 35, 41, 42, 46, 49, 53, 57, 60, 65, 70, 72, 75] .+ y
  L = length(si)

  # Parse reset of Acard line
  ah = Array{String,1}(undef, L)
  for i = 1:L
    setindex!(ah, getindex(A, getindex(si, i):getindex(ei, i)), i)
  end
  v > 2 && println("ah = ", ah)

  # origin time, event depth, and magnitude
  OT            = d2u(DateTime(string(parse(Int64, A[3:4+y]) + c)*A[5+y:12+y],
                      "yyyymmddHHMM")) + parse(Float64, getindex(ah, 1))
  evla          = getindex(ah, 2)
  evlo          = getindex(ah, 3)
  loc[3]        = parse(Float64, getindex(ah, 4))       # depth           :dep
  locflags[3]   = (getindex(ah, 5) == "F") ? '1' : '0'
  MAG           = parse(Float32, getindex(ah, 6))
  nst           = parse(Int64, getindex(ah, 7))
  D["numpha"]   = parse(Int64, getindex(ah, 8))
  loc[10]       = parse(Float64, getindex(ah, 9))       # gap             :gap
  loc[11]       = parse(Float64, getindex(ah, 10))      # min distance    :dmin
  loc[9]        = parse(Float64, getindex(ah, 11))      # rms pick error  :rms
  loc[8]        = parse(Float64, getindex(ah, 12))      # standard error  :se
  D["qual"]     = getindex(ah, 13)
  D["vmod"]     = getindex(ah, 14)

  # Convert lat and lon to decimal degrees
  loc[1] = (parse(Float64, evla[1:3]) +
            parse(Float64, evla[5:6])/60.0 +
            parse(Float64, evla[7:8])/6000.0) * (evla[4] == 'S' ? -1.0 : 1.0)
  loc[2] = (parse(Float64, evlo[1:4]) +
            parse(Float64, evlo[6:7])/60.0 +
            parse(Float64, evlo[8:9])/6000.0) * (evlo[5] == 'W' ? -1.0 : 1.0)

  # ========================================================================
  # Error line
  seekstart(pf)
  eline = nextline(pf, 'E')
  if eline != "-1"
    # E O0  0.27 0.022 0.281 0.281  141.30  38   Z  0.05 0.05 0.11 0.01 4.50 0.000.03
    # Effectively: 10x   MeanRMS    SDabout0    SDaboutMean    SSWRES    NDFR    FIXXYZT    SDx    SDy    SDz    SDt    Mag  5x MeanUncert
    #              10x   f6.3       f6.3        f6.3           f8.2      i4      a4        f5.2   f5.2   f5.2   f5.2   f5.2  5x f4.2
    eline_keys = String["MeanRMS", "SDabout0", "SDaboutMean", "SSWRES", "NDFR", "FIXXYZT", "SDx", "SDy", "SDz", "SDt", "Mag", "MeanUncert"]
    si =           Int8[       11,         17,            23,       29,     37,        42,    46,     51,    56,   61,    66,           76]
    ei =           Int8[       16,         22,            28,       36,     40,        45,    50,     55,    60,   65,    70,           79]
    j = 0

    while j < length(eline_keys)
      j = j + 1
      a = getindex(si, j)
      b = getindex(ei, j)
      s = getindex(eline, a:b)
      if j == 6
        (s[1] == 'X') && (locflags[1] = '1')
        (s[2] == 'Y') && (locflags[2] = '1')
        (s[3] == 'Z') && (locflags[3] = '1')
        (s[4] == 'T') && (locflags[4] = '1')
      elseif j == 7
        loc[4] = parse(Float64, s)
      elseif j == 8
        loc[5] = parse(Float64, s)
      elseif j == 9
        loc[6] = parse(Float64, s)
      elseif j == 10
        if s != "*****"
          loc[7] = parse(Float64, s)
        end
      elseif !isempty(s)
        k = getindex(eline_keys, j)
        D[k] = parse(j == 5 ? Int32 : Float32, s)
      end
    end
    sig = "1σ"
  end
  LOC = EQLoc(loc..., nst, parse(UInt8, join(locflags), base=2), "", "hypocenter", "", "SPONG")

  # ========================================================================
  # Focal mechanism line(s)
  #= Note: planes F and G azimuth and an incidence are NOT in N°E. They're
    measured clockwise from the (N°E) azimuth of the dip vector, because R.
    Crosson wanted to be a unique special snowflake.

    The axes copied to Hdr.axes are therefore P, T, with the last field of
    the 3Tuple set to 0.0.
  =#
  seekstart(pf)
  mline = nextline(pf,'M')
  m = 0
  PAX = Array{Float64,2}(undef, 2 ,2)
  NP = Array{Float64,2}(undef, 2, 2)
  if mline != "-1"
    # Convert first mechanism line
    M = split(mline)

    setindex!(NP, parse(Float64, getindex(M, 3)), 1)
    setindex!(NP, parse(Float64, getindex(M, 4)), 2)
    setindex!(NP, parse(Float64, getindex(M, 6)), 3)
    setindex!(NP, parse(Float64, getindex(M, 7)), 4)

    # Order here is T, P
    setindex!(PAX, parse(Float64, getindex(M, 18)), 1)
    setindex!(PAX, parse(Float64, getindex(M, 19)), 2)
    setindex!(PAX, parse(Float64, getindex(M, 15)), 3)
    setindex!(PAX, parse(Float64, getindex(M, 16)), 4)

    setfield!(R, :pax, PAX)
    setfield!(R, :planes, NP)
    pf_str = abspath(pickfile)
    setfield!(R, :src, pf_str)
    note!(R, "+source ¦ " * pf_str)

    # Add rest to a dictionary
    mech_lines = Array{String, 1}(undef, 0)
    mline = nextline(pf,'M')
    while mline != "-1"
      m += 1
      push!(mech_lines, mline)
      mline = nextline(pf,'M')
    end
    R.gap = getindex(loc, 10)
    if !isempty(mech_lines)
      R.misc["mech_lines"] = mech_lines
    end
    v>0 && println(stdout, "Processed ", m, " focal mechanism lines.")
    note!(R, string("planes are arranged [θ₁ θ₂; ϕ₁ ϕ₂] but θ₁, θ₂ are NOT oriented N°E. ",
                    "They're measured clockwise from the N°E azimuth of the dip vector."))
    note!(R, string("gap is copied from the A-card line; this likely ",
                    "under-represents the true focal mechanism gap."))
  end

  # ========================================================================
  # Comment lines
  seekstart(pf)
  m = 0
  cline = nextline(pf,'C')
  if cline != "-1"
    D["comment"] = Array{String, 1}(undef, 0)
    while cline != "-1"
      m = m + 1
      L = lastindex(cline)
      if occursin("NEAR", cline)
        D["loc_name"] = getindex(cline, 8:L)
      elseif occursin("EVENT ID", cline)
        ID = getindex(cline, 13:L)
      elseif occursin("LOCATED BY", cline)
        setfield!(LOC, :src, getfield(LOC, :src) * "; " * getindex(cline, 3:L))
      else
        push!(D["comment"], getindex(cline, 3:L))
      end
      cline = nextline(pf,'C')
    end
    v > 0 && println(stdout, "Processed ", m, " comment lines.")
  end

  # ========================================================================
  # Done reading
  close(pf)
  H = SeisHdr()
  src_str = abspath(pickfile)
  setfield!(H, :loc, LOC)
  setfield!(H, :src, src_str)
  note!(H, "+source ¦ " * src_str)
  if MAG != -5.0f0
    setfield!(H, :mag, EQMag(val = MAG, scale = "Md", src = "SPONG"))
  end
  if OT != zero(Float64)
    setfield!(H, :ot, u2d(OT))
  end
  if isempty(ID) == false
    setfield!(H, :id, string(ID))
    setfield!(R, :eid, string(ID))
  end
  if isempty(D) == false
    setfield!(H, :misc, D)
  end

  return H, R
end

@doc (@doc uwpf)
function uwpf!(S::SeisEvent, pickfile::String; v::Integer=KW.v)
  (H, R) = uwpf(pickfile, v=v)

  N   = getfield(getfield(S, :data), :n)
  ID  = getfield(getfield(S, :data), :id)
  PHA = getfield(getfield(S, :data), :pha)
  cha = Array{String,1}(undef, N)
  for i = 1:N
    id = split(getindex(ID, i), ".", keepempty=true)
    setindex!(cha, string(".", getindex(id, 2), ".", getindex(id, 4)), i)
  end
  v > 2 && println("cha = ", cha)

  # Pick lines (requires reopening/rereading file)
  m = 0
  ndur = 0
  npol = 0
  pf = open(pickfile, "r")
  pick_line = nextline(pf, '.')

  while pick_line != "-1"
    v>1 && println(stdout, "pick_line = ", pick_line)
    m += 1
    pdat = split(pick_line, "(")
    pick_cha = getindex(pdat, 1)
    pcat = PhaseCat()
    dur = 0.0

    # Parse picks
    for j = 2:length(pdat)
      pha = split(getindex(pdat, j))
      if getindex(pha, 1) == "P"
        v > 2 && println(pha)
        pol = getindex(pha, 3)[1]
        if pol != '_'
          npol = npol + 1
        end
        pcat[getindex(pha,2)] = SeisPha(
          0.0,                              # amp
          0.0,                              # d
          0.0,                              # inc
          parse(Float64, pha[7][1:end-1]),  # res
          0.0,                              # rp
          0.0,                              # ta
          parse(Float64, pha[4]),           # tt --> relative to file begin; fixed below
          parse(Float64, pha[6]),           # unc
          pol,                              # polarity
          pha[5][1]                         # quality
          )
      elseif getindex(pha, 1) == "D"
        dur = parse(Float64, getindex(pha,2)[1:end-1])
      end
    end

    # Assign to the correct channel
    for i = 1:N
      if startswith(pick_cha, getindex(cha, i))
        for p in keys(pcat)
          PHA[i][p] = pcat[p]
        end
        if dur > 0.0
          ndur = ndur + 1
          S.data.misc[i]["dur"] = dur
        end
        break
      end
    end
    pick_line = nextline(pf, '.')
  end
  v>0 && println(stdout, "Processed ", m, " pick lines.")
  close(pf)

  # Set ndur, npol
  setfield!(getfield(H, :mag), :nst, ndur)
  setfield!(R, :npol, npol)

  # Place hdr, source
  setfield!(S, :hdr, H)
  setfield!(S, :source, R)

  # Done
  return S
end
