#!/bin/bash
# ----------------------------------------------------------------------------------------------
# Testing the smart contract
#
# Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2017. The MIT Licence.
# ----------------------------------------------------------------------------------------------

MODE=${1:-test}

GETHATTACHPOINT=`grep ^IPCFILE= settings.txt | sed "s/^.*=//"`
PASSWORD=`grep ^PASSWORD= settings.txt | sed "s/^.*=//"`

CONTRACTSDIR=`grep ^CONTRACTSDIR= settings.txt | sed "s/^.*=//"`

TOKENSOL=`grep ^TOKENSOL= settings.txt | sed "s/^.*=//"`
TOKENTEMPSOL=`grep ^TOKENTEMPSOL= settings.txt | sed "s/^.*=//"`
TOKENJS=`grep ^TOKENJS= settings.txt | sed "s/^.*=//"`

DEPLOYMENTDATA=`grep ^DEPLOYMENTDATA= settings.txt | sed "s/^.*=//"`

TEST2OUTPUT=`grep ^TEST2OUTPUT= settings.txt | sed "s/^.*=//"`
TEST2RESULTS=`grep ^TEST2RESULTS= settings.txt | sed "s/^.*=//"`

CURRENTTIME=`date +%s`
CURRENTTIMES=`date -r $CURRENTTIME -u`

# Setting time to be a block representing one day
BLOCKSINDAY=1

if [ "$MODE" == "dev" ]; then
  # Start time now
  STARTTIME=`echo "$CURRENTTIME" | bc`
else
  # Start time 1m 10s in the future
  STARTTIME=`echo "$CURRENTTIME+75" | bc`
fi
STARTTIME_S=`date -r $STARTTIME -u`
ENDTIME=`echo "$CURRENTTIME+60*3" | bc`
ENDTIME_S=`date -r $ENDTIME -u`

printf "MODE                 = '$MODE'\n" | tee $TEST2OUTPUT
printf "GETHATTACHPOINT      = '$GETHATTACHPOINT'\n" | tee -a $TEST2OUTPUT
printf "PASSWORD             = '$PASSWORD'\n" | tee -a $TEST2OUTPUT

printf "CONTRACTSDIR         = '$CONTRACTSDIR'\n" | tee -a $TEST2OUTPUT

printf "TOKENSOL             = '$TOKENSOL'\n" | tee -a $TEST2OUTPUT
printf "TOKENTEMPSOL         = '$TOKENTEMPSOL'\n" | tee -a $TEST2OUTPUT
printf "TOKENJS              = '$TOKENJS'\n" | tee -a $TEST2OUTPUT

printf "DEPLOYMENTDATA       = '$DEPLOYMENTDATA'\n" | tee -a $TEST2OUTPUT
printf "TEST2OUTPUT          = '$TEST2OUTPUT'\n" | tee -a $TEST2OUTPUT
printf "TEST2RESULTS         = '$TEST2RESULTS'\n" | tee -a $TEST2OUTPUT
printf "CURRENTTIME          = '$CURRENTTIME' '$CURRENTTIMES'\n" | tee -a $TEST2OUTPUT
printf "STARTTIME            = '$STARTTIME' '$STARTTIME_S'\n" | tee -a $TEST2OUTPUT
printf "ENDTIME              = '$ENDTIME' '$ENDTIME_S'\n" | tee -a $TEST2OUTPUT

# Make copy of SOL file and modify start and end times ---
`cp $CONTRACTSDIR/$TOKENSOL $TOKENTEMPSOL`

# Copy secondary files
`cp $CONTRACTSDIR/Ownable.sol .`
`cp $CONTRACTSDIR/SafeMathLib.sol .`
`cp $CONTRACTSDIR/ERC20Basic.sol .`
`cp $CONTRACTSDIR/ERC20.sol .`
`cp $CONTRACTSDIR/ReleasableToken.sol .`
`cp $CONTRACTSDIR/StandardToken.sol .`
`cp $CONTRACTSDIR/MintableToken.sol .`
`cp $CONTRACTSDIR/UpgradeAgent.sol .`
`cp $CONTRACTSDIR/UpgradeableToken.sol .`
#`cp modifiedContracts/* .`

# --- Modify dates ---
#`perl -pi -e "s/address crowdsaleAddress;/address public crowdsaleAddress;/" $TOKENTEMPSOL`
#`perl -pi -e "s/address bonusFinalizeAgentAddress;/address public bonusFinalizeAgentAddress;/" $TOKENTEMPSOL`

#`perl -pi -e "s/uint preMinWei;/uint public preMinWei;/" Crowdsale.sol`
#`perl -pi -e "s/uint preMaxWei;/uint public preMaxWei;/" Crowdsale.sol`
#`perl -pi -e "s/uint minWei;/uint public minWei;/" Crowdsale.sol`
#`perl -pi -e "s/uint maxWei;/uint public maxWei;/" Crowdsale.sol`

DIFFS1=`diff $CONTRACTSDIR/$TOKENSOL $TOKENTEMPSOL`
echo "--- Differences $CONTRACTSDIR/$TOKENSOL $TOKENTEMPSOL ---" | tee -a $TEST2OUTPUT
echo "$DIFFS1" | tee -a $TEST2OUTPUT

echo "var tokenOutput=`solc --optimize --combined-json abi,bin,interface $TOKENTEMPSOL`;" > $TOKENJS

geth --verbosity 3 attach $GETHATTACHPOINT << EOF | tee -a $TEST2OUTPUT
loadScript("$TOKENJS");
loadScript("functions.js");

var tokenAbi = JSON.parse(tokenOutput.contracts["$TOKENTEMPSOL:DayToken"].abi);
var tokenBin = "0x" + tokenOutput.contracts["$TOKENTEMPSOL:DayToken"].bin;

// console.log("DATA: tokenAbi=" + JSON.stringify(tokenAbi));

unlockAccounts("$PASSWORD");
printBalances();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var deployTokenMessage = "Deploy DayToken Contract";
// -----------------------------------------------------------------------------
var _tokenName = "Day";
var _tokenSymbol = "DAY";
var _tokenDecimals = 18;
var _tokenInitialSupply = new BigNumber(11000).shift(18);
var _tokenMintable = true;
var _maxAddresses = 3333;
var _firstTeamContributorId = 10;
var _totalTeamContributorIds = 5;
var _totalPostIcoContributorIds = 5;
// ORIGINAL var _minMintingPower = 5000000000000000000;
var _minMintingPower = 0;
var _maxMintingPower = 0;
var _halvingCycle = 88;
var _minBalanceToSell = 8888;
// ORIGINAL var _DayInSecs = 84600;
var _DayInSecs = 10;
var _teamLockPeriodInSec = 15780000;

// function DayToken(string _name, string _symbol, uint _initialSupply, uint8 _decimals,
//   bool _mintable, uint _maxAddresses, uint _firstTeamContributorId, uint _totalTeamContributorIds, 
//   uint _totalPostIcoContributorIds, uint256 _minMintingPower, uint256 _maxMintingPower, uint _halvingCycle, 
//   uint256 _minBalanceToSell, uint256 _dayInSecs, uint256 _teamLockPeriodInSec) 
// -----------------------------------------------------------------------------
console.log("RESULT: " + deployTokenMessage);
var tokenContract = web3.eth.contract(tokenAbi);
// console.log(JSON.stringify(tokenContract));
var tokenTx = null;
var tokenAddress = null;

var token = tokenContract.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, _tokenMintable,
    _maxAddresses, _firstTeamContributorId, _totalTeamContributorIds, _totalPostIcoContributorIds, 
    _minMintingPower, _maxMintingPower, _halvingCycle,
    _minBalanceToSell, _DayInSecs, _teamLockPeriodInSec, {from: contractOwnerAccount, data: tokenBin, gas: 6000000},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        tokenTx = contract.transactionHash;
      } else {
        tokenAddress = contract.address;
        addAccount(tokenAddress, "Token '" + token.symbol() + "' '" + token.name() + "'");
        addTokenContractAddressAndAbi(tokenAddress, tokenAbi);
        console.log("DATA: tokenAddress=" + tokenAddress);
      }
    }
  }
);


while (txpool.status.pending > 0) {
}

printTxData("tokenAddress=" + tokenAddress, tokenTx);
printBalances();
failIfGasEqualsGasUsed(tokenTx, deployTokenMessage);
printTokenContractDetails();
printPricingContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var setMintAndReleaseAgentMessage = "Set Mint & Release Agent";
// -----------------------------------------------------------------------------
console.log("RESULT: " + setMintAndReleaseAgentMessage);
var setMintAgent1Tx = token.setMintAgent(contractOwnerAccount, true, {from: contractOwnerAccount, gas: 400000});
var setReleaseAgent1Tx = token.setReleaseAgent(contractOwnerAccount, true, {from: contractOwnerAccount, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("setMintAgent1Tx", setMintAgent1Tx);
printTxData("setReleaseAgent1Tx", setReleaseAgent1Tx);
printBalances();
failIfGasEqualsGasUsed(setMintAgent1Tx, setMintAndReleaseAgentMessage + " - Set Mint Agent");
failIfGasEqualsGasUsed(setReleaseAgent1Tx, setMintAndReleaseAgentMessage + " - Set Release Agent");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var allocMinter1Message = "Allocate Minter";
// totalNormalContributorIds = maxAddresses - _totalTeamContributorIds - _totalPostIcoContributorIds;
// var _maxAddresses = 3333;
// var _totalTeamContributorIds = 5;
// var _totalPostIcoContributorIds = 5;
// totalNormalContributorIds = 3333 - 5 - 5 = 3323;
// var _firstTeamContributorId = 10;
// -----------------------------------------------------------------------------
console.log("RESULT: " + allocMinter1Message);
var tokens = web3.toWei("10000", "ether");
var allocMinter1Tx = token.allocateNormalTimeMints(account7, 7, 1007, tokens, tokens, {from: contractOwnerAccount, gas: 400000});
var allocMinter2Tx = token.allocateNormalTimeMints(account8, 8, 1008, tokens, tokens, {from: contractOwnerAccount, gas: 400000});
var allocMinter3Tx = token.allocateNormalTimeMints(account9, 9, 1009, tokens, tokens, {from: contractOwnerAccount, gas: 400000});
var allocMinter4Tx = token.allocateNormalTimeMints(account10, 10, 1010, tokens, tokens, {from: contractOwnerAccount, gas: 400000});
var allocMinter5Tx = token.allocateNormalTimeMints(account11, 11, 1011, tokens, tokens, {from: contractOwnerAccount, gas: 400000});
var allocMinter6Tx = token.allocateNormalTimeMints(account12, 12, 1012, tokens, tokens, {from: contractOwnerAccount, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("allocMinter1Tx", allocMinter1Tx);
printTxData("allocMinter2Tx", allocMinter2Tx);
printTxData("allocMinter3Tx", allocMinter3Tx);
printTxData("allocMinter4Tx", allocMinter4Tx);
printTxData("allocMinter5Tx", allocMinter5Tx);
printTxData("allocMinter6Tx", allocMinter6Tx);
printBalances();
failIfGasEqualsGasUsed(allocMinter1Tx, allocMinter1Message + " - ac7 custid7 id7 10000");
failIfGasEqualsGasUsed(allocMinter2Tx, allocMinter1Message + " - ac8 custid8 id8 10000");
failIfGasEqualsGasUsed(allocMinter3Tx, allocMinter1Message + " - ac9 custid9 id9 10000");
failIfGasEqualsGasUsed(allocMinter4Tx, allocMinter1Message + " - ac10 custid10 id10 10000");
failIfGasEqualsGasUsed(allocMinter5Tx, allocMinter1Message + " - ac11 custid11 id11 10000");
failIfGasEqualsGasUsed(allocMinter6Tx, allocMinter1Message + " - ac12 custid12 id12 10000");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var releaseTokenMessage = "Release Token Which Sets The Initial Block Timestamp";
// -----------------------------------------------------------------------------
console.log("RESULT: " + releaseTokenMessage);
var releaseTokenTx = token.releaseToken($STARTTIME, {from: contractOwnerAccount, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("releaseTokenTx", releaseTokenTx);
printBalances();
failIfGasEqualsGasUsed(releaseTokenTx, releaseTokenMessage);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var transfersMessage = "Testing token transfers";
// -----------------------------------------------------------------------------
console.log("RESULT: " + transfersMessage);
var transfers1Tx = token.approve(account14,  "1000020000000000000", {from: account8, gas: 100000});
while (txpool.status.pending > 0) {
}
var transfers2Tx = token.transfer(account13, "1000020000000000000", {from: account7, gas: 100000});
var transfers3Tx = token.transferFrom(account8, account15, "1000020000000000000", {from: account14, gas: 500000});
while (txpool.status.pending > 0) {
}
printTxData("transfers1Tx", transfers1Tx);
printTxData("transfers2Tx", transfers2Tx);
printTxData("transfers3Tx", transfers3Tx);
printBalances();
failIfGasEqualsGasUsed(transfers1Tx, transfersMessage + " - approve 1.00002 tokens ac8 -> ac14");
failIfGasEqualsGasUsed(transfers2Tx, transfersMessage + " - transfer 1.00002 token ac7 -> ac13");
failIfGasEqualsGasUsed(transfers3Tx, transfersMessage + " - transferFrom 1.00002 tokens ac8 -> ac15 by ac14");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var sellMintingAddressMessage = "Sell Minting Address";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sellMintingAddressMessage);
// var sellMintingAddress1Tx = token.sellMintingAddress(new BigNumber(10.111111111).shift(18), parseInt(eth.blockNumber) + 100, {from: account7, gas: 400000});
var sellMintingAddress2Tx = token.sellMintingAddress(new BigNumber(10.111111111).shift(18), parseInt(eth.blockNumber) + 100, {from: account8, gas: 400000});
while (txpool.status.pending > 0) {
}
// printTxData("sellMintingAddress1Tx", sellMintingAddress1Tx);
printTxData("sellMintingAddress2Tx", sellMintingAddress2Tx);
printBalances();
// failIfGasEqualsGasUsed(sellMintingAddress1Tx, sellMintingAddressMessage + " - ac7");
failIfGasEqualsGasUsed(sellMintingAddress2Tx, sellMintingAddressMessage + " - ac8");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var buyMintingAddressMessage = "Buy Minting Address";
// -----------------------------------------------------------------------------
console.log("RESULT: " + buyMintingAddressMessage);
var buyMintingAddress1Tx = token.buyMintingAddress(1008, new BigNumber(20.444444444).shift(18), {from: contractOwnerAccount, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("buyMintingAddress1Tx", buyMintingAddress1Tx);
printBalances();
failIfGasEqualsGasUsed(buyMintingAddress1Tx, buyMintingAddressMessage + " - ac1 buys");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var fetchSuccessfulSaleProceedMessage = "Fetch Successful Sale Proceed";
// -----------------------------------------------------------------------------
console.log("RESULT: " + fetchSuccessfulSaleProceedMessage);
var fetchSuccessfulSaleProceedTx = token.fetchSuccessfulSaleProceed({from: account8, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("fetchSuccessfulSaleProceedTx", fetchSuccessfulSaleProceedTx);
printBalances();
failIfGasEqualsGasUsed(fetchSuccessfulSaleProceedTx, fetchSuccessfulSaleProceedMessage + " - account8");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var updateBalanceOf1Message = "Update Balance";
// -----------------------------------------------------------------------------
console.log("RESULT: " + updateBalanceOf1Message);
var updateBalanceOf1Tx = token.updateTimeMintBalance(1007, {from: contractOwnerAccount, gas: 400000});
var updateBalanceOf2Tx = token.updateTimeMintBalance(1008, {from: contractOwnerAccount, gas: 400000});
var updateBalanceOf3Tx = token.updateTimeMintBalance(1009, {from: contractOwnerAccount, gas: 400000});
var updateBalanceOf4Tx = token.updateTimeMintBalance(1010, {from: contractOwnerAccount, gas: 400000});
var updateBalanceOf5Tx = token.updateTimeMintBalance(1011, {from: contractOwnerAccount, gas: 400000});
var updateBalanceOf6Tx = token.updateTimeMintBalance(1012, {from: contractOwnerAccount, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("updateBalanceOf1Tx", updateBalanceOf1Tx);
printTxData("updateBalanceOf2Tx", updateBalanceOf2Tx);
printTxData("updateBalanceOf3Tx", updateBalanceOf3Tx);
printTxData("updateBalanceOf4Tx", updateBalanceOf4Tx);
printTxData("updateBalanceOf5Tx", updateBalanceOf5Tx);
printTxData("updateBalanceOf6Tx", updateBalanceOf6Tx);
printBalances();
failIfGasEqualsGasUsed(updateBalanceOf1Tx, updateBalanceOf1Message + " - 1007");
failIfGasEqualsGasUsed(updateBalanceOf2Tx, updateBalanceOf1Message + " - 1008");
failIfGasEqualsGasUsed(updateBalanceOf3Tx, updateBalanceOf1Message + " - 1009");
failIfGasEqualsGasUsed(updateBalanceOf4Tx, updateBalanceOf1Message + " - 1010");
failIfGasEqualsGasUsed(updateBalanceOf5Tx, updateBalanceOf1Message + " - 1011");
failIfGasEqualsGasUsed(updateBalanceOf6Tx, updateBalanceOf1Message + " - 1012");
printTokenContractDetails();
console.log("RESULT: ");


EOF
grep "DATA: " $TEST2OUTPUT | sed "s/DATA: //" > $DEPLOYMENTDATA
cat $DEPLOYMENTDATA
grep "RESULT: " $TEST2OUTPUT | sed "s/RESULT: //" > $TEST2RESULTS
cat $TEST2RESULTS
