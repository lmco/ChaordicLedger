[![CI](https://github.com/lmco/ChaordicLedger/actions/workflows/ci.yml/badge.svg)](https://github.com/lmco/ChaordicLedger/actions/workflows/ci.yml)

# CharodicLedger
The ChaordicLedger is the implementation of a design for a combination of Distributed Ledger Technology (DLT) and a Distributed File System (DFS) to create a secure, enterprise-grade platform for storing interlinked project artifacts.

The development of this platform is in pursuit of the author's PhD research objectives.

## Related Publications
|Title|Forum|URL|
|---|---|---|
|***Distributed Ledgers in Developing Large-Scale Integrated Systems***|[IEEE SYSCON 2021](https://2021.ieeesyscon.org)|[https://www.lens.org/lens/scholar/article/090-912-315-699-108](https://www.lens.org/lens/scholar/article/090-912-315-699-108)|
|***ChaordicLedger: Digital Transformation and Business Intelligence via Data Provenance and Ubiquity***|[IEEE SYSCON 2022](https://2022.ieeesyscon.org)|(Pending)|

## Design Objectives
1. The platform shall be portable.
    1. All deployment-specific attributes shall be specifiable at deployment time (e.g. from a pipeline)
1. Test automation shall be implemented early and where practical.
1. Free and Open-Source technologies shall be leveraged.

## Implementation Roadmap
|Item|Implementation Status|Test Status|Documentation Status|Pipeline Execution|
|---|---|---|---|---|
|Scripted generation of root certificate authority.|&#9745;|&#9745;|&#9745;|&#9745;|
|Scripted generation of node certificate signed by generated root certificate authority.|&#9745;|&#9745;|&#9745;||
|Creation of Hyperledger Nodes|   |   |   ||
|Creation of hybrid Hyperledger/IPFS Nodes|   |   |   ||
|Creation of RESTful API|   |   |   ||
|Creation of Smart Contracts|   |   |   ||
|Gathering Key Performance Indicators (KPIs)|   |   |   ||
|Defining and Executing Simulations|   |   |   ||

## References
* Markdown Editor: [https://jbt.github.io/markdown-editor/](https://jbt.github.io/markdown-editor/)
* kind: [https://kind.sigs.k8s.io/](https://kind.sigs.k8s.io/)
* Obsidian: [https://obsidian-lang.com/](https://obsidian-lang.com/)
* All indexed publications by author: [https://orcid.org/0000-0001-5594-9756](https://orcid.org/0000-0001-5594-9756)
