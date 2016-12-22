
contract Token{
    mapping (address => uint256) balances;

    /// Total amount of tokens
    uint256 public totalSupply;


    modifier noEther() {if (msg.value > 0) throw; _}

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _amount) noEther returns (bool success) {
        if (balances[msg.sender] >= _amount && _amount > 0) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;

            return true;
        } else {
           return false;
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) noEther returns (bool success) {

        if (balances[_from] >= _amount && _amount > 0) {

            balances[_to] += _amount;
            balances[_from] -= _amount;

            return true;
        } else {
            return false;
        }
    }


}

