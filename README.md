# horsecoin

Ignore Contract_OLD

Requirements:

node v8.9.3

npm

ganache(https://github.com/trufflesuite/ganache)

truffle (npm install -g truffle) v4.0.5


Getting started: 

cd into contract dir

copy /secret/mnemonic.example.json to /secret/monemonic.json and change it to your mnemonic.
in contracts/HorseCoinCrowdsale change wallet to the wallet you want the money to appear

npm install

truffle migrate

your contract should now be deployed into your ganache network

go to metamask, link it to your ganache network, send some eth to the contract address add the token. and done.

To redeploy:
Delete build directory (or force recompile)
truffle migrate

To deploy to ropsten:
truffle migrate --network ropsten
