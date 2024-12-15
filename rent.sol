// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RentPayment {

    address public landlord;
    address public tenant;
    uint256 public rentAmount;  // Monthly rent amount in wei
    uint256 public dueDate;     // Due date for rent payment (timestamp)
    uint256 public penalty;     // Penalty for late payments in wei

    // Events to emit for logging purposes
    event RentPaid(address indexed tenant, uint256 amount, uint256 date);
    event LatePayment(address indexed tenant, uint256 penaltyAmount, uint256 date);
    event TenantSet(address indexed tenant);

    modifier onlyTenant() {
        require(msg.sender == tenant, "Only tenant can call this function.");
        _;
    }

    modifier onlyLandlord() {
        require(msg.sender == landlord, "Only landlord can call this function.");
        _;
    }

    constructor() {
        landlord = msg.sender;  // The person deploying the contract is the landlord
    }

    // Function for the landlord to set the tenant's address
    function setTenant(address _tenant) external onlyLandlord {
        tenant = _tenant;
        emit TenantSet(tenant);
    }

    // Function for the landlord to set rent details
    function setRentDetails(uint256 _rentAmount, uint256 _dueInDays, uint256 _penalty) external onlyLandlord {
        rentAmount = _rentAmount;
        penalty = _penalty;
        dueDate = block.timestamp + (_dueInDays * 1 days);  // Calculate due date based on input days
    }

    // Function for tenant to pay rent
    function payRent() external payable onlyTenant {
        uint256 totalAmount = rentAmount;

        // If payment is late, add penalty
        if (block.timestamp > dueDate) {
            totalAmount += penalty;
            emit LatePayment(tenant, penalty, block.timestamp);
        }

        require(msg.value >= totalAmount, "Insufficient funds sent for rent payment.");

        // Transfer rent + penalty to landlord in one go
        payable(landlord).transfer(totalAmount);

        // Update due date to the next month after payment
        dueDate = block.timestamp + 30 days;  // Set next month's due date

        emit RentPaid(tenant, msg.value, block.timestamp);
    }

    // Function for landlord to withdraw contract funds (in case of excess)
    function withdrawFunds() external onlyLandlord {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw.");
        payable(landlord).transfer(balance);
    }

    // Function to check if rent is paid for the current month
    function isRentPaid() external view returns (bool) {
        uint256 expectedPayment = rentAmount;
        if (block.timestamp > dueDate) {
            expectedPayment += penalty;  // Add penalty if the payment is late
        }
        return (address(this).balance >= expectedPayment);  // Check if the contract balance has received the correct payment
    }

    // Function to check the current rent due (including penalties)
    function getCurrentRentDue() external view returns (uint256) {
        if (block.timestamp > dueDate) {
            return rentAmount + penalty;  // Rent + penalty if late
        }
        return rentAmount;
    }

    // Function to get the due date in a human-readable format
    function getDueDate() external view returns (uint256) {
        return dueDate;  // Return the due date timestamp
    }
}
