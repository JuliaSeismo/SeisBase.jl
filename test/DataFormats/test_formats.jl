import SeisIO.Formats: formats, FmtVer, FormatDesc, HistVec
printstyled("  formats()\n", color=:light_green)

Fake_fmt = FormatDesc(
  "Fake data format",
  "\"goat-c\"",
  "Two guys running a startup from a taco truck, Mountain View, California, USA",
  "https://www.youtube.com/watch?v=TMZi25Pq3T8",
  "careers@linkedin.com",
  HistVec(),
  [ "much like SEG Y, everything is in XML for no reason",
    "still a better idea than SEED",
    "abandoned 2004-01-14. (RIP)"],
  [ "Mountain View, CA",
    "Christmas Island"],
  ["https://lmgtfy.com/?q=goatse"],
  0xff
  )
Fake_fmt.ver = [ FmtVer("1.0", "1999-01-01", false); FmtVer() ]
formats["Fake"] = Fake_fmt
@test formats["Fake"].docs ==  ["https://lmgtfy.com/?q=goatse"]
@test formats["Fake"].status ==  0xff
delete!(formats, "Fake")

Fake_fmt_2 = FormatDesc()
formats["Fake2"] = Fake_fmt_2
@test formats["Fake2"].docs ==  []
@test formats["Fake2"].status ==  0x00
delete!(formats, "Fake2")

redirect_stdout(out) do
  show(formats["ah1"])
  show(formats["sac"])
  show(formats["suds"])
  show(formats["uw"])
end
