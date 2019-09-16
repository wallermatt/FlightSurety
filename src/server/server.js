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

const TEST_ORACLES_COUNT = 10;
let flightSuretyData = new web3.eth.Contract(FlightSuretyData.abi, config.dataAddress);
let oracleList = [];

(async() => {
  console.log('async');
  let accounts = await web3.eth.getAccounts();
  console.log('Accounts');
  let fee = await flightSuretyApp.methods.REGISTRATION_FEE().call({from: accounts[0]});
  console.log('FEE: ', fee);

  for(let a=1; a<TEST_ORACLES_COUNT; a++) {      
    await flightSuretyApp.methods.registerOracle().send({ from: accounts[a], value: fee, gas: 3000000 });
    let result = await flightSuretyApp.methods.getMyIndexes().call({from: accounts[a]});
    oracleList.push({'account': accounts[a],'indexes': result});
    console.log(`Oracle Registered: ${result[0]}, ${result[1]}, ${result[2]}`);
  }

})();


flightSuretyApp.events.OracleRequest({
    fromBlock: 0
  }, function (error, event) {
    if (error) {
      console.log(error);
    }
    else {
      if (oracleList.length == 0){
        console.log('No oracles registered yet!!!');
        return;
      }
      console.log('Oracle Request Event Detected');
      let statusCode = Math.floor(Math.random() * 6) * 10;
      console.log(event.returnValues.flightCodeDate, event.returnValues.index);
      for(let a=0; a<(TEST_ORACLES_COUNT - 1); a++) {
        console.log('Oracle Request Event Detected', a, oracleList[a]['account'], oracleList[a]['indexes']);
        if (oracleList[a]['indexes'].includes(event.returnValues.index)) {
          flightSuretyApp.methods.submitOracleResponse(
            event.returnValues.index,
            event.returnValues.flightCodeDate,
            statusCode
          ).send({from: oracleList[a]['account'], gas:5000000});
          console.log('Submitted Oracle Request');
        }
      }
    }
});

const app = express();
app.get('/api', (req, res) => {
    res.send({
      message: 'An API for use with your Dapp!'
    })
})

export default app;


