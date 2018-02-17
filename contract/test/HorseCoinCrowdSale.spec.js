import ether from './helpers/ether';
import {advanceBlock} from './helpers/advanceToBlock';
import {increaseTimeTo, duration} from './helpers/increaseTime';
import latestTime from './helpers/latestTime';

const BigNumber = web3.BigNumber;


require('chai')
    .use(require('chai-as-promised'))
    .use(require('chai-bignumber')(BigNumber))
    .should();

const HorseCoinCrowdSale = artifacts.require('HorsecoinCrowdsale');
const HorsecoinToken = artifacts.require('Horsecoin');


contract('HorseCoinCrowdSale', function (accounts) {

    let owner = accounts[0];
    let wallet = accounts[1];
    let investor = accounts[3];

    let team = accounts[7];
    let ecosystem = accounts[8];
    let bounty = accounts[9];

    console.log(investor);
    const RATE = new web3.BigNumber(100000); // HOW MUCH TOKEN FOR 1 ETH
    const CAP = new web3.BigNumber(5 * Math.pow(10, 18)); // IN ETH
    const CAP_PREICO = new web3.BigNumber(1 * Math.pow(10, 18));// IN ETH
    const CAP_WAVE1 = CAP_PREICO.add(new web3.BigNumber(1 * Math.pow(10, 18)));// IN ETH
    const CAP_WAVE2 = CAP_WAVE1.add(new web3.BigNumber(1 * Math.pow(10, 18)));// IN ETH
    const CAP_WAVE3 = CAP_WAVE2.add(new web3.BigNumber(1 * Math.pow(10, 18)));// IN ETH
    const CAP_WAVE4 = CAP_WAVE3.add( new web3.BigNumber(1 * Math.pow(10, 18)));// IN ETH
    const GOAL = new web3.BigNumber(3 * Math.pow(10, 18)); // IN ETH


    before(async function () {
        // Advance to the next block to correctly read time in the solidity "now" function interpreted by testrpc
        await advanceBlock();
    });

    beforeEach(async function () {
        this.startTime = (latestTime() + duration.weeks(1));
        this.endTime = this.startTime + duration.weeks(500);
        this.afterEndTime = this.endTime + duration.seconds(90);
        this.crowdsale = await HorseCoinCrowdSale.new(this.startTime, this.endTime, RATE, CAP, GOAL, CAP_PREICO,CAP_WAVE1,CAP_WAVE2,CAP_WAVE3,CAP_WAVE4, wallet, team, ecosystem, bounty);
        this.token = HorsecoinToken.at(await this.crowdsale.token());
    });

    it('should create crowdsale with correct parameters', async function () {
        this.crowdsale.should.exist;
        this.token.should.exist;

        const startTime = await this.crowdsale.startTime();
        const endTime = await this.crowdsale.endTime();
        const rate = await this.crowdsale.rate();
        const walletAddress = await this.crowdsale.wallet();
        const cap = await this.crowdsale.cap();

        startTime.should.be.bignumber.equal(this.startTime);
        endTime.should.be.bignumber.equal(this.endTime);
        rate.should.be.bignumber.equal(RATE);
        walletAddress.should.be.equal(wallet);
        cap.should.be.bignumber.equal(CAP);
    });


    it('should not accept payments before start', async function () {
        transactionFailed(await this.crowdsale.send(ether(1))).should.equal(true);
        transactionFailed(await this.crowdsale.buyTokens(investor, {
            from: investor,
            value: ether(1)
        })).should.equal(true);
    });


    it('should accept payments during the sale', async function () {
        const investmentAmount = ether(1);
        //const expectedTokenAmount = new web3.BigNumber(investmentAmount * RATE);

        await increaseTimeTo(this.startTime);
        transactionFailed(await this.crowdsale.buyTokens(investor, {
            value: investmentAmount,
            from: investor
        })).should.equal(false);

        assert.isAtLeast(await this.token.balanceOf(investor),1,"NO MONEY RECEIVED");

    });

    it('should reject payments after end', async function () {
        await increaseTimeTo(this.afterEndTime);
        transactionFailed(await this.crowdsale.send(ether(1))).should.equal(true);
        transactionFailed(await this.crowdsale.buyTokens(investor, {
            value: ether(1),
            from: investor
        })).should.equal(true);
    });

    it('should reject payments over cap', async function () {
        await increaseTimeTo(this.startTime);
        await this.crowdsale.send(CAP);
        transactionFailed(await this.crowdsale.send(1)).should.equal(true);
    });
    it('cannot be finalized twice', async function () {
        await increaseTimeTo(this.afterEndTime);

        transactionFailed(await this.crowdsale.finalize({from: owner})).should.equal(false);
        transactionFailed(await this.crowdsale.finalize({from: owner})).should.equal(true);
    });
    it('should mint a token', async function () {
        await increaseTimeTo(this.startTime);
        await this.crowdsale.mintTokens(investor, 1);
        (await this.token.balanceOf(investor)).should.be.bignumber.equal(1);

    });

    it('should give the correct amount to the wallets after the crowdsale finalizes', async function () {
        const investmentAmount = 1 * Math.pow(10, 18);
        const forEcosystem = ((investmentAmount * 0.2 * RATE))* 3;
        const forBounties = ((investmentAmount * 0.05) * RATE)* 3;
        const forTeam = (investmentAmount * 0.2 * RATE)* 3;

        await increaseTimeTo(this.startTime);
        transactionFailed(await this.crowdsale.buyTokens(investor, {
            value: investmentAmount,
            from: investor
        })).should.equal(false);
        await increaseTimeTo(this.afterEndTime);
        await this.crowdsale.finalize().should.be.fulfilled;

        (new BigNumber(await this.token.balanceOf(ecosystem))).should.be.bignumber.equal(forEcosystem);
        (new BigNumber(await this.token.balanceOf(bounty))).should.be.bignumber.equal(forBounties);
        (new BigNumber(await this.token.balanceOf(team))).should.be.bignumber.equal(forTeam);
    });

    it('should give the PreIco bonus during pre ICO', async function () {
        const investmentAmount = 1 * Math.pow(10, 18);
        const shouldGet = ((investmentAmount * 0.2 * RATE)* 3)*5;

        await increaseTimeTo(this.startTime);
        transactionFailed(await this.crowdsale.buyTokens(investor, {
            value: investmentAmount,
            from: investor
        })).should.equal(false);
        (await this.token.balanceOf(investor)).toNumber().should.equal(shouldGet);
    });

    it('should give the current Stage', async function () {
        await increaseTimeTo(this.startTime);
        (await this.crowdsale.getCurrentStage()).should.be.bignumber.equal(0);
    });
    it('should increase the stage when over current stage cap', async function () {
        await increaseTimeTo(this.startTime);
        transactionFailed(await this.crowdsale.buyTokens(investor, {
            value:  CAP_PREICO - 100000,
            from: investor
        })).should.equal(false);
        (await this.crowdsale.getCurrentStage()).should.be.bignumber.equal(0);
        transactionFailed(await this.crowdsale.buyTokens(investor, {
            value: 100000,
            from: investor
        })).should.equal(false);
        (await this.crowdsale.getCurrentStage()).should.be.bignumber.equal(1);
    });
    it('should say whether to increment the wave or not', async function () {
       (await this.crowdsale.shouldIncrementWave(0,0,CAP_PREICO)).should.equal(false);
       (await this.crowdsale.shouldIncrementWave(0,CAP_PREICO ,CAP_PREICO)).should.equal(true);
       (await this.crowdsale.shouldIncrementWave(CAP_WAVE1,CAP_PREICO,CAP_WAVE1)).should.equal(true);
       (await this.crowdsale.shouldIncrementWave(CAP_WAVE2,CAP_PREICO,CAP_WAVE2)).should.equal(true);
       (await this.crowdsale.shouldIncrementWave(CAP_WAVE3,CAP_PREICO,CAP_WAVE3)).should.equal(true);
       (await this.crowdsale.shouldIncrementWave(CAP_WAVE4,CAP_PREICO,CAP_WAVE4)).should.equal(true);
    });
});

function transactionFailed(tx) {
    return tx.receipt.status === '0x00';
}