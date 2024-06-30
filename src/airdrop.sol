// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
contract GAU is ERC20, ERC20Permit {
    constructor() ERC20("GAUCoin", "GAU") ERC20Permit("GAUCoin") {}

    function mint(address user, uint256 amount) public {
        _mint(user, amount);
    }
}
contract Airdrop {
    address token;
    uint256 counter;
    uint256 totalSupply;
    bytes32 public DOMAIN_SEPARATOR;
    mapping (address => bool) isRegistered;
    mapping (address => bool) hasClaimed;
    mapping (bytes32 => bool) sigHasClaimed;

    event Registered(address user);
    event Claimed(address user, uint256 amount);
    
    constructor(address _token, uint256 _totalSupply, uint256 chainId){
        totalSupply = _totalSupply;
        token = _token;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("Airdrop")), // Name of the app. Should this be a constructor param?
                keccak256(bytes("1")), // Version. Should this be a constructor param?
                chainId, // Replace with actual chainId (Base Sepolia: 84532)
                address(this)
            )
        );

    }
    function register() external {
        require(!isRegistered[msg.sender], "Already Registered");
        isRegistered[msg.sender] = true;
        counter++;
        emit Registered(msg.sender);
    }

    function claim() external {
        require(isRegistered[msg.sender], "You are not Eligible");
        if(hasClaimed[msg.sender]) revert("Has claimed");
        uint256 amountEligible = totalSupply / counter;
        hasClaimed[msg.sender] = true;
        require(IERC20(token).transfer(msg.sender, amountEligible), "Transfer Failed");
        emit Claimed(msg.sender, amountEligible);

    }

    function claimWithSignature(address user, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 hash = keccak256(abi.encode(user,v,r,s));
        require(!sigHasClaimed[hash], "This Signature has claimed");
        bytes32 hashedMessage = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, _hashMessage(user)));
        address recoveredAddress = ecrecover(hashedMessage, v, r, s);
        require(recoveredAddress == user, "The 'user' address must sign the withdraw message");
        require(isRegistered[recoveredAddress], "You are not Eligible");
        uint256 amountEligible = totalSupply / counter;
        sigHasClaimed[hash] = true;
        require(IERC20(token).transfer(user, amountEligible), "Transfer Failed");
        emit Claimed(user, amountEligible);

    }

     function _hashMessage(address user) internal pure returns (bytes32) {
        return keccak256(abi.encode(keccak256("claimWithSignature(address to)"), user));
    }

    function getDOMAIN_SEPARATOR() external view returns(bytes32){
        return DOMAIN_SEPARATOR;
    }
}

interface IERC20 {
    //mints to address
    function mint(address account, uint256 amount) external returns(bool);
    // Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    // Returns the remaining number of tokens that `spender` will be
    // allowed to spend on behalf of `owner` through {transferFrom}. This is
    // zero by default.
    function allowance(address owner, address spender) external view returns (uint256);

    // Sets `amount` as the allowance of `spender` over the caller's tokens.
    function approve(address spender, uint256 amount) external returns (bool);

    // Moves `amount` tokens from `sender` to `recipient` using the
    // allowance mechanism. `amount` is then deducted from the caller's
    // allowance.
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function transfer(address user, uint256 amount) external returns (bool);
}

