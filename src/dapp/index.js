require("babel-core/register");
require("babel-polyfill");
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async() => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
        });
    

        // User-submitted transaction
        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            // Write transaction
            contract.fetchFlightStatus(flight, (error, result) => {
                display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
            });
        })

        // User-submitted transaction
        DOM.elid('get-flight-details').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            // Write transaction
            contract.getFlightDetails(flight, (error, result) => {
                display('Dapp', 'Get Flight Details', [ { label: 'Get Flight Details', error: flight, error, value: flight + ' ' + 'isRegistered: ' + result[0] + ' statusCode: ' + result[1]} ]);
            });
        })

        // User-submitted transaction
        DOM.elid('buy-insurance').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            let value_ = DOM.elid('insurance-value').value;
            // Write transaction
            contract.buyInsurance(flight, value_, (error) => {
                display('Dapp', 'Buy Insurance', [ { label: 'Buy Insurance', error: flight, error, value: flight } ]);
            });
        })

        // User-submitted transaction
        DOM.elid('cancel-insurance').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            // Write transaction
            contract.cancelInsurance(flight, (error) => {
                display('Dapp', 'Cancel Insurance', [ { label: 'Cancel Insurance', error: flight, error, value: flight } ]);
            });
        })

        // User-submitted transaction
        DOM.elid('payout-insurance').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            // Write transaction
            contract.payoutInsurance(flight, (error) => {
                display('Dapp', 'Payout Insurance', [ { label: 'Payout Insurance', error: flight, error, value: flight } ]);
            });
        })
    
    });
    

})();


function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}







