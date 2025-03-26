# CareBlock Smart Contracts

This directory contains the smart contracts that power the CareBlock healthcare platform.

## Contract Architecture

The CareBlock platform uses a single upgradeable smart contract: `HealthcareUpgradeable.sol`.

### HealthcareUpgradeable.sol

This is the main contract that handles all healthcare-related functionality. It is designed using the UUPS (Universal Upgradeable Proxy Standard) pattern from OpenZeppelin, which allows for future upgrades without losing data.

## User Roles

The contract implements three user roles:

1. **Patient**: Can add and manage their own medical records and grant/revoke access to doctors
2. **Doctor**: Can view patient records if granted access
3. **Admin**: Can register doctors and manage the system

## Key Features

### User Management

- Registration of patients, doctors, and admins
- Authentication via address-based ownership
- Role-based access control

### Patient Records

- Secure storage of patient information
- Medical history tracking
- Media file references (via IPFS)
- Patient record updates

### Access Control

- Patients can grant doctors access to their records
- Access can be revoked at any time
- Records are only accessible to authorized parties

### Security Features

- Secure patient code generation
- Role-based permission checking
- Efficient data organization

## Smart Contract Functions

### User Registration

| Function | Description | Access Control |
|----------|-------------|----------------|
| `registerDoctor(address)` | Register a new doctor | Admin/Owner |
| `registerPatient(address)` | Register a new patient | Anyone |
| `registerAdmin(address)` | Register a new admin | Owner |

### Patient Records

| Function | Description | Access Control |
|----------|-------------|----------------|
| `addPatient(name, age, history)` | Add a new patient record | Patient |
| `updatePatient(code, name, age, history)` | Update patient record | Patient (owner) |
| `addPatientMedia(code, ipfsHash, mediaType)` | Add media to patient record | Patient (owner) |
| `removePatientMedia(code, index)` | Remove media from patient record | Patient (owner) |

### Access Control

| Function | Description | Access Control |
|----------|-------------|----------------|
| `grantAccess(doctor, code)` | Grant doctor access to patient | Patient (owner) |
| `revokeAccess(doctor, code)` | Revoke doctor's access | Patient (owner) |

### Data Retrieval

| Function | Description | Access Control |
|----------|-------------|----------------|
| `getPatient(code)` | Get patient information | Patient/Doctor/Admin/Owner |
| `getPatientMedia(code, index)` | Get patient media | Patient/Doctor/Admin/Owner |
| `getPatientCodesByAddress(address)` | Get patient codes by address | Patient/Doctor/Admin/Owner |

### Admin Functions

| Function | Description | Access Control |
|----------|-------------|----------------|
| `grantAdminRole(account)` | Grant admin role | Owner |
| `revokeAdminRole(account)` | Revoke admin role | Owner |
| `_authorizeUpgrade(address)` | Authorize contract upgrade | Owner |

## Development and Testing

The smart contracts are developed using Hardhat and can be tested with the following command:

```bash
npx hardhat test
```

## Contract Upgradeability

The contract follows the UUPS (Universal Upgradeable Proxy Standard) pattern and can be upgraded by:

1. Deploying a new implementation contract
2. Calling the upgrade function on the proxy contract

This allows for future improvements without losing existing data.

## Security Considerations

- The contract uses OpenZeppelin's battle-tested libraries
- Access control is carefully implemented for each function
- Patient code generation uses multiple entropy sources
- Comprehensive input validation for all functions:
  - Age must be between 1 and 150
  - Name and medical history cannot be empty
  - IPFS hashes and media types must be valid
- Data is organized for gas efficiency 