pragma solidity ^0.4.18;

import './Horsecoin.sol';
import "zeppelin-solidity/contracts/crowdsale/CappedCrowdsale.sol";
import "zeppelin-solidity/contracts/crowdsale/RefundableCrowdsale.sol";
import 'zeppelin-solidity/contracts/crowdsale/Crowdsale.sol';
import "zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";


contract HorseCoinCrowdsale is CappedCrowdsale, RefundableCrowdsale {

    enum CrowdsaleStage {PreICO, ICOWave1, ICOWave2, ICOWave3, ICOWave4}
    CrowdsaleStage public stage = CrowdsaleStage.PreICO;


    address wallet = 0xb8D2Adb361e3C631951b636Dd6f68C7182d2E6c6;

    // Amount raised in PreICO
    // -------------------------
    uint256 public totalWeiInPreICO;
    // -----------------------

    // Events
    event EthTransferred(string text);
    event EthRefunded(string text);


    function HorseCoinCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, uint256 _cap, uint256 _goal, address _wallet) public
    CappedCrowdsale(_cap)
    FinalizableCrowdsale()
    RefundableCrowdsale(_goal)
    Crowdsale(_startTime, _endTime, _rate, _wallet) {
        require(_goal <= _cap);

    }

    // HRC Crowdsale Stages
    // -----------------------

    // Change Crowdsale Stage. Available Options: PreICO, ICO

    function setCrowdsaleStage(uint value) public onlyOwner {

        CrowdsaleStage _stage;

        if (uint(CrowdsaleStage.PreICO) == value) {
            _stage = CrowdsaleStage.PreICO;
        } else if (uint(CrowdsaleStage.ICOWave1) == value) {
            _stage = CrowdsaleStage.ICOWave1;
        }

        stage = _stage;

        if (stage == CrowdsaleStage.PreICO) {
            setCurrentRate(2);
        } else if (stage == CrowdsaleStage.ICOWave1) {
            setCurrentRate(1); //TODO: must be 1.5 for first wave
        }
    }

    // Change the current rate
    function setCurrentRate(uint256 _rate) private {
        rate = _rate;
    }

    //---------------------------end stages----------------------------------

    // Token Purchase
    // ------------------------


    // creates the token to be sold.
    // override this method to have crowdsale of a specific MintableToken token.
    function createTokenContract() internal returns (MintableToken) {
        return new HorseCoin();
    }
    // Override to indicate when the crowdsale ends and does not accept any more contributions
    // Checks endTime by default, plus cap from CappedCrowdsale
    function hasEnded() public view returns (bool) {
        return super.hasEnded();
    }

    // Override this method to have a way to add business logic to your crowdsale when buying
    // Returns weiAmount times rate by default
    function getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return super.getTokenAmount(weiAmount * rate);
    }

    // Override to create custom fund forwarding mechanisms
    // Forwards funds to the specified wallet by default
    function forwardFunds() internal {
        if (stage == CrowdsaleStage.PreICO) {
            wallet.transfer(msg.value);
            EthTransferred("forwarding funds to wallet");
        } else if (stage == CrowdsaleStage.ICOWave1) {
            super.forwardFunds();
            EthTransferred("forwarding funds to vault");
        }
    }

    // Criteria for accepting a purchase
    // Make sure to call super.validPurchase(), or all the criteria from parents will be overwritten
    function validPurchase() internal view returns (bool) {
        return super.validPurchase();
    }

    // Override to execute any logic once the crowdsale finalizes
    // Requires a call to the public finalize method, only after the sale hasEnded
    function finalization() internal {
        return super.finalization();
    }
}