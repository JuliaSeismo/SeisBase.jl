export seedlink, seedlink!, sl_info, has_sta, has_stream

# ========================================================================
# Utility functions not for export
function timed_wait!(conn::TCPSocket, to::Real, b::Bool)
  n = bytesavailable(conn)
  m = copy(n)
  ts = time()
  te = copy(ts)
  while (te-ts) < to && m == n
    sleep(1.0)
    b = eof(conn)
    te = time()
    n = bytesavailable(conn)
  end
  return nothing
end

function sl_cparse(C::ChanOpts)
  if isa(C, String)
    sta,pat = parse_sl(parse_chstr(C, ',', false, false))
  elseif ndims(C) == 1
    sta, pat = parse_sl(parse_charr(C, '.', false))
  else
    sta, pat = parse_sl(C)
  end
  return sta, pat
end

# This was deprecated in Julia 0.6; hard-copied here, still works
function sync_add(r::Task)
    spawns = get(task_local_storage(), :SPAWNS, ())
    if spawns != ()
        push!(spawns[1], r)
        tls_r = Base.get_task_tls(r)
        tls_r[:SUPPRESS_EXCEPTION_PRINTING] = true
    end
    r
end

function get_sl_ver(vline::String)
  # Versioning will break if SeedLink switches to VV.PPP.NNN format
  ver = 0.0
  vinfo = split(vline)
  for i in vinfo
      if startswith(i, 'v')
          try
              ver = Meta.parse(i[2:end])
          catch
              continue
          end
      end
  end
  return ver
end

function check_sta_exists(sta::Array{String,1}, xstr::String)

  xstreams = get_elements_by_tagname(root(parse_string(xstr)), "station")
  xid = join([join([attribute(xstreams[i], "network"),
                    attribute(xstreams[i], "name")],'.') for i=1:length(xstreams)], ' ')
  N = length(sta)
  x = falses(N)
  for i = 1:N
    id = split(sta[i], '.', keepempty=true)
    sid = join(id[1:2],'.')
    if occursin(sid, xid)
      x[i] = true
    end
  end
  return x
end

function check_stream_exists(S::Array{String,1}, xstr::String;
                           gap::Real  = KW.SL.gap,
                            to::Int64 = KW.to
                             )

  a = ["seedname","location","type"]
  N = length(S)
  x = falses(N)

  xstreams = get_elements_by_tagname(root(parse_string(xstr)), "station")
  xid = String[join([attribute(xstreams[i], "network"),
                     attribute(xstreams[i], "name")],'.') for i=1:length(xstreams)]
  for i = 1:N
    # Assumes the combination of network name and station name is unique
    id = split(S[i], '.', keepempty=true)
    sid = join(id[1:2], '.')
    K = findid(sid, xid)
    if K > 0
      t = Inf

      # Syntax requires that contains(string, "") returns true for any string
      p = ["","",""]
      for j = 3:length(id)
        p[j-2] = replace(id[j], "?" => "")
      end
      R = get_elements_by_tagname(xstreams[K], "stream")
      if !isempty(R)
        for j = 1:length(R)
          if prod([occursin(p[i], attribute(R[j], a[i])) for i=1:length(p)]) == true
            te = replace(attribute(R[j], "end_time"), " " => "T")
            t = min(t, time()-d2u(Dates.DateTime(te)))
          end
        end
      end

      # Treat station as "present" if there's a match
      if minimum(t) < gap
        x[i] = true
      end
    end
  end
  return x
end
# ========================================================================


"""
    info_xml = sl_info(level=LEVEL::String; u=URL::String, port=PORT::Integer)

Retrieve XML output of SeedLink command "INFO `LEVEL`" from server `URL:PORT`.
Returns formatted XML. `LEVEL` must be one of "ID", "CAPABILITIES",
"STATIONS", "STREAMS", "GAPS", "CONNECTIONS", "ALL".

"""
function sl_info(level::String;                           # verbosity
                    to::Int64   = KW.to,                  # timeout [s]
                     u::String  = KW.SL.u,                # url
                   port::Int64  = KW.SL.port              # port #
                 )
  conn = connect(TCPSocket(), u, port)
  write(conn, string("INFO ", level, "\r"))
  b = false
  timed_wait!(conn, to, b)
  buf = BUF.buf
  if (bytesavailable(conn) == 0) || (isopen(conn) == false)
    @warn(("Connection sent no data after ", to, " seconds; closing."))
    (isopen(conn)) && close(conn)
    x = Array{UInt8, 1}(undef, 0)
  else
    eflg = false
    x = Array{UInt8, 1}(undef, 1048576)
    i = 0x0000000000000001
    c = 0x01
    k = 0x0000
    while true
      N = conn.buffer.size
      checkbuf!(buf, N)

      # buffer to :buf from conn
      unsafe_read(conn.buffer, pointer(buf), N)
      conn.buffer.ptr = 1
      conn.buffer.size = 0

      # copy to x after filtering out 0x00 and first 64 vals of each 520-byte packet
      j = 0x0000000000000000
      while j < N
        j += 0x0000000000000001
        k += 0x0001
        if i + 0x00000000000001c8 > length(x)
          resize!(x, length(x) + 524288)
        end
        if k >= 0x0040
          c = getindex(buf, j)
          if c != 0x00
            setindex!(x, c, i)
            i += 0x0000000000000001
          end
        end
        if k == 0x0208
          if buf[j] == 0x00
            eflg = true
            break
          end
          k = 0x0000
        end
      end
      eflg && break
      timed_wait!(conn, to, b)
    end
    close(conn)
    deleteat!(x, i:length(x))
  end
  resize!(buf, 65535)
  return String(x)
end

"""
    has_sta(sta[, u=url, port=N])

Check that streams exist at `url` for stations `sta`, formatted
NET.STA. Use "?" to match any single character. Returns `true` for
stations that exist. `sta` can also be the name of a valid config
file or a 1d string array.

Returns a BitArray with one value per entry in `sta.`

SeedLink keywords: gap, port
"""
function has_sta(C::String;
                 u::String  = KW.SL.u,    # url base, no "http://""
              port::Int64   = KW.SL.port  # port number
  )

  sta, pat = parse_sl(parse_chstr(C, ',', false, false))

  # This exists to convert SeedLink syntax (SSS NN) to FDSN (NN.SSS)
  for i = 1:length(sta)
    s = split(sta[i], ' ')
    sta[i] = join([s[2], s[1]], '.')
  end
  # This exists to convert SeedLink syntax (SSS NN) to FDSN (NN.SSS)

  return check_sta_exists(sta, sl_info("STATIONS", u=u, port=port))
end

has_sta( sta::Array{String,1};
           u::String  = KW.SL.u,    # url base, no "http://""
        port::Int64   = KW.SL.port  # port number
  ) = check_sta_exists(sta, sl_info("STATIONS", u=u, port=port))

has_sta( sta::Array{String,2};
           u::String  = KW.SL.u,    # url base, no "http://""
        port::Int64   = KW.SL.port  # port number
  ) = check_sta_exists([join(sta[i,:], '.') for i=1:size(sta,1)],
        sl_info("STATIONS", u=u, port=port))

"""
    has_stream(cha[, u=url, port=N, gap=G)

Check that streams with recent data exist at url `u` for channel spec
`cha`, formatted NET.STA.LOC.CHA.DFLAG, e.g. "UW.TDH..EHZ.D,
CC.HOOD..BH?.E". Use "?" to match any single character. Returns `true`
for streams with recent data.

`cha` can also be the name of a valid config file.

    has_stream(sta::Array{String,1}, sel::Array{String,1}, u::String, port=N::Int, gap=G::Real)

If two arrays are passed to has_stream, the first should be
formatted as SeedLink STATION patterns (formated "SSSSS NN", e.g.
["TDH UW", "VALT CC"]); the second be an array of SeedLink selector
patterns (formatted LLCCC.D, e.g. ["??EHZ.D", "??BH?.?"]).

SeedLink keywords: gap, port
"""
function has_stream(sta::Array{String,1}, pat::Array{String,1};
                      u::String  = KW.SL.u,       # url base, no "http://"
                     to::Int64   = KW.to,         # timeout[s]
                   port::Int64   = KW.SL.port,    # port #
                    gap::Real    = KW.SL.gap,     # max gap [s]
                      d::Char    = ' '            # delimiter
                      )

  L = length(sta)
  cha = Array{String,1}(undef, L)
  for i = 1:L
    s = split(sta[i], d)
    c = split(pat[i], '.')
    cha[i] = join([s[1], s[2], c[1][1:2], c[1][3:5], c[2]], '.')
  end
  return check_stream_exists(cha, sl_info("STREAMS", u=u, port=port), gap=gap, to=to)
end

has_stream( sta::String;
              u::String   = KW.SL.u,     # url base, no "http://"
             to::Int64    = KW.to,       # timeout [s]
           port::Int64    = KW.SL.port,  # port number
            gap::Real     = KW.SL.gap,   # max. gap [s]
              d::Char     = ','
) = check_stream_exists(String.(split(sta, d)), sl_info("STREAMS", u=u, port=port), gap=gap, to=to)

has_stream( sta::Array{String,1};
              u::String   = KW.SL.u,     # url base, no "http://"
             to::Int64    = KW.to,       # timeout [s]
           port::Int64    = KW.SL.port,  # port number
            gap::Real     = KW.SL.gap    # max. gap [s]
  ) = check_stream_exists(sta, sl_info("STREAMS", u=u, port=port), gap=gap, to=to)

has_stream( sta::Array{String,2};
              u::String   = KW.SL.u,     # url base, no "http://"
             to::Int64    = KW.to,       # timeout [s]
           port::Int64    = KW.SL.port,  # port number
            gap::Real     = KW.SL.gap    # max. gap [s]
  ) = check_stream_exists([join(sta[i,:], '.') for i=1:size(sta,1)],
        sl_info("STREAMS", u=u, port=port), gap=gap, to=to)

@doc """
    seedlink!(S, mode, chans)
    S = seedlink(mode, chans)

Begin acquiring seedlink data to SeisData structure `S` using mode `mode`. New channels are added to `S` automatically based on `chans`. Connections are added to `S.c`. When finished, close connection manually with `close(S.c[n])` where n is connection #.

This function is fully described in the official documentation at https://SeisBase.readthedocs.io/ in subsection **SeedLink**.

Keywords: gap, kai, port, refresh, s, t, u, v, w, x_on_err

See also: `get_data!`
""" seedlink!
function seedlink!(S::SeisData, mode::String, sta::Array{String,1}, patts::Array{String,1};
                 gap::Real      = KW.SL.gap,        # max gap of live channels
                 kai::Real      = KW.SL.kai,        # keepalive interval [s]
                 seq::String    = "",               # starting sequence number
                port::Int64     = KW.SL.port,       # port number
             refresh::Real      = KW.SL.refresh,    # s between read attempts
                   u::String    = KW.SL.u,          # URL base, no "http://"
                   s::TimeSpec  = 0,                # start time
                   t::TimeSpec  = 300,              # end (termination) time
                   v::Integer   = KW.v,             # vervosity
                   w::Bool      = KW.w,             # write directly to disk?
            x_on_err::Bool      = KW.SL.x_on_err    # exit on error?
                  )


  # ==========================================================================
  # init, warnings, sanity checks
  Ns = size(sta,1)
  setfield!(BUF, :swap, false)

  # Refresh interval
  refresh = maximum([refresh, eps()])
  refresh < 10 && @warn(string("refresh = ", refresh, " < 10 s; Julia may freeze if no packets arrive between consecutive read attempts."))

  # keepalive interval
  if kai < 240
    @warn("KeepAlive interval < 240s violates IRIS netiquette guidelines. YOU are responsible if you get banned for hammering.")
  end

  # Source for logging
  src = join([u,port],':')

  # ==========================================================================
  # connection and server info retrieval
  push!(S.c, connect(TCPSocket(),u,port))
  q = length(S.c)

  # version, server info
  write(S.c[q],"HELLO\r")
  vline = readline(S.c[q])
  sline = readline(S.c[q])
  ver = get_sl_ver(vline)

  (v > 1) && println("Version = ", ver)
  (v > 1) && println("Server = ", strip(sline,['\r','\n']))
  # ==========================================================================

  # ==========================================================================
  # handshaking

  # create mode string and filename for -w
  (d0,d1) = parsetimewin(s,t)
  s = join(split(d0,r"[\-T\:\.]")[1:6],',')
  t = join(split(d1,r"[\-T\:\.]")[1:6],',')
  if mode in ["TIME", "FETCH"]
    if mode == "TIME"
      m_str = string("TIME ", s, " ", t, "\r")
    else
      m_str = string("FETCH", isempty(seq) ? "" : string(" SL", seq, " ", s), "\r")
    end
  else
    # m_str = "DATA\r"
    m_str = string("DATA", isempty(seq) ? "" : string(" SL", seq, " ", s), "\r")
  end

  if w
    fname = hashfname([join(sta,','), join(patts,','), s, t, m_str], "mseed")
    (v > 0) && println(string("Raw packets will be written to file ", fname, " in dir ", realpath(pwd())))
    fid = open(fname, "w")
  end

  # pass strings to server; check responses carefully
  for i = 1:Ns
    # pattern selector
    sel_str = string("SELECT ", patts[i], "\r")
    (v > 1) && println("Sending: ", sel_str)
    write(S.c[q], sel_str)
    sel_resp = readline(S.c[q])
    (v > 1) && println("Response: ", sel_resp)
    if occursin("ERROR", sel_resp)
      if x_on_err
        write(S.c[q], "BYE\r")
        close(S.c[q])
        deleteat!(S.c, q)
        error(string("Error in select string ", patts[i], "; connection closed and deleted, exit with error."))
      else
        @warn(string("Error in select string ", patts[i], "; previous selector, ", i==1 ? "*" : patts[i-1], " used)."))
      end
    end

    # station selector
    sta_str = string("STATION ", sta[i], "\r")
    (v > 1) && println("Sending: ", sta_str)
    write(S.c[q], sta_str)
    sta_resp = readline(S.c[q])
    (v > 1) && println("Response: ", sta_resp)
    if occursin("ERROR", sta_resp)
      if x_on_err
        write(S.c[q], "BYE\r")
        close(S.c[q])
        deleteat!(S.c, q)
        error(string("Error in station string ", sta[i], "; connection closed and deleted, exit with error."))
      else
        @warn(string("Error in station string ", sta[i], " (station excluded)."))
      end
    end

    # mode
    (v > 1) && println("Sending: ", m_str)
    write(S.c[q], m_str)
    m_resp = readline(S.c[q])
    (v > 1) && println("Response: ", m_resp)
  end
  write(S.c[q],"END\r")
  # ==========================================================================

  # ==========================================================================
  # data transfer
  k = @task begin
    j = 0
    while true
      if !isopen(S.c[q])
          (v > 0) && @info(string(timestamp(), ": SeedLink connection closed."))
        w && close(fid)
        break
      else

        #= use of rand() makes it almost impossible for multiple SeedLink
        connections to result in one sleeping indefinitely. =#
        τ = ceil(Int, refresh*(0.8 + 0.2*rand()))
        sleep(τ)
        eof(S.c[q])
        N = div(bytesavailable(S.c[q]), 520)
        if N > 0
          #=
            This syntax consumes 2x memory but is "safe" in that a partially
            downloaded packet will be left in S.c[q], rather than causing the
            SEED parser to throw errors and/or hang the REPL. (From experience,
            it is NOT guaranteed that full packets are transmitted)
          =#
          buf = read(S.c[q], 520*N)
          io = IOBuffer(buf)
          if w
            write(fid, copy(io))
          end
          track_on!(S)
          (v > 1) && printstyled(stdout, now(), ": Processing packets ", color=:green)
          while !eof(io)
            pkt_id = String(read(io, 8))
            (v > 1) && @printf(stdout, "%s, ", pkt_id)
            parserec!(S, BUF, io, 65535, 65535, true, v)
          end
          (v > 1) && @printf(stdout, "\b\b...done current packet dump.\n")
          seed_cleanup!(S, BUF)
          k = track_off!(S)

          # ===========================================================
          # Source logging
          for i in 1:length(k)
            if k[i]
              if haskey(S.misc[i], "SL_logged")
                # Check that :src is still SeedLink
                (S.src[i] == u) || (S.src[i] = u)
              else
                id = split_id(S.id[i])
                if isempty(id[3])
                  id[3] = "??"
                end
                # this can be sent directly to a SeedLink server later
                sl_str = string("commands ¦ SELECT ", id[3], id[4], ".D\r\n",
                                "STATION ", id[2], " ", id[1], "\r\n",
                                m_str, "\n")

                S.src[i] = string(u)                    # Set :src to SeedLink
                note!(S, i, string( "+source ¦ ", u ))  # Log source to :notes
                note!(S, i, sl_str)                     # Log commands to :notes
                S.misc[i]["SL_logged"] = true           # Flag i as SL_logged
              end
            end
            # ===========================================================
          end
        end

        # SeedLink (non-standard) keep-alive gets sent every kai seconds
        j += τ
        if j ≥ kai
          # Secondary "isopen" loop avoids possible error from race condition
          # maybe a Julia bug? First encountered 2017-01-03
          if isopen(S.c[q])
            j -= kai
            write(S.c[q],"INFO ID\r")
          end
        end

      end
    end
  end
  sync_add(k)
  Base.enq_work(k)
  # ========================================================================

  return S
end
function seedlink!(S::SeisData, mode::String, C::ChanOpts;
                 gap::Real      = KW.SL.gap,        # max gap of live channels
                 kai::Real      = KW.SL.kai,        # keepalive interval [s]
                 seq::String    = "",               # starting sequence number
                port::Int64     = KW.SL.port,       # port number
             refresh::Real      = KW.SL.refresh,    # s between read attempts
                   u::String    = KW.SL.u,          # URL base, no "http://"
                   s::TimeSpec  = 0,                # start time
                   t::TimeSpec  = 300,              # end (termination) time
                   v::Integer   = KW.v,             # vervosity
                   w::Bool      = KW.w,             # write directly to disk?
            x_on_err::Bool      = KW.SL.x_on_err    # exit on error?
                  )

  sta, pat = sl_cparse(C)
  seedlink!(S, mode, sta, pat, u=u, port=port, refresh=refresh, kai=kai, seq=seq, s=s, t=t, x_on_err=x_on_err, v=v, w=w)
  return S
end

@doc (@doc seedlink!)
function seedlink(mode::String, sta::Array{String,1}, pat::Array{String,1};
                   gap::Real      = KW.SL.gap,        # max gap of live channels
                   kai::Real      = KW.SL.kai,        # keepalive interval [s]
                   seq::String    = "",               # starting sequence number
                  port::Int64     = KW.SL.port,       # port number
               refresh::Real      = KW.SL.refresh,    # s between read attempts
                     u::String    = KW.SL.u,          # URL base, no "http://"
                     s::TimeSpec  = 0,                # start time
                     t::TimeSpec  = 300,              # end (termination) time
                     v::Integer   = KW.v,             # vervosity
                     w::Bool      = KW.w,             # write directly to disk?
              x_on_err::Bool      = KW.SL.x_on_err    # exit on error?
                    )

  S = SeisData()
  seedlink!(S, mode, sta, pat, u=u, port=port, refresh=refresh, kai=kai, seq=seq, s=s, t=t, x_on_err=x_on_err, v=v, w=w)
  return S
end

function seedlink(mode::String, C::ChanOpts;
                   gap::Real      = KW.SL.gap,        # max gap of live channels
                   kai::Real      = KW.SL.kai,        # keepalive interval [s]
                   seq::String    = "",               # starting sequence number
                  port::Int64     = KW.SL.port,       # port number
               refresh::Real      = KW.SL.refresh,    # s between read attempts
                     u::String    = KW.SL.u,          # URL base, no "http://"
                     s::TimeSpec  = 0,                # start time
                     t::TimeSpec  = 300,              # end (termination) time
                     v::Integer   = KW.v,             # vervosity
                     w::Bool      = KW.w,             # write directly to disk?
              x_on_err::Bool      = KW.SL.x_on_err    # exit on error?
                    )

  S = SeisData()
  sta, pat = sl_cparse(C)
  seedlink!(S, mode, sta, pat, u=u, port=port, refresh=refresh, kai=kai, seq=seq, s=s, t=t, x_on_err=x_on_err, v=v, w=w)
  return S
end
