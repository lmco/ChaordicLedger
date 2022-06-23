[![CI](https://github.com/lmco/ChaordicLedger/actions/workflows/ci.yml/badge.svg)](https://github.com/lmco/ChaordicLedger/actions/workflows/ci.yml)

# CharodicLedger
The ChaordicLedger is the implementation of a design for a combination of Distributed Ledger Technology (DLT) and a Distributed File System (DFS) to create a secure, enterprise-grade platform for storing interlinked project artifacts.

The development of this platform is in pursuit of the author's PhD research objectives.

# Goal
The goal of this codebase is to establish a [TRL Level 4](https://en.wikipedia.org/wiki/Technology_readiness_level) Proof of Concept (PoC) of integrating the distributed nature of the InterPlanetary File System (IPFS) with the permissioned, private nature of Hyperledger Fabric via industry-relevant smart contracts to achieve a macro-to-micro-scale view of large integrated systems in support of Systems Engineering, Configuration Management, Software Engineering, and Cost Account Management.

## Related Publications
|Title|Forum|URL|
|---|---|---|
|***ChaordicLedger: Digital Transformation and Business Intelligence via Data Provenance and Ubiquity***|[Institute of Electrical and Electronics Engineers Systems Conference (IEEE SYSCON) 2022](https://2022.ieeesyscon.org)|[https://ieeexplore.ieee.org/document/9773812](https://ieeexplore.ieee.org/document/9773812)|
|***Distributed Ledgers in Developing Large-Scale Integrated Systems***|[Institute of Electrical and Electronics Engineers Systems Conference (IEEE SYSCON) 2021](https://2021.ieeesyscon.org)|[https://ieeexplore.ieee.org/document/9447136](https://ieeexplore.ieee.org/document/9447136)|
* All indexed publications by author: [https://orcid.org/0000-0001-5594-9756](https://orcid.org/0000-0001-5594-9756)

## Design Objectives
1. The platform shall be portable.
    1. All deployment-specific attributes shall be specifiable at deployment time (e.g. from a pipeline)
1. Test automation shall be implemented early and where practical.
1. Free and Open-Source technologies shall be leveraged.
1. Behavior and results are measurable and repeatable.

## Implementation Road Map
|Item|Implementation Status|Documentation Status|Pipeline Execution|
|---|---|---|---|
|Scripted generation of root certificate authority.|&#9745;|&#9745;|&#9745;|
|Scripted generation of node certificate signed by generated root certificate authority.|&#9745;|&#9745;||
|Creation of Hyperledger Node|&#9745;|&#9745;||
|Creation of hybrid Hyperledger/IPFS Cluster|&#9745;|&#9745;||
|Creation of RESTful API|&#9745;|&#9745;|&#9745;|
|Creation of Chaincode|&#9745;|&#9745;|&#9745;|
|Enable Communication of Multiple Nodes on a common Network|   |   |   |
|Defining and Executing Simulations|In Progress|   |   |
|Gathering Key Performance Indicators (KPIs) via OpenTelemetry|   |   |   |

## Near-Term Items
1. Metrics trending

## Future Development Goals
1. Add log aggregation.
1. Clean up the form of API return values.
1. Add Infrastructure as Code (IaC) configuration.
1. Diagnose/correct Java-based chaincode connectivity issues (may be due to proxy on corporate network or TLS configuration).
1. Enable communication of multiple nodes across disparate networks.
1. Enable role-based authorization.
1. Enable TLS for chaincode.
1. Enable use of specified Certificate Authority.

## References
* Hyperledger Fabric Cheat Sheet: [https://softwaremill.com/hyperledger-fabric-cheat-sheet/](https://softwaremill.com/hyperledger-fabric-cheat-sheet/)
* Markdown Editor: [https://jbt.github.io/markdown-editor/](https://jbt.github.io/markdown-editor/)
* K9s - Kubernetes CLI To Manage Your Clusters In Style!: [https://k9scli.io/](https://k9scli.io/)
* kind: [https://kind.sigs.k8s.io/](https://kind.sigs.k8s.io/)
* Kubernetes Cheat Sheet: [https://kubernetes.io/docs/reference/kubectl/cheatsheet/](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
* Obsidian: [https://obsidian-lang.com/](https://obsidian-lang.com/)
* Obsidian Tutorial: [https://obsidian.readthedocs.io/en/latest/tutorial/tutorial.html](https://obsidian.readthedocs.io/en/latest/tutorial/tutorial.html)
* Swagger Editor: [https://editor.swagger.io/](https://editor.swagger.io/)
* Technology Readiness Level (TRL): [https://en.wikipedia.org/wiki/Technology_readiness_level](https://en.wikipedia.org/wiki/Technology_readiness_level)
* Taking IPFS Nodes Online: [https://docs.ipfs.io/how-to/command-line-quick-start/#take-your-node-online](https://docs.ipfs.io/how-to/command-line-quick-start/#take-your-node-online)
* Exchanging Files Between IPFS Nodes: [https://docs.ipfs.io/how-to/exchange-files-between-nodes/](https://docs.ipfs.io/how-to/exchange-files-between-nodes/)
* Making HTTP Requests in Golang: [https://medium.com/@masnun/making-http-requests-in-golang-dd123379efe7](https://medium.com/@masnun/making-http-requests-in-golang-dd123379efe7)
* Go IPFS API: [https://github.com/ipfs/go-ipfs-api](https://github.com/ipfs/go-ipfs-api)
* Hyperledger Explorer: [https://github.com/hyperledger/blockchain-explorer](https://github.com/hyperledger/blockchain-explorer)
* Kubernetes Dashboard: [https://github.com/kubernetes/dashboard](https://github.com/kubernetes/dashboard)
* Kubernetes Metrics Server: [https://github.com/kubernetes-sigs/metrics-server](https://github.com/kubernetes-sigs/metrics-server)
* YAML Lint: [http://www.yamllint.com/](http://www.yamllint.com/)
* Graphviz Online [https://dreampuf.github.io/GraphvizOnline/] (https://dreampuf.github.io/GraphvizOnline/)
* Examples -- graphviz 0.20 documentation [https://graphviz.readthedocs.io/en/stable/examples.html] (https://graphviz.readthedocs.io/en/stable/examples.html)
* Drawing graphs with dot [https://www.graphviz.org/pdf/dotguide.pdf] (https://www.graphviz.org/pdf/dotguide.pdf)
