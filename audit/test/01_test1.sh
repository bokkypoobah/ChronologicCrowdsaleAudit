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

TEST1OUTPUT=`grep ^TEST1OUTPUT= settings.txt | sed "s/^.*=//"`
TEST1RESULTS=`grep ^TEST1RESULTS= settings.txt | sed "s/^.*=//"`

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

printf "MODE                 = '$MODE'\n" | tee $TEST1OUTPUT
printf "GETHATTACHPOINT      = '$GETHATTACHPOINT'\n" | tee -a $TEST1OUTPUT
printf "PASSWORD             = '$PASSWORD'\n" | tee -a $TEST1OUTPUT

printf "CONTRACTSDIR         = '$CONTRACTSDIR'\n" | tee -a $TEST1OUTPUT

printf "TOKENSOL             = '$TOKENSOL'\n" | tee -a $TEST1OUTPUT
printf "TOKENTEMPSOL         = '$TOKENTEMPSOL'\n" | tee -a $TEST1OUTPUT
printf "TOKENJS              = '$TOKENJS'\n" | tee -a $TEST1OUTPUT

printf "DEPLOYMENTDATA       = '$DEPLOYMENTDATA'\n" | tee -a $TEST1OUTPUT
printf "TEST1OUTPUT          = '$TEST1OUTPUT'\n" | tee -a $TEST1OUTPUT
printf "TEST1RESULTS         = '$TEST1RESULTS'\n" | tee -a $TEST1OUTPUT
printf "CURRENTTIME          = '$CURRENTTIME' '$CURRENTTIMES'\n" | tee -a $TEST1OUTPUT
printf "STARTTIME            = '$STARTTIME' '$STARTTIME_S'\n" | tee -a $TEST1OUTPUT
printf "ENDTIME              = '$ENDTIME' '$ENDTIME_S'\n" | tee -a $TEST1OUTPUT

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
echo "--- Differences $CONTRACTSDIR/$TOKENSOL $TOKENTEMPSOL ---" | tee -a $TEST1OUTPUT
echo "$DIFFS1" | tee -a $TEST1OUTPUT

echo "var tokenOutput=`solc --optimize --combined-json abi,bin,interface $TOKENTEMPSOL`;" > $TOKENJS

geth --verbosity 3 attach $GETHATTACHPOINT << EOF | tee -a $TEST1OUTPUT
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
var _minMintingPower = 10000000000000000000;
var _maxMintingPower = 10000000000000000000;
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
var sellMintingAddress1Tx = token.sellMintingAddress(new BigNumber(10.111111111).shift(18), parseInt(eth.blockNumber) + 100, {from: account7, gas: 400000});
var sellMintingAddress2Tx = token.sellMintingAddress(new BigNumber(10.111111111).shift(18), parseInt(eth.blockNumber) + 100, {from: account8, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("sellMintingAddress1Tx", sellMintingAddress1Tx);
printTxData("sellMintingAddress2Tx", sellMintingAddress2Tx);
printBalances();
failIfGasEqualsGasUsed(sellMintingAddress1Tx, sellMintingAddressMessage + " - ac7");
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


exit;


// -----------------------------------------------------------------------------
var deployCrowdsaleMessage = "Deploy Crowdsale Contract";
// -----------------------------------------------------------------------------
// var _startTime = getUnixTimestamp('2017-07-23 09:00:00 GMT');
// var _endTime = getUnixTimestamp('2017-08-7 09:00:00 GMT');
var _minimumFundingGoal = web3.toWei(1500, "ether");
var _cap = web3.toWei(38383, "ether");
var _preMinWei = web3.toWei(33, "ether");
var _preMaxWei = web3.toWei(333, "ether");
var _minWei = web3.toWei(1, "ether");
var _maxWei = web3.toWei(33333, "ether");
// function AddressCappedCrowdsale(address _token, PricingStrategy _pricingStrategy, 
//   address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal, uint _weiIcoCap, 
//   uint _preMinWei, uint _preMaxWei, uint _minWei,  uint _maxWei) 
// -----------------------------------------------------------------------------
console.log("RESULT: " + deployCrowdsaleMessage);
var crowdsaleContract = web3.eth.contract(crowdsaleAbi);
// console.log(JSON.stringify(crowdsaleContract));
var crowdsaleTx = null;
var crowdsaleAddress = null;

var crowdsale = crowdsaleContract.new(tokenAddress, pricingAddress, multisig,
    $STARTTIME, $ENDTIME, _minimumFundingGoal, _cap, _preMinWei, _preMaxWei,
    _minWei, _maxWei, {from: contractOwnerAccount, data: crowdsaleBin, gas: 6000000},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        crowdsaleTx = contract.transactionHash;
      } else {
        crowdsaleAddress = contract.address;
        addAccount(crowdsaleAddress, "Crowdsale");
        addCrowdsaleContractAddressAndAbi(crowdsaleAddress, crowdsaleAbi);
        console.log("DATA: crowdsaleAddress=" + crowdsaleAddress);
      }
    }
  }
);

while (txpool.status.pending > 0) {
}

printTxData("crowdsaleAddress=" + crowdsaleAddress, crowdsaleTx);
printBalances();
failIfGasEqualsGasUsed(crowdsaleTx, deployCrowdsaleMessage);
printCrowdsaleContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var deployFinaliserMessage = "Deploy BonusFinalizerAgent Contract";
// -----------------------------------------------------------------------------
var _teamAddresses = [team1, team2, team3];
var _testAddresses = [testAddress1, testAddress2];
var _testAddressTokens = 88;
var _teamBonus = 5;
var _totalBountyInDay = 8888;
// function BonusFinalizeAgent(DayToken _token, Crowdsale _crowdsale,  address[] _teamAddresses, 
// address[] _testAddresses, uint _testAddressTokens, uint _teamBonus, uint _totalBountyInDay)
// -----------------------------------------------------------------------------
console.log("RESULT: " + deployFinaliserMessage);
var finaliserContract = web3.eth.contract(finaliserAbi);
// console.log(JSON.stringify(finaliserContract));
var finaliserTx = null;
var finaliserAddress = null;

var finaliser = finaliserContract.new(tokenAddress, crowdsaleAddress, _teamAddresses,
    _testAddresses, _testAddressTokens, _teamBonus, _totalBountyInDay,
    {from: contractOwnerAccount, data: finaliserBin, gas: 6000000},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        finaliserTx = contract.transactionHash;
      } else {
        finaliserAddress = contract.address;
        addAccount(finaliserAddress, "BonusFinalizerAgent");
        addFinaliserContractAddressAndAbi(finaliserAddress, finaliserAbi);
        console.log("DATA: finaliserAddress=" + finaliserAddress);
      }
    }
  }
);

while (txpool.status.pending > 0) {
}

printTxData("finaliserAddress=" + finaliserAddress, finaliserTx);
printBalances();
failIfGasEqualsGasUsed(finaliserTx, deployFinaliserMessage);
printTokenContractDetails();
printPricingContractDetails();
printCrowdsaleContractDetails();
printFinaliserContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var stitchMessage = "Stitch Contracts Together";
// -----------------------------------------------------------------------------
console.log("RESULT: " + stitchMessage);
var stitch1Tx = token.setMintAgent(crowdsaleAddress, true, {from: contractOwnerAccount, gas: 400000});
var stitch2Tx = token.setMintAgent(finaliserAddress, true, {from: contractOwnerAccount, gas: 400000});
var stitch3Tx = token.setReleaseAgent(finaliserAddress, {from: contractOwnerAccount, gas: 400000});
var stitch4Tx = token.setTransferAgent(crowdsaleAddress, true, {from: contractOwnerAccount, gas: 400000});
var stitch5Tx = token.setBonusFinalizeAgentAddress(finaliserAddress, {from: contractOwnerAccount, gas: 400000});
var stitch6Tx = token.addCrowdsaleAddress(crowdsaleAddress, {from: contractOwnerAccount, gas: 400000});
var stitch7Tx = crowdsale.setFinalizeAgent(finaliserAddress, {from: contractOwnerAccount, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("stitch1Tx", stitch1Tx);
printTxData("stitch2Tx", stitch2Tx);
printTxData("stitch3Tx", stitch3Tx);
printTxData("stitch4Tx", stitch4Tx);
printTxData("stitch5Tx", stitch5Tx);
printTxData("stitch6Tx", stitch6Tx);
printTxData("stitch7Tx", stitch6Tx);
printBalances();
failIfGasEqualsGasUsed(stitch1Tx, stitchMessage + " 1");
failIfGasEqualsGasUsed(stitch2Tx, stitchMessage + " 2");
failIfGasEqualsGasUsed(stitch3Tx, stitchMessage + " 3");
failIfGasEqualsGasUsed(stitch4Tx, stitchMessage + " 4");
failIfGasEqualsGasUsed(stitch5Tx, stitchMessage + " 5");
failIfGasEqualsGasUsed(stitch6Tx, stitchMessage + " 6");
failIfGasEqualsGasUsed(stitch7Tx, stitchMessage + " 7");
printTokenContractDetails();
printPricingContractDetails();
printCrowdsaleContractDetails();
printFinaliserContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
// Wait for crowdsale start
// -----------------------------------------------------------------------------
var startsAtTime = crowdsale.startsAt();
var startsAtTimeDate = new Date(startsAtTime * 1000);
console.log("RESULT: Waiting until startsAt date at " + startsAtTime + " " + startsAtTimeDate + " currentDate=" + new Date());
while ((new Date()).getTime() <= startsAtTimeDate.getTime()) {
}
console.log("RESULT: Waited until startsAt date at " + startsAtTime + " " + startsAtTimeDate + " currentDate=" + new Date());


// -----------------------------------------------------------------------------
var validContribution1Message = "Send Valid Contribution After Crowdsale Start";
// -----------------------------------------------------------------------------
console.log("RESULT: " + validContribution1Message);
// var addContributor1Tx = crowdsale.preallocate(account8, web3.toWei(20000, "ether"), 1, {from: contractOwnerAccount, gas: 400000});
// while (txpool.status.pending > 0) {
// }
var validContribution1Tx = eth.sendTransaction({from: account8, to: crowdsaleAddress, gas: 400000, value: web3.toWei("20000", "ether")});
var validContribution2Tx = eth.sendTransaction({from: account9, to: crowdsaleAddress, gas: 400000, value: web3.toWei("1000", "ether")});
while (txpool.status.pending > 0) {
}
// printTxData("addContributor1Tx", addContributor1Tx);
printTxData("validContribution1Tx", validContribution1Tx);
printTxData("validContribution2Tx", validContribution2Tx);
printBalances();
// failIfGasEqualsGasUsed(addContributor1Tx, validContribution1Message + " - Add Contributor");
failIfGasEqualsGasUsed(validContribution1Tx, validContribution1Message + " - ac8 contributes 20,000 ETH");
failIfGasEqualsGasUsed(validContribution2Tx, validContribution1Message + " - ac9 contributes 1,000 ETH");
printTokenContractDetails();
printPricingContractDetails();
printCrowdsaleContractDetails();
printFinaliserContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
// Wait for crowdsale end
// -----------------------------------------------------------------------------
var endsAtTime = crowdsale.endsAt();
var endsAtTimeDate = new Date(endsAtTime * 1000);
console.log("RESULT: Waiting until endsAt date at " + endsAtTime + " " + endsAtTimeDate + " currentDate=" + new Date());
while ((new Date()).getTime() <= endsAtTimeDate.getTime()) {
}
console.log("RESULT: Waited until endsAt date at " + endsAtTime + " " + endsAtTimeDate + " currentDate=" + new Date());


// -----------------------------------------------------------------------------
var finaliseMessage = "Finalise Crowdsale";
// -----------------------------------------------------------------------------
console.log("RESULT: " + finaliseMessage);
var finaliseTx = crowdsale.finalize({from: contractOwnerAccount, gas: 4000000});
while (txpool.status.pending > 0) {
}
printTxData("finaliseTx", finaliseTx);
printBalances();
failIfGasEqualsGasUsed(finaliseTx, finaliseMessage);
printTokenContractDetails();
printPricingContractDetails();
printCrowdsaleContractDetails();
printFinaliserContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var activateMessage = "Activate DayToken";
// -----------------------------------------------------------------------------
console.log("RESULT: " + activateMessage);
var activateTx = token.setInitialBlockTimestamp(eth.getBlock("latest").timestamp, {from: contractOwnerAccount, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("activateTx", activateTx);
printBalances();
failIfGasEqualsGasUsed(activateTx, activateMessage);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var transfersMessage = "Testing token transfers";
console.log("RESULT: " + transfersMessage);
// -----------------------------------------------------------------------------
var transfers1Tx = token.transfer(account10, "1000000000000000000", {from: account8, gas: 400000});
var transfers2Tx = token.approve(account11,  "2000000000000000000", {from: account9, gas: 400000});
while (txpool.status.pending > 0) {
}
var transfers3Tx = token.transferFrom(account9, account12, "2000000000000000000", {from: account11, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("transfers1Tx", transfers1Tx);
printTxData("transfers2Tx", transfers2Tx);
printTxData("transfers3Tx", transfers3Tx);
printBalances();
failIfGasEqualsGasUsed(transfers1Tx, transfersMessage + " - transfer 1 token ac8 -> ac10");
failIfGasEqualsGasUsed(transfers2Tx, transfersMessage + " - approve 2 tokens ac9 -> ac11");
failIfGasEqualsGasUsed(transfers3Tx, transfersMessage + " - transferFrom 2 tokens ac9 -> ac12");
printTokenContractDetails();
console.log("RESULT: ");


exit;


// -----------------------------------------------------------------------------
var invalidContribution1Message = "Send Invalid Contribution - 100 ETH From Account6 - Before Crowdsale Start";
console.log("RESULT: " + invalidContribution1Message);
var invalidContribution1Tx = eth.sendTransaction({from: account6, to: mecAddress, gas: 400000, value: web3.toWei("100", "ether")});
while (txpool.status.pending > 0) {
}
printTxData("invalidContribution1Tx", invalidContribution1Tx);
printBalances();
passIfGasEqualsGasUsed(invalidContribution1Tx, invalidContribution1Message);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var validContribution1Message = "Send Valid Contribution - 100 ETH From Account6 - After Crowdsale Start";
console.log("RESULT: " + validContribution1Message);
var validContribution1Tx = mec.investWithCustomerId(account6, 123, {from: account6, to: mecAddress, gas: 400000, value: web3.toWei("100", "ether")});

while (txpool.status.pending > 0) {
}
printTxData("validContribution1Tx", validContribution1Tx);
printBalances();
failIfGasEqualsGasUsed(validContribution1Tx, validContribution1Message);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var validContribution2Message = "Send Valid Contribution - 1900 ETH From Account7 - After Crowdsale Start";
console.log("RESULT: " + validContribution1Message);
var validContribution2Tx = mec.investWithCustomerId(account7, 124, {from: account7, to: mecAddress, gas: 400000, value: web3.toWei("1900", "ether")});

while (txpool.status.pending > 0) {
}
printTxData("validContribution2Tx", validContribution2Tx);
printBalances();
failIfGasEqualsGasUsed(validContribution2Tx, validContribution2Message);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var finaliseMessage = "Finalise Crowdsale";
console.log("RESULT: " + finaliseMessage);
var finaliseTx = mec.finalize({from: contractOwnerAccount, to: mecAddress, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("finaliseTx", finaliseTx);
printBalances();
failIfGasEqualsGasUsed(finaliseTx, finaliseMessage);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var transfersMessage = "Testing token transfers";
console.log("RESULT: " + transfersMessage);
var transfers1Tx = cst.transfer(account8, "1000000000000000000", {from: account6, gas: 100000});
var transfers2Tx = cst.approve(account9,  "2000000000000000000", {from: account7, gas: 100000});
while (txpool.status.pending > 0) {
}
var transfers3Tx = cst.transferFrom(account7, account9, "2000000000000000000", {from: account9, gas: 100000});
while (txpool.status.pending > 0) {
}
printTxData("transfers1Tx", transfers1Tx);
printTxData("transfers2Tx", transfers2Tx);
printTxData("transfers3Tx", transfers3Tx);
printBalances();
failIfGasEqualsGasUsed(transfers1Tx, transfersMessage + " - transfer 1 token ac6 -> ac8");
failIfGasEqualsGasUsed(transfers2Tx, transfersMessage + " - approve 2 tokens ac7 -> ac9");
failIfGasEqualsGasUsed(transfers3Tx, transfersMessage + " - transferFrom 2 tokens ac7 -> ac9");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var invalidPaymentMessage = "Send invalid payment to token contract";
console.log("RESULT: " + invalidPaymentMessage);
var invalidPaymentTx = eth.sendTransaction({from: account7, to: cstAddress, gas: 400000, value: web3.toWei("123", "ether")});

while (txpool.status.pending > 0) {
}
printTxData("invalidPaymentTx", invalidPaymentTx);
printBalances();
passIfGasEqualsGasUsed(invalidPaymentTx, invalidPaymentMessage);
printTokenContractDetails();
console.log("RESULT: ");


exit;


// -----------------------------------------------------------------------------
// Wait for crowdsale end
// -----------------------------------------------------------------------------
var endsAtTime = mec.endsAt();
var endsAtTimeDate = new Date(endsAtTime * 1000);
console.log("RESULT: Waiting until startAt date at " + endsAtTime + " " + endsAtTimeDate +
  " currentDate=" + new Date());
while ((new Date()).getTime() <= endsAtTimeDate.getTime()) {
}
console.log("RESULT: Waited until start date at " + endsAtTime + " " + endsAtTimeDate +
  " currentDate=" + new Date());

EOF
grep "DATA: " $TEST1OUTPUT | sed "s/DATA: //" > $DEPLOYMENTDATA
cat $DEPLOYMENTDATA
grep "RESULT: " $TEST1OUTPUT | sed "s/RESULT: //" > $TEST1RESULTS
cat $TEST1RESULTS
