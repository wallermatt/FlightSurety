import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        this.config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(this.config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, this.config.appAddress);
        this.flightSuretyData = new this.web3.eth.Contract(FlightSuretyData.abi, this.config.dataAddress);
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];

    }

    async initialize(callback) {
        let accounts = await this.web3.eth.getAccounts();


        this.owner = accounts[0];


            console.log('Register App contract');
            try {
                await this.flightSuretyData.methods.registerAppContract(this.config.appAddress).send({from: this.owner})
            }
            catch(e) {
                console.log(e);
            }
            

            console.log('Register Airline');
            try {
                await this.flightSuretyApp.methods.registerAirline(accounts[1], 'UA', 'United Airlines').send({from: this.owner, gas: 1500000});
            }
            catch(e) {
                console.log(e);
            }

            console.log('Register Flight');
            try {
                await this.flightSuretyApp.methods.registerFlight('UAL925-20190801').send({from: this.owner, gas: 1500000});
            }
            catch(e) {
                console.log(e);
            }
            console.log('Flight Registered');
            // register flight
            callback();
    }

    isOperational(callback) {
       let self = this;
       console.log('isOperational');
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }

    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        } 
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }

    getFlightDetails(flight, callback) {
        let self = this;
        let payload = {
            flight: flight,
        } 
        console.log('getFlightDetails');
        self.flightSuretyApp.methods
            .getFlightDetails(payload.flight)
            .send({ from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }


    // get flight status
}