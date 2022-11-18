export env!, env

"""
    env!(S::GphysData[, chans=CC, v=V])
    env(S::GphysData)

Compute the envelope of channel data in S. Only affects regularly-sampled channels.

In-place conversion of S.x[i] ==> Env(S.x[i]) (≡ |H(S.x[i])|, where H denotes
the Hilbert transform).

### Keywords
* chans=CC: only process channels in CC (with fs > 0.0).
* v=V: verbosity.
"""
function env!(S::GphysData;
  chans::ChanSpec=Int64[],
  v::Integer=KW.v)

  # preprocess data channels
  chans = mkchans(chans, S, keepirr=false)

  proc_str = string("env!(S, chans=", chans, ")")

  # Get groups
  GRPS = get_unique(S, ["eltype"], chans)

  # Initialize Y
  Nx = nx_max(S, chans)
  (Nx == 0) && return
  Y = Array{Float64,1}(undef, 2*max(Nx, 128))

  # Arrays to hold data and windows
  @inbounds for grp in GRPS
    c = grp[1]
    T = eltype(S.x[c])
    R = reinterpret(Complex{T}, Y)

    # Get views and window lengths of each segment
    c2 = T(2)
    (L, X) = get_views(S, grp)
    nL = length(L)
    nx = L[1]

    n2 = div(nx, 2)
    H = view(R, 1:nx)
    v1 = view(R, 1:n2 + 1)
    v2 = view(R, 2:n2 + (isodd(nx) ? 1 : 0))
    v3 = view(R, n2+1:nx)
    P = plan_rfft(X[1])
    nx_last = nx
    np = 0

    for i = 1:nL
      nx = L[i]
      x = X[i]

      # determine whether to update P, YS
      too_short = false
      # update P, nx, YS
      if nx < 128 || nx != nx_last
        # very short segments
        if nx < 128
          y = zeros(eltype(x), 128)
          copyto!(y, 1, X[i], 1, nx)
          X₀ = y
          nx₀ = nx
          x = view(y, :)
          too_short = true
          nx = length(x)
        end
        P = plan_rfft(x)
        n2 = div(nx, 2)
        H = view(R, 1:nx)
        v1 = view(R, 1:n2 + 1)
        v2 = view(R, 2:n2 + (isodd(nx) ? 1 : 0))
        v3 = view(R, n2+1:nx)
      end

      #  Compute envelope → adapted from DSP.hilbert for recycled H
      fill!(v3, zero(Complex{T}))
      mul!(v1, P, x)
      broadcast!(*, v2, v2, c2)
      ifft!(H)

      # overwrite x
      if too_short
        copyto!(X[i], 1, x, 1, nx₀)
      else
        broadcast!(abs, x, H)
      end

      # update nx_last
      nx_last = nx

    end
    # log processing to :notes
    proc_note!(S, grp, proc_str, "replaced :x with abs(H(:x))")
  end
  return nothing
end

function env!(C::GphysChannel;
  v::Integer=KW.v
  )

  C.fs == 0.0 && return

  # Arrays to hold data and windows
  if size(C.t, 1) == 2
    C.x .= abs.(DSP.hilbert(C.x))
  else
    # Initialize R
    T = eltype(C.x)
    Nx = nx_max(C)
    (Nx == 0) && return
    R = Array{Complex{T}, 1}(undef, max(Nx, 128))

    # Get views and window lengths of each segment
    c2 = T(2)
    (L, X) = get_views(C)
    nL = length(L)
    nx = L[1]
    n2 = div(nx, 2)
    H = view(R, 1:nx)
    v1 = view(R, 1:n2 + 1)
    v2 = view(R, 2:n2 + (isodd(nx) ? 1 : 0))
    v3 = view(R, n2+1:nx)
    P = plan_rfft(X[1])
    nx_last = nx
    np = 0

    for i = 1:nL
      nx = L[i]
      x = X[i]

      # determine whether to update P, YS
      too_short = false
      # update P, nx, YS
      if nx < 128 || nx != nx_last
        # very short segments
        if nx < 128
          y = copyto!(zeros(eltype(x), 128), x)
          X₀ = y
          nx₀ = nx
          nx = 128
          x = view(y, :)
          too_short = true
        end
        P = plan_rfft(x)
        n2 = div(nx, 2)
        H = view(R, 1:nx)
        v1 = view(R, 1:n2 + 1)
        v2 = view(R, 2:n2 + (isodd(nx) ? 1 : 0))
        v3 = view(R, n2+1:nx)
      end

      #  Compute envelope → adapted from DSP.hilbert for recycled H
      fill!(v3, zero(Complex{T}))
      mul!(v1, P, x)
      broadcast!(*, v2, v2, c2)
      ifft!(H)

      # overwrite x
      if too_short
        copyto!(X[i], 1, x, 1, nx₀)
      else
        broadcast!(abs, x, H)
      end

      # update nx_last
      nx_last = nx
    end
  end

  # log processing to :notes
  proc_note!(C, "env!(C)", "replaced :x with abs(H(:x))")
  return nothing
end

@doc (@doc env!)
function env(S::GphysData;
  chans::ChanSpec=Int64[],
  v::Integer=KW.v
  )

  U = deepcopy(S)
  env!(U, chans=chans, v=v)
  return U
end

function env(C::GphysChannel;
  v::Integer=KW.v
  )

  U = deepcopy(C)
  env!(U, v=v)
  return U
end
