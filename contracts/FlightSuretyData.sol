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
    }

    mapping(address => airline) private registeredAirlines;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/
    event registeredAppContract(address appContract);
    event deRegisteredAppContract(address appContract);
    event airlineRegistered(address airline);

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
        //registerAirline(msg.sender, 'BA', 'British Airways');
        registeredAirlines[contractOwner].code = 'BA';
        registeredAirlines[contractOwner].name = 'British Airways';
        registeredAirlines[contractOwner].registered = true;
        registeredAirlines[contractOwner].paid = true;
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
                                string name
                            )
                            public
                            requireIsOperational
                            requireRegisteredAppContract
   
    {
        registeredAirlines[airline].code = code;
        registeredAirlines[airline].name = name;
        registeredAirlines[airline].registered = true;
        emit airlineRegistered(airline);
    }


   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (                             
                            )
                            external
                            payable
    {

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

