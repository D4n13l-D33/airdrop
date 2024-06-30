// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract StakingERC20{

    address public owner;
    address public stakingToken;

    uint public stakeCount;

    uint public unlockTime;

    struct stakers{
        uint stakeID;
        address stakerADD;
        uint amountStaked;
        uint TimeStaked;
    }
    //keeps tracks of all the stakeposition opened
    mapping(uint => mapping(address => stakers)) stakePosition;

    //tracks user deposits including ROI on stakes
    mapping(address => uint)TotalBalance;

    constructor(address _stakingToken){
        stakingToken = _stakingToken;

        unlockTime = 20 seconds;

        owner = msg.sender;
    }

    event DepositSuccessful(address _depositor);
    event withdrawalSuccessful(address _withd, uint _amount);
    event StakeOpened(uint _stakeID, uint _stakeamount);
    event StakeClosed(uint _stakeiD, uint _stakeGain);

    function deposit(uint _amount) external {
        require(msg.sender != address(0));

        require (_amount > 0, "Can't Deposit Zero");

        require (IERC20(stakingToken).balanceOf(msg.sender) >= _amount, "Insufficient Balance");

        require (IERC20(stakingToken).transferFrom(msg.sender, address(this), _amount), "Deposit Failed");

        TotalBalance[msg.sender] = TotalBalance[msg.sender] + _amount;

        emit DepositSuccessful(msg.sender);
        
    }

    function openStake(uint _stakingAmount) external {
        require(_stakingAmount > 0, "Can not stake Zero");
        require(TotalBalance[msg.sender] >= _stakingAmount, "Insufficent Balance Please Deposit");

        TotalBalance[msg.sender] = TotalBalance[msg.sender] - _stakingAmount;

        stakeCount = stakeCount + 1;

        stakers storage _openStaking = stakePosition[stakeCount] [msg.sender];

        _openStaking.amountStaked = _stakingAmount;
        _openStaking.stakerADD = msg.sender;
        _openStaking.TimeStaked = block.timestamp;
        _openStaking.stakeID = stakeCount;       

        emit StakeOpened(stakeCount, _stakingAmount);

        
    }

    function closeStake(uint _stakeID) external {
        require(_stakeID > 0, "Invalid stake ID");

        require(_stakeID<= stakeCount, "Invalid Stake ID");

        require(stakePosition[_stakeID][msg.sender].stakeID != 0, "Stake Already Closed");

        require(msg.sender == stakePosition[_stakeID][msg.sender].stakerADD, "You're not the Staker");

        stakers storage _closeStaking = stakePosition[_stakeID][msg.sender];

        uint time = block.timestamp - _closeStaking.TimeStaked;

        require(time >= unlockTime, "Not Yet Time!");

        uint stakeGain = (_closeStaking.amountStaked * 2)/100;

        _closeStaking.stakeID = 0;

        TotalBalance[msg.sender] = TotalBalance[msg.sender] + stakeGain + _closeStaking.amountStaked;

        emit StakeClosed(_stakeID, stakeGain);
               
    }

    function withdraw(uint _amount) external{
        require(TotalBalance[msg.sender] >= _amount, "Insufficient Balance");
        
        TotalBalance[msg.sender] = TotalBalance[msg.sender] - _amount;

        require(IERC20(stakingToken).transfer(msg.sender, _amount), "Withdrawal Not Successful");

        emit withdrawalSuccessful(msg.sender, _amount); 
    }

    function getUserBalance(address user) external view returns (uint){
        return TotalBalance[user];
    }  

    function getContractBal() external view returns(uint){
        return (IERC20(stakingToken).balanceOf(address(this)));
    } 

}