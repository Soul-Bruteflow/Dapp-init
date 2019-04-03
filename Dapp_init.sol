pragma solidity ^0.5.1;

interface PassportInterface {
  function isRegistered(address _address) external view returns(bool);
}

// Contract 1 Pasport
//---------------------------------------------
contract Pasport
{
    struct      Person
    {
        string  name;
        string  surname;
        uint8   age;
        uint256 id;
        bool    authorized;
        bool    registered;
    }
    
    address payable public              owner;
    mapping(address => Person) public   people;
    uint256                             idCount;
    
    modifier ownerOnly()
    {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public payable
    {
        owner = msg.sender;
    }
    
    function authorize(address _person) public
    {
        people[_person].authorized = true;
    }
    
    function registerID(string memory _name, string memory _surname, uint8 _age) public
    {
        require(!people[msg.sender].registered);
        require(people[msg.sender].authorized);
        
        bytes memory emptyStringTest1 = bytes(_name);
        bytes memory emptyStringTest2 = bytes(_surname);
        require(emptyStringTest1.length >= 3);
        require(emptyStringTest2.length >= 3);
        require(_age >= 18);
        
        people[msg.sender].name = _name;
        people[msg.sender].surname = _surname;
        people[msg.sender].age = _age;
        people[msg.sender].id = idCount;
        
        people[msg.sender].registered = true;
        
        idCount += 1;
    }
    
    function isRegistered(address _address) public view returns (bool)
    {
        return people[_address].registered;
    }
    
    function end() ownerOnly public
    {
        selfdestruct(owner);
    }
}


// Contract 2 Election
//---------------------------------------------

contract Election
{
    struct      Candidate
    {
        string  name;
        uint    voteCount;
    }
    
    struct      Voter
    {
        bool    authorized;
        bool    voted;
        uint    voteTarget;
    }
    address payable  public             owner;
    string public                       electionName;
    mapping(address => Voter) public    voters;
    Candidate[] public                  candidates;
    uint public                         totalVotes;
    PassportInterface                   passportContract;
    uint                                winnerIndexFinal;
    
    event LogSelfDestruct(address sender, string winner);
    
    modifier ownerOnly()
    {
        require(msg.sender == owner);
        _;
    }
    
    constructor(string memory _electionName, address passportContractAddress) public
    {
        passportContract = PassportInterface(passportContractAddress);
        owner = msg.sender;
        electionName = _electionName;
    }
    
    function addCandidate(string memory _candidateName) ownerOnly public
    {
        candidates.push(Candidate(_candidateName, 0));
    }
    
    function getNumCandidate() public view returns(uint)
    {
        return candidates.length;
    }
    
    function authorize(address _person) public
    {
        voters[_person].authorized = true;
    }
    
    function vote(uint _voteIndex) public
    {
        require(passportContract.isRegistered(msg.sender), "You don't have a passport");
        require(!voters[msg.sender].voted);
        require(voters[msg.sender].authorized);
        
        voters[msg.sender].voteTarget = _voteIndex;
        voters[msg.sender].voted = true;
        
        candidates[_voteIndex].voteCount += 1;
        totalVotes += 1;
    }
    
    function chooseWinner() private
    {
        uint winnerIndex = 0;
        uint maxVotes = 0;
        
        for (uint i = 0; i < candidates.length; i++)
        {
            if (candidates[i].voteCount > maxVotes)
            {
                winnerIndex = i;
                maxVotes = candidates[i].voteCount;
                winnerIndexFinal = i;
            }
        }
    }
    
    function getWinner() public view returns(string memory)
    {
        return candidates[winnerIndexFinal].name;
    }
    
    function end() ownerOnly public
    {
        chooseWinner();
        emit LogSelfDestruct(msg.sender, getWinner());
        selfdestruct(owner);
    }
}