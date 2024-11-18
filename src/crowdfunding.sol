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
    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address => bool) voters;
    }

    mapping(uint => Request) public requests;
    // necessário porque mapping não indexa automaticamente
    uint public numRequests;

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

    receive() payable external {
        contribute();
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    // caso a campanha não atinja seu objetivo
    // é possível pedir o seu dinheiro de volta
    function getRefund() public{
        // exige que a campanha não tenha sido bem sucedida
        require(block.timestamp > deadline && raisedAmount < goal);
        // somente alguém que contribuiu pode solicitar o reembolso
        require(contributors[msg.sender] > 0);

        address payable recipient = payable(msg.sender);
        uint value = contributors[msg.sender];
        recipient.transfer(value);

        // zera a contribuição para impedir ataques
        contributors[msg.sender] = 0;
    }
}