xml_evfile1 = path*"/SampleFiles/XML/fdsnws-event_2017-01-12T03-18-55Z.xml"
xml_evfile2 = path*"/SampleFiles/XML/ISC_2011-tohoku-oki.xml"
xml_stfile = path*"/SampleFiles/XML/fdsnws-station_2017-01-12T03-17-42Z.xml"

printstyled("  QuakeML\n", color=:light_green)

id_err = "error in Station ID creation!"
unit_err = "units don't match instrument code!"
true_id = String["3337497", "3279407", "2844986", "2559759", "2092067", "1916079", "2413"]
true_ot = DateTime("2011-03-11T05:46:23.200")
true_loc = Float64[2.2376 38.2963; 93.0144 142.498; 26.3 19.7]
true_mag = Float32[8.6, 9.1, 8.8, 8.5, 8.6, 9.0, 8.5]
true_msc = String["MW", "MW", "MW", "MW", "MW", "MW", ""]
r1 = PZResp(Complex{Float32}.([ 0.0+0.0im -981.0+1009.0im
                                0.0+0.0im -981.0-1009.0im
                                0.0+0.0im -3290.0+1263.0im
                                0.0+0.0im -3290.0-1263.0im]), rev=true)
r2 = PZResp(Complex{Float32}.([   0.0+0.0im       -0.037-0.037im
                                  0.0+0.0im       -0.037+0.037im
                                  -15.15+0.0im    -15.64+0.0im
                                  -176.6+0.0im    -97.34-400.7im
                                  -463.1-430.5im  -97.34+400.7im
                                  -463.1+430.5im  -374.8+0.0im
                                  0.0+0.0im       -520.3+0.0im
                                  0.0+0.0im       -10530.0-10050.0im
                                  0.0+0.0im       -10530.0+10050.0im
                                  0.0+0.0im       -13300.0+0.0im
                                  0.0+0.0im       -255.097+0.0im ]),rev=true)

printstyled("    file read 1\n", color=:light_green)
(EC,RR) = read_qml(xml_evfile1)
Nev = length(EC)
@test Nev == length(true_id)
for i = 1:Nev
  @test EC[i].id == true_id[i]
  @test EC[i].mag.val == true_mag[i]
  @test EC[i].mag.scale == true_msc[i]
end

@test EC[2].ot==true_ot
for i = 1:2
  @test ≈(EC[i].loc.lat, true_loc[1,i])
  @test ≈(EC[i].loc.lon, true_loc[2,i])
  @test ≈(EC[i].loc.dep, true_loc[3,i])
end

printstyled("    file read 2\n", color=:light_green)
H, R = read_qml(xml_evfile2)
H = H[1]
R = R[1]

# Check basic headers
@test H.typ == "earthquake"
@test H.id == "16461282"

# Check that the correct magnitude is retained
@test H.mag.val ≥ 9.0f0
@test H.mag.scale == "MW"

# Check H.loc
@test H.loc.lat ≈ 38.2963
@test H.loc.lon ≈ 142.498
@test H.loc.dep ≈ 19.7152
@test H.loc.nst == 2643
@test H.loc.gap ≈ 6.314
@test H.loc.dt ≈ 0.31
@test H.loc.se ≈ 2.1567
@test H.loc.dmin ≈ 0.917
@test H.loc.dmax ≈ 163.253
@test H.loc.src == "smi:ISC/origid=602227159,ISC"

# Check source params
@test R.id == "600002952"
@test R.m0 == 5.312e22
@test R.mt == [1.73e22, -2.81e21, -1.45e22, 2.12e22, 4.55e22, -6.57e21]
@test R.dm == [6.0e19, 5.0e19, 5.0e19, 6.8e20, 6.5e20, 4.0e19]
@test R.pax == [295.0 115.0 205.0; 55.0 35.0 0.0; 5.305e22 -5.319e22 1.4e20]
@test R.planes == [25.0 203.0; 80.0 10.0; 90.0 88.0]
@test R.st.dur == 70.0
@test R.misc["methodID"] == "smi:ISC/methodID=Best_double_couple"
@test R.misc["pax_desc"] == "azimuth, plunge, length"
@test R.misc["planes_desc"] == "strike, dip, rake"
@test R.misc["derivedOriginID"] == "600126955"

printstyled("    file write\n", color=:light_green)
xf = "test.xml"
if isfile(xf)
  safe_rm(xf)
end
write_qml(xf, H, R)
H1, R1 = read_qml(xf)
H1 = H1[1]
R1 = R1[1]
@test H1.src == abspath(xf)
@test R1.src == abspath(xf)
compare_SeisHdr(H1, H)
compare_SeisSrc(R1, R)

write_qml(xf, [H], [R])
write_qml(xf, H)
write_qml(xf, [H])
H1, R1 = read_qml(xf)
H1 = H1[4]
R1 = R1[2]
compare_SeisHdr(H1, H)
compare_SeisSrc(R1, R)

xstr = read(xml_evfile1)
io = open(xf, "w")
write(io, xstr)
close(io)
write_qml(xf, [H], [R])
H1, R1 = read_qml(xf)
H1 = H1[2:end]
R1 = R1[2:end]
H, R = read_qml(xml_evfile1)
for i in 1:length(R)
  @test H1[i].src == abspath(xf)
  @test R1[i].src == abspath(xf)
  compare_SeisHdr(H1[i], H[i])
  compare_SeisSrc(R1[i], R[i])
end

# Write with no location set: should warn
H1[1].loc = EQLoc()
write_qml(xf, H1, R1)

# Write with no magnitude
Ev = randSeisEvent()
Ev.hdr.mag = EQMag()
write_qml(xf, Ev, v=3)
H1, R1 = read_qml(xf)
H1 = H1[end]
R1 = R1[end]
compare_SeisHdr(H1, Ev.hdr)
compare_SeisSrc(R1, Ev.source)

printstyled("      does trying to append a non-XML file error?\n", color=:light_green)
io = open(xf, "w")
write(io, rand(UInt8, 64))
close(io)
@test_throws ErrorException write_qml(xf, H, R)

# Clean up
safe_rm(xf)
