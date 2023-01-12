# XML Meta-Data
SeisBase can read and write the following XML metadata formats:

* QuakeML Version 1.2
* StationXML Version 1.1

## StationXML

```julia
read_sxml(fpat::String, s::String, t::String, memmap::Bool, msr::Bool, v::Integer)
```

!!! note 
    This function is not exported anywhere

Read FDSN StationXML files matching string pattern **fpat** into a new SeisData
object.

Keywords:
* `s`: start time. Format "YYYY-MM-DDThh:mm:ss", e.g., "0001-01-01T00:00:00".
* `t`: termination (end) time. Format "YYYY-MM-DDThh:mm:ss".
* `msr`: (Bool) read instrument response info as MultiStageResp?

**msr=true** processes XML files to give full response information
at every documented stage of the acquisition process: sampling, digitization,
FIR filtering, decimation, etc.

**How often is MultiStageResp needed?**
Almost never. By default, the **:resp** field of each channel contains a
simple instrument response with poles, zeros, sensitivity (**:a0**), and
sensitivity frequency (**:f0**). Very few use cases require more detail.

## [QuakeML](@id quakeml)

```@docs
read_qml
```


Read QuakeML files matching string pattern **fpat**. Returns a tuple containing
an array of **SeisHdr** objects **H** and an array of **SeisSrc** objects **R**.
Each pair (H[i], R[i]) describes the preferred location (origin, SeisHdr) and
event source (focal mechanism or moment tensor, SeisSrc) of event **i**.

If multiple focal mechanisms, locations, or magnitudes are present in a single
Event element of the XML file(s), the following rules are used to select one of
each per event:

**FocalMechanism**
  1. **preferredFocalMechanismID** if present
  2. Solution with best-fitting moment tensor
  3. First **FocalMechanism** element

**Magnitude**
  1. **preferredMagnitudeID** if present
  2. Magnitude whose ID matches **MomentTensor/derivedOriginID**
  3. Last moment magnitude (lowercase scale name begins with "mw")
  4. First **Magnitude** element

**Origin**
  1. **preferredOriginID** if present
  2. **derivedOriginID** from the chosen **MomentTensor** element
  3. First **Origin** element

Non-essential QuakeML data are saved to `misc` in each SeisHdr or SeisSrc object
as appropriate.
