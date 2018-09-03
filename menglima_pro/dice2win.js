var we3 = new Web3(new Web3.providers.HttpProvider("https://kovan.infura.io/CUNjkZ8qg6WZHqeFNJyL"));

var transactions = web3.eth.getBlock(8509939).transactions;

var addr = "0xbfb2e296d9cf3e593e79981235aed29ab9984c0f"
var filter = web3.eth.filter({fromBlock:0, toBlock:'latest', address: addr});
filter.get(function (err, transactions) {
  transactions.forEach(function (tx) {
    var txInfo = web3.eth.getTransaction(tx.transactionHash);
    //这时可以将交易信息txInfo存入数据库
  });
});