// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
pragma solidity ^0.4.16;

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


contract ERC20 {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ExchangeLikepointToPKC is Ownable {
  using SafeMath for uint;
  event Deposit(address token, address user, uint256 amount, uint256 balance);
  event Withdraw(address token, address user, uint256 amount, uint256 balance);
  event SwapLIKE(address token, address token2, address user, uint256 amount, uint256 balanceReturn);
  event SwapPKC(address token, address token2, address user, uint256 amount, uint256 balanceReturn);
  event Reserve(address token, address user, uint256 amount);
  mapping (address => mapping (address => uint256)) public tokens;
  
  address public likepoint;
  address public pkc;
  uint256 public rate = 100;
  function setLikepoint(address setAddr) onlyOwner  public returns (bool) {
      likepoint = setAddr;
      return true;
  }
  function setPKC(address setAddr) onlyOwner public returns (bool) {
      pkc = setAddr;
      return true;
  }
  function setRate(uint256 set) onlyOwner public returns (bool) {
      rate = set;
      return true;
  }
  
  function checkAddressLikepoint(address token) internal view returns (bool) {
      if(token == address(likepoint)) {
          return true;
      }
  }
  function checkAddressPKC(address token) internal view returns (bool) {
      if(token == address(pkc)) {
          return true;
      }
  }
  function reserveToken(address token, uint256 amount) onlyOwner public {
     tokens[token][this] = tokens[token][this].add(amount);
     if(!ERC20(token).transferFrom(msg.sender, this, amount)) revert();
     Reserve(token, msg.sender, amount);
  }
  function withdrawByAdmin(address token, uint256 amount) onlyOwner public returns (bool) {
    if (tokens[token][this] < amount) revert();
    tokens[token][this] = tokens[token][this].sub(amount);
    if (token == address(0)) {
      if (!msg.sender.send(amount)) revert();
    } else {
      if (!ERC20(token).transfer(msg.sender, amount)) revert();
    }
    return true;
  }
  function swapLikeToPKC(address token, address token2, uint256 amount) public returns (bool) {
      if(!checkAddressLikepoint(token)) revert();
      if(!checkAddressPKC(token2)) revert();
      tokens[token][this] = tokens[token][this].add(amount);
      if(!ERC20(token).transferFrom(msg.sender, this, amount)) revert();
      tokens[token2][this] = tokens[token2][this].sub(amount/rate);
      if (!ERC20(token2).transfer(msg.sender, amount/rate)) revert();
      SwapLIKE(token, token2, msg.sender, amount, amount/rate);     
      return true;
  }
  function swapPKCToLike(address token, address token2, uint256 amount) public returns (bool) {
      if(!checkAddressPKC(token)) revert();
      if(!checkAddressLikepoint(token2)) revert();
      tokens[token][this] = tokens[token][this].add(amount);
      if(!ERC20(token).transferFrom(msg.sender, this, amount)) revert();
      tokens[token2][this] = tokens[token2][this].sub(amount*rate);
      if (!ERC20(token2).transfer(msg.sender, amount*rate)) revert();
      SwapPKC(token, token2, msg.sender, amount, amount*rate);
      return true;
  }
  

}

//0x4717304bf97941a7645e53bd9abc32d23bd4f203

//code: 6060604052606460045560008054600160a060020a033316600160a060020a0319909116179055610c4a806100356000396000f3006060604052600436106100ab5763ffffffff60e060020a6000350416632c4e722e81146100b057806334fcf437146100d55780633e2e1a55146100ff578063478575531461011e578063487c358014610146578063508493bc146101685780636b643d591461018d57806379657870146101b55780637e957367146101d95780638da5cb5b146102085780639805985a1461021b578063f2fde38b1461023a578063fc22258514610259575b600080fd5b34156100bb57600080fd5b6100c361026c565b60405190815260200160405180910390f35b34156100e057600080fd5b6100eb600435610272565b604051901515815260200160405180910390f35b341561010a57600080fd5b6100eb600160a060020a036004351661029c565b341561012957600080fd5b6100eb600160a060020a03600435811690602435166044356102ea565b341561015157600080fd5b6100eb600160a060020a0360043516602435610573565b341561017357600080fd5b6100c3600160a060020a03600435811690602435166106ef565b341561019857600080fd5b6100eb600160a060020a036004358116906024351660443561070c565b34156101c057600080fd5b6101d7600160a060020a0360043516602435610978565b005b34156101e457600080fd5b6101ec610ad3565b604051600160a060020a03909116815260200160405180910390f35b341561021357600080fd5b6101ec610ae2565b341561022657600080fd5b6100eb600160a060020a0360043516610af1565b341561024557600080fd5b6101d7600160a060020a0360043516610b3f565b341561026457600080fd5b6101ec610b95565b60045481565b6000805433600160a060020a0390811691161461028e57600080fd5b50600481905560015b919050565b6000805433600160a060020a039081169116146102b857600080fd5b5060028054600160a060020a03831673ffffffffffffffffffffffffffffffffffffffff199091161790556001919050565b60006102f584610ba4565b151561030057600080fd5b61030983610bc5565b151561031457600080fd5b600160a060020a038085166000908152600160209081526040808320309094168352929052205461034b908363ffffffff610be616565b600160a060020a0380861660008181526001602090815260408083203095861684529091528082209490945590926323b872dd9233929091879190516020015260405160e060020a63ffffffff8616028152600160a060020a0393841660048201529190921660248201526044810191909152606401602060405180830381600087803b15156103da57600080fd5b6102c65a03f115156103eb57600080fd5b50505060405180519050151561040057600080fd5b6104456004548381151561041057fe5b600160a060020a038087166000908152600160209081526040808320309094168352929052205491900463ffffffff610bfe16565b600160a060020a038085166000818152600160209081526040808320309095168352939052919091209190915560045463a9059cbb9033908581151561048757fe5b0460006040516020015260405160e060020a63ffffffff8516028152600160a060020a0390921660048301526024820152604401602060405180830381600087803b15156104d457600080fd5b6102c65a03f115156104e557600080fd5b5050506040518051905015156104fa57600080fd5b7fbfa733648c9fb0cf410974f65fa2906a336d5461212650f37f150fa4324ecce1848433856004548781151561052c57fe5b04604051600160a060020a0395861681529385166020850152919093166040808401919091526060830193909352608082015260a001905180910390a15060019392505050565b6000805433600160a060020a0390811691161461058f57600080fd5b600160a060020a0380841660009081526001602090815260408083203090941683529290522054829010156105c357600080fd5b600160a060020a03808416600090815260016020908152604080832030909416835292905220546105fa908363ffffffff610bfe16565b600160a060020a0380851660008181526001602090815260408083203090951683529390529190912091909155151561066357600160a060020a03331682156108fc0283604051600060405180830381858888f19350505050151561065e57600080fd5b6106e6565b82600160a060020a031663a9059cbb338460006040516020015260405160e060020a63ffffffff8516028152600160a060020a0390921660048301526024820152604401602060405180830381600087803b15156106c057600080fd5b6102c65a03f115156106d157600080fd5b5050506040518051905015156106e657600080fd5b50600192915050565b600160209081526000928352604080842090915290825290205481565b600061071784610bc5565b151561072257600080fd5b61072b83610ba4565b151561073657600080fd5b600160a060020a038085166000908152600160209081526040808320309094168352929052205461076d908363ffffffff610be616565b600160a060020a0380861660008181526001602090815260408083203095861684529091528082209490945590926323b872dd9233929091879190516020015260405160e060020a63ffffffff8616028152600160a060020a0393841660048201529190921660248201526044810191909152606401602060405180830381600087803b15156107fc57600080fd5b6102c65a03f1151561080d57600080fd5b50505060405180519050151561082257600080fd5b600454600160a060020a038085166000908152600160209081526040808320309094168352929052205461085d91840263ffffffff610bfe16565b600160a060020a03808516600081815260016020908152604080832030909516835293905282812093909355600454909263a9059cbb92339287029190516020015260405160e060020a63ffffffff8516028152600160a060020a0390921660048301526024820152604401602060405180830381600087803b15156108e257600080fd5b6102c65a03f115156108f357600080fd5b50505060405180519050151561090857600080fd5b7f38a7398d96a941d95e458a2cf30434437567796df3effa8c29a90bc5fcb31267848433856004548702604051600160a060020a0395861681529385166020850152919093166040808401919091526060830193909352608082015260a001905180910390a15060019392505050565b60005433600160a060020a0390811691161461099357600080fd5b600160a060020a03808316600090815260016020908152604080832030909416835292905220546109ca908263ffffffff610be616565b600160a060020a0380841660008181526001602090815260408083203095861684529091528082209490945590926323b872dd9233929091869190516020015260405160e060020a63ffffffff8616028152600160a060020a0393841660048201529190921660248201526044810191909152606401602060405180830381600087803b1515610a5957600080fd5b6102c65a03f11515610a6a57600080fd5b505050604051805190501515610a7f57600080fd5b7f2c9c203fde68ab5658a8ae7bfdd8c98046a6b464ee280461390b8f321332c103823383604051600160a060020a039384168152919092166020820152604080820192909252606001905180910390a15050565b600254600160a060020a031681565b600054600160a060020a031681565b6000805433600160a060020a03908116911614610b0d57600080fd5b5060038054600160a060020a03831673ffffffffffffffffffffffffffffffffffffffff199091161790556001919050565b60005433600160a060020a03908116911614610b5a57600080fd5b600160a060020a03811615610b92576000805473ffffffffffffffffffffffffffffffffffffffff1916600160a060020a0383161790555b50565b600354600160a060020a031681565b600254600090600160a060020a038381169116141561029757506001610297565b600354600090600160a060020a038381169116141561029757506001610297565b6000828201610bf784821015610c12565b9392505050565b6000610c0c83831115610c12565b50900390565b801515610b9257600080fd00a165627a7a723058201cc82f152cc60dd4bba9a40ecbefa7a5d07b22653007ca2429b7f953777f66f00029

//abi: [ { "constant": false, "inputs": [ { "name": "token", "type": "address" }, { "name": "amount", "type": "uint256" } ], "name": "reserveToken", "outputs": [], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": false, "inputs": [ { "name": "setAddr", "type": "address" } ], "name": "setLikepoint", "outputs": [ { "name": "", "type": "bool" } ], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": false, "inputs": [ { "name": "setAddr", "type": "address" } ], "name": "setPKC", "outputs": [ { "name": "", "type": "bool" } ], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": false, "inputs": [ { "name": "set", "type": "uint256" } ], "name": "setRate", "outputs": [ { "name": "", "type": "bool" } ], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": false, "inputs": [ { "name": "token", "type": "address" }, { "name": "token2", "type": "address" }, { "name": "amount", "type": "uint256" } ], "name": "swapLikeToPKC", "outputs": [ { "name": "", "type": "bool" } ], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": false, "inputs": [ { "name": "token", "type": "address" }, { "name": "token2", "type": "address" }, { "name": "amount", "type": "uint256" } ], "name": "swapPKCToLike", "outputs": [ { "name": "", "type": "bool" } ], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": false, "inputs": [ { "name": "newOwner", "type": "address" } ], "name": "transferOwnership", "outputs": [], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": false, "inputs": [ { "name": "token", "type": "address" }, { "name": "amount", "type": "uint256" } ], "name": "withdrawByAdmin", "outputs": [ { "name": "", "type": "bool" } ], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "anonymous": false, "inputs": [ { "indexed": false, "name": "token", "type": "address" }, { "indexed": false, "name": "user", "type": "address" }, { "indexed": false, "name": "amount", "type": "uint256" }, { "indexed": false, "name": "balance", "type": "uint256" } ], "name": "Deposit", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": false, "name": "token", "type": "address" }, { "indexed": false, "name": "user", "type": "address" }, { "indexed": false, "name": "amount", "type": "uint256" }, { "indexed": false, "name": "balance", "type": "uint256" } ], "name": "Withdraw", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": false, "name": "token", "type": "address" }, { "indexed": false, "name": "token2", "type": "address" }, { "indexed": false, "name": "user", "type": "address" }, { "indexed": false, "name": "amount", "type": "uint256" }, { "indexed": false, "name": "balanceReturn", "type": "uint256" } ], "name": "SwapLIKE", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": false, "name": "token", "type": "address" }, { "indexed": false, "name": "token2", "type": "address" }, { "indexed": false, "name": "user", "type": "address" }, { "indexed": false, "name": "amount", "type": "uint256" }, { "indexed": false, "name": "balanceReturn", "type": "uint256" } ], "name": "SwapPKC", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": false, "name": "token", "type": "address" }, { "indexed": false, "name": "user", "type": "address" }, { "indexed": false, "name": "amount", "type": "uint256" } ], "name": "Reserve", "type": "event" }, { "constant": true, "inputs": [], "name": "likepoint", "outputs": [ { "name": "", "type": "address" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": true, "inputs": [], "name": "owner", "outputs": [ { "name": "", "type": "address" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": true, "inputs": [], "name": "pkc", "outputs": [ { "name": "", "type": "address" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": true, "inputs": [], "name": "rate", "outputs": [ { "name": "", "type": "uint256" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": true, "inputs": [ { "name": "", "type": "address" }, { "name": "", "type": "address" } ], "name": "tokens", "outputs": [ { "name": "", "type": "uint256" } ], "payable": false, "stateMutability": "view", "type": "function" } ]