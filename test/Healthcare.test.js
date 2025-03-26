const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("HealthcareUpgradeable", function () {
  let healthcareContract;
  let owner;
  let doctor;
  let patient;
  let admin;
  let patientCode;

  // Utility function to convert user type to enum
  function userTypeToString(userType) {
    return ["Doctor", "Patient", "Admin"][userType];
  }

  beforeEach(async function () {
    // Get signers
    [owner, doctor, patient, admin] = await ethers.getSigners();

    // Deploy the contract
    const HealthcareUpgradeable = await ethers.getContractFactory(
      "HealthcareUpgradeable"
    );
    healthcareContract = await upgrades.deployProxy(
      HealthcareUpgradeable,
      [owner.address],
      {
        initializer: "initialize",
        kind: "uups",
      }
    );
    await healthcareContract.waitForDeployment();
  });

  describe("User Registration", function () {
    it("Should register a doctor", async function () {
      // Register doctor by owner
      await healthcareContract.registerDoctor(doctor.address);

      // Check doctor registration
      const [userType, isRegistered] = await healthcareContract.getUserType(
        doctor.address
      );
      expect(isRegistered).to.equal(true);
      expect(userTypeToString(userType)).to.equal("Doctor");
    });

    it("Should register a patient", async function () {
      // Register patient
      await healthcareContract
        .connect(patient)
        .registerPatient(patient.address);

      // Check patient registration
      const [userType, isRegistered] = await healthcareContract.getUserType(
        patient.address
      );
      expect(isRegistered).to.equal(true);
      expect(userTypeToString(userType)).to.equal("Patient");
    });

    it("Should register an admin", async function () {
      // Register admin by owner
      await healthcareContract.registerAdmin(admin.address);

      // Check admin registration
      const [userType, isRegistered] = await healthcareContract.getUserType(
        admin.address
      );
      expect(isRegistered).to.equal(true);
      expect(userTypeToString(userType)).to.equal("Admin");
    });

    it("Should not allow non-admins to register doctors", async function () {
      // Try to register doctor by non-admin
      await expect(
        healthcareContract.connect(patient).registerDoctor(doctor.address)
      ).to.be.revertedWith("Caller is not an admin or owner");
    });
  });

  describe("Patient Record Management", function () {
    beforeEach(async function () {
      // Register patient
      await healthcareContract
        .connect(patient)
        .registerPatient(patient.address);
    });

    it("Should add a patient record", async function () {
      // Add patient record
      const tx = await healthcareContract
        .connect(patient)
        .addPatient("John Doe", 30, "Patient with high blood pressure");
      const receipt = await tx.wait();

      // Find PatientAdded event
      const patientAddedEvent = receipt.logs.find(
        (log) => log.fragment && log.fragment.name === "PatientAdded"
      );

      // Get patientCode from event
      patientCode = patientAddedEvent.args.patientCode;

      // Verify patient record
      const patientRecord = await healthcareContract
        .connect(patient)
        .getPatient(patientCode);
      expect(patientRecord[0]).to.equal("John Doe"); // name
      expect(patientRecord[1]).to.equal(30); // age
      expect(patientRecord[3]).to.equal(0); // mediaCount (initially 0)
    });

    it("Should update a patient record", async function () {
      // First add patient record
      const tx = await healthcareContract
        .connect(patient)
        .addPatient("John Doe", 30, "Patient with high blood pressure");
      const receipt = await tx.wait();

      // Find PatientAdded event
      const patientAddedEvent = receipt.logs.find(
        (log) => log.fragment && log.fragment.name === "PatientAdded"
      );

      // Get patientCode from event
      patientCode = patientAddedEvent.args.patientCode;

      // Update patient record
      await healthcareContract
        .connect(patient)
        .updatePatient(
          patientCode,
          "John Smith",
          35,
          "Updated medical history"
        );

      // Verify updated record
      const patientRecord = await healthcareContract
        .connect(patient)
        .getPatient(patientCode);
      expect(patientRecord[0]).to.equal("John Smith"); // updated name
      expect(patientRecord[1]).to.equal(35); // updated age
    });
  });

  describe("Access Control", function () {
    beforeEach(async function () {
      // Register doctor
      await healthcareContract.registerDoctor(doctor.address);

      // Register patient
      await healthcareContract
        .connect(patient)
        .registerPatient(patient.address);

      // Add patient record
      const tx = await healthcareContract
        .connect(patient)
        .addPatient("John Doe", 30, "Patient with high blood pressure");
      const receipt = await tx.wait();

      // Find PatientAdded event
      const patientAddedEvent = receipt.logs.find(
        (log) => log.fragment && log.fragment.name === "PatientAdded"
      );

      // Get patientCode from event
      patientCode = patientAddedEvent.args.patientCode;
    });

    it("Should grant access to a doctor", async function () {
      // Grant access to doctor
      await healthcareContract
        .connect(patient)
        .grantAccess(doctor.address, patientCode);

      // Doctor should be able to access patient record
      const patientRecord = await healthcareContract
        .connect(doctor)
        .getPatient(patientCode);
      expect(patientRecord[0]).to.equal("John Doe");
    });

    it("Should revoke access from a doctor", async function () {
      // Grant access to doctor
      await healthcareContract
        .connect(patient)
        .grantAccess(doctor.address, patientCode);

      // Revoke access
      await healthcareContract
        .connect(patient)
        .revokeAccess(doctor.address, patientCode);

      // Doctor should not be able to access patient record
      await expect(
        healthcareContract.connect(doctor).getPatient(patientCode)
      ).to.be.revertedWith("Doctor does not have access to this patient");
    });

    it("Should not allow unauthorized access to patient records", async function () {
      // Another user trying to access patient record
      const [, , , , unauthorizedUser] = await ethers.getSigners();

      await expect(
        healthcareContract.connect(unauthorizedUser).getPatient(patientCode)
      ).to.be.revertedWith("Unauthorized access");
    });
  });

  describe("Admin Functions", function () {
    it("Should allow owner to grant admin role", async function () {
      await healthcareContract.grantAdminRole(admin.address);

      // Register admin in the system
      await healthcareContract.registerAdmin(admin.address);

      // Admin should be able to register a doctor
      await healthcareContract.connect(admin).registerDoctor(doctor.address);

      // Verify doctor was registered
      const [userType, isRegistered] = await healthcareContract.getUserType(
        doctor.address
      );
      expect(isRegistered).to.equal(true);
      expect(userTypeToString(userType)).to.equal("Doctor");
    });

    it("Should allow owner to revoke admin role", async function () {
      // Register and grant admin role
      await healthcareContract.registerAdmin(admin.address);

      // Revoke admin role
      await healthcareContract.revokeAdminRole(admin.address);

      // Admin should no longer be able to register doctors
      await expect(
        healthcareContract.connect(admin).registerDoctor(doctor.address)
      ).to.be.revertedWith("Caller is not an admin or owner");
    });
  });
});
