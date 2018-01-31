pragma solidity 0.4.18;
import 'zeppelin-solidity/contracts/token/ERC20/MintableToken.sol';

contract HorseCoin is MintableToken {
    string public name = "HORSECOIN";
    string public symbol = "HRC";
    uint8 public decimals = 18;
}