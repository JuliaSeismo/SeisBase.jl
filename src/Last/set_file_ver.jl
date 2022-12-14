export get_file_ver, set_file_ver

"""
    set_file_ver(fname, ver)

Sets the SeisBase file version of file fname.
"""
function set_file_ver(f::String, ver::Float32=vSeisBase)
  isfile(f) || error("File not found!")
  io = open(f, "a+")
  seekstart(io)
  String(fastread(io, 6)) == "SeisBase" || error("Not a SeisBase file!")
  write(io, ver)
  close(io)
  return nothing
end
set_file_ver(f::String, ver::Float64) = set_file_ver(f, Float32(ver))

"""
    get_file_ver(f)

Get the version of a SeisBase native format file.
"""
function get_file_ver(f::String)
  isfile(f) || error("File not found!")
  io = open(f, "r")
  seekstart(io)
  String(fastread(io, 6)) == "SeisBase" || error("Not a SeisBase file!")
  ver = fastread(io, Float32)
  close(io)
  return ver
end
