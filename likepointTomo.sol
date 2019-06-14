pragma solidity ^0.4.11;


/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implemantation of the basic standart token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint _value) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint value);
  event MintMore(address indexed to, uint value);
  event BurnToken(address indexed to, uint value);
  event MintFinished();

  bool public mintingFinished = false;
  uint public totalSupply = 0;


  modifier canMint() {
    if(mintingFinished) throw;
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

  function addMint(uint _amount) onlyOwner returns (bool){
      totalSupply = totalSupply.add(_amount);
      balances[msg.sender] = balances[msg.sender].add(_amount);
      MintMore(msg.sender, _amount);
      return true;
  }
  function burnToken(uint _amount) returns (bool) {
      totalSupply = totalSupply.sub(_amount);
      balances[msg.sender] = balances[msg.sender].sub(_amount);
      require(balances[msg.sender] >= 0);
      BurnToken(msg.sender, _amount);
      return true;
  }
  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    if (paused) throw;
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    if (!paused) throw;
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}


/**
 * Pausable token
 *
 * Simple ERC20 Token example, with pausable token creation
 **/

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint _value) whenNotPaused {
    super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) whenNotPaused {
    super.transferFrom(_from, _to, _value);
  }
}


/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a time has passed
 */
contract TokenTimelock {

  // ERC20 basic token contract being held
  ERC20Basic token;

  // beneficiary of tokens after they are released
  address beneficiary;

  // timestamp where token release is enabled
  uint releaseTime;

  function TokenTimelock(ERC20Basic _token, address _beneficiary, uint _releaseTime) {
    require(_releaseTime > now);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

  /**
   * @dev beneficiary claims tokens held by time lock
   */
  function claim() {
    require(msg.sender == beneficiary);
    require(now >= releaseTime);

    uint amount = token.balanceOf(this);
    require(amount > 0);

    token.transfer(beneficiary, amount);
  }
}


/**
 * @title OMGToken
 * @dev Omise Go Token contract
 */
contract LIKEPOINT is PausableToken, MintableToken {
  using SafeMath for uint256;

  string public name = "Loyalty Inspiration Token";
  string public symbol = "LIKE";
  uint public decimals = 18;

  /**
   * @dev mint timelocked tokens
   */
  function mintTimelocked(address _to, uint256 _amount, uint256 _releaseTime)
    onlyOwner canMint returns (TokenTimelock) {

    TokenTimelock timelock = new TokenTimelock(this, _to, _releaseTime);
    mint(timelock, _amount);

    return timelock;
  }

}
//version 4.19
//0xb1b4615508528de75012e38a0e1c07e0143c0c5d

//code: 606060409081526003805460a060020a61ffff021916905560006004558051908101604052601981527f4c6f79616c747920496e737069726174696f6e20546f6b656e00000000000000602082015260059080516100619291602001906100cf565b5060408051908101604052600481527f4c494b4500000000000000000000000000000000000000000000000000000000602082015260069080516100a99291602001906100cf565b50601260075560038054600160a060020a03191633600160a060020a031617905561016a565b828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f1061011057805160ff191683800117855561013d565b8280016001018555821561013d579182015b8281111561013d578251825591602001919060010190610122565b5061014992915061014d565b5090565b61016791905b808211156101495760008155600101610153565b90565b610f9a806101796000396000f3006060604052600436106101115763ffffffff7c010000000000000000000000000000000000000000000000000000000060003504166305d2035b811461011657806306fdde031461013d578063095ea7b3146101c757806318160ddd146101eb57806323b872dd14610210578063313ce567146102385780633f4ba83a1461024b578063403398301461025e57806340c10f19146102745780635c975abb1461029657806370a08231146102a95780637b47ec1a146102c85780637d64bcb4146102de5780638456cb59146102f15780638da5cb5b1461030457806395d89b4114610333578063a9059cbb14610346578063c14a3b8c14610368578063dd62ed3e1461038d578063f2fde38b146103b2575b600080fd5b341561012157600080fd5b6101296103d1565b604051901515815260200160405180910390f35b341561014857600080fd5b6101506103e1565b60405160208082528190810183818151815260200191508051906020019080838360005b8381101561018c578082015183820152602001610174565b50505050905090810190601f1680156101b95780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b34156101d257600080fd5b6101e9600160a060020a036004351660243561047f565b005b34156101f657600080fd5b6101fe610520565b60405190815260200160405180910390f35b341561021b57600080fd5b6101e9600160a060020a0360043581169060243516604435610526565b341561024357600080fd5b6101fe61054d565b341561025657600080fd5b610129610553565b341561026957600080fd5b6101296004356105d9565b341561027f57600080fd5b610129600160a060020a0360043516602435610690565b34156102a157600080fd5b61012961075f565b34156102b457600080fd5b6101fe600160a060020a036004351661076f565b34156102d357600080fd5b61012960043561078a565b34156102e957600080fd5b610129610838565b34156102fc57600080fd5b6101296108ad565b341561030f57600080fd5b610317610938565b604051600160a060020a03909116815260200160405180910390f35b341561033e57600080fd5b610150610947565b341561035157600080fd5b6101e9600160a060020a03600435166024356109b2565b341561037357600080fd5b610317600160a060020a03600435166024356044356109d7565b341561039857600080fd5b6101fe600160a060020a0360043581169060243516610a65565b34156103bd57600080fd5b6101e9600160a060020a0360043516610a90565b60035460a860020a900460ff1681565b60058054600181600116156101000203166002900480601f0160208091040260200160405190810160405280929190818152602001828054600181600116156101000203166002900480156104775780601f1061044c57610100808354040283529160200191610477565b820191906000526020600020905b81548152906001019060200180831161045a57829003601f168201915b505050505081565b80158015906104b25750600160a060020a0333811660009081526002602090815260408083209386168352929052205415155b156104bc57600080fd5b600160a060020a03338116600081815260026020908152604080832094871680845294909152908190208490557f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b9259084905190815260200160405180910390a35050565b60045481565b60035460a060020a900460ff161561053d57600080fd5b610548838383610ae6565b505050565b60075481565b60035460009033600160a060020a0390811691161461057157600080fd5b60035460a060020a900460ff16151561058957600080fd5b6003805474ff0000000000000000000000000000000000000000191690557f7805862f689e2f13df9f062ff482ad3ad112aca9e0847911ed832e158c525b3360405160405180910390a150600190565b60035460009033600160a060020a039081169116146105f757600080fd5b60045461060a908363ffffffff610c0716565b600455600160a060020a033316600090815260016020526040902054610636908363ffffffff610c0716565b600160a060020a0333166000818152600160205260409081902092909255907f1c5e0744c1da3cb41b315608a34ba72e62d5ee9d526850e1762deb049e2715e59084905190815260200160405180910390a2506001919050565b60035460009033600160a060020a039081169116146106ae57600080fd5b60035460a860020a900460ff16156106c557600080fd5b6004546106d8908363ffffffff610c0716565b600455600160a060020a038316600090815260016020526040902054610704908363ffffffff610c0716565b600160a060020a0384166000818152600160205260409081902092909255907f0f6798a560793a54c3bcfe86a93cde1e73087d944c0ea20544137d41213968859084905190815260200160405180910390a250600192915050565b60035460a060020a900460ff1681565b600160a060020a031660009081526001602052604090205490565b6004546000906107a0908363ffffffff610c1f16565b600455600160a060020a0333166000908152600160205260409020546107cc908363ffffffff610c1f16565b600160a060020a03331660009081526001602052604081208290559010156107f357600080fd5b33600160a060020a03167fe12923b90d8a6ca7dc57994322d2afba0be75f98e97e2b892fd34c0d7c6229698360405190815260200160405180910390a2506001919050565b60035460009033600160a060020a0390811691161461085657600080fd5b6003805475ff000000000000000000000000000000000000000000191660a860020a1790557fae5184fba832cb2b1f702aca6117b8d265eaf03ad33eb133f19dde0f5920fa0860405160405180910390a150600190565b60035460009033600160a060020a039081169116146108cb57600080fd5b60035460a060020a900460ff16156108e257600080fd5b6003805474ff0000000000000000000000000000000000000000191660a060020a1790557f6985a02210a168e66602d3235cb6db0e70f92b3ba4d376a33c0f3d9434bff62560405160405180910390a150600190565b600354600160a060020a031681565b60068054600181600116156101000203166002900480601f0160208091040260200160405190810160405280929190818152602001828054600181600116156101000203166002900480156104775780601f1061044c57610100808354040283529160200191610477565b60035460a060020a900460ff16156109c957600080fd5b6109d38282610c33565b5050565b600354600090819033600160a060020a039081169116146109f757600080fd5b60035460a860020a900460ff1615610a0e57600080fd5b308584610a19610d0a565b600160a060020a0393841681529190921660208201526040808201929092526060019051809103906000f0801515610a5057600080fd5b9050610a5c8185610690565b50949350505050565b600160a060020a03918216600090815260026020908152604080832093909416825291909152205490565b60035433600160a060020a03908116911614610aab57600080fd5b600160a060020a03811615610ae3576003805473ffffffffffffffffffffffffffffffffffffffff1916600160a060020a0383161790555b50565b600060606064361015610af857600080fd5b600160a060020a038086166000908152600260209081526040808320338516845282528083205493881683526001909152902054909250610b3f908463ffffffff610c0716565b600160a060020a038086166000908152600160205260408082209390935590871681522054610b74908463ffffffff610c1f16565b600160a060020a038616600090815260016020526040902055610b9d828463ffffffff610c1f16565b600160a060020a03808716600081815260026020908152604080832033861684529091529081902093909355908616917fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef9086905190815260200160405180910390a35050505050565b6000828201610c1884821015610cfe565b9392505050565b6000610c2d83831115610cfe565b50900390565b60406044361015610c4357600080fd5b600160a060020a033316600090815260016020526040902054610c6c908363ffffffff610c1f16565b600160a060020a033381166000908152600160205260408082209390935590851681522054610ca1908363ffffffff610c0716565b600160a060020a0380851660008181526001602052604090819020939093559133909116907fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef9085905190815260200160405180910390a3505050565b801515610ae357600080fd5b60405161025480610d1b8339019056006060604052341561000f57600080fd5b60405160608061025483398101604052808051919060200180519190602001805191505042811161003f57600080fd5b60008054600160a060020a03948516600160a060020a03199182161790915560018054939094169216919091179091556002556101d3806100816000396000f3006060604052600436106100275763ffffffff60e060020a6000350416634e71d92d811461002c575b600080fd5b341561003757600080fd5b61003f610041565b005b6001546000903373ffffffffffffffffffffffffffffffffffffffff90811691161461006c57600080fd5b60025442101561007b57600080fd5b6000805473ffffffffffffffffffffffffffffffffffffffff16906370a082319030906040516020015260405160e060020a63ffffffff841602815273ffffffffffffffffffffffffffffffffffffffff9091166004820152602401602060405180830381600087803b15156100f057600080fd5b6102c65a03f1151561010157600080fd5b50505060405180519150506000811161011957600080fd5b60005460015473ffffffffffffffffffffffffffffffffffffffff9182169163a9059cbb91168360405160e060020a63ffffffff851602815273ffffffffffffffffffffffffffffffffffffffff90921660048301526024820152604401600060405180830381600087803b151561019057600080fd5b6102c65a03f115156101a157600080fd5b505050505600a165627a7a72305820273b6131ccc5a3d10e53aa0b405431f6b055209045b8762e9df8a8623b5b95cf0029a165627a7a723058201aceca8567c5b6b870ef51f9081176993ce7fb3550ed9b847d422aff70f4e9db0029

//abi : [ { "constant": false, "inputs": [ { "name": "_amount", "type": "uint256" } ], "name": "addMint", "outputs": [ { "name": "", "type": "bool" } ], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": false, "inputs": [ { "name": "_spender", "type": "address" }, { "name": "_value", "type": "uint256" } ], "name": "approve", "outputs": [], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": false, "inputs": [ { "name": "_amount", "type": "uint256" } ], "name": "burnToken", "outputs": [ { "name": "", "type": "bool" } ], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": false, "inputs": [], "name": "finishMinting", "outputs": [ { "name": "", "type": "bool" } ], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": false, "inputs": [ { "name": "_to", "type": "address" }, { "name": "_amount", "type": "uint256" } ], "name": "mint", "outputs": [ { "name": "", "type": "bool" } ], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": false, "inputs": [ { "name": "_to", "type": "address" }, { "name": "_amount", "type": "uint256" }, { "name": "_releaseTime", "type": "uint256" } ], "name": "mintTimelocked", "outputs": [ { "name": "", "type": "address" } ], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": false, "inputs": [], "name": "pause", "outputs": [ { "name": "", "type": "bool" } ], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": false, "inputs": [ { "name": "_to", "type": "address" }, { "name": "_value", "type": "uint256" } ], "name": "transfer", "outputs": [], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": false, "inputs": [ { "name": "_from", "type": "address" }, { "name": "_to", "type": "address" }, { "name": "_value", "type": "uint256" } ], "name": "transferFrom", "outputs": [], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": false, "inputs": [ { "name": "newOwner", "type": "address" } ], "name": "transferOwnership", "outputs": [], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": false, "inputs": [], "name": "unpause", "outputs": [ { "name": "", "type": "bool" } ], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "anonymous": false, "inputs": [ { "indexed": true, "name": "to", "type": "address" }, { "indexed": false, "name": "value", "type": "uint256" } ], "name": "Mint", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": true, "name": "to", "type": "address" }, { "indexed": false, "name": "value", "type": "uint256" } ], "name": "MintMore", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": true, "name": "to", "type": "address" }, { "indexed": false, "name": "value", "type": "uint256" } ], "name": "BurnToken", "type": "event" }, { "anonymous": false, "inputs": [], "name": "MintFinished", "type": "event" }, { "anonymous": false, "inputs": [], "name": "Pause", "type": "event" }, { "anonymous": false, "inputs": [], "name": "Unpause", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": true, "name": "owner", "type": "address" }, { "indexed": true, "name": "spender", "type": "address" }, { "indexed": false, "name": "value", "type": "uint256" } ], "name": "Approval", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": true, "name": "from", "type": "address" }, { "indexed": true, "name": "to", "type": "address" }, { "indexed": false, "name": "value", "type": "uint256" } ], "name": "Transfer", "type": "event" }, { "constant": true, "inputs": [ { "name": "_owner", "type": "address" }, { "name": "_spender", "type": "address" } ], "name": "allowance", "outputs": [ { "name": "remaining", "type": "uint256" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": true, "inputs": [ { "name": "_owner", "type": "address" } ], "name": "balanceOf", "outputs": [ { "name": "balance", "type": "uint256" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": true, "inputs": [], "name": "decimals", "outputs": [ { "name": "", "type": "uint256" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": true, "inputs": [], "name": "mintingFinished", "outputs": [ { "name": "", "type": "bool" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": true, "inputs": [], "name": "name", "outputs": [ { "name": "", "type": "string" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": true, "inputs": [], "name": "owner", "outputs": [ { "name": "", "type": "address" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": true, "inputs": [], "name": "paused", "outputs": [ { "name": "", "type": "bool" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": true, "inputs": [], "name": "symbol", "outputs": [ { "name": "", "type": "string" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": true, "inputs": [], "name": "totalSupply", "outputs": [ { "name": "", "type": "uint256" } ], "payable": false, "stateMutability": "view", "type": "function" } ]