const HorsecoinCrowdsale = artifacts.require("./../contracts/HorsecoinCrowdsale.sol");
const Web3 = require('web3');

module.exports = function (deployer, network, accounts) {
    const RATE = 100000;
    //TODO: when truffleHdwallet finally upgrades to the new web3 provider, rewrite with promises
    web3.eth.getBlockNumber((e, blocknr) => {
        if (!e) {
            web3.eth.getBlock(blocknr, (e, block) => {
                if(e) {console.error('error' + e);}

                if (block) {
                    console.log(block);
                    const startTime = block.timestamp + duration.seconds(1); // one second in the future
                    const endTime = startTime + duration.minutes(5);//TODO: RESET TO: duration.days(178); // half a year
                    const rate = new web3.BigNumber(RATE);
                    const cap = new web3.BigNumber(5 * Math.pow(10, 18));
                    const goal = new web3.BigNumber(3 *Math.pow(10, 18));
                    console.log(cap);
                    const wallet = accounts[0];

                    deployer.deploy(HorsecoinCrowdsale, startTime, endTime, rate, cap, goal, wallet).then( async () => {
                        const instance = await HorsecoinCrowdsale.deployed();
                        const token = await instance.token.call();

                        console.log('-----> Token Address', token);
                        console.log('-----> startTime:  ', new Date(startTime*1000).toISOString());
                        console.log('-----> endTime:    ', new Date(endTime*1000).toISOString());
                        console.log('-----> rate:       ', rate.toString());
                        console.log('-----> wallet:     ', wallet);
                        console.log('-----> cap:        ', cap);
                        console.log('-----> goal:       ', goal);

                    }).catch(console.error);
                }
                else {
                    console.error('CANNOT GET ETH BLOCK, RETRY PLS')
                }
            })
        }
    })
};

const duration = {
    seconds: function (val) {
        return val
    },
    minutes: function (val) {
        return val * this.seconds(60)
    },
    hours: function (val) {
        return val * this.minutes(60)
    },
    days: function (val) {
        return val * this.hours(24)
    },
    weeks: function (val) {
        return val * this.days(7)
    },
    years: function (val) {
        return val * this.days(365)
    }
};