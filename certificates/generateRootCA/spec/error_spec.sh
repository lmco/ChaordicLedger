#!/bin/sh
# Uncomment and use when comparison to constants is worked out.
# %const ASDF: 'Usage: ../bin/generateRootCA.sh
#     [-h]
#     -f <Results file name to appear in output directory>
#     -p <Passphrase>
#     -o <Output directory>
#     -c <ISO 3166-2 two-letter country code>
#     -s <State>
#     -l <Location>
#     -r <Organization>
#     -u <Organizational Unit>
#     -n <Common Name>'

Describe 'Root Certificate Authority (CA) Generation'
  It 'lists usage with no options provided'
    When run script ../bin/generateRootCA.sh
    The output should equal 'Usage: ../bin/generateRootCA.sh
    [-h]
    -f <Results file name to appear in output directory>
    -p <Passphrase>
    -o <Output directory>
    -c <ISO 3166-2 two-letter country code>
    -s <State>
    -l <Location>
    -r <Organization>
    -u <Organizational Unit>
    -n <Common Name>'
    The status should equal 1
  End

  It 'lists usage with help switch'
    When run script ../bin/generateRootCA.sh -h
    The output should equal 'Usage: ../bin/generateRootCA.sh
    [-h]
    -f <Results file name to appear in output directory>
    -p <Passphrase>
    -o <Output directory>
    -c <ISO 3166-2 two-letter country code>
    -s <State>
    -l <Location>
    -r <Organization>
    -u <Organizational Unit>
    -n <Common Name>'
    The status should equal 2
  End

  It 'lists usage with an invalid switch'
    When run script ../bin/generateRootCA.sh -Z
    The output should equal 'Error: Invalid option
Usage: ../bin/generateRootCA.sh
    [-h]
    -f <Results file name to appear in output directory>
    -p <Passphrase>
    -o <Output directory>
    -c <ISO 3166-2 two-letter country code>
    -s <State>
    -l <Location>
    -r <Organization>
    -u <Organizational Unit>
    -n <Common Name>'
    The stderr should equal 'Illegal option -Z'
    The status should equal 3
  End

  It 'errors out when the results file is not specified'
    When run script ../bin/generateRootCA.sh -o tmp
    The output should equal 'ERROR: ResultsFileName must be provided'
    The status should equal 4
  End

  It 'errors out when the output directory is not specified'
    When run script ../bin/generateRootCA.sh -f results.json
    The output should equal 'ResultsFileName is "results.json"
ERROR: OutputDirectory must be provided'
    The status should equal 5
  End

  It 'errors out when the country code is not specified'
    When run script ../bin/generateRootCA.sh -f results.json -o tmp
    The output should equal 'ResultsFileName is "results.json"
OutputDirectory is "tmp"
ERROR: CountryCode must be provided'
    The status should equal 6
  End

  It 'errors out when the state is not specified'
    When run script ../bin/generateRootCA.sh -f results.json -o tmp -c US
    The output should equal 'ResultsFileName is "results.json"
OutputDirectory is "tmp"
CountryCode is "US"
ERROR: State must be provided'
    The status should equal 7
  End

  It 'errors out when the location is not specified'
    When run script ../bin/generateRootCA.sh -f results.json -o tmp -c US -s Colorado
    The output should equal 'ResultsFileName is "results.json"
OutputDirectory is "tmp"
CountryCode is "US"
State is "Colorado"
ERROR: Location must be provided'
    The status should equal 8
  End

  It 'errors out when the organization is not specified'
    When run script ../bin/generateRootCA.sh -f results.json -o tmp -c US -s Colorado -l Denver
    The output should equal 'ResultsFileName is "results.json"
OutputDirectory is "tmp"
CountryCode is "US"
State is "Colorado"
Location is "Denver"
ERROR: Organization must be provided'
    The status should equal 9
  End

  It 'errors out when the organizational unit is not specified'
    When run script ../bin/generateRootCA.sh -f results.json -o tmp -c US -s Colorado -l Denver -r "Lockheed Martin Corporation"
    The output should equal 'ResultsFileName is "results.json"
OutputDirectory is "tmp"
CountryCode is "US"
State is "Colorado"
Location is "Denver"
Organization is "Lockheed Martin Corporation"
ERROR: OrganizationalUnit must be provided'
    The status should equal 10
  End

  It 'errors out when the common name is not specified'
    When run script ../bin/generateRootCA.sh -f results.json -o tmp -c US -s Colorado -l Denver -r "Lockheed Martin Corporation" -u "Space"
    The output should equal 'ResultsFileName is "results.json"
OutputDirectory is "tmp"
CountryCode is "US"
State is "Colorado"
Location is "Denver"
Organization is "Lockheed Martin Corporation"
OrganizationalUnit is "Space"
ERROR: CommonName must be provided'
    The status should equal 11
  End
End
