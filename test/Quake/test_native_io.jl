# save to disk/read from disk
savfile1 = "test.evt"

printstyled("  read/write of EventTraceData with compression\n", color=:light_green)
SeisBase.KW.comp = 0x02
S = convert(EventTraceData, randSeisData())
wseis(savfile1, S)
R = rseis(savfile1)[1]
@test R == S

SeisBase.KW.comp = 0x01
S = convert(EventTraceData, randSeisData())
C = convert(EventChannel, SeisChannel())
nx = SeisBase.KW.n_zip*2
C.t = [1 0; nx 0]
C.x = randn(nx)
push!(S, C)
wseis(savfile1, S)
R = rseis(savfile1)[1]
@test R == S

rm(savfile1)
