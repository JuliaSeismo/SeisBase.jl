export note!, clear_notes!

# ============================================================================
# Annotation

# Adding a string to SeisData writes a note; if the string mentions a channel
# name or ID, the note is restricted to the given channels(s), else it's
# added to all channels
@doc """
    note!(S::SeisData, i::Int64, s::String)

Append `s` to channel `i` of `S` and time stamp.

    note!(S::SeisData, id::String, s::String)

As above for the first channel in `S` whose id is an exact match to `id`.

  note!(S::SeisData, s::String)

Append `s` to `S.notes` and time stamp. If `txt` contains a channel name or ID, only the channel mentioned is annotated; otherwise, all channels are annotated.

See also: `clear_notes!`, `show_processing`, `show_src`, `show_writes`
""" note!
note!(S::T, i::Int64, s::String) where {T<:GphysData} = push!(S.notes[i], tnote(s))

function note!(S::GphysData, s::String)
    J = [occursin(i, s) for i in S.name]
    K = [occursin(i, s) for i in S.id]
    j = findall(max.(J,K) .== true)
  if !isempty(j)
    [push!(S.notes[i], tnote(s)) for i in j]
  else
    tn = tnote(s)
    for i = 1:S.n
      push!(S.notes[i], tn)
    end
  end
  return nothing
end

function note!(S::GphysData, id::String, s::String)
  i = findid(id, S)
  (i == 0) && error(string("id = ", id, " not found in S!"))
  push!(S.notes[i], tnote(s))
  return nothing
end

function note!(S::GphysData, chans::Union{UnitRange,Array{Int64,1}}, s::String)
  tn = tnote(s)
  for c in chans
    push!(S.notes[c], tn)
  end
  return nothing
end

note!(S::GphysChannel, s::String) = push!(S.notes, tnote(s))

# DND, these methods prevent memory reuse
"""
    clear_notes!(U::Union{SeisData,SeisChannel,SeisHdr})

Clear all notes from `U` and leaves a note about this.

    clear_notes!(S::SeisData, i::Int64, s::String)

Clear all notes from channel `i` of `S` and leaves a note about this.

    clear_notes!(S::SeisData, id::String, s::String)

As above for the first channel in `S` whose id is an exact match to `id`.

See also: `note!`, `show_processing`, `show_src`
"""
function clear_notes!(S::GphysData)
  cstr = tnote("notes cleared.")
  for i = 1:S.n
    empty!(S.notes[i])
    push!(S.notes[i], identity(cstr))
  end
  return nothing
end

function clear_notes!(S::GphysData, i::Int64)
  empty!(S.notes[i])
  push!(S.notes[i], tnote("notes cleared."))
  return nothing
end

function clear_notes!(S::GphysData, id::String)
  i = findid(id, S)
  (i == 0) && error(string("id = ", id, " not found in S!"))
  empty!(S.notes[i])
  push!(S.notes[i], tnote("notes cleared."))
  return nothing
end

clear_notes!(U::GphysChannel) = (U.notes = Array{String,1}(undef,1); U.notes[1] = tnote("notes cleared."); return nothing)
