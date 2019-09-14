pragma solidity ^0.4.25;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/


    FlightSuretyData flightsuretydata;

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    uint8 private constant INSURANCE_MULTIPLIER = 15;
    uint8 private constant INSURANCE_DIVIDER = 10;


    address private contractOwner;          // Account used to deploy contract


    event debugEvent(string info);
    event debugInt(uint256 number);
    event debugBool(bool flag);
    event debugBytes32(bytes32 flightKey);
    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
         // Modify to call data contract's status
        require(isOperational(), "Contract is currently not operational");  
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor
                                (
                                    address dataContract
                                ) 
                                public
    {
        contractOwner = msg.sender;
        flightsuretydata = FlightSuretyData(dataContract);
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() 
                            public 
                            returns(bool) 
    {
        return flightsuretydata.isOperational();
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

  
   /**
    * @dev Add an airline to the registration queue
    *
    */   
    function registerAirline
                            ( 
                                address airline,
                                string code,
                                string name 
                            )
                            external
                            requireIsOperational
                            returns(bool success, uint newVotes)
    {
        require(flightsuretydata.isPaidAirline(msg.sender), 'Sender not paid airline therefore cannot register another airline');
        bool registered = false;
        uint votes = flightsuretydata.getAirlineVotes(airline) + 1;
        uint256 paidAirlineCount = flightsuretydata.getPaidAirlineCount();
        if (paidAirlineCount <= 4){
            registered = true;
        } else {
            if (votes > paidAirlineCount / 2) {
                registered = true;
            }
        }
        flightsuretydata.registerAirline(airline, code, name, registered);
        return (registered, flightsuretydata.getAirlineVotes(airline));
    }


   /**
    * @dev Register a future flight for insuring.
    *
    */  
    function registerFlight
                                (
                                    string flightCodeDate
                                )
                                external
                                requireIsOperational

    {
        require(flightsuretydata.isPaidAirline(msg.sender), 'Sender not paid airline therefore cannot register a flight');
        uint256 timestamp = now;
        flightsuretydata.registerFlight(flightCodeDate, msg.sender, timestamp, STATUS_CODE_UNKNOWN);
    }

    function getFlightDetails
                            (
                                string flightCodeDate
                            )
                            external
                            requireIsOperational
                            returns(bool, uint8)
    {
        bool isFlightRegistered = flightsuretydata.isFlightRegistered(flightCodeDate);
        uint8 flightStatusCode = 0;
        if (isFlightRegistered) {
            flightStatusCode = flightsuretydata.getFlightStatusCode(flightCodeDate);
        }
        return (isFlightRegistered, flightStatusCode);
    }
    

    function buyInsurance
                        (
                            string flightCodeDate
                        )
                        external
                        payable
                        requireIsOperational
    {
        require(msg.value <= 1 ether, 'Maximum insurance value is 1 ether');
        require(flightsuretydata.isFlightRegistered(flightCodeDate));
        require(flightsuretydata.getFlightStatusCode(flightCodeDate) == STATUS_CODE_UNKNOWN, 'Cannot buy insurance for flight that has completed');
        flightsuretydata.buyInsurance(msg.sender, flightCodeDate, msg.value);
    }


    function getInsurance
                        (
                            string flightCodeDate,
                            address passenger
                        )
                        external
                        view
                        requireIsOperational
                        returns(uint256, bool, bool, bool)
    {
        require(flightsuretydata.isFlightRegistered(flightCodeDate));
        return flightsuretydata.getInsurance(flightCodeDate, passenger); 
    }


    function cancelInsurance
                            (
                                string flightCodeDate
                            )
                            external
                            requireIsOperational
    {
        require(flightsuretydata.isFlightRegistered(flightCodeDate), 'Flight not registered');
        require(flightsuretydata.getFlightStatusCode(flightCodeDate) == STATUS_CODE_UNKNOWN, 'Cannot cancel insurance for flight that has completed');
        (uint256 value, bool cancelled, bool payout, bool paid) = flightsuretydata.getInsurance(flightCodeDate, msg.sender);
        require(value > 0, 'No insurance found');
        require(cancelled == false, 'Insurance has been cancelled');
        require(paid == false, 'Insurance has already paid out');
        require(payout == false, 'Insurance claim can already payout');
        bool cancelSuccess = flightsuretydata.cancelInsurance(flightCodeDate, msg.sender);
        if (cancelSuccess){
            //address payable passenger = address(uint160(_insurance.buyer));
            msg.sender.transfer(value);
        }
    }

    function payoutInsurance
                            (
                               string flightCodeDate 
                            )
                            external
                            requireIsOperational
    {
        require(flightsuretydata.isFlightRegistered(flightCodeDate), 'Flight not registered');
        require(flightsuretydata.getFlightStatusCode(flightCodeDate) != STATUS_CODE_UNKNOWN, 'Cannot claim payout for unknown flight status');
        (uint256 value, bool cancelled, bool payout, bool paid) = flightsuretydata.getInsurance(flightCodeDate, msg.sender);
        require(value > 0, 'No insurance found');
        require(cancelled == false, 'Insurance has been cancelled');
        require(paid == false, 'Insurance has already paid out');
        require(payout == true, 'Insurance must be able to payout');
        bool setPaidSuccess = flightsuretydata.setInsurancePaid(flightCodeDate, msg.sender);
        if (setPaidSuccess){
            uint256 payoutValue = value.mul(INSURANCE_MULTIPLIER).div(INSURANCE_DIVIDER);
            msg.sender.transfer(payoutValue);
        }
    }

    function changeFlightStatusCode
                                    (
                                        string flightCodeDate,
                                        uint8 statusCode
                                    )
                                    internal  // for testing purposes - change later
                                    requireIsOperational
    {
        require(flightsuretydata.isFlightRegistered(flightCodeDate), 'Flight not registered');
        //require(flightsuretydata.getFlightStatusCode(flightCodeDate) == STATUS_CODE_UNKNOWN, 'Flight status already changed');
        bool result = flightsuretydata.changeFlightStatusCode(flightCodeDate, statusCode);
        if (result) {
            if (statusCode >= STATUS_CODE_LATE_AIRLINE) {
                setInsurancePayout(flightCodeDate);
            }
        }
    }

    function ownerChangeFlightStatusCode
                                        (
                                            string flightCodeDate,
                                            uint8 statusCode
                                        )
                                        external
                                        requireIsOperational
    {
        require(msg.sender == contractOwner, 'Only contract owner can call this');
        bool result = flightsuretydata.changeFlightStatusCode(flightCodeDate, statusCode);
        if (result) {
            if (statusCode >= STATUS_CODE_LATE_AIRLINE) {
                setInsurancePayout(flightCodeDate);
            }
        }
    }

    function setInsurancePayout
                                (
                                    string flightCodeDate
                                )
                                internal
                                requireIsOperational
    
    {
        flightsuretydata.setInsurancePayout(flightCodeDate);
    }
   /**
    * @dev Called after oracle has updated flight status
    *
    */  
    function processFlightStatus
                                (
                                    address airline,
                                    string memory flight,
                                    uint256 timestamp,
                                    uint8 statusCode
                                )
                                internal
                                pure
    {
    }


    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus
                        (
                            string flightCodeDate                            
                        )
                        external
                        requireIsOperational
    {
        uint8 index = getRandomIndex(msg.sender);

        oracleResponses[flightCodeDate] = ResponseInfo({
                                                requester: msg.sender,
                                                isOpen: true
                                            });

        emit OracleRequest(index, flightCodeDate);
    }

    function airlinePay()
                        external
                        payable
                        requireIsOperational
    {
        if (msg.value >= 10 ether){
            if (flightsuretydata.isRegisteredAirline(msg.sender)){
                flightsuretydata.airlinePaid(msg.sender);
            }
        }
    }




// region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;    

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 2;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;        
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = string flightCodeDate
    mapping(string => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(string flightCodeDate, uint8 status);

    event OracleReport(string flightCodeDate, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, string flightCodeDate);


    // Register an oracle with the contract
    function registerOracle
                            (
                            )
                            external
                            payable
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
    }

    function getMyIndexes
                            (
                            )
                            view
                            external
                            returns(uint8[3])
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }




    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse
                        (
                            uint8 index,
                            string flightCodeDate,
                            uint8 statusCode
                        )
                        external
    {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");

        require(oracleResponses[flightCodeDate].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[flightCodeDate].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(flightCodeDate, statusCode);
        if (oracleResponses[flightCodeDate].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(flightCodeDate, statusCode);

            // Handle flight status as appropriate
            changeFlightStatusCode(flightCodeDate, statusCode);
        }
    }


    function getFlightKey
                        (
                            address airline,
                            string flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes
                            (                       
                                address account         
                            )
                            internal
                            returns(uint8[3])
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);
        
        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex
                            (
                                address account
                            )
                            internal
                            returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion

}

contract FlightSuretyData {
    function isOperational() external view returns(bool);
    function registerAirline(address airline, string code, string name, bool registered) external;
    function isRegisteredAirline(address airline) external view returns(bool);
    function isPaidAirline(address airline) external view returns(bool);
    function getAirlineVotes(address airline) external view returns(uint);
    function getRegisteredAirlineCount() external  view returns(uint256);
    function getPaidAirlineCount() external  view returns(uint256);
    function airlinePaid(address airline) external;
    function registerFlight(string flightCodeDate, address airline, uint256 timestamp, uint8 flightStatus) external;
    function isFlightRegistered(string flightCodeDate) external view returns(bool);
    function buyInsurance(address purchaser, string flightCodeDate, uint256 purchasedValue) external;
    function getInsurance(string flightCodeDate, address passenger) external view returns(uint256, bool, bool, bool);
    function cancelInsurance(string flightCodeDate, address passenger) external returns(bool);
    function getFlightStatusCode(string flightCodeDate) external view returns(uint8);
    function setInsurancePaid(string flightCodeDate, address passenger) external returns(bool);
    function changeFlightStatusCode(string flightCodeDate, uint8 statusCode) external returns(bool);
    function setInsurancePayout(string flightCodeDate) external;
}
