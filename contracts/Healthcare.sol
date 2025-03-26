// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title HealthcareUpgradeable
 * @dev A healthcare records management system on blockchain
 * @notice This contract allows patients to store medical records and control doctor access
 * @custom:security-contact admin@careblock.io
 * @custom:upgradeable Uses UUPS upgradeable pattern for future extensibility
 */
contract HealthcareUpgradeable is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    enum UserType { Doctor, Patient, Admin }

    struct User {
        UserType userType;
        bool isRegistered;
    }

    struct Media {
        string ipfsHash;
        string mediaType; // "image", "video", or "pdf"
    }

    struct Patient {
        string name;
        uint256 age;
        bytes32 medicalHistoryHash;
        mapping(uint256 => Media) media;
        uint256 mediaCount;
        bool exists;
    }

    // State variables
    mapping(address => User) private users;
    EnumerableSet.AddressSet private doctors;
    mapping(bytes32 => Patient) private patients;
    mapping(address => bytes32[]) private patientsByAddress;
    mapping(address => mapping(bytes32 => bool)) private doctorPatientAccess;
    mapping(address => bool) private adminRoles;
    mapping(address => mapping(bytes32 => bool)) private patientCodeOwnership;

    uint256 private codeCounter;
    // Random seed for more secure patient code generation
    bytes32 private seed;

    // Events
    event DoctorAdded(address indexed doctor);
    event DoctorRemoved(address indexed doctor);
    event PatientAdded(address indexed patient, string name, bytes32 patientCode);
    event PatientUpdated(address indexed patient, string name, bytes32 patientCode);
    event PatientMediaAdded(address indexed patient, bytes32 indexed patientCode, string mediaType);
    event PatientMediaRemoved(address indexed patient, bytes32 indexed patientCode, uint256 mediaIndex);
    event AccessGranted(address indexed doctor, address indexed patient);
    event AccessRevoked(address indexed doctor, address indexed patient);
    event AdminRoleGranted(address indexed account);
    event AdminRoleRevoked(address indexed account);
    event UserRegistered(address indexed user, UserType userType);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the contract
     * @param initialOwner The address of the initial owner/admin
     */
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        adminRoles[initialOwner] = true;
        seed = keccak256(abi.encodePacked(block.prevrandao, block.timestamp));
        emit AdminRoleGranted(initialOwner);
    }

    /**
     * @dev Modifier to restrict function access to doctors only
     */
    modifier onlyDoctor() {
        require(users[msg.sender].isRegistered && users[msg.sender].userType == UserType.Doctor, "Caller is not a doctor");
        _;
    }

    /**
     * @dev Modifier to restrict function access to admins or the contract owner
     */
    modifier onlyAdminOrOwner() {
        require(
            (users[msg.sender].isRegistered && users[msg.sender].userType == UserType.Admin) || owner() == msg.sender,
            "Caller is not an admin or owner"
        );
        _;
    }

    /**
     * @notice Register a new doctor in the system
     * @param _doctor Address of the doctor to register
     */
    function registerDoctor(address _doctor) external onlyAdminOrOwner {
        require(_doctor != address(0), "Invalid doctor address");
        require(!users[_doctor].isRegistered, "User already registered");
        users[_doctor] = User(UserType.Doctor, true);
        doctors.add(_doctor);
        emit UserRegistered(_doctor, UserType.Doctor);
        emit DoctorAdded(_doctor);
    }

    /**
     * @notice Register a new patient in the system
     * @param _patient Address of the patient to register
     */
    function registerPatient(address _patient) external {
        require(_patient != address(0), "Invalid patient address");
        require(!users[_patient].isRegistered, "User already registered");
        users[_patient] = User(UserType.Patient, true);
        emit UserRegistered(_patient, UserType.Patient);
    }

    /**
     * @notice Register a new admin in the system
     * @param _admin Address of the admin to register
     */
    function registerAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "Invalid admin address");
        require(!users[_admin].isRegistered, "User already registered");
        users[_admin] = User(UserType.Admin, true);
        adminRoles[_admin] = true;
        emit UserRegistered(_admin, UserType.Admin);
        emit AdminRoleGranted(_admin);
    }

    /**
     * @notice Remove a doctor from the system
     * @param _doctor Address of the doctor to remove
     */
    function removeDoctor(address _doctor) external onlyAdminOrOwner {
        require(users[_doctor].isRegistered && users[_doctor].userType == UserType.Doctor, "Not a registered doctor");
        delete users[_doctor];
        doctors.remove(_doctor);
        emit DoctorRemoved(_doctor);
    }

    /**
     * @notice Add a new patient record
     * @param _name Patient's name
     * @param _age Patient's age
     * @param _medicalHistory Medical history description
     * @return patientCode Unique identifier for the patient record
     */
    function addPatient(string calldata _name, uint256 _age, string calldata _medicalHistory) 
        external returns (bytes32 patientCode) {
        require(users[msg.sender].isRegistered && users[msg.sender].userType == UserType.Patient, 
            "Caller is not a registered patient");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(_age > 0 && _age < 150, "Age must be between 1 and 150");
        require(bytes(_medicalHistory).length > 0, "Medical history cannot be empty");
        
        bytes32 medicalHistoryHash = keccak256(abi.encodePacked(_medicalHistory));
        
        // Generate a more secure unique code for the patient entry using multiple entropy sources
        // This approach uses a combination of:
        // 1. Previous seed value (which gets updated with each patient addition)
        // 2. block.prevrandao (Ethereum's randomness source after the merge)
        // 3. msg.sender (user's address)
        // 4. block.timestamp (current timestamp)
        // 5. codeCounter (sequential counter)
        // Making it significantly more secure against prediction attacks
        seed = keccak256(abi.encodePacked(seed, block.prevrandao, msg.sender, block.timestamp, codeCounter));
        patientCode = seed;
        codeCounter++;

        // Create a new patient entry
        Patient storage newPatient = patients[patientCode];
        newPatient.name = _name;
        newPatient.age = _age;
        newPatient.medicalHistoryHash = medicalHistoryHash;
        newPatient.mediaCount = 0;
        newPatient.exists = true;

        // Add the patient code to the sender's list of patients
        patientsByAddress[msg.sender].push(patientCode);
        patientCodeOwnership[msg.sender][patientCode] = true;

        emit PatientAdded(msg.sender, _name, patientCode);
        return patientCode;
    }

    /**
     * @notice Add media to a patient record
     * @param _patientCode Unique identifier for the patient
     * @param _ipfsHash IPFS hash where the media is stored
     * @param _mediaType Type of media (image, video, pdf)
     * @return mediaIndex Index of the added media
     */
    function addPatientMedia(bytes32 _patientCode, string memory _ipfsHash, string memory _mediaType) 
        external returns (uint256 mediaIndex) {
        require(users[msg.sender].isRegistered && users[msg.sender].userType == UserType.Patient, 
            "Caller is not a registered patient");
        require(patients[_patientCode].exists, "Patient does not exist");
        require(patientCodeOwnership[msg.sender][_patientCode], "Not authorized to modify this patient");
        require(bytes(_ipfsHash).length > 0, "IPFS hash cannot be empty");
        require(bytes(_mediaType).length > 0, "Media type cannot be empty");
        
        mediaIndex = patients[_patientCode].mediaCount;
        patients[_patientCode].media[mediaIndex] = Media(_ipfsHash, _mediaType);
        patients[_patientCode].mediaCount++;
        
        emit PatientMediaAdded(msg.sender, _patientCode, _mediaType);
        return mediaIndex;
    }

    /**
     * @notice Remove media from a patient record
     * @param _patientCode Unique identifier for the patient
     * @param _mediaIndex Index of the media to remove
     */
    function removePatientMedia(bytes32 _patientCode, uint256 _mediaIndex) external {
        require(users[msg.sender].isRegistered && users[msg.sender].userType == UserType.Patient, 
            "Caller is not a registered patient");
        require(patients[_patientCode].exists, "Patient does not exist");
        require(patientCodeOwnership[msg.sender][_patientCode], "Not authorized to modify this patient");
        require(_mediaIndex < patients[_patientCode].mediaCount, "Media index out of bounds");
        
        // Shift all elements after the removed index down by one
        for (uint256 i = _mediaIndex; i < patients[_patientCode].mediaCount - 1; i++) {
            patients[_patientCode].media[i] = patients[_patientCode].media[i + 1];
        }
        
        // Delete the last element and decrement the count
        delete patients[_patientCode].media[patients[_patientCode].mediaCount - 1];
        patients[_patientCode].mediaCount--;
        
        emit PatientMediaRemoved(msg.sender, _patientCode, _mediaIndex);
    }

    /**
     * @notice Update an existing patient record
     * @param _patientCode Unique identifier for the patient
     * @param _name Patient's name
     * @param _age Patient's age
     * @param _medicalHistory Medical history description
     */
    function updatePatient(bytes32 _patientCode, string calldata _name, uint256 _age, string calldata _medicalHistory) external {
        require(users[msg.sender].isRegistered && users[msg.sender].userType == UserType.Patient, 
            "Caller is not a registered patient");
        require(patients[_patientCode].exists, "Patient does not exist");
        require(patientCodeOwnership[msg.sender][_patientCode], "Not authorized to modify this patient");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(_age > 0 && _age < 150, "Age must be between 1 and 150");
        require(bytes(_medicalHistory).length > 0, "Medical history cannot be empty");
        
        bytes32 medicalHistoryHash = keccak256(abi.encodePacked(_medicalHistory));
        
        Patient storage patient = patients[_patientCode];
        patient.name = _name;
        patient.age = _age;
        patient.medicalHistoryHash = medicalHistoryHash;
        
        emit PatientUpdated(msg.sender, _name, _patientCode);
    }

    /**
     * @notice Grant a doctor access to a patient record
     * @param _doctor Address of the doctor
     * @param _patientCode Unique identifier for the patient
     */
    function grantAccess(address _doctor, bytes32 _patientCode) external {
        require(patientCodeOwnership[msg.sender][_patientCode], "Not authorized to grant access to this patient");
        require(doctors.contains(_doctor), "Not a valid doctor");
        require(!doctorPatientAccess[_doctor][_patientCode], "Access already granted");
        doctorPatientAccess[_doctor][_patientCode] = true;
        emit AccessGranted(_doctor, msg.sender);
    }

    /**
     * @notice Revoke a doctor's access to a patient record
     * @param _doctor Address of the doctor
     * @param _patientCode Unique identifier for the patient
     */
    function revokeAccess(address _doctor, bytes32 _patientCode) external {
        require(patientCodeOwnership[msg.sender][_patientCode], "Not authorized to revoke access to this patient");
        require(doctors.contains(_doctor), "Not a valid doctor");
        require(doctorPatientAccess[_doctor][_patientCode], "Access not found");
        doctorPatientAccess[_doctor][_patientCode] = false;
        emit AccessRevoked(_doctor, msg.sender);
    }

    /**
     * @notice Get patient information
     * @param _patientCode Unique identifier for the patient
     * @return name Patient's name
     * @return age Patient's age
     * @return medicalHistoryHash Hash of the medical history
     * @return mediaCount Number of media files attached
     */
    function getPatient(bytes32 _patientCode) external view returns (
        string memory name,
        uint256 age,
        bytes32 medicalHistoryHash,
        uint256 mediaCount
    ) {
        require(patients[_patientCode].exists, "Patient not found");
        require(
            doctors.contains(msg.sender) || adminRoles[msg.sender] || owner() == msg.sender || patientCodeOwnership[msg.sender][_patientCode],
            "Unauthorized access"
        );
        if (doctors.contains(msg.sender)) {
            require(doctorPatientAccess[msg.sender][_patientCode], "Doctor does not have access to this patient");
        }
        Patient storage patient = patients[_patientCode];
        return (patient.name, patient.age, patient.medicalHistoryHash, patient.mediaCount);
    }

    /**
     * @notice Get patient media information
     * @param _patientCode Unique identifier for the patient
     * @param index Index of the media to retrieve
     * @return ipfsHash IPFS hash of the media
     * @return mediaType Type of media (image, video, pdf)
     */
    function getPatientMedia(bytes32 _patientCode, uint256 index) external view returns (string memory ipfsHash, string memory mediaType) {
        require(patients[_patientCode].exists, "Patient not found");
        require(
            doctors.contains(msg.sender) || adminRoles[msg.sender] || owner() == msg.sender || patientCodeOwnership[msg.sender][_patientCode],
            "Unauthorized access"
        );
        if (doctors.contains(msg.sender)) {
            require(doctorPatientAccess[msg.sender][_patientCode], "Doctor does not have access to this patient");
        }
        require(index < patients[_patientCode].mediaCount, "Media index out of bounds");
        Media storage media = patients[_patientCode].media[index];
        return (media.ipfsHash, media.mediaType);
    }

    /**
     * @notice Get all patient codes associated with an address
     * @param _patientAddress Address of the patient
     * @return Array of patient codes for the given address
     */
    function getPatientCodesByAddress(address _patientAddress) external view returns (bytes32[] memory) {
        require(
            msg.sender == _patientAddress || 
            doctors.contains(msg.sender) || 
            adminRoles[msg.sender] || 
            owner() == msg.sender,
            "Unauthorized access"
        );
        return patientsByAddress[_patientAddress];
    }

    /**
     * @notice Grant admin role to an account
     * @param _account Address to grant admin role to
     */
    function grantAdminRole(address _account) external onlyOwner {
        require(_account != address(0), "Invalid address");
        adminRoles[_account] = true;
        emit AdminRoleGranted(_account);
    }

    /**
     * @notice Revoke admin role from an account
     * @param _account Address to revoke admin role from
     */
    function revokeAdminRole(address _account) external onlyOwner {
        require(_account != owner(), "Cannot revoke owner's admin role");
        adminRoles[_account] = false;
        emit AdminRoleRevoked(_account);
    }

    /**
     * @dev Function that should revert when msg.sender is not authorized to upgrade the contract
     * @param newImplementation Address of the new implementation
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @notice Log in a user and retrieve their user type
     * @return UserType of the caller
     */
    function login() external view returns (UserType) {
        require(users[msg.sender].isRegistered, "User not registered");
        return users[msg.sender].userType;
    }

    /**
     * @notice Get the user type of an address
     * @param _user Address to check
     * @return userType Type of the user
     * @return isRegistered Whether the user is registered
     */
    function getUserType(address _user) external view returns (UserType userType, bool isRegistered) {
        return (users[_user].userType, users[_user].isRegistered);
    }

    /**
     * @notice Check if a patient code is owned by an address
     * @param _address Address to check
     * @param _patientCode Patient code to verify
     * @return Whether the address owns the patient code
     */
    function isPatientCodeOwnedByAddress(address _address, bytes32 _patientCode) internal view returns (bool) {
        return patientCodeOwnership[_address][_patientCode];
    }
}