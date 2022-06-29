# Input Details

|Type|Item|Source|File|Format|
|---|---|---|---|---|
|Upper-level specification|Global Positioning Systems Directorate Systems Engineering & Integration Interface Specification IS-GPS-200|[https://www.gps.gov/technical/icwg/IS-GPS-200G.pdf](https://www.gps.gov/technical/icwg/IS-GPS-200G.pdf)|[IS-GPS-200G.pdf](IS-GPS-200G.pdf)|PDF|
|Upper-tier Requirement|GPS time format|Excerpt from IS-GPS-200|[GPSTimeFormatRequirement.txt](GPSTimeFormatRequirement.txt)|Text|
|Derived Requirement|GPS Time-of-Week value range|Upper-tier Requirement|[GPSTimeOfWeekValueRange.txt](GPSTimeOfWeekValueRange.txt)|Text|
|Derived Requirement|Maximum GPS Time-of-Week size|Upper-tier Requirement|[GPSMaxTimeOfWeekSize.txt](GPSMaxTimeOfWeekSize.txt)|Text|
|Test Result|Nominal Test: Min value testing of GPS Time-of-Week field|Derived Requirements for range and size|[MinValResult.txt](MinValResult.txt)|Text|
|Test Result|Negative Test: Min-1 value testing of GPS Time-of-Week field|Derived Requirement for range and size|[MinValMinusOneResult.txt](MinValMinusOneResult.txt)|Text|
|Test Result|Nominal Test: Max value testing of GPS Time-of-Week field|Derived Requirement for range and size|[MaxValResult.txt](MaxValResult.txt)|Text|
|Test Result|Negative Test: Max+1 value testing of GPS Time-of-Week field|Derived Requirement for range and size|[MaxValPlusOneResult.txt](MaxValPlusOneResult.txt)|Text|
|Test Result|25 KiB of Random Binary Content|head -c 35KiB /dev/urandom > random25KiBfile.bin|random25KiBfile.bin|Binary|

Note: The [map.json](map.json) file describes the relationships for the test driver to call the proper API methods; it's intentionally written in JSON format to differentiate it from the output GraphViz DOT format as retrieved from the digraph generator.
