# CareBlock API Documentation

This document outlines the API endpoints available in the CareBlock backend server.

## Base URL

For local development: `http://localhost:3001`

## Authentication

Currently, the API uses frontend-based authentication with MetaMask. Future versions will implement proper backend authentication.

## Endpoints

### Health Check

Check if the API server is running.

```
GET /api/health
```

#### Response

```json
{
  "status": "OK",
  "message": "Server is running"
}
```

### File Upload

Upload a file to IPFS via Pinata.

```
POST /api/upload
```

#### Request

- Content-Type: `multipart/form-data`
- Body:
  - `file`: The file to upload (required)
- File Restrictions:
  - Allowed types: Images, videos, PDFs
  - Maximum size: 10MB

#### Response

Success (200 OK):

```json
{
  "ipfsHash": "QmX...",
  "url": "https://gateway.pinata.cloud/ipfs/QmX...",
  "success": true
}
```

Error (400 Bad Request):

```json
{
  "error": "No file uploaded",
  "success": false
}
```

Error (413 Payload Too Large):

```json
{
  "error": "File is too large. Maximum size is 10MB",
  "success": false
}
```

Error (415 Unsupported Media Type):

```json
{
  "error": "Unsupported file type. Only images, videos and PDFs are allowed",
  "success": false
}
```

Error (500 Internal Server Error):

```json
{
  "error": "Error message",
  "success": false
}
```

## Smart Contract API

The smart contract provides the following methods (accessed through the frontend):

### User Management

#### Register Patient

Register a new patient in the system.

```solidity
function registerPatient(address _patient) external
```

#### Register Doctor

Register a new doctor in the system (admin/owner only).

```solidity
function registerDoctor(address _doctor) external onlyAdminOrOwner
```

#### Register Admin

Register a new admin in the system (owner only).

```solidity
function registerAdmin(address _admin) external onlyOwner
```

### Patient Records

#### Add Patient

Add a new patient record.

```solidity
function addPatient(string calldata _name, uint256 _age, string calldata _medicalHistory) external returns (bytes32 patientCode)
```

#### Update Patient

Update an existing patient record.

```solidity
function updatePatient(bytes32 _patientCode, string calldata _name, uint256 _age, string calldata _medicalHistory) external
```

#### Add Patient Media

Add media to a patient record.

```solidity
function addPatientMedia(bytes32 _patientCode, string memory _ipfsHash, string memory _mediaType) external returns (uint256 mediaIndex)
```

#### Remove Patient Media

Remove media from a patient record.

```solidity
function removePatientMedia(bytes32 _patientCode, uint256 _mediaIndex) external
```

### Access Control

#### Grant Access

Allow a doctor to access a patient record.

```solidity
function grantAccess(address _doctor, bytes32 _patientCode) external
```

#### Revoke Access

Revoke a doctor's access to a patient record.

```solidity
function revokeAccess(address _doctor, bytes32 _patientCode) external
```

### Data Retrieval

#### Get Patient

Retrieve patient information.

```solidity
function getPatient(bytes32 _patientCode) external view returns (string memory name, uint256 age, bytes32 medicalHistoryHash, uint256 mediaCount)
```

#### Get Patient Media

Retrieve patient media information.

```solidity
function getPatientMedia(bytes32 _patientCode, uint256 index) external view returns (string memory ipfsHash, string memory mediaType)
```

#### Get Patient Codes By Address

Get all patient codes associated with an address.

```solidity
function getPatientCodesByAddress(address _patientAddress) external view returns (bytes32[] memory)
```

## Smart Contract Error Handling

The smart contract functions include various validations and will revert with specific error messages:

### User Management Errors

- `"Invalid doctor/patient/admin address"`: Address is zero
- `"User already registered"`: Attempting to register an already registered user
- `"Not a registered doctor"`: When trying to remove an address that is not a registered doctor

### Patient Record Errors

- `"Caller is not a registered patient"`: Only registered patients can manage patient records
- `"Name cannot be empty"`: Patient name must be provided
- `"Age must be between 1 and 150"`: Age validation error
- `"Medical history cannot be empty"`: Medical history must be provided
- `"Patient does not exist"`: When accessing a non-existent patient record
- `"Not authorized to modify this patient"`: When a user tries to modify another user's patient record
- `"IPFS hash cannot be empty"`: IPFS hash must be provided for media uploads
- `"Media type cannot be empty"`: Media type must be specified
- `"Media index out of bounds"`: When accessing a media item that doesn't exist

### Access Control Errors

- `"Caller is not a doctor"`: Only doctors can call doctor-specific functions
- `"Caller is not an admin or owner"`: Admin/owner-specific function called by unauthorized user
- `"Not authorized to grant/revoke access to this patient"`: Only record owners can manage access
- `"Not a valid doctor"`: Attempting to grant access to a non-doctor account
- `"Access already granted"`: Trying to grant access that's already been granted
- `"Access not found"`: Trying to revoke access that doesn't exist
- `"Doctor does not have access to this patient"`: Doctor trying to access a patient without permission
- `"Unauthorized access"`: General access control violation

### Admin Errors

- `"Cannot revoke owner's admin role"`: Attempting to revoke the owner's admin role

## Error Codes

The API returns standard HTTP error codes:

- `200 OK`: Request successful
- `400 Bad Request`: Invalid request parameters
- `401 Unauthorized`: Authentication required
- `403 Forbidden`: Access denied
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server-side error

## Rate Limiting

Currently, there is no rate limiting implemented. Future versions will include rate limiting to prevent abuse. 