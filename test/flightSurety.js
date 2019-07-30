
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.registerAppContract(config.flightSuretyApp.address, {from: config.owner});
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try 
      {
          await config.flightSurety.setTestingMode(true);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);

  });


  it('Initial airline registered on deployment', async () => {
      let count = await config.flightSuretyData.getPaidAirlineCount.call({from: config.flightSuretyApp.address});
      assert.equal(count, 1, "Airline not registered on deployment")
  });

  it('(airline) can register an Airline using registerAirline() if it is funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[2];

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(newAirline, 'TEST', 'Test Airline', {from: config.owner});
    }
    catch(e) {

    }

    // ASSERT
    let result = await config.flightSuretyData.isRegisteredAirline.call(newAirline, {from: config.flightSuretyApp.address}); 
    assert.equal(result, true, "Paid airline should be able to register another airline");

  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[2];
    let newerAirline = accounts[3];

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(newerAirline, 'TEST2', 'Test Airline2', {from: newAirline});
    }
    catch(e) {

    }
    let result = await config.flightSuretyData.isRegisteredAirline.call(newerAirline, {from: config.flightSuretyApp.address}); 

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  it('Only 4 airlines can be registered by single airline before multi-party consensus is required', async () => {
    
    // ARRANGE

    let airline3 = accounts[3];
    let airline4 = accounts[4];
    let airline5 = accounts[5];

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(airline3, 'TEST3', 'Test Airline3', {from: config.owner});
    }
    catch(e) {

    }
    let result3 = await config.flightSuretyData.isRegisteredAirline.call(airline3, {from: config.flightSuretyApp.address}); 

    // ASSERT
    assert.equal(result3, true, "Airline should be able to register new airline if 4 or less airlines registered");

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(airline4, 'TEST4', 'Test Airline4', {from: config.owner});
    }
    catch(e) {

    }
    let result4 = await config.flightSuretyData.isRegisteredAirline.call(airline4, {from: config.flightSuretyApp.address}); 

    // ASSERT
    assert.equal(result4, true, "Airline should be able to register new airline if 4 or less airlines registered");

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(airline5, 'TEST5', 'Test Airline5', {from: config.owner});
    }
    catch(e) {

    }
    let result5 = await config.flightSuretyData.isRegisteredAirline.call(airline5, {from: config.flightSuretyApp.address}); 

    // ASSERT
    assert.equal(result5, false, "Airline should be able to register new airline if 4 or less airlines registered");


  });
 

});
