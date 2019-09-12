import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';


let config = Config['localhost'];
let web3 = new Web3(config.url.replace('http', 'ws'));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);

console.log("Run server");


let flightSuretyData = new web3.eth.Contract(FlightSuretyData.abi, config.dataAddress);


(async() => {
  console.log('async');
  /*
  const TEST_ORACLES_COUNT = 10;
  let accounts = await web3.eth.getAccounts();
  let fee = await config.flightSuretyApp.REGISTRATION_FEE.call({from: accounts[0]});

  for(let a=1; a<TEST_ORACLES_COUNT; a++) {      
    await config.flightSuretyApp.registerOracle({ from: accounts[a], value: fee });
    let result = await config.flightSuretyApp.getMyIndexes.call({from: accounts[a]});
    console.log(`Oracle Registered: ${result[0]}, ${result[1]}, ${result[2]}`);
  }
  */

})();


flightSuretyApp.events.OracleRequest({
    fromBlock: 0
  }, function (error, event) {
    if (error) console.log(error)
    console.log(event)
});

const app = express();
app.get('/api', (req, res) => {
    res.send({
      message: 'An API for use with your Dapp!'
    })
})

export default app;


