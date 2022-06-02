async function getOwned(contract, account) {

    function addressEqual(a, b) {
        return a.toLowerCase() === b.toLowerCase();
    }

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

    let owned = new Array();

    for (const log of logs) {
        if (log.event == 'TransferSingle') {
            const { from, to, id, value } = log.args;
            if (addressEqual(to, account)) {
                let newOwnedToken;
                let existingOwnedToken = owned.find(item => item.id === id.toString());

                if (typeof existingOwnedToken === 'undefined' || existingOwnedToken === null) {
                    newOwnedToken = {
                        'id': id.toString(),
                        'quantity': (parseInt(value.toString()))
                    };
                } else {
                    newOwnedToken = {
                        'id': id.toString(),
                        'quantity': (existingOwnedToken.quantity + parseInt(value.toString()))
                    };
                    owned = owned.filter(item => item.id != id.toString());
                }
                owned.push(newOwnedToken);
            }
            else if (addressEqual(from, account)) {
                let existingOwnedToken = owned.find(item => item.id === id.toString());
                let newOwnedToken = {
                    'id': id.toString(),
                    'quantity': (existingOwnedToken.quantity - parseInt(value.toString()))
                };
                owned = owned.filter(item => item.id != id.toString());
                owned.push(newOwnedToken);
            }
        }
        else if (log.event == 'TransferBatch') {
            const { from, to, ids } = log.args;
            if (addressEqual(to, account)) {
                for (var i = 0; i < log.args[3].length; i++) {
                    let newOwnedToken;
                    let existingOwnedToken = owned.find(item => item.id === log.args[3][i].toString());

                    if (typeof existingOwnedToken === 'undefined' || existingOwnedToken === null) {
                        newOwnedToken = {
                            'id': log.args[3][i].toString(),
                            'quantity': parseInt(log.args[4][i].toString())
                        };
                    } else {
                        newOwnedToken = {
                            'id': log.args[3][i].toString(),
                            'quantity': (existingOwnedToken.quantity + parseInt(log.args[4][i].toString()))
                        };
                        owned = owned.filter(item => item.id != log.args[3][i].toString());
                    }
                    owned.push(newOwnedToken);
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
                }
            }
        }
    }
    owned = owned.filter(item => item.quantity != 0);
    return owned;
}

export { getOwned }; //export list of variants