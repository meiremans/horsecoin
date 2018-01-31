pragma solidity ^0.4.10;
import './StandardToken.sol';

contract HRCSafe {
  mapping (address => uint256) allocations;
  uint256 public unlockDate;
  address public HRC;
  uint256 public constant exponent = 10**18;

  function HRCSafe(address _HRC) {
    HRC = _HRC;
    unlockDate = now + 6 * 30 days; //half a year
    allocations[0x8D3AfE0bd3e0FbF96e6a78103d100C359e0b17e5] = 100000;
    allocations[0x73f787BD3aEcb8cEbc4843C7420542a2660CE433] = 100000;
  }

  function unlock() external {
    if(now < unlockDate) throw;
    uint256 entitled = allocations[msg.sender];
    allocations[msg.sender] = 0;
    if(!StandardToken(HRC).transfer(msg.sender, entitled * exponent)) throw;
  }

}
