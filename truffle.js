var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat";
var mnemonic = 'repair laptop nasty acoustic drastic trash juice puppy brain result belt soccer';
var mnemonic = 'gentle mobile mixed age wine trumpet bicycle fun minimum mansion robust doll';

module.exports = {
  networks: {
    develop: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "http://127.0.0.1:7545/", 0, 50);
      },
      network_id: '*',
      gas: 9999999,
      accounts: 20,
      port: 7545,
    }
  },
  compilers: {
    solc: {
      version: "^0.4.25"
    }
  }
};