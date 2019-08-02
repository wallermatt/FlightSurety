
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

    let airline2 = accounts[2];
    let airline3 = accounts[3];
    let airline4 = accounts[4];
    let airline5 = accounts[5];
    let airline6 = accounts[6];

    await config.flightSuretyApp.airlinePay({from: airline2, value: web3.utils.toWei('10', 'ether')});

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(airline3, 'TEST3', 'Test Airline3', {from: config.owner});
    }
    catch(e) {

    }
    let result3 = await config.flightSuretyData.isRegisteredAirline.call(airline3, {from: config.flightSuretyApp.address}); 

    // ASSERT
    assert.equal(result3, true, "Airline should be able to register new airline if 4 or less airlines registered");

    await config.flightSuretyApp.airlinePay({from: airline3, value: web3.utils.toWei('10', 'ether')});

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(airline4, 'TEST4', 'Test Airline4', {from: config.owner});
    }
    catch(e) {

    }
    let result4 = await config.flightSuretyData.isRegisteredAirline.call(airline4, {from: config.flightSuretyApp.address}); 

    // ASSERT
    assert.equal(result4, true, "Airline should be able to register new airline if 4 or less airlines registered");

    await config.flightSuretyApp.airlinePay({from: airline4, value: web3.utils.toWei('10', 'ether')});

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(airline5, 'TEST5', 'Test Airline5', {from: config.owner});
    }
    catch(e) {

    }
    let result5 = await config.flightSuretyData.isRegisteredAirline.call(airline5, {from: config.flightSuretyApp.address}); 

    // ASSERT
    assert.equal(result5, true, "Airline should be able to register new airline if 4 or less airlines registered");

    await config.flightSuretyApp.airlinePay({from: airline5, value: web3.utils.toWei('10', 'ether')});

     // ACT
    try {
        await config.flightSuretyApp.registerAirline(airline6, 'TEST6', 'Test Airline6', {from: config.owner});
    }
    catch(e) {

    }
    let result6 = await config.flightSuretyData.isRegisteredAirline.call(airline6, {from: config.flightSuretyApp.address}); 

    // ASSERT
    assert.equal(result6, false, "Single airline registration should be false when 5 paid airlines are registered");

  });

  it('Multi-party consensus - half registered and paid airlines required to register airline', async () => {
    
    // ARRANGE

    let airline2 = accounts[2];
    let airline3 = accounts[3];
    let airline4 = accounts[4];
    let airline5 = accounts[5];
    let airline6 = accounts[6];

    let votes1 = await config.flightSuretyData.getAirlineVotes.call(airline6, {from: config.flightSuretyApp.address});
    assert.equal(votes1, 1, 'Initial votes should be one');

     // ACT
     try {
        await config.flightSuretyApp.registerAirline(airline6, 'TEST6', 'Test Airline6', {from: airline2});
    }
    catch(e) {

    }
    let result1 = await config.flightSuretyData.isRegisteredAirline.call(airline6, {from: config.flightSuretyApp.address}); 

    // ASSERT
    assert.equal(result1, false, "Airline needs half total paid airlines to register it");

    let votes2 = await config.flightSuretyData.getAirlineVotes.call(airline6, {from: config.flightSuretyApp.address});
    assert.equal(votes2, 2, 'Votes should be two');

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(airline6, 'TEST6', 'Test Airline6', {from: airline2});
    }
    catch(e) {

    }
    let result2 = await config.flightSuretyData.isRegisteredAirline.call(airline6, {from: config.flightSuretyApp.address}); 

    // ASSERT
    assert.equal(result2, true, "Airline needs half total paid airlines to register it");

    let votes3 = await config.flightSuretyData.getAirlineVotes.call(airline6, {from: config.flightSuretyApp.address});
    assert.equal(votes3, 3, 'Votes should be three');


  });

  it('Multi-party consensus - half registered and paid airlines required to register airline', async () => {

    try {
        let flightKey1 = await config.flightSuretyApp.registerFlight('Flight1', {from: config.owner});
        console.log('FK:', flightKey1);
    }
    catch(e) {
        console.log(e);
    }
    assert.equal(1,2, 'Flight should be registered by paid airline')
  });
 

});
