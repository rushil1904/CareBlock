# CareBlock: Blockchain-Based Healthcare Records Management

CareBlock is a decentralized healthcare records management system built on blockchain technology that allows patients to securely store, manage, and selectively share their medical records with healthcare providers.

Check the following walkthrough video:

![CareBlock](https://github.com/rushil1904/CareBlock/blob/main/Untitled%20design%20(7).png?raw=true)

## 🚀 Features

- **Secure Medical Record Storage**: Patients can store their medical records securely on the blockchain with access control
- **Role-Based Access Control**: Three user types (Patient, Doctor, Admin) with different permissions
- **IPFS Media Storage**: Support for storing medical media (images, videos, PDFs) on IPFS
- **Doctor-Patient Relationship Management**: Patients can grant and revoke access to specific doctors
- **Upgradeable Smart Contracts**: Using OpenZeppelin's UUPS pattern for future improvements
- **Modern Web Interface**: React-based frontend with Tailwind CSS styling
- **MetaMask Integration**: Easy authentication and blockchain interaction
- **Backend API**: Express server for secure IPFS uploads and future functionality
- **Comprehensive Test Suite**: Automated tests for smart contracts

## 🛠️ Technology Stack

### Smart Contract
- Solidity 0.8.21+
- OpenZeppelin Contracts & Upgradeable Contracts
- Hardhat & Truffle Development Frameworks

### Frontend
- React 18
- Tailwind CSS
- Web3.js / Ethers.js
- FilePond for file uploads

### Backend
- Express.js
- Multer for file uploads
- Axios for API calls

### Storage
- IPFS/Pinata for decentralized file storage
- Ethereum blockchain for records and permissions

### Security
- Role-based access control
- Secure random patient code generation
- Environment variable configuration
- Backend proxy for third-party API calls

## 📋 Prerequisites

- Node.js (v16+)
- npm or yarn
- MetaMask browser extension
- Ganache or other Ethereum development network
- Pinata account (for IPFS storage)

## 🔧 Installation & Setup

1. **Clone the repository**

```bash
git clone https://github.com/yourusername/careblock.git
cd careblock
```

2. **Install dependencies**

```bash
# Install root project dependencies
npm install

# Install frontend dependencies
cd healthcare-dapp
npm install
cd ..
```

3. **Environment setup**

```bash
# Create .env file from template
cp .env.example .env
```

Edit the `.env` file with your configuration values:
- Set your development network URL
- Configure your private keys (for development only)
- Add your Pinata API keys

4. **Setup a local blockchain network**

You can use Ganache UI or CLI:
```bash
# Install Ganache globally
npm install -g ganache-cli

# Run Ganache
ganache-cli
```

5. **Compile and deploy smart contracts**

```bash
# Compile contracts
npx hardhat compile

# Run tests
npx hardhat test

# Deploy contracts
npx hardhat run scripts/deploy.js --network development
```

6. **Start the application**

```bash
# Start the frontend and backend concurrently
cd healthcare-dapp
npm run dev
```

The frontend will be available at http://localhost:3000 and the backend API at http://localhost:3001.

## 🧪 Testing

CareBlock includes comprehensive automated tests:

```bash
# Run smart contract tests
npx hardhat test

# Run frontend component tests
cd healthcare-dapp
npm test
```

## 📚 Documentation

- [API Documentation](./API.md) - Details on backend API endpoints
- [Smart Contract Documentation](./contracts/README.md) - Smart contract specifications
- [Improvements](./IMPROVEMENTS.md) - Summary of improvements made to the codebase

## 🚦 Usage

### User Registration
1. Connect your MetaMask wallet
2. Register as a Patient or Doctor
3. For Doctor registration, an Admin approval is required

### Patient Operations
- Add medical records and history
- Upload medical media files (images, PDFs, etc.)
- Grant and revoke access to doctors
- View and manage your medical history

### Doctor Operations
- View patient records (with permission)
- Browse patient medical history and media

### Admin Operations
- Approve new doctors
- Manage user access and permissions

## 🔐 Security Measures

CareBlock implements several security best practices:
- No hardcoded secrets in the codebase
- Environment-based configuration
- Secure patient code generation using multiple entropy sources
- Backend proxy for third-party API calls to protect API keys
- Comprehensive access control on smart contracts
- Data validation and sanitization

## 🛣️ Roadmap

- [ ] Mobile application
- [ ] Integration with existing healthcare systems (FHIR support)
- [ ] Enhanced analytics for medical data
- [ ] Multi-language support
- [ ] Advanced medical record search capabilities

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📬 Contact

Project Link: [https://github.com/rushil1904/CareBlock](https://github.com/rushil1904/CareBlock)

## 🗂️ Project Structure

```
/
├── contracts/               # Smart contract code
│   ├── Healthcare.sol       # Main healthcare smart contract
│   └── README.md            # Smart contract documentation
│
├── healthcare-dapp/         # Frontend application
│   ├── public/              # Static assets
│   ├── server/              # Backend API for file uploads
│   │   └── index.js         # Express server implementation
│   └── src/                 # Source code
│       ├── assets/          # Images, fonts, etc.
│       ├── components/      # React components
│       └── artifacts/       # Smart contract ABIs
│
├── migrations/              # Contract deployment migrations
│   └── 2_deploy_contracts.js # Deployment script for Healthcare contract
│
├── scripts/                 # Utility and deployment scripts
│   └── deploy.js            # Hardhat deployment script
│
├── test/                    # Test files
│   └── Healthcare.test.js   # Tests for Healthcare contract
│
├── .env.example             # Template for environment variables
├── API.md                   # API documentation
├── IMPROVEMENTS.md          # Summary of code improvements
├── LICENSE                  # MIT License
└── README.md                # This file
```

---

<p align="center">Built with ❤️ for better healthcare data management</p> 