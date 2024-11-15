// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract CrowdFunding{
    mapping(address => uint) public contributors;
    address public admin;
    uint public noOfContributors;
    uint public minimumContributor;
    uint public deadline; // timestamp
    uint public goal;
    uint public raisedAmount;

    constructor(uint _goal, uint _deadline){
        goal = _goal;
        deadline = block.timestamp + _deadline;
        minimumContributor = 100 wei;
        admin = msg.sender;
    }

    function contribute() public payable{
        require(block.timestamp < deadline, "Deadline has passed!");
        require(msg.value >= minimumContributor);

        if(contributors[msg.sender] == 0){
            noOfContributors++;
        }
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }
}