import "Token.sol";

// This is just a simple example of a Mutual Insurance contract.


contract MetaCoin is Token {
struct BoardMeeting {        
        // Address who created the board meeting for a proposal
        address creator;  

        // unix timestamp, denoting the end of the set period
        uint setDeadline;
        // Fees (in wei) paid by the creator of the board meeting
        uint fees; 
        // Fees (in wei) rewarded to the voters
        uint totalRewardedAmount;
        // A unix timestamp, denoting the end of the voting period
        uint votingDeadline;
        // True if the proposal's votes have yet to be counted, otherwise False
        bool open; 
        // A unix timestamp, denoting the date of the execution of the voted procedure
        uint dateOfExecution;
        // Number of shares in favor of the proposal
        uint yea; 
        // Number of shares opposed to the proposal
        uint nay; 
        // Index to identify the board meeting of the proposal
        uint BoardMeetingID;
        // The address of the proposal creator where the `amount` will go to if the proposal is accepted
        //address recipient;
        // The amount to transfer to `recipient` if the proposal is accepted.
        uint amount; 
        // The hash of the proposal's document
        bytes32 hashOfTheDocument; 
        // mapping to check if a shareholder has voted
        mapping (address => bool) hasVoted;  

    }

    struct Rules {
        // Index to identify the board meeting which decided to apply the rules
        uint BoardMeetingID;  
        // The quorum needed for each proposal is calculated by totalSupply / minQuorumDivisor
        uint minQuorumDivisor;  
        // The minimum debate period that a generic proposal can have
        uint minMinutesDebatePeriod; 
        // The maximum debate period that a generic proposal can have
        uint maxMinutesDebatePeriod;
        // Minimal fees (in wei) to create a board meeting for contractor and private funding proposals
        uint minBoardMeetingFees; 
        // Period after which a proposal is closed
        uint minutesExecuteProposalPeriod;
        // Period needed for the curator to check the idendity of a contractor or private funding creator
        uint minMinutesSetPeriod; 
        // If true, the tokens can be transfered from a tokenholder to another
        bool tokenTransferAble;
        // The address of a new revision of Dao contract
        address newDao;
        //每次互助金额
        uint minAmount;
    } 


    uint partnerNum;
    uint partnerlen;
    mapping (address => uint) blocked; //0:close;1:normal;2:claiming;
    mapping (address => uint) openPeriod;
    mapping (uint => address) Partners;
    struct recipientData {
        // Address of the recipient
        address recipient;
        // Identification number given by the recipient
        uint RecipientID; 
        // Name of the recipient
        string RecipientName;  
    }
    // Board meetings to decide the result of a proposal
    BoardMeeting[] public BoardMeetings; 

    // The current Dao rules
    Rules public DaoRules; 

    uint[4][5] votesNum;
    bytes32[5] votesDoc;


    // Protects users by preventing the execution of method calls that
    // inadvertently also transferred ether
    modifier noEther() {if (msg.value > 0) throw; _}
     // Modifier that allows only the cient to manage tokens
    modifier onlyClient {if (msg.sender != address(this)) throw; _ }
    // modifier to allow public to fund only in case of crowdfunding
    modifier onlyRecipient {if (msg.sender != address(Recipient.recipient)) throw; _ }   
    
    // Modifier that allows only shareholders to vote and create new proposals
    modifier onlyTokenholders {if (balances[msg.sender] < 3) throw; _ }
    // Information about the recipient
    recipientData public Recipient;

	function MetaCoin(){

        Recipient.recipient=msg.sender;
        Recipient.RecipientID=0;
        Recipient.RecipientName="DAO ACCOUNT RECIPIENT";
        

        DaoRules.minQuorumDivisor = 2;
        DaoRules.minMinutesDebatePeriod = 2;
        DaoRules.maxMinutesDebatePeriod = 2;
        DaoRules.minBoardMeetingFees = 10;
        DaoRules.minutesExecuteProposalPeriod = 2;
        DaoRules.minMinutesSetPeriod = 1;
        DaoRules.minAmount=3;

        partnerNum = 0;
        partnerlen = 0;


    }

    function joinContract(uint _amount) external returns (bool) {

        address _tokenHolder;
        _tokenHolder=msg.sender;

        if (_tokenHolder == address(this)) {
            return true;} 
        if(_amount<DaoRules.minAmount){return true;}
        if(balances[_tokenHolder]==0){

            Partners[partnerlen]=_tokenHolder;
            partnerlen++;
            openPeriod[_tokenHolder]=now;
            
        }        
        if(blocked[_tokenHolder]!=1 && balances[_tokenHolder]<DaoRules.minAmount){
            partnerNum++;
            openPeriod[_tokenHolder]=now;
        }
        if(blocked[_tokenHolder]!=2)
        {
            blocked[_tokenHolder]=1;
        }
        
        balances[_tokenHolder] += _amount; 
        totalSupply += _amount;
 

        return true;    
    }


	function getBalance(address addr) returns(uint) {
		return balances[addr];
	}


    /// @dev Function used by the client
    /// @return The total supply of tokens 
    function TotalSupply() external returns (uint256) {
        return totalSupply;
    }
    
        
    /// @dev Function used by the client to send ethers
    /// @param _recipient The address to send to
    /// @param _amount The amount to send
    function sendTo(
        address _recipient, 
        uint _amount
    ) internal onlyClient {
        if (!_recipient.send(_amount)) throw;    
    }
      


    function getpartnerNum() external returns(uint){
    	return partnerNum;
    }
    function getpartnerLen() external returns(uint){
        return partnerlen;
    }


    /// @dev internal function to create a board meeting

    /// @param _description The description of the case  
    /// @return the index of the board meeting
    function newBoardMeeting( 
        bytes32 _description
    ) returns (uint) {

        if(blocked[msg.sender]!=1)
            {return;}
        else{blocked[msg.sender]=2;}
        uint _BoardMeetingID = BoardMeetings.length++;
        BoardMeeting p = BoardMeetings[_BoardMeetingID];
        uint opendate=openPeriod[msg.sender];
        uint _MinutesDebatingPeriod=2;
        //测试阶段注释
        //if ((msg.value < DaoRules.minBoardMeetingFees)|| ((now - opendate) * 1 days )< 180 ) throw;


        uint _setdeadline=now + DaoRules.minMinutesSetPeriod * 1 minutes;
        p.BoardMeetingID=_BoardMeetingID;
        p.creator = msg.sender;
        p.fees = msg.value;
        p.totalRewardedAmount = 0;     
        
        uint _DebatePeriod;
        if (_MinutesDebatingPeriod < DaoRules.minMinutesDebatePeriod) _DebatePeriod = DaoRules.minMinutesDebatePeriod; 
        else _DebatePeriod = _MinutesDebatingPeriod; 

        p.votingDeadline =now + (_DebatePeriod * 1 minutes); 
        p.setDeadline =_setdeadline + (_DebatePeriod * 1 minutes); 
        p.open = true; 
        p.yea=0;
        p.nay=0;
        p.amount = 0;
        p.hashOfTheDocument = _description; 

        return _BoardMeetingID;

    }


    function getcaseId() external returns(uint){
    	return BoardMeetings.length-1;
    }
    function getcasedoc(uint _BoardMeetingID) external returns(bytes32){

    	return BoardMeetings[_BoardMeetingID].hashOfTheDocument;
    }
    function getVote(uint _BoardMeetingID) external returns(uint){

    	return BoardMeetings[_BoardMeetingID].yea;
    }
    function getVotenay(uint _BoardMeetingID) external returns(uint){

        return BoardMeetings[_BoardMeetingID].nay;
    }
    function getAccount(uint _BoardMeetingID) external returns(address){

    	return BoardMeetings[_BoardMeetingID].creator;
    }
    function getStatus(uint _BoardMeetingID) external returns(bool){

        return BoardMeetings[_BoardMeetingID].open;
    }
    function getVoted(uint _BoardMeetingID) external returns(bool){

        return BoardMeetings[_BoardMeetingID].hasVoted[msg.sender];
    }
    function colArray() external returns(bool){


         for(uint i=0;i<BoardMeetings.length;i++)
        {
           
           votesNum[i][0]=BoardMeetings[i].BoardMeetingID;
           votesDoc[i]=BoardMeetings[i].hashOfTheDocument;
           votesNum[i][1]=BoardMeetings[i].yea;
           votesNum[i][2]=balances[BoardMeetings[i].creator];
           if(BoardMeetings[i].open)
           {
            votesNum[i][3]=1;
           }else{
            votesNum[i][3]=0;
           }
         
        }
    }
    function getArrayNum() external returns(uint[4][5]){

        return votesNum;
    }
    function getArrayDoc() external returns(bytes32[5]){

        return votesDoc;
    }

    /// @notice Function to vote during a board meeting
    /// @param _BoardMeetingID The index of the _BoardMeeting
    ///@param _supportsProposal 1 if the proposal is supported
    /// @return Whether the transfer was successful or not 
function vote(uint _BoardMeetingID,uint _supportsProposal) noEther onlyTokenholders returns (bool _success) {

        BoardMeeting p = BoardMeetings[_BoardMeetingID];
 /*       if (p.hasVoted[msg.sender] 
            || now > p.votingDeadline 
            ||!p.open||balances[msg.sender]<DaoRules.minAmount
        ) {

        return;
        }*/
        //简化for test
         if (p.hasVoted[msg.sender]) {

        return;
        }
        /*
        if (p.fees > 0 && p.ContractorProposalID != 0) {
            uint _rewardedamount = p.fees/partnerNum;
            if (!msg.sender.send(_rewardedamount)) throw;
            p.totalRewardedAmount += _rewardedamount;
        }*/

         if (_supportsProposal==1) {
            p.yea += 1;
           
        } 
        else {
            p.nay += 1; 
        }

        p.hasVoted[msg.sender] = true;

        return true;

    }

    /// @notice Function to executes a board meeting decision
    /// @param _BoardMeetingID The index of the board meeting
    /// @return Whether the transfer was successful or not    
    function executeDecision(uint _BoardMeetingID)  returns (bool _success) 
        {
        BoardMeeting p = BoardMeetings[_BoardMeetingID];


        uint quorum = p.yea + p.nay;

         
       
/*
        if (now > p.votingDeadline + DaoRules.minutesExecuteProposalPeriod * 1 minutes 
                    || now > p.votingDeadline && ( quorum < minQuorum() || p.yea < p.nay ) ) {
            //takeBoardingFees(_BoardMeetingID);
            p.open = false;
            return;
        }

 */      //先屏蔽日期条件，for test
         if ( quorum > minQuorum() && p.yea < p.nay ) {

            p.open = false;

            return;
        } else if (quorum > minQuorum() && p.yea > p.nay ){
            for(uint i=0;i<partnerlen;i++){
                address adr = Partners[i];
               
                    if ((balances[adr] - DaoRules.minAmount)>=0){
                        balances[adr] = balances[adr] - DaoRules.minAmount;
                        p.amount += DaoRules.minAmount;
                    }
                    else{
                        partnerNum=partnerNum-1;
                        blocked[adr]=0;
                    }                    
                

            }

            balances[p.creator]+=p.amount;
 
            p.dateOfExecution = now;
            p.open = false;
        }
                              
        

        _success = true; 
        p.dateOfExecution = now;

    }




        
    /// @notice Interface function to get the number of meetings 
    /// @return the number of meetings (passed or current)
    function numberOfMeetings() external returns (uint) {
        return BoardMeetings.length;
    }
 
    /// @dev internal function to get the minimum quorum needed for a proposal    
    /// @return The minimum quorum for the proposal to pass 
    function minQuorum() constant returns (uint) {
        return uint(partnerNum/ DaoRules.minQuorumDivisor);
    }

}
