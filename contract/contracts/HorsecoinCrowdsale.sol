pragma solidity ^0.4.18;

import './Horsecoin.sol';
import './MathHelp.sol';
import "zeppelin-solidity/contracts/crowdsale/CappedCrowdsale.sol";
import "zeppelin-solidity/contracts/crowdsale/RefundableCrowdsale.sol";
import 'zeppelin-solidity/contracts/crowdsale/Crowdsale.sol';
import "zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "zeppelin-solidity/contracts/token/ERC20/PausableToken.sol";


contract HorseCoinCrowdsale is CappedCrowdsale, RefundableCrowdsale, Pausable {

    enum CrowdsaleStage {PreICO, ICOWave1, ICOWave2, ICOWave3, ICOWave4, ICOFinished}
    CrowdsaleStage public stage = CrowdsaleStage.PreICO;

    MathHelp math = new MathHelp();
    address private wallet;
    address private teamWallet;
    address private ecosystemWallet;
    address private bountyWallet;
    address private remainingTokensWallet;

    // Amount raised in PreICO
    // -------------------------
    uint256 public totalWeiInPreICO;
    uint256 public totalWeiInICO;
    // -----------------------
    uint256 private bonus;
    uint256 private rate;
    uint256 private tokensCap;
    uint256 private PRE_ICO_CAP_ETH;
    uint256 private CAP_WAVE1;
    uint256 private CAP_WAVE2;
    uint256 private CAP_WAVE3;
    uint256 private CAP_WAVE4;
    bool isFinalized;

    // Token Distribution
    // -------------------
    uint256 public tokensForEcosystem = 100000000 * math.power(10, 18); // There will be total 100.000.000 HRC Tokens fot the ecosystem
    uint256 public tokensForTeam = 50000000 * math.power(10, 18);// There will be total 50.000.000 HRC Tokens for the team
    uint256 public tokensForBounty = 1000000 * math.power(10, 18); // There will be total 1.000.000 HRC Tokens for bounties
    uint256 public totalTokensForSale = 339000000 * math.power(10, 18); // 339.000.000 HRCs will be sold in Crowdsale
    uint256 public totalTokensForSaleDuringPreICO;


    // ==============================

    // Events
    event EthTransferred(string text);
    event EthRefunded(string text);
    event TokenMint(address indexed beneficiary, uint256 amount);

    /**
        * @dev Contructor
        * @param _startTime startTime of crowdsale
        * @param _endTime endTime of crowdsale
        * @param _rate HRC / ETH rate
        * @param _cap The cap in WEI(hardcap)
        * @param _goal the goal in WEI(softcap)
        * @param _wallet wallet on which the contract gets created
        * @param _teamWallet wallet for the team
        * @param _ecosystemWallet wallet for the ecosystem
        * @param _bountyWallet wallet for the bounties
    */
    function HorseCoinCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, uint256 _cap, uint256 _goal, uint256 _preIcoCap,uint256 _capWave1,uint256 _capWave2,uint256 _capWave3,uint256 _capWave4, address _wallet, address _teamWallet, address _ecosystemWallet, address _bountyWallet) public
    CappedCrowdsale(_cap)
    FinalizableCrowdsale()
    RefundableCrowdsale(_goal)
    Crowdsale(_startTime, _endTime, _rate, _wallet) {
        require(_goal <= _cap);
        remainingTokensWallet = _wallet;
        wallet = _wallet;
        tokensCap = _cap;
        rate = _rate;
        PRE_ICO_CAP_ETH = _preIcoCap;
        CAP_WAVE1 = _capWave1;
        CAP_WAVE2 = _capWave2;
        CAP_WAVE3 = _capWave3;
        CAP_WAVE4 = _capWave4;
        teamWallet = _teamWallet;
        ecosystemWallet = _ecosystemWallet;
        bountyWallet = _bountyWallet;

        totalTokensForSaleDuringPreICO = _preIcoCap * _rate; //PRE-ICO CAP IS IN WEI, CONVERT TO TOKEN AMOUNT
        setCrowdsaleStage(stage);
    }

    // HRC Crowdsale Stages
    // -----------------------

    // Change Crowdsale Stage. Available Options: PreICO, ICOWave1, ICOWave2, ICOWave3, ICOWave4

    function setCrowdsaleStage(CrowdsaleStage _stage) private {

        if (_stage == CrowdsaleStage.PreICO) {setCurrentBonus(200);}
        if (_stage == CrowdsaleStage.ICOWave1) {setCurrentBonus(100);}
        if (_stage == CrowdsaleStage.ICOWave2) {setCurrentBonus(75);}
        if (_stage == CrowdsaleStage.ICOWave3) {setCurrentBonus(50);}
        if (_stage == CrowdsaleStage.ICOWave4) {setCurrentBonus(25);}

        stage = _stage;
    }

    function getCurrentStage() public constant returns (CrowdsaleStage){
        return stage;
    }

    function currentWaveCap() public constant returns (uint256) {
        if (stage == CrowdsaleStage.PreICO) {
            return PRE_ICO_CAP_ETH;
        }
        if (stage == CrowdsaleStage.ICOWave1) {
            return CAP_WAVE1;
        }
        if (stage == CrowdsaleStage.ICOWave2) {
            return CAP_WAVE2;
        }
        if (stage == CrowdsaleStage.ICOWave3) {
            return CAP_WAVE3;
        }
        if (stage == CrowdsaleStage.ICOWave4) {
            return CAP_WAVE4;
        }
    }

    function incrementWave() private {
        if (stage == CrowdsaleStage.PreICO) {
            setCrowdsaleStage(CrowdsaleStage.ICOWave1);
            return;
        }
        if (stage == CrowdsaleStage.ICOWave1) {
            setCrowdsaleStage(CrowdsaleStage.ICOWave2);

            return;
        }
        if (stage == CrowdsaleStage.ICOWave2) {
            setCrowdsaleStage(CrowdsaleStage.ICOWave3);
            return;
        }
        if (stage == CrowdsaleStage.ICOWave3) {
            setCrowdsaleStage(CrowdsaleStage.ICOWave4);
            return;
        }
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
        return super.getTokenAmount(weiAmount + math.getPercentAmount(weiAmount, bonus, 18));
        //give them the bonus
    }

    // Override to create custom fund forwarding mechanisms
    // Forwards funds to the specified wallet by default
    function forwardFunds() internal {
        if (stage == CrowdsaleStage.PreICO) {
            wallet.transfer(msg.value);
            totalWeiInPreICO = totalWeiInPreICO + msg.value;
            if (shouldIncrementWave(totalWeiInICO,totalWeiInPreICO,currentWaveCap())) {
                incrementWave();
            }
            EthTransferred("forwarding funds to wallet");
        } else {
            super.forwardFunds();
            totalWeiInICO = totalWeiInICO.add(msg.value);
            EthTransferred("forwarding funds to vault");
            if (shouldIncrementWave(totalWeiInICO,totalWeiInPreICO,currentWaveCap())) {
                incrementWave();
            }

        }
    }

    function shouldIncrementWave(uint256 _totalWeiInICO, uint256 _totalWeiInPreIco, uint256 _currentWaveCap) constant public returns (bool){
        return (_totalWeiInICO + _totalWeiInPreIco) >= _currentWaveCap;
    }

    // Criteria for accepting a purchase
    // Make sure to call super.validPurchase(), or all the criteria from parents will be overwritten
    function validPurchase() internal view returns (bool) {
        return super.validPurchase();
    }

    // Override to execute any logic once the crowdsale finalizes
    // Requires a call to the public finalize method, only after the sale hasEnded
    function finalization() internal {
        uint256 totalSold = token.totalSupply();

        //mint tokens up to total cap
        if (token.totalSupply() < tokensCap) {
            mintTokens(remainingTokensWallet, tokensCap.sub(token.totalSupply()));
        }
        //no more tokens from now on
        token.finishMinting();
        return super.finalization();
    }

    function finalize() public {

        uint256 tokenSupplyBeforeExtraMinting = token.totalSupply();
        require(!isFinalized);
        require(hasEnded());
        mintTokens(teamWallet, math.getPercentAmount(tokenSupplyBeforeExtraMinting, 20, 18));
        mintTokens(bountyWallet, math.getPercentAmount(tokenSupplyBeforeExtraMinting, 5, 18));
        mintTokens(ecosystemWallet, math.getPercentAmount(tokenSupplyBeforeExtraMinting, 20, 18));
        finalization();
        isFinalized = true;
    }


    function mintTokens(address beneficiary, uint256 tokens) whenNotPaused public onlyOwner {
        require(beneficiary != 0x0);
        // Cannot mint after sale is closed
        require(!isFinalized);
        token.mint(beneficiary, tokens);
        TokenMint(beneficiary, tokens);
    }
}