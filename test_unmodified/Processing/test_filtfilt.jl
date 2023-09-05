fs = 100.0
nx = 10000
T = Float32

printstyled("  filtfilt!\n", color=:light_green)
Δ = round(Int64, sμ/fs)

# Methods
C = randSeisChannel(s=true)
C.fs = fs
C.t = [1 100; div(nx,4) Δ; div(nx,2) 5*Δ+3; nx 0]
C.x = randn(T, nx)
D = filtfilt(C)
filtfilt!(C)
@test C == D

# test for channel ranges
S = randSeisData(24, s=1.0, fs_min=40.0)
for i in (1, S.n)
  S.fs[i] = fs
  S.t[i] = [1 0; nx 0]
  S.x[i] = randn(Float32, nx)
end
U = deepcopy(S)
filtfilt!(S)
S1 = filtfilt(U)
klist = Int64[]
for i = 1:S.n
  if any(isnan.(S.x[i])) || any(isnan.(S1.x[i]))
    push!(klist, i)
  end
end
deleteat!(S, klist)
deleteat!(S1, klist)
if S.n > 0
  @test S == S1
else
  warn("All channels deleted; can't test equality.")
end

printstyled("    source logging\n", color=:light_green)
redirect_stdout(out) do
  show_processing(S, 1)
  show_processing(S[1])
  show_processing(S)
end

printstyled("    equivalence with DSP.filtfilt\n", color=:light_green)
for i = 1:10
  C = randSeisChannel(s=true)
  C.fs = fs
  C.t = [1 100; nx 0]
  C.x = randn(Float64, nx)
  D = deepcopy(C)
  filtfilt!(C)
  naive_filt!(D)
  @test isapprox(C.x, D.x)
end

printstyled("    former breaking cases\n", color=:light_green)
printstyled("      very short data windows\n", color=:light_green)
n_short = 5

C = randSeisChannel()
C.fs = fs
C.t = [1 0; n_short 0]
C.x = randn(Float32, n_short)
filtfilt!(C)

S = randSeisData(24, s=1.0, fs_min=40.0)
S.fs[S.n] = fs
S.t[S.n] = [1 0; n_short 0]
S.x[S.n] = randn(Float32, n_short)
filtfilt!(S)

printstyled("      repeated segment lengths\n", color=:light_green)
n_rep = 2048

S = randSeisData(24, s=1.0, fs_min=40.0)
for i in (1, S.n)
  S.fs[i] = fs
  S.t[i] = [1 0; n_rep 0]
  S.x[i] = randn(Float32, n_rep)
end
filtfilt!(S)
GC.gc()

# test for channel ranges
S = randSeisData(24, s=1.0, fs_min=40.0)
for i in (1, S.n)
  S.fs[i] = fs
  S.t[i] = [1 0; n_rep 0]
  S.x[i] = randn(Float32, n_rep)
end
U = deepcopy(S)
filtfilt!(S, chans=1:3)
for i = 1:S.n
  if i < 4
    @test S[i] != U[i]
  else
    @test S[i] == U[i]
  end
end
GC.gc()

printstyled("    checking that all filters work\n", color=:light_green)
for dm in String["Butterworth", "Chebyshev1", "Chebyshev2", "Elliptic"]
  for rt in String["Bandpass", "Bandstop", "Lowpass", "Highpass"]
    S = randSeisData(3, s=1.0, fs_min=40.0)
    filtfilt!(S, rt=rt, dm=dm)
  end
end

printstyled("    test all filters on SeisData\n\n", color = :light_green)
@printf("%12s | %10s | time (ms) | filt (MB) | data (MB) | ratio\n", "Name (dm=)", "Type (rt=)")
@printf("%12s | %10s | --------- | --------- | --------- | -----\n", " -----------", "---------")

for dm in String["Butterworth", "Chebyshev1", "Chebyshev2", "Elliptic"]
  for rt in String["Bandpass", "Bandstop", "Lowpass", "Highpass"]
    S = randSeisData(8, s=1.0, fs_min=40.0)
    (xx, t, b, xx, xx) = @timed filtfilt!(S, rt=rt, dm=dm)
    s = sum([sizeof(S.x[i]) for i = 1:S.n])
    r = b/s
    @printf("%12s | %10s | %9.2f | %9.2f | %9.2f | ", dm, rt, t*1000, b/1024^2, s/1024^2)
    printstyled(@sprintf("%0.2f\n", r), color=printcol(r))
    GC.gc()
  end
end

printstyled(string("\n    test all filters on a long, gapless ", T, " SeisChannel\n\n"), color = :light_green)
nx = 3456000
@printf("%12s | %10s |  data   |     filtfilt!    |  naive_filtfilt! |     ratio    |\n", "", "")
@printf("%12s | %10s | sz (MB) | t (ms) | sz (MB) | t (ms) | sz (MB) | speed | size |\n", "Name (dm=)", "Type (rt=)")
@printf("%12s | %10s | ------- | ------ | ------- | ------ | ------- | ----- | ---- |\n", " -----------", "---------")

for dm in String["Butterworth", "Chebyshev1", "Chebyshev2", "Elliptic"]
  for rt in String["Bandpass", "Bandstop", "Lowpass", "Highpass"]
    C = randSeisChannel(s=true)
    C.fs = fs
    C.t = [1 100; nx 0]
    C.x = randn(T, nx)
    D = deepcopy(C)

    # b = @allocated(filtfilt!(C, rt=rt, dm=dm))
    (xx, tc, b, xx, xx) = @timed(filtfilt!(C, rt=rt, dm=dm))
    (xx, td, n, xx, xx) = @timed(naive_filt!(D, rt=rt, dm=dm))
    # n = @allocated(naive_filt!(D, rt=rt, dm=dm))
    sz = sizeof(C.x)
    p = b/sz
    r = b/n
    q = tc/td

    @printf("%12s | %10s | %7.2f | %6.1f | %7.2f | %6.1f | %7.2f | ", dm, rt, sz/1024^2, tc*1000.0, b/1024^2, td*1000.0, n/1024^2)
    printstyled(@sprintf("%5.2f", q), color=printcol(q))
    @printf(" | ")
    printstyled(@sprintf("%4.2f", r), color=printcol(r))
    @printf(" | \n")
    GC.gc()
  end
end
println("")
