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

    // eventos necessários para criação de logs
    event ContributeEvent(address _sender, uint _value);
    event CreateRequestEvent(string _description,address _recipient,uint _value);
    event MakePaymentRequest(address _recipient, uint _value);

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

        emit ContributeEvent(msg.sender, msg.value);
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

    modifier onlyAdmin(){
        require(msg.sender == admin, "Only admin can call this function!");
        _;
    }

    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyAdmin{
        Request storage newRequest = requests[numRequests];
        numRequests++;

        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;

        emit CreateRequestEvent(_description, _recipient, _value);
    }

    // uma vez contribuindo, cada um
    // poderá votar para qual causa
    // o valor será utilizado
    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender] > 0, "You must to be a contributor to vote!");
        Request storage thisRequest = requests[_requestNo];

        require(thisRequest.voters[msg.sender] == false, "You have already voted!");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }

    function makePayment(uint _requestNo) public onlyAdmin{
        require(raisedAmount >= goal);
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false, "The request has been completed.");
        require(thisRequest.noOfVoters > noOfContributors / 2);

        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;

        emit MakePaymentRequest(thisRequest.recipient, thisRequest.value);
    }
}