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
    address remainingTokensWallet = 0xb8D2Adb361e3C631951b636Dd6f68C7182d2E6c6;

    // Amount raised in PreICO
    // -------------------------
    uint256 public totalWeiInPreICO;
    // -----------------------
    uint256 private bonus;
    uint256 private tokensCap;
    bool isFinalized;

    // Token Distribution
    // -------------------
    uint256 public tokensForEcosystem = 100000000 * power(10, 18); // There will be total 100.000.000 HRC Tokens fot the ecosystem
    uint256 public tokensForTeam = 100000000 * power(10, 18);// There will be total 100.000.000 HRC Tokens for the team
    uint256 public tokensForBounty = 100000000 * power(10, 18); // There will be total 100.000.000 HRC Tokens for bounties
    uint256 public totalTokensForSale = 100000000 * power(10, 18); // 100.000.000 HRCs will be sold in Crowdsale
    uint256 public totalTokensForSaleDuringPreICO = 10000000 * power(10, 18); // 10.000.000 out of 500.000.000 HRC will be sold during PreICO
    // ==============================

    function power(uint256 A, uint256 B) public returns (uint256){
        return A ** B;
    }

    // Events
    event EthTransferred(string text);
    event EthRefunded(string text);
    event TokenMint(address indexed beneficiary, uint256 amount);


    function HorseCoinCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, uint256 _cap, uint256 _goal, address _wallet) public
    CappedCrowdsale(_cap)
    FinalizableCrowdsale()
    RefundableCrowdsale(_goal)
    Crowdsale(_startTime, _endTime, _rate, _wallet) {
        require(_goal <= _cap);
        remainingTokensWallet = _wallet;
        wallet = _wallet;
        tokensCap = _cap;
        // allocate tokens to Owners
        mintTokens(_wallet, tokensForTeam);
        mintTokens(_wallet, tokensForEcosystem);
        mintTokens(_wallet, tokensForBounty);
    }

    // HRC Crowdsale Stages
    // -----------------------

    // Change Crowdsale Stage. Available Options: PreICO, ICOWave1

    //TODO: Automate switch of stage
    function setCrowdsaleStage(uint value) public onlyOwner {
        CrowdsaleStage _stage;

        if (uint(CrowdsaleStage.PreICO) == value) {
            _stage = CrowdsaleStage.PreICO;
        } else if (uint(CrowdsaleStage.ICOWave1) == value) {
            _stage = CrowdsaleStage.ICOWave1;
        }

        stage = _stage;

        if (stage == CrowdsaleStage.PreICO) {setCurrentBonus(200);}
        if (stage == CrowdsaleStage.ICOWave1) {setCurrentBonus(100);}
        if (stage == CrowdsaleStage.ICOWave2) {setCurrentBonus(75);}
        if (stage == CrowdsaleStage.ICOWave3) {setCurrentBonus(50);}
        if (stage == CrowdsaleStage.ICOWave4) {setCurrentBonus(25);}
    }

    // Change the current bonus
    function setCurrentBonus(uint256 _bonus) private {
        bonus = _bonus;
    }

    //---------------------------end stages----------------------------------

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
        return super.getTokenAmount((weiAmount) + (weiAmount * bonus));
        //give them the bonus
    }

    // Override to create custom fund forwarding mechanisms
    // Forwards funds to the specified wallet by default
    function forwardFunds() internal {
        if (stage == CrowdsaleStage.PreICO) {
            wallet.transfer(msg.value);
            totalWeiInPreICO = totalWeiInPreICO.add(msg.value);
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
        //mint tokens up to total cap
         if (token.totalSupply() < tokensCap) {
          mintTokens(remainingTokensWallet, tokensCap.sub(token.totalSupply()));
         }
        //no more tokens from now on
         token.finishMinting();
        isFinalized = true;
        return super.finalization();
    }


    function mintTokens(address beneficiary, uint256 tokens) public onlyOwner {
        require(beneficiary != 0x0);

        // Cannot mint after sale is closed
        require(!isFinalized);


        token.mint(beneficiary, tokens);
        TokenMint(beneficiary, tokens);
    }
}