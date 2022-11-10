export sachdr, writesac, writesacpz

# =====================================================================
# Bytes 305:308 as a littleendian Int32 should read 0x06 0x00 0x00 0x00; compare each end to 0x0a to allow older SAC versions (if version in same place?)
function should_bswap(io::IO)
  fastskip(io, 304)
  u = fastread(io)
  fastskip(io, 2)
  v = fastread(io)
  q::Bool = (
    # Least significant byte in u
    if 0x00 < u < 0x0a && v == 0x00
      false
    # Most significant byte in u
    elseif u == 0x00 && 0x00 < v < 0x0a
      true
    else
      error("Invalid SAC file.")
    end
    )
  return q
end

function reset_sacbuf()
  checkbuf_strict!(BUF.sac_fv, 70)
  checkbuf_strict!(BUF.sac_iv, 40)
  checkbuf_strict!(BUF.sac_cv, 192)
  checkbuf_strict!(BUF.sac_dv, 22)

  fill!(BUF.sac_fv, sac_nul_f)
  fill!(BUF.sac_dv, sac_nul_d)
  fill!(BUF.sac_iv, sac_nul_i)
  for i in 1:24
    BUF.sac_cv[1+8*(i-1):8*i] = sac_nul_c
  end
  BUF.sac_cv[17:24] .= 0x20
  BUF.sac_iv[7] = Int32(7)
end

# =====================================================================
# write internals
function fill_sac_id(id_str::String)
  id = split_id(id_str)

  # Chars, all segments
  ci = [169, 1, 25, 161]
  for j = 1:4
    (j == 3) && continue
    sj = ci[j]
    if isempty(id[j])
      BUF.sac_cv[sj:sj+7] .= sac_nul_c
    else
      s = codeunits(id[j])
      L = min(length(s), 8)
      copyto!(BUF.sac_cv, sj, s, 1, L)
      if L < 8
        BUF.sac_cv[sj+L:sj+7] .= 0x20
      end
    end
  end
  return id
end

function fill_sac(si::Int64, nx::Int32, ts::Int64, id::Array{String,1})
  @assert nx ≤ typemax(Int32)
  t_arr!(BUF.sac_iv, ts)

  # Ints
  BUF.sac_iv[10] = Int32(nx)

  # Floats
  b = ts - round(Int64, ts/1000)*1000
  BUF.sac_fv[6] = (b == 0) ? 0.0f0 : b*1.0f-6
  BUF.sac_fv[7] = BUF.sac_fv[6] + BUF.sac_fv[1]*nx

  # Filename
  y_s = lpad(BUF.sac_iv[1], 4, '0')
  j_s = lpad(BUF.sac_iv[2], 3, '0')
  h_s = lpad(BUF.sac_iv[3], 2, '0')
  m_s = lpad(BUF.sac_iv[4], 2, '0')
  s_s = lpad(BUF.sac_iv[5], 2, '0')
  ms_s = lpad(BUF.sac_iv[6], 3, '0')
  fname = join([y_s, j_s, h_s, m_s, s_s, ms_s, id[1], id[2], id[3], id[4], "R.SAC"], '.')
  return fname
end

function write_sac_file(fname::String, x::AbstractArray{T,1}) where T
  open(fname, "w") do io
    write(io, BUF.sac_fv)
    write(io, BUF.sac_iv)
    write(io, BUF.sac_cv)
    if eltype(x) == Float32
      write(io, x)
    else
      write(io, Float32.(x))
    end

    # Switching this to a user option
    if BUF.sac_iv[7] == Int32(7)
      write(io, BUF.sac_dv)
    end
  end
  return nothing
end

function write_sac_channel(S::GphysData, i::Integer, nvhdr::Integer, fn::String, v::Integer)
  id = fill_sac_id(S.id[i])
  fs = S.fs[i]
  t = S.t[i]

  # Floats, all segments
  dt = (fs == 0.0 ? 0.0 : 1.0/fs)
  if nvhdr == 7
    BUF.sac_dv[1] = dt
  end
  BUF.sac_fv[1] = Float32(dt)
  BUF.sac_fv[4] = Float32(S.gain[i])
  for i in (32, 33, 34, 58, 59)
    BUF.sac_fv[i] = 0.0f0
  end
  if !isempty(S.loc[i])
    loc = S.loc[i]
    if typeof(loc) == GeoLoc
      lat = getfield(loc, :lat)
      lon = getfield(loc, :lon)
      BUF.sac_fv[32] = Float32(lat)
      BUF.sac_fv[33] = Float32(lon)
      BUF.sac_fv[34] = Float32(getfield(loc, :el))
      BUF.sac_fv[58] = Float32(getfield(loc, :az))
      BUF.sac_fv[59] = Float32(getfield(loc, :inc))

      # IRIS docs claim STLA, STLO order is reversed w.r.t. single floats
      if nvhdr == 7
        BUF.sac_dv[19] = lon
        BUF.sac_dv[20] = lat
      end
    end
  end

  fname = ""
  if fs == 0.0
    v > 0  && @warn(string("Can't write irregular channels (fs = 0.0) to file; skipped channel ", i))
  else
    W = t_win(S.t[i], fs)
    inds = x_inds(S.t[i])
    BUF.sac_iv[7] = Int32(nvhdr)
    BUF.sac_iv[16] = one(Int32)
    BUF.sac_iv[36] = one(Int32)
    for j in 1:size(inds,1)
      si = inds[j,1]
      ei = inds[j,2]
      ts = W[j,1]
      nx = Int32(ei-si+1)
      if fn == ""
        fname = fill_sac(si, nx, ts, id)
      else
        fill_sac(si, nx, ts, id)
        fname = fn
      end
      vx = view(S.x[i], si:ei)
      write_sac_file(fname, vx)
      v > 0  && println(stdout, now(), ": Wrote SAC ts file ", fname, " from channel ", i, " segment ", j)
      fwrite_note!(S, i, "writesac", fname, string(", fname=\"", fn, "\", v=", v))
    end
  end
  return nothing
end

# =====================================================================
# read internals

function read_sac_stream(io::IO, full::Bool, swap::Bool)
  fv = BUF.sac_fv
  iv = BUF.sac_iv
  cv = BUF.sac_cv
  fastread!(io, fv)
  fastread!(io, iv)
  fastread!(io, cv)
  if swap == true
    fv .= bswap.(fv)
    iv .= bswap.(iv)
  end
  nx = getindex(iv, 10)
  x = Array{Float32,1}(undef, nx)
  fastread!(io, x)
  if swap == true
    broadcast!(bswap, x, x)
  end

  # floats
  loc = GeoLoc()
  j = 0
  lf = (:lat, :lon, :el, :az, :inc)
  for k in (32,33,34,58,59)
    j += 1
    val = getindex(fv, k)
    if val != sac_nul_f
      setfield!(loc, lf[j], Float64(val))
    end
  end

  # ints
  ts = mktime(getindex(iv, 1),
              getindex(iv, 2),
              getindex(iv, 3),
              getindex(iv, 4),
              getindex(iv, 5),
              getindex(iv, 6)*Int32(1000))
  b = getindex(fv, 6)
  if b != sac_nul_f
    ts += round(Int64, b*sμ)
  end

  # chars
  id = zeros(UInt8, 15)
  i = 0x01
  while i < 0xc1
    c = getindex(cv, i)
    if (c == sac_nul_start) && (i < 0xbc)
      val = getindex(cv, i+0x01:i+0x05)
      if val == sac_nul_Int8
        cv[i:i+0x05] .= 0x20
      end
    elseif c == 0x00
      setindex!(cv, i, 0x20)
    end
    # fill ID
    if i == 0x01
      i = fill_id!(id, cv, i, 0x08, 0x04, 0x08)
    elseif i == 0xa1
      id[0x0c] = 0x2e
      i = fill_id!(id, cv, i, 0xa8, 0x0d, 0x0f)
    elseif i == 0xa9
      i = fill_id!(id, cv, i, 0xb0, 0x01, 0x02)
    else
      i = i+0x01
    end
  end
  for i in 15:-1:1
    if id[i] == 0x00
      deleteat!(id, i)
    end
  end

  # Create a seischannel
  D = Dict{String,Any}()
  C = SeisChannel(unsafe_string(pointer(id)),
                "",
                loc,
                Float64(1.0f0/getindex(fv, 1)),
                fv[4] == sac_nul_f ? 1.0 : Float64(fv[4]),
                PZResp(),
                "",
                "",
                D,
                Array{String,1}(undef, 0),
                mk_t(nx, ts),
                x)

  # Create dictionary if full headers are desired
  if full == true
    # Parse floats
    m = 0x00
    while m < 0x46
      m += 0x01
      if fv[m] != sac_nul_f
        D[sac_float_k[m]] = getindex(fv, m)
      end
    end

    # Parse ints
    m = 0x00
    while m < 0x28
      m += 0x01
      if iv[m] != sac_nul_i
        D[sac_int_k[m]] = getindex(iv, m)
      end
    end

    m = 0x00
    j = 0x01
    while j < 0x18
      n = j == 0x02 ? 0x10 : 0x08
      p = m + n
      ii = m
      while ii < p
        ii += 0x01
        if getindex(cv,ii) != 0x20
          D[sac_string_k[j]] = unsafe_string(pointer(cv, m+0x01), n)
          break
        end
      end
      m += n
      j += 0x01
    end
  end

  # SAC v102.0 (NVHDR == 7) adds a footer
  if iv[7] > 6
    dv = BUF.sac_dv
    fastread!(io, dv)
    swap && (dv .= bswap.(dv))

    # DELTA
    if dv[1] != sac_nul_d
      C.fs = 1.0/dv[1]
    end

    # B
    if (b != sac_nul_f) && (dv[2] != sac_nul_d)
      C.t[1,2] += (round(Int64, dv[2]*sμ) - round(Int64, b*sμ))
    end

    # STLO, STLA? (IRIS docs claim order is reversed w.r.t. single floats)
    if dv[19] != sac_nul_d
      C.loc.lon = dv[19]
    end

    if dv[20] != sac_nul_d
      C.loc.lat = dv[20]
    end

    if full == true
      m = 0x00
      while m < 0x16
        m += 0x01
        if dv[m] != sac_nul_d
          C.misc[sac_double_k[m]] = getindex(dv, m)
        end
      end
    end
  end
  return C
end

function read_sac_file!(S::SeisData, fname::String, full::Bool, memmap::Bool, strict::Bool)
  io = memmap ? IOBuffer(Mmap.mmap(fname)) : open(fname, "r")
  q = should_bswap(io)
  seekstart(io)
  C = read_sac_stream(io, full, q)
  close(io)
  add_chan!(S, C, strict)
  return nothing
end

# ============================================================================
# read_sacpz internals

function add_pzchan!(S::GphysData, D::Dict{String, Any}, file::String)
  id  = D["NETWORK   (KNETWK)"] * "." *
        D["STATION    (KSTNM)"] * "." *
        D["LOCATION   (KHOLE)"] * "." *
        D["CHANNEL   (KCMPNM)"]
  i = findid(id, S)
  loc   = GeoLoc( lat = parse(Float64, D["LATITUDE"]),
                  lon = parse(Float64, D["LONGITUDE"]),
                  el  = parse(Float64, D["ELEVATION"]),
                  dep = parse(Float64, D["DEPTH"]),
                  az  = parse(Float64, D["AZIMUTH"]),
                  inc = parse(Float64, D["DIP"])-90.0
                )
  fs    = parse(Float64, D["SAMPLE RATE"])

  # gain, units; note, not "INSTGAIN", that's just a scalar multipler
  gu    = split(D["SENSITIVITY"], limit=2, keepempty=false)
  gain  = parse(Float64, gu[1])
  units = lowercase(String(gu[2]))
  if startswith(units, "(")
    units = units[2:end]
  end
  if endswith(units, ")")
    units = units[1:end-1]
  end
  units = fix_units(units2ucum(units))

  #= fix for poorly-documented fundamental shortcoming:
    "INPUT UNIT"         => "M"
    I have no idea why SACPZ uses displacement PZ =#
  u_in = fix_units(units2ucum(D["INPUT UNIT"]))
  Z = get(D, "Z", ComplexF32[])
  if u_in != units
    if u_in == "m" && units == "m/s"
      deleteat!(Z, 1)
    elseif u_in == "m" && units == "m/s2"
      deleteat!(Z, 1:2)
    end
  end

  resp = PZResp(parse(Float32, D["A0"]),
                0.0f0,
                get(D, "P", ComplexF32[]),
                Z
                )

  if i == 0
    # resp
    C = SeisChannel()
    setfield!(C, :id, id)
    setfield!(C, :name, D["DESCRIPTION"])
    setfield!(C, :loc, loc)
    setfield!(C, :fs, fs)
    setfield!(C, :gain, gain)
    setfield!(C, :resp, resp)
    setfield!(C, :units, units)
    setfield!(C, :misc, D)
    push!(S, C)
  else
    ts = Dates.DateTime(get(D, "START", "1970-01-01T00:00:00")).instant.periods.value*1000 - dtconst
    te = Dates.DateTime(get(D, "END", "2599-12-31T23:59:59")).instant.periods.value*1000 - dtconst
    t0 = isempty(S.t[i]) ? ts : starttime(S.t[i], S.fs[i])
    if ts ≤ t0 ≤ te
      (S.fs[i] == 0.0) && (S.fs[i] = fs)
      (isempty(S.units[i])) && (S.units[i] = units)
      (S.gain[i] == 1.0) && (S.gain[i] = gain)
      (typeof(S.resp[i]) == GenResp || isempty(S.resp[i])) && (S.resp[i] = resp)
      (isempty(S.name[i])) && (S.name[i] = D["DESCRIPTION"])
      isempty(S.loc[i]) && (S.loc[i]  = loc)

      S.misc[i] = merge(D, S.misc[i])
    end
  end
  return nothing
end

# ============================================================================
# NOTE: Leave keyword arguments, even if some aren't type-stable!
# Use of "optional" variables instead is a 5x **slowdown**

"""
    sachdr(f)

Print formatted SAC headers from file `f` to stdout. Does not accept wildcard
file strings.
"""
function sachdr(fname::String)
  S = read_data("sac", fname, full=true)
  for i = 1:S.n
    D = getindex(getfield(S, :misc), i)
    src = getindex(getfield(S, :src), i)
    printstyled(string(src, "\n"), color=:light_green, bold=true)
    for k in sort(collect(keys(D)))
      println(stdout, uppercase(k), ": ", string(D[k]))
    end
  end
  return nothing
end

"""
    writesac(S::Union{GphysData,GphysChannel}[, chans, nvhdr=6, fname="", v=0])

Write all data in SeisData structure `S` to auto-generated SAC files.

Keywords:
* `chans="CC"` writes data from ChanSpec CC (GphysData only)
* `fname="FF"` uses filename FF (GphysChannel only)
* `nvhdr` is SAC NVHDR, the file header version (6 or 7). Default is 6.
* `v` is verbosity.
"""
function writesac(S::GphysData;
  chans::ChanSpec=Int64[],
  fname::String="",
  nvhdr::Integer=6,
  v::Integer=KW.v)
  reset_sacbuf()

  chans = mkchans(chans, S)
  for i in chans
    write_sac_channel(S, i, nvhdr, fname, v)
    reset_sacbuf()
  end
  return nothing
end

function writesac(S::GphysChannel;
  fname::String="",
  nvhdr::Integer=6,
  v::Integer=KW.v)

  fstr = String(
    if fname == ""
      fname
    else
      if endswith(lowercase(fname), ".sac")
        fname
      else
        fname * ".sac"
      end
    end
    )
  writesac(SeisData(S), nvhdr=nvhdr, fname=fstr, v=v)
  return nothing
end

@doc """
    read_sacpz!(S::GphysData, pzfile::String)

Read sacpz file `pzfile` into SeisIO struct `S`.

If an ID in the pz file matches channel `i` at times in `S.t[i]`:
* Fields :fs, :gain, :loc, :name, :resp, :units are overwritten if empty/unset
* Information from the pz file is merged into :misc if the corresponding keys
aren't in use.
""" read_sacpz!
function read_sacpz!(S::GphysData, file::String; memmap::Bool=false)
  io = memmap ? IOBuffer(Mmap.mmap(file)) : open(file, "r")
  read_state = 0x00
  D = Dict{String, Any}()
  kv = Array{String, 1}(undef, 2)

  # Do this for each channel
  while true

    # EOF
    if fasteof(io)
      add_pzchan!(S, D, file)
      break
    end

    line = fast_readline(io)

    # Header section
    if startswith(line, "*")
      if endswith(strip(line), "**")
        read_state += 0x01
        if read_state == 0x03
          add_pzchan!(S, D, file)
          read_state = 0x01
          D = Dict{String, Any}()
        end
      else
        kv .= strip.(split(line[2:end], ":", limit=2, keepempty=false))
        D[kv[1]] = kv[2]
      end

    # Zeros section
    elseif startswith(line, "ZEROS")
      N = parse(Int64, split(line, limit=2, keepempty=false)[2])
      D["Z"] = zeros(Complex{Float32}, N)
      for i = 1:N
        try
          mark(io)
          zc = split(fast_readline(io), limit=2, keepempty=false)
          D["Z"][i] = complex(parse(Float32, zc[1]), parse(Float32, zc[2]))
        catch
          reset(io)
        end
      end

    # Poles section
    elseif startswith(line, "POLES")
      N = parse(Int64, split(line, limit=2, keepempty=false)[2])
      D["P"] = Array{Complex{Float32},1}(undef, N)
      for i = 1:N
        pc = split(fast_readline(io), limit=2, keepempty=false)
        D["P"][i] = complex(parse(Float32, pc[1]), parse(Float32, pc[2]))
      end

    # Constant section
    elseif startswith(line, "CONSTANT")
      D["CONSTANT"] = String(split(line, limit=2, keepempty=false)[2])
    end
  end
  close(io)
  return S
end

@doc (@doc read_sacpz)
function read_sacpz(file::String; memmap::Bool=false)
  S = SeisData()
  read_sacpz!(S, file, memmap=memmap)
  return S
end

@doc """
    writesacpz(pzfile::String, S::GphysData[, chans::ChanSpec=CC])

Write fields from SeisIO struct `S` into sacpz file `pzfile`. Uses information
from fields :fs, :gain, :loc, :misc, :name, :resp, :units. Specify `chans=CC` to only write channels `CC`.
""" writesacpz
function writesacpz(file::String, S::GphysData; chans::ChanSpec=Int64[])
  cc = mkchans(chans, S, keepempty=true)
  io = open(file, "w")
  for i in cc
    id = split_id(S.id[i])
    created   = get(S.misc[i], "CREATED", string(u2d(time())))
    ts_str    = isempty(S.t[i]) ? "1970-01-01T00:00:00" : string(u2d(starttime(S.t[i], S.fs[i])*μs))
    t_start   = get(S.misc[i], "START", ts_str)
    t_end     = get(S.misc[i], "END", "2599-12-31T23:59:59")
    unit_in   = get(S.misc[i], "INPUT UNIT", "?")
    unit_out  = get(S.misc[i], "OUTPUT UNIT", "?")

    Y = typeof(S.resp[i])
    if Y == GenResp
      a0 = 1.0
      P = S.resp[i].resp[:,1]
      Z = deepcopy(S.resp[i].resp[:,2])
    elseif Y in (PZResp, PZResp64)
      a0 = getfield(S.resp[i], :a0)
      P = getfield(S.resp[i], :p)
      Z = deepcopy(getfield(S.resp[i], :z))
    elseif Y == MultiStageResp
      j = 0
      for k = 1:length(S.resp[i].stage)
        stg = S.resp[i].stage[k]
        if typeof(stg) in (PZResp, PZResp64)
          j = k
          break
        end
      end
      if j == 0
        @warn(string("Skipped channel ", i, " (", id, "): incompatible response Type"))
        continue
      else
        a0 = getfield(S.resp[i].stage[j], :a0)
        P = getfield(S.resp[i].stage[j], :p)
        Z = deepcopy(getfield(S.resp[i].stage[j], :z))
      end
    end

    write(io, 0x2a)
    write(io, 0x20)
    write(io, fill!(zeros(UInt8, 34), 0x2a))
    write(io, 0x0a)

    write(io, "* NETWORK   (KNETWK): ", id[1], 0x0a)
    write(io, "* STATION    (KSTNM): ", id[2], 0x0a)
    write(io, "* LOCATION   (KHOLE): ", isempty(id[3]) ? "  " : id[3], 0x0a)
    write(io, "* CHANNEL   (KCMPNM): ", id[4], 0x0a)

    write(io, "* CREATED           : ", created, 0x0a)
    write(io, "* START             : ", t_start, 0x0a)
    write(io, "* END               : ", t_end, 0x0a)
    write(io, "* DESCRIPTION       : ", S.name[i], 0x0a)
    loc = zeros(Float64, 6)
    if typeof(S.loc[i]) == GeoLoc
      for (j, f) in enumerate([:lat, :lon, :el, :dep, :inc, :az])
        loc[j] = getfield(S.loc[i], f)
      end
    end
    write(io, "* LATITUDE          : ", @sprintf("%0.6f", loc[1]), 0x0a)
    write(io, "* LONGITUDE         : ", @sprintf("%0.6f", loc[2]), 0x0a)
    write(io, "* ELEVATION         : ", string(loc[3]), 0x0a)
    write(io, "* DEPTH             : ", string(loc[4]), 0x0a)
    write(io, "* DIP               : ", string(loc[5]+90.0), 0x0a)
    write(io, "* AZIMUTH           : ", string(loc[6]), 0x0a)
    write(io, "* SAMPLE RATE       : ", string(S.fs[i]), 0x0a)

    for j in ("INPUT UNIT", "OUTPUT UNIT", "INSTTYPE", "INSTGAIN", "COMMENT")
      write(io, 0x2a, 0x20)
      write(io, rpad(j, 18))
      write(io, 0x3a, 0x20)
      v = get(S.misc[i], j, "")
      write(io, v)
      if j == "INSTGAIN" && v == ""
        write(io, "1.0E+00 (", S.units[i], ")")
      end
      write(io, 0x0a)
    end

    write(io, "* SENSITIVITY       : ", @sprintf("%12.6e", S.gain[i]), 0x20, 0x28, uppercase(S.units[i]), 0x29, 0x0a)
    NZ = length(Z)
    NP = length(P)
    write(io, "* A0                : ", @sprintf("%12.6e", a0), 0x0a)
    CONST = get(S.misc[i], "CONSTANT", string(a0*S.gain[i]))

    write(io, 0x2a)
    write(io, 0x20)
    write(io, fill!(zeros(UInt8, 34), 0x2a))
    write(io, 0x0a)

    # fix for units_in always being m
    if S.units[i] == "m/s"
      NZ += 1
      pushfirst!(Z, zero(ComplexF32))
    elseif S.units[i] == "m/s2"
      NZ += 2
      prepend!(Z, zeros(ComplexF32, 2))
    end
    write(io, "ZEROS\t", string(NZ), 0x0a)
    for i = 1:NZ
      write(io, 0x09, @sprintf("%+12.6e", real(Z[i])), 0x09, @sprintf("%+12.6e", imag(Z[i])), 0x09, 0x0a)
    end

    write(io, "POLES\t", string(NP), 0x0a)
    for i = 1:NP
      write(io, 0x09, @sprintf("%+12.6e", real(P[i])), 0x09, @sprintf("%+12.6e", imag(P[i])), 0x09, 0x0a)
    end

    write(io, "CONSTANT\t", CONST, 0x0a)
    write(io, 0x0a, 0x0a)
    fwrite_note!(S, i, "writesacpz", file, string(", chans=\"", i))
  end
  close(io)
  return nothing
end
writesacpz(fname::String, C::GphysChannel) = writesacpz(fname, SeisData(C), chans=1)
