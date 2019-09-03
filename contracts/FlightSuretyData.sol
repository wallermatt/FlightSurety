pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false

    mapping(address => bool) private registeredAppContracts;            // List of registered app addresses address

    struct airline {
        string code;
        string name;
        bool registered;
        bool paid;
        uint votes;
    }

    mapping(address => airline) private registeredAirlines;

    address[] registeredAirlineList;

    struct Insurance {
        address passenger;
        uint256 value;
        bool cancelled;
        bool payout;
        bool paid;
    }

    struct Flight {
        bool registered;
        uint8 statusCode;
        uint256 updatedTimestamp;        
        address airline;
        Insurance[] insuranceList;
    }
    mapping(string => Flight) private flights;

    string[] flightList;



    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/
    event registeredAppContract(address appContract);
    event deRegisteredAppContract(address appContract);
    event airlineRegistered(address airline);
    event airlinePaidEvent(address airline);
    event flightRegistered(string flightCodeDate, address airline, uint256 timestamp, uint8 statusCode);
    event insurancePurchased(string flightCodeDate, address passenger, uint value);
    event insuranceCancelled(string flightCodeDate, address passenger);
    event flightStatusCodeChanged(string flightCodedate, uint8 statusCode);
    event insurancePayout(string flightCodeDate, address passenger);
    event insurancePaidOut(string flightCodeDate, address passenger, uint value);

    event debugDataEvent(string info);
    event debugDataInt(uint256 number);
    event debugDataBool(bool flag);
    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        registeredAppContracts[this] = true;
        emit registeredAppContract(this);
        registeredAirlines[contractOwner].code = 'BA';
        registeredAirlines[contractOwner].name = 'British Airways';
        registeredAirlines[contractOwner].registered = true;
        registeredAirlines[contractOwner].paid = true;
        registeredAirlineList.push(contractOwner);
        emit airlineRegistered(contractOwner);
    }

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
        require(operational, "Contract is currently not operational");
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

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireRegisteredAppContract()
    {
        require(isSenderRegisteredAppContract(), "Caller is not registered app contract");
        _;
    }

    


    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }

    /**
    * @dev Get registered app contract status of address
    *
    * @return A bool is caller registered as an app contract
    */      
    function isSenderRegisteredAppContract() 
                            public 
                            view 
                            returns(bool) 
    {
        return registeredAppContracts[msg.sender];
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner
    {
        operational = mode;
    }

    
    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /**
    * @dev register n app contract so that it can call functions in the data contract
    *
    */   
    function registerAppContract
                            (   
                                address appContract
                            )
                            external
                            requireIsOperational
                            requireContractOwner
   
    {
        registeredAppContracts[appContract] = true;
        emit registeredAppContract(appContract);
    }

    /**
    * @dev register n app contract so that it can call functions in the data contract
    *
    */   
    function deRegisterAppContract
                            (   
                                address appContract
                            )
                            external
                            requireIsOperational
                            requireContractOwner
   
    {
        registeredAppContracts[appContract] = false;
        emit deRegisteredAppContract(appContract);
    }

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            (   
                                address airline,
                                string code,
                                string name,
                                bool registered
                            )
                            external
                            requireIsOperational
                            requireRegisteredAppContract
   
    {
        require(registeredAirlines[airline].registered == false, 'Airline already registered');
        registeredAirlines[airline].code = code;
        registeredAirlines[airline].name = name;
        registeredAirlines[airline].registered = registered;
        registeredAirlines[airline].paid = false;
        registeredAirlines[airline].votes = registeredAirlines[airline].votes + 1;
        if (registered) {
            registeredAirlineList.push(airline);
            emit airlineRegistered(airline);
        }
    }


    function airlinePaid
                        (
                            address airline
                        )
                        external
                        requireIsOperational
                        requireRegisteredAppContract
    {
        registeredAirlines[airline].paid = true;
        emit airlinePaidEvent(airline);
    }


    function isRegisteredAirline
                        (
                            address airline
                        )
                        external
                        requireIsOperational
                        requireRegisteredAppContract
                        returns(bool)
    {
        return registeredAirlines[airline].registered;
    }


    function getAirlineVotes
                        (
                            address airline
                        )
                        external
                        requireIsOperational
                        requireRegisteredAppContract
                        returns(uint)
    {
        return registeredAirlines[airline].votes;
    }

    function isPaidAirline
                        (
                            address airline
                        )
                        external
                        requireIsOperational
                        requireRegisteredAppContract
                        returns(bool)
    {
        return registeredAirlines[airline].paid;
    }


    function getRegisteredAirlineCount()
                                            external
                                            requireIsOperational
                                            requireRegisteredAppContract
                                            returns(uint256)
    {
        return registeredAirlineList.length;
    }
    
    function getPaidAirlineCount()
                                            external
                                            requireIsOperational
                                            requireRegisteredAppContract
                                            returns(uint256)
    {
        uint32 count = 0;
        for (uint i=0; i<registeredAirlineList.length; i++) {
            address currentAirline = registeredAirlineList[i];
            if(registeredAirlines[currentAirline].paid){
               count = count + 1; 
            }
        }
        return count;
    }

    function registerFlight 
                            (
                                string flightCodeDate,
                                address airline,
                                uint256 timestamp,
                                uint8 statusCode
                            )
                            external
                            requireIsOperational
                            requireRegisteredAppContract
    {
        require(flights[flightCodeDate].registered == false, 'Flight already registered');
        flights[flightCodeDate].registered = true;
        flights[flightCodeDate].airline = airline;
        flights[flightCodeDate].updatedTimestamp = timestamp;
        flights[flightCodeDate].statusCode = statusCode;
        flightList.push(flightCodeDate);
        emit flightRegistered(flightCodeDate, airline, timestamp, statusCode);
    }

    function isFlightRegistered
                        (
                            string flightCodeDate
                        )
                        external
                        requireIsOperational
                        requireRegisteredAppContract
                        returns(bool)
    {
        return flights[flightCodeDate].registered;
    }

    function getFlightStatusCode
                            (
                                string flightCodeDate
                            )
                            external
                            requireIsOperational
                            requireRegisteredAppContract
                            returns(uint8)
    {
        require(flights[flightCodeDate].registered, 'Flight not registered');
        return flights[flightCodeDate].statusCode;
    }

    function changeFlightStatusCode
                                (
                                    string flightCodeDate,
                                    uint8 statusCode
                                )
                                external
                                requireIsOperational
                                requireRegisteredAppContract
                                returns(bool)
    {
        require(flights[flightCodeDate].registered, 'Flight not registered');
        flights[flightCodeDate].statusCode = statusCode;
        emit flightStatusCodeChanged(flightCodeDate, statusCode);
        return true;
    }


    function buyInsurance
                        (
                            address purchaser,
                            string flightCodeDate,
                            uint256 purchasedValue
                        )
                        external
                        requireIsOperational
                        requireRegisteredAppContract
    {
        flights[flightCodeDate].insuranceList.push(Insurance({passenger: purchaser, value: purchasedValue, cancelled: false, payout: false, paid: false}));
        emit insurancePurchased(flightCodeDate, purchaser, purchasedValue);
    }

    function getInsurance
                        (
                            string flightCodeDate,
                            address passenger
                        )
                        external
                        requireIsOperational
                        requireRegisteredAppContract
                        returns(uint, bool, bool, bool)
    {
        for (uint i=0; i<flights[flightCodeDate].insuranceList.length; i++) {
            Insurance currentInsurance = flights[flightCodeDate].insuranceList[i];
            if(currentInsurance.passenger == passenger){
               return(
                   currentInsurance.value,
                   currentInsurance.cancelled,
                   currentInsurance.payout,
                   currentInsurance.paid
                );
            }
        return (0, false, false, false);
        }
    }
   
   function cancelInsurance
                            (
                                string flightCodeDate,
                                address passenger 
                            )
                            external
                            requireIsOperational
                            requireRegisteredAppContract
                            returns(bool)
    {
        for (uint i=0; i<flights[flightCodeDate].insuranceList.length; i++) {
            Insurance currentInsurance = flights[flightCodeDate].insuranceList[i];
            if(currentInsurance.passenger == passenger){
                currentInsurance.cancelled = true;
                emit insuranceCancelled(flightCodeDate, passenger);
                return true;
            }
        }
        return false;
    }

    function setInsurancePayout
                                (
                                    string flightCodeDate
                                )
                                external
                                requireIsOperational
                                requireRegisteredAppContract
    {
        require(flights[flightCodeDate].registered, 'Flight not registered');
        for (uint i=0; i<flights[flightCodeDate].insuranceList.length; i++) {
            Insurance currentInsurance = flights[flightCodeDate].insuranceList[i];
            if(currentInsurance.cancelled == false && currentInsurance.paid == false){
                currentInsurance.payout = true;
                emit insurancePayout(flightCodeDate, currentInsurance.passenger);
            }
        }
    }

    function setInsurancePaid
                            (
                                string flightCodeDate,
                                address passenger 
                            )
                            external
                            requireIsOperational
                            requireRegisteredAppContract
                            returns(bool)
    {
        for (uint i=0; i<flights[flightCodeDate].insuranceList.length; i++) {
            Insurance currentInsurance = flights[flightCodeDate].insuranceList[i];
            if(currentInsurance.passenger == passenger && currentInsurance.payout && currentInsurance.paid == false){
                currentInsurance.paid = true;
                emit insurancePaidOut(flightCodeDate, passenger, currentInsurance.value);
                return true;
            }
        }
        return false;
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
                                pure
    {
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
                            pure
    {
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (   
                            )
                            public
                            payable
    {
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() 
                            external 
                            payable 
    {
        fund();
    }


}

