# low-memory way of accessing data by segment
function get_views(S::GphysData, inds::Array{Int64,1})
  L = Array{Int64,1}(undef,0)
  X = Array{SubArray,1}(undef,0)
  for i in inds
    n_seg = size(S.t[i],1)-1
    for k = 1:n_seg
      si = S.t[i][k,1]
      ei = S.t[i][k+1,1] - (k == n_seg ? 0 : 1)
      push!(X, view(S.x[i], si:ei))
      lx = ei-si+1
      push!(L, lx)
    end
  end
  ii = sortperm(L, rev=true)
  X = X[ii]
  L = L[ii]
  return L,X
end

function get_views(C::GphysChannel)
  L = Array{Int64,1}(undef,0)
  X = Array{SubArray,1}(undef,0)
  n_seg = size(C.t,1)-1
  for k = 1:n_seg
    si = C.t[k,1]
    ei = C.t[k+1,1] - (k == n_seg ? 0 : 1)
    push!(X, view(C.x, si:ei))
    lx = ei-si+1
    push!(L, lx)
  end
  ii = sortperm(L, rev=true)
  X = X[ii]
  L = L[ii]
  return L,X
end
