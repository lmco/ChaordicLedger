#!/bin/sh
# Uncomment and use when comparison to constants is worked out.
# %const ASDF: 'Usage: ../bin/generateNodeCert.sh
# [-h]
#     -f <Results file name to appear in output directory>
#     -a <RootCACertFile>
#     -b <RootCAKeyFile>
#     -d <RootCAPassphrase>
#     -p <NodeCertPassphrase>
#     -o <Output directory>
#     -c <ISO 3166-2 two-letter country code>
#     -s <State>
#     -l <Location>
#     -r <Organization>
#     -u <Organizational Unit>
#     -n <Common Name>'

Describe 'Node Certificate Generation'
  It 'lists usage with no options provided'
    When run script ../bin/generateNodeCert.sh
    The output should equal 'Usage: ../bin/generateNodeCert.sh
    [-h]
    -f <Results file name to appear in output directory>
    -a <RootCACertFile>
    -b <RootCAKeyFile>
    -d <RootCAPassphrase>
    -p <NodeCertPassphrase>
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
    When run script ../bin/generateNodeCert.sh -h
    The output should equal 'Usage: ../bin/generateNodeCert.sh
    [-h]
    -f <Results file name to appear in output directory>
    -a <RootCACertFile>
    -b <RootCAKeyFile>
    -d <RootCAPassphrase>
    -p <NodeCertPassphrase>
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
    When run script ../bin/generateNodeCert.sh -Z
    The output should equal 'Error: Invalid option
Usage: ../bin/generateNodeCert.sh
    [-h]
    -f <Results file name to appear in output directory>
    -a <RootCACertFile>
    -b <RootCAKeyFile>
    -d <RootCAPassphrase>
    -p <NodeCertPassphrase>
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

  It 'errors out when the root CA certificate file is not specified'
    When run script ../bin/generateNodeCert.sh -o tmp
    The output should equal 'ERROR: RootCACertFile must be provided'
    The status should equal 12
  End

  It 'errors out when the root CA private key file is not specified'
    When run script ../bin/generateNodeCert.sh -a rootCA.pem
    The output should equal 'RootCACertFile is "rootCA.pem"
ERROR: RootCAKeyFile must be provided'
    The status should equal 13
  End

  It 'errors out when the root CA passphrase file is not specified'
    When run script ../bin/generateNodeCert.sh -a rootCA.pem -b rootCA.key
    The output should equal 'RootCACertFile is "rootCA.pem"
RootCAKeyFile is "rootCA.key"
ERROR: RootCAPassphrase must be provided'
    The status should equal 14
  End

  It 'errors out when the results file is not specified'
    When run script ../bin/generateNodeCert.sh -a rootCA.pem -b rootCA.key -d something
    The output should equal 'RootCACertFile is "rootCA.pem"
RootCAKeyFile is "rootCA.key"
Not showing value for argument "RootCAPassphrase"
ERROR: ResultsFileName must be provided'
    The status should equal 4
  End

  It 'errors out when the output directory is not specified'
    When run script ../bin/generateNodeCert.sh -a rootCA.pem -b rootCA.key -d something -f results.json
    The output should equal 'RootCACertFile is "rootCA.pem"
RootCAKeyFile is "rootCA.key"
Not showing value for argument "RootCAPassphrase"
ResultsFileName is "results.json"
ERROR: OutputDirectory must be provided'
    The status should equal 5
  End

  It 'errors out when the country code is not specified'
    When run script ../bin/generateNodeCert.sh -a rootCA.pem -b rootCA.key -d something -f results.json -o tmp
    The output should equal 'RootCACertFile is "rootCA.pem"
RootCAKeyFile is "rootCA.key"
Not showing value for argument "RootCAPassphrase"
ResultsFileName is "results.json"
OutputDirectory is "tmp"
ERROR: CountryCode must be provided'
    The status should equal 6
  End

  It 'errors out when the state is not specified'
    When run script ../bin/generateNodeCert.sh -a rootCA.pem -b rootCA.key -d something -f results.json -o tmp -c US
    The output should equal 'RootCACertFile is "rootCA.pem"
RootCAKeyFile is "rootCA.key"
Not showing value for argument "RootCAPassphrase"
ResultsFileName is "results.json"
OutputDirectory is "tmp"
CountryCode is "US"
ERROR: State must be provided'
    The status should equal 7
  End

  It 'errors out when the location is not specified'
    When run script ../bin/generateNodeCert.sh -a rootCA.pem -b rootCA.key -d something -f results.json -o tmp -c US -s Colorado
    The output should equal 'RootCACertFile is "rootCA.pem"
RootCAKeyFile is "rootCA.key"
Not showing value for argument "RootCAPassphrase"
ResultsFileName is "results.json"
OutputDirectory is "tmp"
CountryCode is "US"
State is "Colorado"
ERROR: Location must be provided'
    The status should equal 8
  End

  It 'errors out when the organization is not specified'
    When run script ../bin/generateNodeCert.sh -a rootCA.pem -b rootCA.key -d something -f results.json -o tmp -c US -s Colorado -l Denver
    The output should equal 'RootCACertFile is "rootCA.pem"
RootCAKeyFile is "rootCA.key"
Not showing value for argument "RootCAPassphrase"
ResultsFileName is "results.json"
OutputDirectory is "tmp"
CountryCode is "US"
State is "Colorado"
Location is "Denver"
ERROR: Organization must be provided'
    The status should equal 9
  End

  It 'errors out when the organizational unit is not specified'
    When run script ../bin/generateNodeCert.sh -a rootCA.pem -b rootCA.key -d something -f results.json -o tmp -c US -s Colorado -l Denver -r LMCO
    The output should equal 'RootCACertFile is "rootCA.pem"
RootCAKeyFile is "rootCA.key"
Not showing value for argument "RootCAPassphrase"
ResultsFileName is "results.json"
OutputDirectory is "tmp"
CountryCode is "US"
State is "Colorado"
Location is "Denver"
Organization is "LMCO"
ERROR: OrganizationalUnit must be provided'
    The status should equal 10
  End

  It 'errors out when the common name is not specified'
    When run script ../bin/generateNodeCert.sh -a rootCA.pem -b rootCA.key -d something -f results.json -o tmp -c US -s Colorado -l Denver -r LMCO -u RMS
    The output should equal 'RootCACertFile is "rootCA.pem"
RootCAKeyFile is "rootCA.key"
Not showing value for argument "RootCAPassphrase"
ResultsFileName is "results.json"
OutputDirectory is "tmp"
CountryCode is "US"
State is "Colorado"
Location is "Denver"
Organization is "LMCO"
OrganizationalUnit is "RMS"
ERROR: CommonName must be provided'
    The status should equal 11
  End
End
