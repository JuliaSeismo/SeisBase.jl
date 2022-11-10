hexIDs = UInt16[0x0001, 0x0002, 0x0003]
@test findhex(0x0000, hexIDs) == -1
@test findhex(0x0001, hexIDs) == 1
@test findhex(0x0002, hexIDs) == 2
@test findhex(0x0003, hexIDs) == 3

# win32 with gaps
if has_restricted
  cfile = path*"/SampleFiles/Restricted/03_02_27_20140927.euc.ch"
  printstyled("  win32\n", color=:light_green)
  @info(string(timestamp(), ": win32 tests use an SSL-encrypted tarball."))

  # test that verbose logging works
  printstyled("    verbose logging\n", color=:light_green)
  redirect_stdout(out) do
    fname = path*"/SampleFiles/Restricted/2014092709*.cnt"
    cfile = path*"/SampleFiles/Restricted/03_02_27_20140927.euc.ch"
    S = verified_read_data("win32", fname, cf=cfile, v=3, vl=true)
    files = ls(fname)
    S2 = SeisData()
    read_data!(S2, "win32", files, cf=cfile, v=3, vl=true)
    compare_SeisData(S, S2)

    for i in 1:S.n
      notes = S.notes[i]
      @test length(notes) == 60
      for n in notes
        @test occursin("jst = true", n)
        @test occursin("nx_new = 8640000", n)
        @test occursin("nx_add = 360000", n)
        @test occursin("v = 3", n)
      end
    end

    # There should be 8 channels
    @test S.n==8

    # There should be exactly 360000 points per channel (all are 100 Hz)
    nx = [length(S.x[i]) for i=1:1:S.n]
    @test minimum(nx)==360000
    @test maximum(nx)==360000

    # Check against SAC files
    testfiles = path*"/SampleFiles/Restricted/".*["20140927000000.V.ONTA.E.SAC",
                                                  "20140927000000.V.ONTA.H.SAC",
                                                  "20140927000000.V.ONTA.N.SAC",
                                                  "20140927000000.V.ONTA.U.SAC",
                                                  "20140927000000.V.ONTN.E.SAC",
                                                  "20140927000000.V.ONTN.H.SAC",
                                                  "20140927000000.V.ONTN.N.SAC",
                                                  "20140927000000.V.ONTN.U.SAC"]

    # SAC files prepared in SAC with these commands from day-long Ontake files
    # beginning at midnight Japan time converted to SAC with win32 precompiled
    # utilities
    #
    # SAC commands that generate these from day-long SAC files:
    # cut b 32400 35999.99
    # r /home/josh/SAC/20140927000000.V.*.SAC"
    # ch b 0 nzjday 270 nzhour 09
    # w over
    # q

    U = SeisData()
    for f in testfiles
      T = verified_read_data("sac", f)[1]
      push!(U, T)
    end

    # ID correspondence
    j = Array{Int64,1}(undef, S.n)
    for (n,i) in enumerate(S.id)
      id = split(i, '.')
      id[3] = ""
      id[2] = "V"*id[2]
      id[1] = "JP"
      c = id[4][3:3]
      if c == "Z"
        id[4] = "U"
      else
        id[4] = c
      end
      id = join(id, '.')
      j[n] = findid(id, U)
    end

    inds = Array{Array{Int64,1}}(undef, S.n)
    for (n,i) in enumerate(j)
      inds[n] = findall(abs.(S.x[n]-U.x[i]).>eps())
    end

    # The only time gaps should be what are in the logs:
    # ┌ Warning: Time gap detected! (15.0 s at V.ONTA.H, beginning 2014-09-27T09:58:00)
    # └ @ SeisIO ~/.julia/dev/SeisIO/src/Formats/Win32.jl:137
    # ┌ Warning: Time gap detected! (15.0 s at V.ONTA.U, beginning 2014-09-27T09:58:00)
    # └ @ SeisIO ~/.julia/dev/SeisIO/src/Formats/Win32.jl:137
    # ┌ Warning: Time gap detected! (15.0 s at V.ONTA.N, beginning 2014-09-27T09:58:00)
    # └ @ SeisIO ~/.julia/dev/SeisIO/src/Formats/Win32.jl:137
    # ┌ Warning: Time gap detected! (15.0 s at V.ONTA.E, beginning 2014-09-27T09:58:00)
    # └ @ SeisIO ~/.julia/dev/SeisIO/src/Formats/Win32.jl:137

    for k = 1:S.n
      i = j[k]
      if !isempty(inds[i])
        @test length(inds[i]) == 1500
        @test div(first(inds[i]), 6000) == 58
        @test div(last(inds[i]), 6000) == 58
        r₀ = rem(first(inds[i]), 6000)
        r₁ = rem(last(inds[i]), 6000)
        @test round((r₁ - r₀)/100, digits=1) == 15.0
      end
    end
  end
  # Converting the mean to single-point precision gives exactly the same
  # result as SAC conversion from win32; however, the average computed
  # over an hour will be slightly different.
  #
  # This can be verified using the script "ontake_test.jl" in ../../internal_tests/

  # Now test the other two bits types, 4-bit Int ...
  printstyled("    Int4\n", color=:light_green)
  fname = path*"/SampleFiles/Restricted/2014092700000302.cnt"
  cfile = path*"/SampleFiles/Restricted/03_02_27_20140927*ch"
  S = SeisData()
  redirect_stdout(out) do
    verified_read_data!(S, "win32", fname, cf=cfile, v=3)
  end
  i = findid("V.ONTA.23.EHH", S)
  @test length(S.x[i]) == 60*S.fs[i]
  @test maximum(S.x[i]) == 11075.0
  @test minimum(S.x[i]) == -5026.0

  # ...and 24-bit bigendian Int...
  printstyled("    Int24\n", color=:light_green)
  fname = path*"/SampleFiles/Restricted/2014092712000302.cnt"
  verified_read_data!(S, "win32", fname, cf=cfile)
  printstyled("     channel continuation\n", color=:light_green)
  @test length(S.x[1]) == round(Int64, 120*S.fs[1]) == S.t[1][end,1]
  ii = findlast(S.id.=="V.ONTA.23.EHH")
  @test maximum(S.x[ii]) == 14896.0
  @test minimum(S.x[ii]) == -12651.0
  for id in unique(S.id)
    @test length(findall(S.id.==id))==1
  end

  # ...and 32-bit bigendian Int ...
  printstyled("    Int32\n", color=:light_green)
  cfile = path*"/SampleFiles/Restricted/chandata_20140927.txt"
  fname = path*"/SampleFiles/Restricted/2014092712370207VM.cnt"
  verified_read_data!(S, "win32", fname, cf=cfile)
else
  printstyled("  win32 data format not tested (files not found)\n", color=:red)
end
