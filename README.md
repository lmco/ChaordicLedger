[![CI](https://github.com/lmco/ChaordicLedger/actions/workflows/ci.yml/badge.svg)](https://github.com/lmco/ChaordicLedger/actions/workflows/ci.yml)

# CharodicLedger
The ChaordicLedger is the implementation of a design for a combination of Distributed Ledger Technology (DLT) and a Distributed File System (DFS) to create a secure, enterprise-grade platform for storing interlinked project artifacts.

The development of this platform is in pursuit of the author's PhD research objectives.

## Related Publications
|Title|Forum|URL|
|---|---|---|
|***ChaordicLedger: Digital Transformation and Business Intelligence via Data Provenance and Ubiquity***|[Institute of Electrical and Electronics Engineers Systems Conference (IEEE SYSCON) 2022](https://2022.ieeesyscon.org)|[https://ieeexplore.ieee.org/document/9773812](https://ieeexplore.ieee.org/document/9773812)|
|***Distributed Ledgers in Developing Large-Scale Integrated Systems***|[Institute of Electrical and Electronics Engineers Systems Conference (IEEE SYSCON) 2021](https://2021.ieeesyscon.org)|[https://ieeexplore.ieee.org/document/9447136](https://ieeexplore.ieee.org/document/9447136)|


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
|Creation of Hyperledger Nodes|In Progress|   |   ||
|Creation of hybrid Hyperledger/IPFS Cluster|&#9745;|In Progress|   ||
|Creation of RESTful API|&#9745;|In Progress|In Progress||
|Creation of Smart Contracts|In Progress|In Progress|   ||
|Gathering Key Performance Indicators (KPIs)|   |   |   ||
|Defining and Executing Simulations|   |   |   ||

## References
* All indexed publications by author: [https://orcid.org/0000-0001-5594-9756](https://orcid.org/0000-0001-5594-9756)
* Hyperledger Fabric Cheat Sheet: [https://softwaremill.com/hyperledger-fabric-cheat-sheet/](https://softwaremill.com/hyperledger-fabric-cheat-sheet/)
* Markdown Editor: [https://jbt.github.io/markdown-editor/](https://jbt.github.io/markdown-editor/)
* K9s - Kubernetes CLI To Manage Your Clusters In Style!: [https://k9scli.io/](https://k9scli.io/)
* kind: [https://kind.sigs.k8s.io/](https://kind.sigs.k8s.io/)
* Kubernetes Cheat Sheet: [https://kubernetes.io/docs/reference/kubectl/cheatsheet/](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
* Obsidian: [https://obsidian-lang.com/](https://obsidian-lang.com/)
* Swagger Editor: [https://editor.swagger.io/](https://editor.swagger.io/)

https://docs.ipfs.io/how-to/command-line-quick-start/#take-your-node-online
https://docs.ipfs.io/how-to/exchange-files-between-nodes/
