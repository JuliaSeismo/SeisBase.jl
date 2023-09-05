printstyled("  env!\n", color=:light_green)

# GphysChannel, gaps
printstyled("    on SeisChannel\n", color=:light_green)
C = randSeisChannel(s=true)
C.t = [ 1 0;
        2 500;
        1959 69420;
        90250 0]
C.x = randn(C.t[end,1])
env!(C)

# GphysChannel, no gaps
C = randSeisChannel(s=true)
ungap!(C)
D = env(C)

# GphysData
printstyled("    on SeisData\n", color=:light_green)
S = randSeisData(24)
ungap!(S)
U = deepcopy(S)
env!(S, v=2)
T = env(U, v=2)
printstyled("    testing that env! == DSP.hilbert\n", color=:light_green)
for i = 1:S.n
  if S.fs[i] > 0.0 && length(S.x[i]) > 256
    ex1 = S.x[i]
    ex2 = abs.(DSP.hilbert(U.x[i]))
    @test isapprox(ex1, ex2)
    @test isapprox(S.x[i], T.x[i])
  end
end

for k = 1:4
  S = randSeisData(24, s=1.0, fs_min=20.0)
  for i = 1:S.n
    nx = 2^16
    t = [1 0; 512 134235131; 2^14 100000; 2^15 12345678; nx 0]
    S.t[i] = t
    S.x[i] = randn(eltype(S.x[i]), nx)
  end
  U = deepcopy(S)
  env!(S)

  for i = 1:S.n
    j = rand(1:3)
    si = S.t[i][j,1]
    ei = S.t[i][j+1,1]-1
    ex1 = S.x[i][si:ei]
    ex2 = abs.(DSP.hilbert(U.x[i][si:ei]))
    @test isapprox(ex1, ex2)
  end

end

printstyled("    testing on very short data segments\n", color=:light_green)
S = randSeisData(5)
N = 2 .^ collect(1:1:5)
for i = 1:S.n
  nx = N[i]
  S.fs[i] = 100.0
  S.t[i] = [1 0; nx 0]
  S.x[i] = rand(nx)
end
env!(S)
