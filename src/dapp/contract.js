import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.flightSuretyData = new this.web3.eth.Contract(FlightSuretyData.abi, config.dataAddress);
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];

    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {
           
            let config = Config["localhost"];

            this.owner = accts[0];

            let counter = 1;
            
            while(this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            console.log('Register App contract');
            try {
                this.flightSuretyData.methods.registerAppContract(config.appAddress).send({from: this.owner});
            }
            catch(e) {
                console.log(e);
            }
            

            console.log('Register Airline');
            try {
                this.flightSuretyApp.methods.registerAirline(this.airlines[1], 'UA', 'United Airlines').send({from: this.owner});
            }
            catch(e) {
                console.log(e);
            }

            console.log('Register Flight');
            try {
                this.flightSuretyApp.methods.registerFlight('UAL925-20190801').send({from: airlines[1]});
            }
            catch(e) {
                console.log(e);
            }

            // register flight

            callback();
        });
    }

    isOperational(callback) {
       let self = this;
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
        self.flightSuretyApp.methods
            .getFlightDetails(payload.flight)
            .call({ from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }


    // get flight status
}