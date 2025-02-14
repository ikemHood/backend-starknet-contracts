# Cairo Backend for StarkNet Smart Contracts

This repository contains the backend for developing and deploying smart contracts on **StarkNet** using **Cairo**. The backend provides functionalities for creating, managing, and deploying smart contracts, along with utilities to interact with StarkNet's blockchain.

---

## Features

- Develop smart contracts using Cairo.
- Compile and deploy contracts to StarkNet.
- Interact with deployed contracts (read/write operations).
- Integrated testing utilities for Cairo contracts.
- Scripts for automating deployments and contract management.

---
## Contributing
Contributions are welcome! Please follow the steps below:

Fork the repository.
Create a feature branch. this got to be feat/name-of-branch
Commit your changes. feat:changes
Open a pull request.

## Prerequisites

To get started, ensure you have the following installed:

- **Python** >= 3.9
- **Cairo-lang**: [Installation Guide](https://www.cairo-lang.org/)
- **StarkNet CLI**: [Quickstart](https://www.cairo-lang.org/docs/quickstart.html#starknet-cli)
- **Node.js** >= 14 (for optional utilities)
- **pip**: For managing Python dependencies

---

## Installation and Setup

1. Fork and then clone the repository:

   ```bash
   git clone https://github.com/yourusername/cairo-backend.git
   cd cairo-backend

2. usage 
## Compile a contract 
starknet-compile path/to/contract.cairo --output path/to/output.json
## Deploy a contract
starknet deploy --contract path/to/output.json --network testnet
3. Test contracts 
pytest tests/
## IMPORTANT!!
Each contract, connection or backend contributing must come with their own test to check up funcionality!
