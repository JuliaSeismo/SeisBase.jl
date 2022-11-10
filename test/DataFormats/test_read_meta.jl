printstyled("  read_meta equivalencies\n", color=:light_green)
printstyled("    full (XML, RESP, dataless)\n", color=:light_green)

fname         = "JRO.sacpz"
dataless_name = "CC.dataless"
sxml_file     = path*"/SampleFiles/XML/fdsnws-station_2019-09-11T06_26_58Z.xml"
resp_file     = path*"/SampleFiles/SEED/JRO.resp"
dataless_file = path*"/SampleFiles/SEED/"*dataless_name
dataless_wc   = path*"/SampleFiles/SEED/CC.*"
sacpz_file    = path*"/SampleFiles/SAC/"*fname
sacpz_wc      = path*"/SampleFiles/SAC/JRO.sacp*"

S1 = read_meta("sxml", sxml_file, s="2016-01-01T00:00:00", memmap=true, msr=true)
S2 = read_meta("resp", resp_file, memmap=true, units=true)
S3 = read_meta("dataless", dataless_file, memmap=true, s="2016-01-01T00:00:00", units=true)[56:58]
S4 = read_meta("sacpz", sacpz_file, memmap=true)

@test_throws ErrorException read_meta("dataless", sxml_file)
@test_throws ErrorException read_meta("deez", "nutz.sac")
@test_throws ErrorException read_meta("deez", sxml_file)

C = Array{Char,2}(undef, 10, 3)
fill!(C, ' ')
SA = Array{String, 2}(undef, 10, 3)
for k = 1:3
  fstr = ""
  n = 0
  # println("    ===== ", S1.id[k], " =====")
  R1 = S1.resp[k]
  R2 = S2.resp[k]
  R3 = S3.resp[k]
  for f in fieldnames(MultiStageResp)
    fstr = uppercase(String(f))
    n += 1
    f1 = getfield(R1, f)
    f2 = getfield(R2, f)
    f3 = getfield(R3, f)
    t = min(isequal(f1, f2), isequal(f1, f3))
    if t
      C[n,k] = '='
    else

      # Check for same size, type
      L = length(f1)
      if L != length(f2) || L != length(f3)
        C[n,k] = 'f'
        continue
      elseif typeof(f1) != typeof(f2) || typeof(f1) != typeof(f3)
        C[n,k] = 'f'
        continue
      end

      # Check for approximately equal fields
      T = falses(L)
      for i = 1:L
        i1 = getindex(f1, i)
        i2 = getindex(f2, i)
        i3 = getindex(f3, i)
        t2 = min(isequal(i1, i2), isequal(i1, i3))
        if t2 == true
          T[i] = true
        else
          T1 = typeof(i1)
          if T1 != typeof(i2) || T1 != typeof(i3)
            C[n,k] = 'f'
            break

          # Easyfor a bitstype
          elseif isbitstype(T1)
            if isapprox(i1, i2) && isapprox(i1, i3)
              C[n,k] = '≈'
              T[i] = true
              continue
            end
          else
            FF = fieldnames(T1)

            # Only possible for a String in these Types
            if isempty(FF)
              C[n,k] = 'f'

            # Check for approximately equal subfields
            else
              TT = falses(length(FF))
              for (j,g) in enumerate(FF)
                j1 = getfield(i1, g)
                j2 = getfield(i2, g)
                j3 = getfield(i3, g)

                # Dimension mismatch
                if !(length(j1) == length(j2) == length(j3))
                  C[n,k] = 'f'

                # True mismatch
                elseif min(isapprox(j1, j2), isapprox(j1, j3)) == false
                  C[n,k] = 'f'

                # Approx. equality
                else
                  TT[j] = true
                end
              end

              # If they're all approximate, set T[i] to true
              if minimum(TT) == true
                T[i] = true
              end
            end
          end
        end
      end

      # If they're all approximate, set C[n,k] to ≈
      if minimum(T) == true
        C[n,k] = '≈'
      end
    end
    SA[n,k] = (k == 1 ? lpad(fstr * ": ", 12) : "") * lpad(C[n,k], 5)
    @test C[n,k] in ('≈', '=')
  end
end
println("")
println(" "^12,
        lpad(S1.id[1][end-3:end], 6),
        lpad(S1.id[2][end-3:end], 6),
        lpad(S1.id[3][end-3:end], 6))
println(" "^12, "|", "="^5, "|", "="^5, "|", "="^5)
for i = 1:size(SA,1)
  println(join(SA[i,:], " "))
end
println("")

printstyled("    one-stage (SACPZ, XML)\n", color=:light_green)
S1 = read_meta("sxml", sxml_file, s="2016-01-01T00:00:00", msr=false)
S4 = read_meta("sacpz", sacpz_file)
K = Array{Char,2}(undef, 3, 3)
fill!(K, ' ')
SA = Array{String, 2}(undef, 3, 3)
for k = 1:3
  n = 0
  R1 = S1.resp[k]
  R2 = S4.resp[k]
  for f in fieldnames(PZResp)
    fstr = uppercase(String(f))
    (f == :f0) && continue # SACPZ lacks f0 for some reason
    n += 1
    f1 = getfield(R1, f)
    f2 = getfield(R2, f)
    t = isequal(f1, f2)
    if t == true
      K[n,k] = '='
    else

      # Check for same size, type
      L = length(f1)
      if L != length(f2)
        K[n,k] = 'f'
        continue
      elseif typeof(f1) != typeof(f2)
        K[n,k] = 'f'
        continue
      elseif isapprox(f1, f2)
        K[n,k] = '≈'
      end
    end
    @test K[n,k] in ('≈', '=')
    SA[n,k] = (k == 1 ? lpad(fstr * ": ", 12) : "") * lpad(K[n,k], 5)
  end
end
println("")
println(" "^12,
        lpad(S1.id[1][end-3:end], 6),
        lpad(S1.id[2][end-3:end], 6),
        lpad(S1.id[3][end-3:end], 6))
println(" "^12, "|", "="^5, "|", "="^5, "|", "="^5)
for i = 1:size(SA,1)
  println(join(SA[i,:], " "))
end
println("")

S1 = read_meta("sacpz", sacpz_file)
S2 = read_meta("sacpz", sacpz_wc)
S3 = read_meta("dataless", dataless_wc, s="2016-01-01T00:00:00")
for f in SeisIO.datafields
  if (f in (:src, :notes)) == false
    @test isequal(getfield(S1,f), getfield(S2,f))
  end
end

# test here to track +meta logging
printstyled("    logging to :notes\n", color=:light_green)
for i in 1:S1.n
  @test any([occursin(fname, n) for n in S1.notes[i]])
end
for i in 1:S2.n
  @test any([occursin(fname, n) for n in S2.notes[i]])
end
for i in 1:S3.n
  @test any([occursin(dataless_name, n) for n in S3.notes[i]])
end

printstyled("    array of inputs\n", color=:light_green)
S = read_meta("sacpz", [sacpz_file, sacpz_wc])
