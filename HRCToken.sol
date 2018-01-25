pragma solidity ^0.4.10;
import "./StandardToken.sol";
import "./SafeMath.sol";

contract HRCToken is StandardToken, SafeMath {

    // metadata
    string public constant name = "Horsecoin";
    string public constant symbol = "HRC";
    uint256 public constant decimals = 0;
    string public version = "0.1";

    // contracts
    address public ethFundDeposit;      // deposit address for ETH for AB-IT
    address public hrcFundDeposit;      // deposit address for AB-IT use and HRC User Fund

    // crowdsale parameters
    bool public isFinalized;              // switched to true in operational state
    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;
    uint256 public constant hrcFund = 500 * (10**6) * 10**decimals;   // 500m HRC reserved for Horsecoin use
    uint256 public constant tokenExchangeRate = 10000; // 10000 HRC tokens per 1 ETH
    uint256 public constant tokenCreationCap =  2 * (10**6) * 10**decimals;//200.000.000 HRC TOKENS MAX
    uint256 public constant tokenCreationMin =  1 * (10**6) * 10**decimals;//100.000.000 HRC TOKENS MIN


    // events
    event LogRefund(address indexed _to, uint256 _value);
    event CreateHRC(address indexed _to, uint256 _value);

    // constructor
    function HRCToken(
        address _ethFundDeposit,
        address _hrcFundDeposit,
        uint256 _fundingStartBlock,
        uint256 _fundingEndBlock)
    {
      isFinalized = false;                   //controls pre through crowdsale state
      ethFundDeposit = _ethFundDeposit;
      hrcFundDeposit = _hrcFundDeposit;
      fundingStartBlock = _fundingStartBlock;
      fundingEndBlock = _fundingEndBlock;
      totalSupply = hrcFund;
      balances[hrcFundDeposit] = hrcFund;    // Deposit AB-IT share
      CreateHRC(hrcFundDeposit, hrcFund);  // logs AB-IT fund
    }

    /// @dev Accepts ether and creates new HRC tokens.
    function createTokens() payable external {
      if (isFinalized) throw;
      if (block.number < fundingStartBlock) throw;
      if (block.number > fundingEndBlock) throw;
      if (msg.value == 0) throw;

      uint256 tokens = safeMult(msg.value, tokenExchangeRate); // check that we're not over totals
      uint256 checkedSupply = safeAdd(totalSupply, tokens);

      // return money if something goes wrong
      if (tokenCreationCap < checkedSupply) throw;  // odd fractions won't be found

      totalSupply = checkedSupply;
      balances[msg.sender] += tokens;  // safeAdd not needed; bad semantics to use here
      CreateHRC(msg.sender, tokens);  // logs token creation
    }

    /// @dev Ends the funding period and sends the ETH home
    function finalize() external {
      if (isFinalized) throw;
      if (msg.sender != ethFundDeposit) throw; // locks finalize to the ultimate ETH owner
      if(totalSupply < tokenCreationMin) throw;      // have to sell minimum to move to operational
      if(block.number <= fundingEndBlock && totalSupply != tokenCreationCap) throw;
      // move to operational
      isFinalized = true;
      if(!ethFundDeposit.send(this.balance)) throw;  // send the eth to AB-IT
    }

    /// @dev Allows contributors to recover their ether in the case of a failed funding campaign.
    function refund() external {
      if(isFinalized) throw;                       // prevents refund if operational
      if (block.number <= fundingEndBlock) throw; // prevents refund until sale period is over
      if(totalSupply >= tokenCreationMin) throw;  // no refunds if we sold enough
      uint256 hrcVal = balances[msg.sender];
      if (hrcVal == 0) throw;
      balances[msg.sender] = 0;
      totalSupply = safeSubtract(totalSupply, hrcVal); // extra safe
      uint256 ethVal = hrcVal / tokenExchangeRate;     // should be safe; previous throws covers edges
      LogRefund(msg.sender, ethVal);               // log it 
      if (!msg.sender.send(ethVal)) throw;       // if you're using a contract; make sure it works with .send gas limits
    }

}
