async function getOwned(contract, account) {

    function addressEqual(a, b) {
        return a.toLowerCase() === b.toLowerCase();
    }

    console.log("PL1155", 'tokens owned by', account);

    const singleSentLogs = await contract.queryFilter(
        contract.filters.TransferSingle(null, account, null),
    );
    const singleReceivedLogs = await contract.queryFilter(
        contract.filters.TransferSingle(null, null, account),
    );

    const batchSentLogs = await contract.queryFilter(
        contract.filters.TransferBatch(null, account, null),
    );

    const batchReceivedLogs = await contract.queryFilter(
        contract.filters.TransferBatch(null, null, account),
    );

    const singleLogs = singleSentLogs.concat(singleReceivedLogs)
        .sort(
            (a, b) =>
                a.blockNumber - b.blockNumber ||
                a.transactionIndex - b.TransactionIndex,
        );

    const batchLogs = batchSentLogs.concat(batchReceivedLogs)
        .sort(
            (a, b) =>
                a.blockNumber - b.blockNumber ||
                a.transactionIndex - b.TransactionIndex,
        );

    const logs = singleLogs.concat(batchLogs)
        .sort(
            (a, b) =>
                a.blockNumber - b.blockNumber ||
                a.transactionIndex - b.TransactionIndex,
        );
    console.log('log is----------------------------', logs);

    let owned = new Array();

    for (const log of logs) {
        if (log.event == 'TransferSingle') {
            const { from, to, id, value } = log.args;
            if (addressEqual(to, account)) {
                console.log('log is ', log);
                let newOwnedToken;
                let existingOwnedToken = owned.find(item => item.id === id.toString());
                console.log('check point one', existingOwnedToken, typeof existingOwnedToken != 'undefined', existingOwnedToken != null);

                if (typeof existingOwnedToken === 'undefined' || existingOwnedToken === null) {
                    newOwnedToken = {
                        'id': id.toString(),
                        'quantity': (parseInt(value.toString()))
                    };
                    console.log('There are no duplicated token id');
                } else {
                    newOwnedToken = {
                        'id': id.toString(),
                        'quantity': (existingOwnedToken.quantity + parseInt(value.toString()))
                    };
                    owned = owned.filter(item => item.id != id.toString());
                    console.log('There are duplicated token id');
                }
                owned.push(newOwnedToken);

                console.log('check point two', newOwnedToken);
                for (let i = 0; i < owned.length; i++) {
                    console.log('owned', owned[i]);
                }
                console.log('what\'s stopped');
            }
            else if (addressEqual(from, account)) {
                let existingOwnedToken = owned.find(item => item.id === id.toString());
                let newOwnedToken = {
                    'id': id.toString(),
                    'quantity': (existingOwnedToken.quantity - parseInt(value.toString()))
                };
                owned = owned.filter(item => item.id != id.toString());
                owned.push(newOwnedToken);
                console.log('check point three', newOwnedToken);
                for (let i = 0; i < owned.length; i++) {
                    console.log('owned', owned[i]);
                }
            }
        }
        else if (log.event == 'TransferBatch') {
            const { from, to, ids } = log.args;
            if (addressEqual(to, account)) {
                for (var i = 0; i < log.args[3].length; i++) {
                    let newOwnedToken;
                    let existingOwnedToken = owned.find(item => item.id === log.args[3][i].toString());
                    console.log('check point four', existingOwnedToken, typeof existingOwnedToken != 'undefined', existingOwnedToken != null);

                    if (typeof existingOwnedToken === 'undefined' || existingOwnedToken === null) {
                        newOwnedToken = {
                            'id': log.args[3][i].toString(),
                            'quantity': parseInt(log.args[4][i].toString())
                        };
                        console.log('There are no duplicated token id');
                    } else {
                        newOwnedToken = {
                            'id': log.args[3][i].toString(),
                            'quantity': (existingOwnedToken.quantity + parseInt(log.args[4][i].toString()))
                        };
                        owned = owned.filter(item => item.id != log.args[3][i].toString());
                        console.log('There are duplicated token id');
                    }
                    owned.push(newOwnedToken);

                    console.log('check point five', newOwnedToken);
                    for (let i = 0; i < owned.length; i++) {
                        console.log('owned', owned[i]);
                    }
                }
            }
            else if (addressEqual(from, account)) {
                for (var i = 0; i < log.args[3].length; i++) {
                    let existingOwnedToken = owned.find(item => item.id === log.args[3][i].toString());
                    let newOwnedToken = {
                        'id': log.args[3][i].toString(),
                        'quantity': (existingOwnedToken.quantity - parseInt(log.args[4][i].toString()))
                    };
                    owned = owned.filter(item => item.id != log.args[3][i].toString());
                    owned.push(newOwnedToken);
                    console.log('check point six', newOwnedToken);
                    for (let i = 0; i < owned.length; i++) {
                        console.log('owned', owned[i]);
                    }
                }
            }
        }
    }
    return owned;
}

// 📁 say.js
function sayHi(user) {
    console.log(`Hello, ${user}!`);
}

function sayBye(user) {
    console.log(`Bye, ${user}!`);
}

export { getOwned, sayHi, sayBye }; //export list of variants