import SeisBase: get_svn
path = joinpath(Base.source_dir(),"../test/TestHelpers/0_check_deps.jl")
include(path)
include("./check_data.jl")
pkg_check(["DSP", "SeisBase", "IJulia"])
# we cannot copy the test data 
# get_svn("https://github.com/SeismoJulia/SeisBase-TestData/trunk/Tutorial", "DATA")

using IJulia
jupyterlab(dir=joinpath(dirname(dirname(pathof(SeisBase))),"tutorial"))
