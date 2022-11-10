function read_string_vec(io::IO, u::Array{UInt8,1})
  b = fastread(io)
  S = String[]
  if b == 0x00
    N = fastread(io, UInt64)
    p = pointer(u)
    L = fastread(io, UInt16, N)
    i = 0
    while i < N
      i = i + 1
      l = getindex(L, i)
      fast_unsafe_read(io, p, l)
      push!(S, unsafe_string(p, l))
    end
  end
  return S
end

function read_misc(io::IO, u::Array{UInt8,1})
  D = Dict{String,Any}()
  L = fastread(io, UInt64)
  if L != zero(Int64)
    n     = zero(Int64)
    dims  = Array{Int64, 1}(undef, 3)
    p     = pointer(u)
    K     = read_string_vec(io, u)
    for k in K
      t = fastread(io)
      T = code2typ(t)

      # String array
      if t == 0x81
        nd = fastread(io, Int64)
        checkbuf_strict!(dims, nd)
        fastread!(io, dims)
        if dims == [0]
          D[k] = String[]
        else
          S = String[]
          i = 0
          N = prod(dims)
          L = fastread(io, UInt16, N)
          while i < N
            i = i + 1
            l = getindex(L, i)
            fast_unsafe_read(io, p, l)
            push!(S, unsafe_string(p, l))
          end
          D[k] = reshape(S, dims...)
        end

      # Numeric or Char array
      elseif T <: AbstractArray
        nd = fastread(io, Int64)
        if nd == 1
          D[k] = read!(io, T(undef, fastread(io, Int64)))
        else
          checkbuf_strict!(dims, nd)
          fastread!(io, dims)
          D[k] = read!(io, T(undef, dims...))
        end

      # String
      elseif T == String
        n = fastread(io, UInt16)
        fast_unsafe_read(io, p, n)
        D[k] = unsafe_string(p, n)

      # Bits type
      elseif Type{T} <: FastReads
        D[k] = fastread(io, T)

      else
        D[k] = read(io, T)
      end
    end
  end
  return D
end

# ============================================================================
# Write functions
function write_string_vec(io::IO, v::Array{String,1})
  b = isempty(v)
  write(io, b)
  if b == false
    write(io, Int64(length(v)))
    for s in v
      write(io, UInt16(sizeof(s)))
    end
    for s in v
      write(io, s)
    end
  end
  return nothing
end

function write_misc(io::IO, D::Dict{String,Any})
  L = Int64(length(D))
  write(io, L)
  if L != zero(Int64)
    K = keys(D)
    write_string_vec(io, collect(K))
    for v in values(D)
      T = typeof(v)
      t = typ2code(T)
      write(io, t)

      # String array
      if t == 0x81
        dims = Int64.(size(v))
        write(io, Int64(length(dims)))
        for i in dims
          write(io, i)
        end
        if dims != (0,)
          for s in v
            write(io, UInt16(sizeof(s)))
          end
          for s in v
            write(io, s)
          end
        end

      elseif T <: AbstractArray
        dims = Int64.(size(v))
        write(io, Int64(length(dims)))
        for i in dims
          write(io, i)
        end
        write(io, v)

      elseif T == String
        write(io, UInt16(sizeof(v)))
        write(io, v)

      elseif T <: Union{Char, AbstractFloat, Complex, Integer}
        write(io, v)
      end
    end
  end
  return nothing
end
