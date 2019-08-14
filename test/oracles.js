
var Test = require('../config/testConfig.js');
//var BigNumber = require('bignumber.js');

contract('Oracles', async (accounts) => {

  const TEST_ORACLES_COUNT = 10;

  // Watch contract events
  const STATUS_CODE_UNKNOWN = 0;
  const STATUS_CODE_ON_TIME = 10;
  const STATUS_CODE_LATE_AIRLINE = 20;
  const STATUS_CODE_LATE_WEATHER = 30;
  const STATUS_CODE_LATE_TECHNICAL = 40;
  const STATUS_CODE_LATE_OTHER = 50;


  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.registerAppContract(config.flightSuretyApp.address, {from: config.owner});
   
    // Watch contract events
    const STATUS_CODE_UNKNOWN = 0;
    const STATUS_CODE_ON_TIME = 10;
    const STATUS_CODE_LATE_AIRLINE = 20;
    const STATUS_CODE_LATE_WEATHER = 30;
    const STATUS_CODE_LATE_TECHNICAL = 40;
    const STATUS_CODE_LATE_OTHER = 50;

  });


  it('can register oracles', async () => {
    
    // ARRANGE
    let fee = await config.flightSuretyApp.REGISTRATION_FEE.call({from: accounts[0]});

    console.log('FEE:', fee);

    // ACT
    for(let a=1; a<TEST_ORACLES_COUNT; a++) {      
      await config.flightSuretyApp.registerOracle({ from: accounts[a], value: fee });
      let result = await config.flightSuretyApp.getMyIndexes.call({from: accounts[a]});
      console.log(`Oracle Registered: ${result[0]}, ${result[1]}, ${result[2]}`);
    }

  });

  it('can request flight status', async () => {
    
    // ARRANGE
    let flightCodeDate = 'UAL925-20190805'; 

    try {
      await config.flightSuretyApp.registerFlight(flightCodeDate, {from: config.owner});
  }
  catch(e) {
      console.log(e);
  }

    // Submit a request for oracles to get status information for a flight
    let statusCode = await config.flightSuretyData.getFlightStatusCode.call(flightCodeDate, {from: config.flightSuretyApp.address});
    console.log('Old Status:', statusCode);
    assert.equal(statusCode, 0, 'Status code not initial/0');
    // ACT

    await config.flightSuretyApp.fetchFlightStatus(flightCodeDate, {from: config.owner});

    // Since the Index assigned to each test account is opaque by design
    // loop through all the accounts and for each account, all its Indexes (indices?)
    // and submit a response. The contract will reject a submission if it was
    // not requested so while sub-optimal, it's a good test of that feature
    for(let a=1; a<TEST_ORACLES_COUNT; a++) {

      // Get oracle information
      let oracleIndexes = await config.flightSuretyApp.getMyIndexes.call({ from: accounts[a]});
      for(let idx=0;idx<3;idx++) {

        try {
          // Submit a response...it will only be accepted if there is an Index match
          await config.flightSuretyApp.submitOracleResponse(oracleIndexes[idx], flightCodeDate, STATUS_CODE_ON_TIME, { from: accounts[a] });

        }
        catch(e) {
          // Enable this when debugging
           console.log('\nError', idx, oracleIndexes[idx].toNumber(), flightCodeDate, e);
        }

      }
      

      }
      let statusCode2 = await config.flightSuretyData.getFlightStatusCode.call(flightCodeDate, {from: config.flightSuretyApp.address});
      console.log('New Status:', statusCode2.toNumber());
      assert.equal(statusCode2, STATUS_CODE_ON_TIME, 'Status code not ON_TIME/10');
      console.log('New Status:', statusCode2);


  });


 
});
