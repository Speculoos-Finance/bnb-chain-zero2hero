// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Waitlist is Initializable, OwnableUpgradeable, PausableUpgradeable {
    mapping(address => bool) public waitlist;
    mapping(address => uint256) public registrationDates;
    mapping(address => uint256) public paidRegistrationFees;
    mapping(uint256 => address) public indexedWaitlist;
    mapping(bytes32 => uint256) public discountCodes;
    mapping(address => bool) public refundExceptions;
    mapping(address => bool) public blacklist;
    uint256 public waitlistLength;
    uint256 public registrationFee;
    uint256 public refundTimeSpan;

    event UserRegistered(address indexed user, uint256 waitlistIndex);
    event UserAddedByOwner(address indexed user, uint256 waitlistIndex);
    event UserRemovedByOwner(address indexed user);
    event AccessGranted(address indexed user);
    event RefundClaimed(address indexed user);
    event AccessGrantedToAll();
    event RefundTimeSpanUpdated(uint256 newRefundTimeSpan);
    event RegistrationPaused();
    event RegistrationResumed();
    event DiscountCodeAdded(bytes32 indexed code, uint256 discountPercentage);
    event DiscountCodeRemoved(bytes32 indexed code);
    event RefundExceptionAdded(address indexed user);
    event RefundExceptionRemoved(address indexed user);
    event UserBlacklisted(address indexed user);
    event UserUnblacklisted(address indexed user);
    event FundsTransferred(address indexed to, uint256 amount);
    event TokensRecovered(
        address indexed tokenAddress,
        address indexed to,
        uint256 amount
    );

    function initialize(uint256 _registrationFee, uint256 _refundTimeSpan)
        public
        initializer
    {
        __Ownable_init();
        __Pausable_init();

        registrationFee = _registrationFee;
        refundTimeSpan = _refundTimeSpan;
    }

    function register(bytes32 discountCode) public payable whenNotPaused {
        uint256 discountedRegistrationFee = getDiscountedRegistrationFee(
            discountCode
        );
        require(
            msg.value >= discountedRegistrationFee,
            "Insufficient registration fee"
        );
        require(!waitlist[msg.sender], "User is already registered");
        require(!blacklist[msg.sender], "User is blacklisted");

        waitlist[msg.sender] = true;
        indexedWaitlist[waitlistLength] = msg.sender;
        waitlistLength++;
        registrationDates[msg.sender] = block.timestamp;
        paidRegistrationFees[msg.sender] = msg.value;

        emit UserRegistered(msg.sender, waitlistLength - 1);
    }

    function getDiscountedRegistrationFee(bytes32 discountCode)
        public
        view
        returns (uint256)
    {
        uint256 discountPercentage = discountCodes[discountCode];
        return (registrationFee * (100 - discountPercentage)) / 100;
    }

    function addDiscountCode(bytes32 discountCode, uint256 discountPercentage)
        public
        onlyOwner
    {
        require(
            discountPercentage > 0 && discountPercentage < 100,
            "Discount percentage must be between 0 and 100"
        );
        discountCodes[discountCode] = discountPercentage;
        emit DiscountCodeAdded(discountCode, discountPercentage);
    }

    function removeDiscountCode(bytes32 discountCode) public onlyOwner {
        require(discountCodes[discountCode] > 0, "Discount code not found");
        delete discountCodes[discountCode];
        emit DiscountCodeRemoved(discountCode);
    }

    function claimRefund() public {
        require(isEligibleForRefund(msg.sender), "Refund is not available");

        uint256 refundAmount = paidRegistrationFees[msg.sender];
        registrationDates[msg.sender] = 0;
        waitlist[msg.sender] = false;
        paidRegistrationFees[msg.sender] = 0;
        payable(msg.sender).transfer(refundAmount);

        emit RefundClaimed(msg.sender);
    }

    function isEligibleForRefund(address user) public view returns (bool) {
        return ((registrationDates[user] > 0 &&
            block.timestamp <= registrationDates[user] + refundTimeSpan) ||
            refundExceptions[user]);
    }

    function grantAccess(address user) public onlyOwner {
        require(waitlist[user], "User is not on the waitlist");

        waitlist[user] = false;
        registrationDates[user] = 0;

        emit AccessGranted(user);
    }

    function grantAccessToAll() public onlyOwner {
        for (uint256 i = 0; i < waitlistLength; i++) {
            if (waitlist[indexedWaitlist[i]]) {
                waitlist[indexedWaitlist[i]] = false;
                registrationDates[indexedWaitlist[i]] = 0;

                emit AccessGranted(indexedWaitlist[i]);
            }
        }
        emit AccessGrantedToAll();
    }

    function updateRefundTimeSpan(uint256 newRefundTimeSpan) public onlyOwner {
        require(
            newRefundTimeSpan > 0,
            "Refund time span must be greater than zero"
        );

        refundTimeSpan = newRefundTimeSpan;
        emit RefundTimeSpanUpdated(newRefundTimeSpan);
    }

    function setRegistrationFee(uint256 _registrationFee) public onlyOwner {
        registrationFee = _registrationFee;
    }

    function pauseRegistrations() public onlyOwner {
        _pause();
        emit RegistrationPaused();
    }

    function resumeRegistrations() public onlyOwner {
        _unpause();
        emit RegistrationResumed();
    }

    function addRefundException(address user) public onlyOwner {
        require(waitlist[user], "User is not on the waitlist");
        refundExceptions[user] = true;
        emit RefundExceptionAdded(user);
    }

    function removeRefundException(address user) public onlyOwner {
        require(refundExceptions[user], "User is not an exception");
        refundExceptions[user] = false;
        emit RefundExceptionRemoved(user);
    }

    function batchRegisterUsers(address[] memory users) public onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            registerUser(users[i]);
        }
    }

    function batchDeregisterUsers(address[] memory users) public onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            deregisterUser(users[i]);
        }
    }

    function blacklistUser(address user) public onlyOwner {
        require(!blacklist[user], "User is already blacklisted");
        blacklist[user] = true;
        emit UserBlacklisted(user);
    }

    function unblacklistUser(address user) public onlyOwner {
        require(blacklist[user], "User is not blacklisted");
        blacklist[user] = false;
        emit UserUnblacklisted(user);
    }

    function registerUser(address user) public onlyOwner {
        require(!waitlist[user], "User is already registered");
        require(!blacklist[user], "User is blacklisted");
        waitlist[user] = true;
        indexedWaitlist[waitlistLength] = user;
        waitlistLength++;
        registrationDates[user] = block.timestamp;
        emit UserAddedByOwner(user, waitlistLength - 1);
    }

    function deregisterUser(address user) public onlyOwner {
        require(waitlist[user], "User is not registered");

        waitlist[user] = false;
        registrationDates[user] = 0;

        emit UserRemovedByOwner(user);
    }

    function transferFunds(address payable to, uint256 amount)
        public
        onlyOwner
    {
        require(address(this).balance >= amount, "Insufficient balance");
        to.transfer(amount);
        emit FundsTransferred(to, amount);
    }

    function recoverERC20Tokens(
        address tokenAddress,
        address to,
        uint256 amount
    ) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(to, amount);
        emit TokensRecovered(tokenAddress, to, amount);
    }
}
