export translate_resp!, translate_resp, remove_resp!, remove_resp

# =====================================================================

@doc """
    translate_resp!(S, resp_new[, chans=CC, wl=γ])
    translate_resp(S, resp_new[, chans=CC, wl=γ])

Translate the instrument response of seismic data channels `CC` in `S` to
`resp_new`. Replaces field `:resp` with `resp_new` for all affected channels.

    remove_resp!(S, chans=CC, wl=γ])
    remove_resp(S, chans=CC, wl=γ])

Remove (flatten to DC) the instrument response of seismic data channels `cha`
in `S`. Replaces field `:resp` with the appropriate (all-pass) response.

    translate_resp!(Ch, resp_new[, wl=γ])
    translate_resp(Ch, resp_new[, wl=γ])

Translate the instrument response of seismic data in SeisChannel object `Ch` to
`resp_new`. Replaces field `:resp` with `resp_new`.

    remove_resp!(Ch[, chans=CC, wl=γ])
    remove_resp(Ch[, chans=CC, wl=γ])

Remove (flatten to DC) the instrument response of seismic data in `Ch`.
Replaces field `:resp` with the appropriate (all-pass) response.

### Keywords
* **chans=CC** restricts response translation to channel(s) `CC`. By default, all seismic data channels have responses translated to `resp_new`.
* **wl=γ** sets the waterlevel to γ (default: `γ` = eps(Float32) ≈ ~1f-7)

### Interaction with the :resp field
`translate_resp` and `remove_resp` only work on a channel `i` that satisfies `S.resp[i] <: PZResp, PZResp64, MultiStageResp`. In the last case, `S.resp[i].stage[1]` must be a PZResp or PZResp64, only the first stage of the response is changed, and the stage gain is ignored; instead, the sensitivity `S.resp[i].stage[1].a0` is used.

### Poles and zeros should be rad/s
Always check when loading from an unsupported data format. Responses read from station XML are corrected to rad/s automatically (most use rad/s); responses read from a SACPZ or SEED RESP file already use rad/s.

!!! warning

    Response translation doesn't guarantee causality; if this is a problem, detrend and taper first!
""" translate_resp!
function translate_resp!(S::GphysData,
                         resp_new::Union{PZResp, PZResp64};
                         chans::ChanSpec=Int64[],
                         wl::Float32=eps(Float32))

  # first ensure that there is something to do
  chans = mkchans(chans, S, keepirr=false)
  @inbounds for i in chans
    if S.resp[i] != resp_new
      break
    end
    if i == last(chans)
      @info(string(timestamp(), ": nothing done (no valid responses to translate)."))
      return nothing
    end
  end

  # remove channels with inappropriate response types
  k = Int64[]
  for (n,i) in enumerate(chans)
    if (typeof(S.resp[i]) <: Union{PZResp, PZResp64, MultiStageResp}) == false
      push!(k,n)
    end
  end
  deleteat!(chans, k)

  # initialize complex "work" vectors to the largest size we need
  Nx      = nx_max(S, chans)
  (Nx == 0) && return
  N2      = nextpow(2, Nx)
  Xw      = Array{Complex{Float32},1}(undef, N2)
  ff_old  = Array{Complex{Float32},1}(undef, N2)
  ff_new  = Array{Complex{Float32},1}(undef, N2)
  f       = Array{Float32,1}(undef, N2)

  GRPS = get_unique(S, ["fs", "resp", "units"], chans)
  for grp in GRPS

    # get fs, resp
    j = grp[1]
    RT = typeof(getindex(getfield(S, :resp), j))

    # no translating instrument responses unless we're dealing with seismometers
    codes = inst_codes(S)
    kill = falses(length(grp))
    for i = 1:length(grp)
      if codes[i] in seis_inst_codes
        continue
      else
        kill[i] = true
      end
    end
    deleteat!(grp, kill)
    isempty(grp) && continue
    j = grp[1]
    uu = lowercase(S.units[j])

    # onward
    resp_old = RT == MultiStageResp ? deepcopy(S.resp[j].stage[1]) : deepcopy(S.resp[j])
    fs = Float32(S.fs[j])

    if resp_old != resp_new

      # we'll need this for logging
      resp_str = string("processing ¦ translate_resp!(S, wl = ", wl, ", resp_old = ", typeof(resp_old),
        "(a0=", resp_old.a0, ", f0=", resp_old.f0, ", p=", resp_old.p, ", z=", resp_old.z,
        ") ¦ instrument response translation")

      # for accelerometers, working *in* acceleration units, we check: are there any poles below the nyquist?
      if uu == "m/s2"
        P = resp_old.p
        k = trues(length(P))
        for (i,p) in enumerate(P)
          if abs(p)/pi ≤ fs # equivalent to abs(p)/2pi ≤ fn/2 which is the true condition
            k[i] = false
          end
        end
        deleteat!(P, k)

        # Most accelerometers have two complex zeros at the origin, but many XML resp files don't show it.
        if isempty(resp_old.z)
          resp_old.z = map(eltype(resp_old.z), [0.0 + 0.0im, 0.0 - 0.0im])
        end
      end

      # get views to segments from each target channel
      (L,X) = get_views(S, grp)

      # initialize Nx, N2, xre
      Nx = first(L)
      N2 = nextpow(2, Nx)
      xfl, xre = update_resp_vecs!(Xw, f, ff_old, ff_new, N2)
      update_resp!(f, ff_old, ff_new, N2, fs, resp_old, resp_new, wl)

      j = 0
      while j < length(L)
        j = j + 1
        if L[j] != Nx
          Nx = L[j]
          N2 = nextpow(2, Nx)
          xfl, xre = update_resp_vecs!(Xw, f, ff_old, ff_new, N2)
          update_resp!(f, ff_old, ff_new, N2, fs, resp_old, resp_new, wl)
        end

        # copy X[j] to Xw and compute FFT
        fill!(Xw, zero(Complex{Float32}))
        copyto!(Xw, 1, X[j], 1, Nx)
        fft!(Xw)
        broadcast!(*, Xw, Xw, ff_new)
        ifft!(Xw)
        copyto!(X[j], 1, xre, 1, Nx)
      end

      # post-processing: set resp and log to :notes
      for k in grp
        if RT == MultiStageResp
          S.resp[k].stage[1] = deepcopy(resp_new)
        else
          setindex!(S.resp, deepcopy(resp_new), k)
        end
        note!(S, k, resp_str)
      end
    end
  end
 return nothing
end

@doc (@doc translate_resp!)
function translate_resp( S::GphysData,
                    resp_new::Union{PZResp, PZResp64};
                    chans::ChanSpec=Int64[],
                    wl::Float32=eps(Float32))

  U = deepcopy(S)
  translate_resp!(U, resp_new, chans=chans, wl=wl)
  return U
end

function translate_resp!(C::GphysChannel,
                    resp_new::Union{PZResp, PZResp64};
                    wl::Float32=eps(Float32))

  # first ensure that there is something to do
  uu = lowercase(C.units)
  fs = Float32(C.fs)
  if any([C.resp == resp_new,
          uu in ("m/s", "m/s2", "m") == false,
          fs ≤ 0.0f0,
          inst_code(C) in seis_inst_codes == false])
    @info(string(timestamp(), ": nothing done (no valid responses to translate)."))
    return nothing
  end

  # initialize complex "work" vectors to the largest size we need
  Nx      = nx_max(C)
  (Nx == 0) && return
  N2      = nextpow(2, Nx)
  Xw      = zeros(Complex{Float32}, N2)
  ff_old  = Array{Complex{Float32},1}(undef, N2)
  ff_new  = Array{Complex{Float32},1}(undef, N2)
  f       = Array{Float32,1}(undef, N2)

  # for accelerometers, working *in* acceleration units, we check: are there any poles below the nyquist?
  if uu == "m/s2"
    P = C.resp.p
    k = trues(length(P))
    for (i,p) in enumerate(P)
      if abs(p)/pi ≤ fs # equivalent to abs(p)/2pi ≤ fn/2 which is the true condition
        k[i] = false
      end
    end
    deleteat!(P, k)

    # Most accelerometers have two complex zeros at the origin, but many XML resp files don't show it.
    if isempty(C.resp.z)
      C.resp.z = map(eltype(C.resp.z), [0.0 + 0.0im, 0.0 - 0.0im])
    end
  end

  # Get views
  if size(C.t,1) == 2
    xfl, xre = update_resp_vecs!(Xw, f, ff_old, ff_new, N2)
    update_resp!(f, ff_old, ff_new, N2, fs, C.resp, resp_new, wl)

    # copy X[j] to Xw and compute FFT
    copyto!(Xw, 1, C.x, 1, Nx)
    fft!(Xw)
    broadcast!(*, Xw, Xw, ff_new)
    ifft!(Xw)
    copyto!(C.x, 1, xre, 1, Nx)
  else
    (L,X) = get_views(C)
    xfl = reinterpret(Float32, Xw)
    xre = view(xfl, 1:2:2*N2-1)
    update_resp!(f, ff_old, ff_new, N2, fs, C.resp, resp_new, wl)

    j = 0
    while j < length(L)
      j = j + 1

      if L[j] != Nx
        Nx = L[j]
        N2 = nextpow(2, Nx)
        xfl, xre = update_resp_vecs!(Xw, f, ff_old, ff_new, N2)
        update_resp!(f, ff_old, ff_new, N2, fs, C.resp, resp_new, wl)
      end

      if j > 1
        fill!(Xw, zero(Complex{Float32}))
      end

      copyto!(Xw, 1, X[j], 1, Nx)
      fft!(Xw)
      broadcast!(*, Xw, Xw, ff_new)
      ifft!(Xw)
      copyto!(X[j], 1, xre, 1, Nx)
    end
  end
  resp_str = string("processing ¦ translate_resp!(S, wl = ", wl, ", resp_old = ", typeof(C.resp),
    "(a0=", C.resp.a0, ", f0=", C.resp.f0, ", p=", C.resp.p, ", z=", C.resp.z,
    ") ¦ instrument response translation")
  C.resp = deepcopy(resp_new)
  note!(C, resp_str)
  return nothing
end

function translate_resp(C::GphysChannel,
                        resp_new::Union{PZResp, PZResp64};
                        wl::Float32=eps(Float32))

  U = deepcopy(C)
  translate_resp!(U, resp_new, wl=wl)
  return U
end

@doc (@doc translate_resp!)
remove_resp!(S::GphysData;
             chans::ChanSpec=Int64[],
             wl::Float32=eps(Float32)) = translate_resp!(S, flat_resp, chans=chans, wl=wl)

@doc (@doc translate_resp!)
remove_resp(S::GphysData;
            chans::ChanSpec=Int64[],
            wl::Float32=eps(Float32)) = translate_resp(S, flat_resp, chans=chans, wl=wl)

remove_resp!(Ch::GphysChannel;
             wl::Float32=eps(Float32)) = translate_resp!(Ch, flat_resp, wl=wl)

remove_resp(Ch::GphysChannel;
            wl::Float32=eps(Float32)) = translate_resp(Ch, flat_resp, wl=wl)
