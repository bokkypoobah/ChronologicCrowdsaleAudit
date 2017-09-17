# ChronoLogic Crowdsale Contract Audit

<br />

## Summary

[ChronoLogic](https://chronologic.network/) [ran a crowdsale](https://blog.chronologic.network/chronologic-contribution-period-closed-successful-3655b738757e)
that commenced on August 27 2017 and closed on September 10 2017. The whitepaper can be found
[here](https://chronologic.network/uploads/Chronologic_Whitepaper.pdf).

Bok Consulting Pty Ltd was commissioned to perform an audit on the Ethereum smart contracts for ChronoLogic's crowdsale.

Source code for the original crowdsale/token code that were submitted for audit was available in commits
[3ba1fe8](https://github.com/chronologic/chronologic/commit/3ba1fe830881ca9e85f2c2db3e77b3b333bc4dd1),
[fd67944](https://github.com/chronologic/chronologic/commit/fd679446f01c2d29b02856719548d6a35e8c34c8),
[be2bbba](https://github.com/chronologic/chronologic/commit/be2bbba97ba1c78206d2a21724f6e0b94c9afd93) and
[73a775a](https://github.com/chronologic/chronologic/commit/73a775a61af2c3acdc81dce604aa005e6bd96290).

However the development of the *DayToken* smart contract code was not completed before the start of the crowdsale and
participants sent their ether contributions directly to a multisig wallet at
[0xA723606e907bF84215d5785Ea7f6cD93A0Fbd121](https://etherscan.io/address/0xA723606e907bF84215d5785Ea7f6cD93A0Fbd121).

The crowdsale code was removed from the repository and the refinment of the *DayToken* smart contract continued in commits
[677175a](https://github.com/chronologic/chronologic/commit/677175a5d698bd6f524f59de4cca7f6c1526f32d),
[c91ab6a](https://github.com/chronologic/chronologic/commit/c91ab6abacf29d577a49d5e44a4573e68a1e92c2),
[17e11f0](https://github.com/chronologic/chronologic/commit/17e11f08d632e0fe991f740427f573c7fe7f4860),
[6be55de](https://github.com/chronologic/chronologic/commit/6be55de9774819e7ab3c7f496f861bff8ab91417),
[817ac9f](https://github.com/chronologic/chronologic/commit/817ac9f24d0057b6faafe8e9e7c3ce1f8c2a32c6),
[25c153b](https://github.com/chronologic/chronologic/commit/25c153b028f2007c0ea6e3f0ef614f4c8c0acd83),
[54f032a](https://github.com/chronologic/chronologic/commit/54f032a244d066e09b52445d9171ff514e9baa63),
[af42507](https://github.com/chronologic/chronologic/commit/af42507129c90682afedeae8c7b95ea17a73760b) and
[33c4826](https://github.com/chronologic/chronologic/commit/33c4826aa51dbf720e2a3ed8385669b85a6926aa).

On Sep 16 2015 the finalised *DayToken* contract was deployed to
[0x7268f9c2bc9c9e65b4a16888cb5672531ce8e945](https://etherscan.io/address/0x7268f9c2bc9c9e65b4a16888cb5672531ce8e945#code).

No potential vulnerabilities have been identified in the token contract.

<br />

### Token Contract

The token contract is [ERC20](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md) 
with the following features:

* `decimals` is correctly defined as `uint8` instead of `uint256`
* `transfer(...)` and `transferFrom(...)` will throw an error instead of return true/false when the transfer is invalid
* `transfer(...)` and `transferFrom(...)` have not been built with a check on the size of the data being passed. This check is
  [no longer a recommended feature](https://blog.coinfabrik.com/smart-contract-short-address-attack-mitigation-failure/)
* `approve(...)` has the [requirement that a non-zero approval limit be set to 0 before a new non-zero limit can be set](https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
* The owner is able to modify the `name` and `symbol` of this token contract at any time
* The token balances on "minter" accounts will increase in value daily. The new balance is only calculated when certain
  transactions are executed. The increase in the `totalSupply` will be reflected when the new balance is calculated

See [Know everything about your Time Mints](https://blog.chronologic.network/know-everything-about-your-time-mints-3f6fe7081560)
for some of the features of this token contract.

<br />

<hr />

## Table Of Contents

* [Summary](#summary)
* [Table Of Contents](#table-of-contents)
* [Recommendations](#recommendations)
  * [Recommendations For The Token Contract Only](#recommendations-for-the-token-contract-only)
  * [Recommendations For The Crowdsale And Token Contracts](#recommendations-for-the-crowdsale-and-token-contracts)
* [Potential Vulnerabilities](#potential-vulnerabilities)
* [Scope](#scope)
* [Limitations](#limitations)
* [Due Diligence](#due-diligence)
* [Risks](#risks)
* [Testing](#testing)
* [Code Review](#code-review)

<br />

<hr />

## Recommendations

### Recommendations For The Token Contract Only

These are the recommendations for the token contracts after the removal of the crowdsale contracts.

* **LOW IMPORTANCE** Add a `Transfer({source}, {destination}, {amount});` event log in `sellMintingAddress(...)`, `buyMintingAddress(...)`,
  `fetchSuccessfulSaleProceed()` and `refundFailedAuctionAmount()` - any where tokens are transferred
  * Fixed in [af42507](https://github.com/chronologic/chronologic/commit/af42507129c90682afedeae8c7b95ea17a73760b)
* **LOW IMPORTANCE** Add the `id` to the event `MintingAdrTransferred(...)` emitted in `transferMintingAddress(...)`
  * Fixed in [af42507](https://github.com/chronologic/chronologic/commit/af42507129c90682afedeae8c7b95ea17a73760b)
* **LOW IMPORTANCE** Add a `Transfer(0x0, {account}, {amount});` event log in `updateBalanceOf(...)` when new tokens are minted
  * Fixed in [af42507](https://github.com/chronologic/chronologic/commit/af42507129c90682afedeae8c7b95ea17a73760b)
* **LOW IMPORTANCE** Add a function for any individual account to update their balance
  * Fixed in [33c4826](https://github.com/chronologic/chronologic/commit/33c4826aa51dbf720e2a3ed8385669b85a6926aa) 
* **MEDIUM IMPORTANCE** `listOnSaleAddresses()` could cost more gas that the block gas limit making it impossible for anyone to list all
  the minting addresses on sale. Additionally, each user wanting to find out the list of minting addresses on sale will spend a non-significant
  amount of ethers getting an up-to-date list.

  Gas cost of 3 minting addresses, 1 of which is on sale

      listOnSaleAddressesTx gas=4000000 gasUsed=1520331 costETH=0.027365958 costUSD=7.180772647284 @ ETH/USD=262.398 gasPrice=18000000000 block=910 txId=0x5c29b493f82559d5534074a3ccc11094c04baed6058b8aeb00575e7b45290064

  Gas cost of 6 minting addresses, 1 of which is on sale

      listOnSaleAddressesTx gas=4000000 gasUsed=1522227 costETH=0.027400086 costUSD=7.189727766228 @ ETH/USD=262.398 gasPrice=18000000000 block=994 txId=0x97126654d5f8710660af5874665174010830bfad0986c36e227f850fdc3061d5
      Difference = 1896 for additional 3
      For additional 3330 = 2104560
      Estimated gas for all = 1520331+2104560=3624891

  Gas cost of 6 minting addresses, 2 of which is on sale

      listOnSaleAddressesTx gas=4000000 gasUsed=1524584 costETH=0.027442512 costUSD=7.200860263776 @ ETH/USD=262.398 gasPrice=18000000000 block=1081 txId=0xb01bb0d5e6d10e89a88ee98823335ff91c4d4afa84cb1e82247fdc9184baeb97
      Each additional on sale = 2357
      If +2000 minting addresses are on sale, then the additional gas is 2357 * 2000 = 4714000
      Estimated gas for all = 6818560

  Some suggestions to workaround this issue:

  * Emit an event log message for each call to `sellMintingAddress(...)` with the following information: `_minPriceInDay` and
    `_expiryBlockNumber`
    * [x] Fixed in [54f032a](https://github.com/chronologic/chronologic/commit/54f032a244d066e09b52445d9171ff514e9baa63)
  * Emit an event log message for each call to `buyMintingAddress(...)` when a minting address is successfully sold
    * [x] Fixed in [54f032a](https://github.com/chronologic/chronologic/commit/54f032a244d066e09b52445d9171ff514e9baa63)
  * Provide a *constant* function to list each minting address on sale, and this function call does not emit any events

        function getOnSaleIds() constant public returns(uint[]) {
            uint[] memory idsOnSale = new uint[](maxAddresses);
            uint j = 0;
            for(uint i=1; i <= maxAddresses; i++)
            {
                if (isValidContributorId(i)) {
                    if(contributors[i].expiryBlockNumber!=0 && block.number <= contributors[i].expiryBlockNumber ){
                        if(contributors[i].status == sellingStatus.ONSALE){
                            idsOnSale[j] = i;
                            j++;
                        }
                    }
                }
            }
            return idsOnSale;
        }

    And the output will resemble:
    
    > idsOnSale=["1007","1008","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0", ...]

    * [x] Fixed in [54f032a](https://github.com/chronologic/chronologic/commit/54f032a244d066e09b52445d9171ff514e9baa63)
  * Provide a *constant* function to list the sale status of the minting address specified in the function parameter
    * [x] Fixed in [54f032a](https://github.com/chronologic/chronologic/commit/54f032a244d066e09b52445d9171ff514e9baa63)
  * [x] Fixed in [54f032a](https://github.com/chronologic/chronologic/commit/54f032a244d066e09b52445d9171ff514e9baa63)
* **LOW IMPORTANCE** - In *DayToken*, `isDayTokenActivated()` should be marked as a constant
  * [x] Fixed in [817ac9f](https://github.com/chronologic/chronologic/commit/817ac9f24d0057b6faafe8e9e7c3ce1f8c2a32c6)
* **LOW IMPORTANCE** - In *DayToken*, `isValidContributorId()` should be marked as a constant
  * [x] Fixed in [817ac9f](https://github.com/chronologic/chronologic/commit/817ac9f24d0057b6faafe8e9e7c3ce1f8c2a32c6)
* **LOW IMPORTANCE** - In *DayToken*, `isValidContributorAddress()` should be marked as a constant
  * [x] Fixed in [817ac9f](https://github.com/chronologic/chronologic/commit/817ac9f24d0057b6faafe8e9e7c3ce1f8c2a32c6)
* **LOW IMPORTANCE** - In *DayToken*, `isTeamLockInPeriodOverIfTeamAddress()` should be marked as a constant
  * [x] Fixed in [817ac9f](https://github.com/chronologic/chronologic/commit/817ac9f24d0057b6faafe8e9e7c3ce1f8c2a32c6)
* **LOW IMPORTANCE** - In *DayToken*, `getOnSaleAddresses()` should be named something other than `get...` as it is not a getter and it 
  changes the state
  * [x] Fixed in [25c153b](https://github.com/chronologic/chronologic/commit/25c153b028f2007c0ea6e3f0ef614f4c8c0acd83)

<br />

### Recommendations For The Crowdsale And Token Contracts

These were the recommendations for the crowdsale and token contracts prior to the removal of the crowdsale contracts.

* **HIGH IMPORTANCE** - In *DayToken*, `balances[_to] = safeAdd(balances[msg.sender], _value);` in `transfer(...)` should be
  `balances[_to] = safeAdd(balances[to], _value); `
  * [x] Fixed in [fd679446](https://github.com/chronologic/chronologic/commit/fd679446f01c2d29b02856719548d6a35e8c34c8)
* **MEDIUM IMPORTANCE** - In *DayToken* and *Crowdsale*, please convert the magic numbers like `333`, `3227`, `3227`, `3245` into
  constant variable that will explain the meaning of these numbers
  * [x] Fixed in [be2bbba9](https://github.com/chronologic/chronologic/commit/be2bbba97ba1c78206d2a21724f6e0b94c9afd93)
* **LOW IMPORTANCE** - In *DayToken*, `minBalanceToSell`, `crowdsaleAddress` and `BonusFinalizeAgentAddress` should be made public to
  provide visibility
  * [x] Fixed for `minBalanceToSell` in [fd679446](https://github.com/chronologic/chronologic/commit/fd679446f01c2d29b02856719548d6a35e8c34c8)
* **LOW IMPORTANCE** - In *DayToken*, `DayInSecs` should be renamed `dayInSecs` and `BonusFinalizeAgentAddress` should be renamed
  `bonusFinalizeAgentAddress` for variable naming consistency
  * [x] Fixed for `bonusFinalizeAgentAddress` in [be2bbba9](https://github.com/chronologic/chronologic/commit/be2bbba97ba1c78206d2a21724f6e0b94c9afd93)
* **LOW IMPORTANCE** - In *DayToken*, `modifier onlyCrowdsale()` is unused and can be removed to simplify the contract
  * [x] Fixed in [be2bbba9](https://github.com/chronologic/chronologic/commit/be2bbba97ba1c78206d2a21724f6e0b94c9afd93)
* **LOW IMPORTANCE** - Un-indent `function transferFrom(...)` in *DayToken*
  * [x] Fixed in [fd679446](https://github.com/chronologic/chronologic/commit/fd679446f01c2d29b02856719548d6a35e8c34c8)
* **LOW IMPORTANCE** - In *Crowdsale*, `preMinWei`, `preMaxWei`, `minWei` and `maxWei` should be made public to provide visibility
  * [x] Fixed
* **LOW IMPORTANCE** - In *AddressCappedCrowdsale*, `maxIcoAddresses` is never used
  * [x] Fixed in [fd679446](https://github.com/chronologic/chronologic/commit/fd679446f01c2d29b02856719548d6a35e8c34c8)
* **LOW IMPORTANCE** - Remove `DayToken.updateAllBalances()`. After enquiring about the potentially large gas cost of executing
  this function, the developers have stated that this function is not required any more, as balances are now calculated on the fly
  and this function is now disabled by default, using the switch `updateAllBalancesEnabled`
  * [x] Fixed prior to [817ac9f](https://github.com/chronologic/chronologic/commit/817ac9f24d0057b6faafe8e9e7c3ce1f8c2a32c6)
* **LOW/MEDIUM? IMPORTANCE** `totalSupply` (504,011) does not match up with the total token balances from the accounts (504,000)

       # Account                                             EtherBalanceChange                          Token Name
      -- ------------------------------------------ --------------------------- ------------------------------ ---------------------------
       0 0xa00af22d07c87d96eeeb0ed583f8f6ac7812827e       90.170304840000000000           0.000000000000000000 Account #0 - Miner
       1 0xa11aae29840fbb5c86e6fd4cf809eba183aef433       -0.160592112000000000           0.000000000000000000 Account #1 - Contract Owner
       2 0xa22ab8a9d641ce77e06d98b7d7065d324d3d6976    21000.000000000000000000           0.000000000000000000 Account #2 - Multisig
       3 0xa33a6c312d9ad0e0f2e95541beed0cc081621fd0        0.000000000000000000           0.000000000000000000 Account #3 - Team #1
       4 0xa44a08d3f6933c69212114bb66e2df1813651844        0.000000000000000000           0.000000000000000000 Account #4 - Team #2
       5 0xa55a151eb00fded1634d27d1127b4be4627079ea        0.000000000000000000           0.000000000000000000 Account #5 - Team #3
       6 0xa66a85ede0cbe03694aa9d9de0bb19c99ff55bd9        0.000000000000000000           0.000000000000000000 Account #6 - Test Address #1
       7 0xa77a2b9d4b1c010a22a7c565dc418cef683dbcec        0.000000000000000000           0.000000000000000000 Account #7 - Test Address #2
       8 0xa88a05d2b88283ce84c8325760b72a64591279a2   -20000.005396364000000000      480000.000000000007680000 Account #8
       9 0xa99a0ae3354c06b1459fd441a32a3f71005d7da0    -1000.004316364000000000       24000.000000000000384000 Account #9
      10 0x27daa9fe81944d721dc95e09f54c8bd3a90a5603        0.000000000000000000           0.000000000000000000 Token 'DAY' 'Day'
      11 0x5029cacf1799deb161dc3ab611b2b368c06f15e8        0.000000000000000000           0.000000000000000000 Pricing
      12 0x332ceb425309f4ab99839300329a9626983323be        0.000000000000000000           0.000000000000000000 Crowdsale
      13 0xd8dc1b690f36cf38e8032d751343c9e4df9bdf87        0.000000000000000000           0.000000000000000000 BonusFinalizerAgent
      -- ------------------------------------------ --------------------------- ------------------------------ ---------------------------
                                                                                     504000.000000000008064000 Total Token Balances
      -- ------------------------------------------ --------------------------- ------------------------------ ---------------------------

      PASS Send Valid Contribution After Crowdsale Start - ac8 contributes 20,000 ETH
      PASS Send Valid Contribution After Crowdsale Start - ac9 contributes 1,000 ETH
      ...
      token.totalSupply=504011.000000000008064

  The reason for this is that I deployed the *DayToken* with an `_initialSupply` of 11 and these 11 tokens should have been 
  assigned to the contract owner account 0xa11a . This issue will be of **LOW IMPORTANCE** if this contract will only be
  deployed with an `_initialSupply` of 0.

  This issue may be fixed by the next issue.

  * [x] Fixed prior to [817ac9f](https://github.com/chronologic/chronologic/commit/817ac9f24d0057b6faafe8e9e7c3ce1f8c2a32c6)

* **HIGH IMPORTANCE** `DayToken.balanceOf(...)` does not work as expected for non-minting addresses. If DAY tokens are transferred
  from a minting address to a non-minting address, the non-minting address is not registered in the `DayToken.contributors` data
  structure.

  Following is the `DayToken.balanceOf(...)` function:

      function balanceOf(address _adr) public constant returns (uint256 balance) {
          return balanceById(idOf[_adr]);   
      }

  And following is the `DayToken.balanceById(...)` function:

      function balanceById(uint _id) public constant returns (uint256 balance) {
          address adr = contributors[_id].adr; 
          if (isDayTokenActivated()) {
              if (isValidContributorId(_id)) {
                  return ( availableBalanceOf(_id) );
              }
          }
          return balances[adr]; 
      }

  As the non-minting address is not registered in the `DayToken.contributors` data structure, `adr` will be set to `0x0`. The
  balance of any non-minting address will therefore always be 0.
  
  A suggested fix follows:
  
      function balanceOf(address _adr) public constant returns (uint256 balance) {
          return balanceById(idOf[_adr], _adr);   
      }
      
      function balanceById(uint _id, address a) public constant returns (uint256 balance) {
          address adr = contributors[_id].adr;
          // BK TEST
          if (adr == 0x0)
            adr = a; 
          if (isDayTokenActivated()) {
              if (isValidContributorId(_id)) {
                  return ( availableBalanceOf(_id) );
              }
          }
          return balances[adr]; 
      }

  * [x] Fixed prior to [817ac9f](https://github.com/chronologic/chronologic/commit/817ac9f24d0057b6faafe8e9e7c3ce1f8c2a32c6)

<br />

<hr />

## Potential Vulnerabilities

No potential vulnerabilities have been identified in the token contract.

<br />

<hr />

## Scope

This audit is into the technical aspects of the crowdsale contracts. The primary aim of this audit is to ensure that 
and funds contributed to these contracts are not easily attacked or stolen by third parties. The secondary aim of this
audit is that ensure the coded algorithms work as expected. This audit does not guarantee that that the code is bugfree,
but intends to highlight any areas of weaknesses.

<br />

<hr />

## Limitations

This audit makes no statements or warranties about the viability of the ChronoLogic's business proposition, the individuals
involved in this business or the regulatory regime for the business model.

<br />

<hr />

## Due Diligence

As always, potential participants in any crowdsale are encouraged to perform their due diligence on the business proposition
before funding any crowdsales.

Potential participants are also encouraged to only send their funds to the official crowdsale Ethereum address, published on
the crowdsale beneficiary's official communication channel.

Scammers have been publishing phishing address in the forums, twitter and other communication channels, and some go as far as
duplicating crowdsale websites. Potential participants should NOT just click on any links received through these messages.
Scammers have also hacked the crowdsale website to replace the crowdsale contract address with their scam address.
 
Potential participants should also confirm that the verified source code on EtherScan.io for the published crowdsale address
matches the audited source code, and that the deployment parameters are correctly set, including the constant parameters.

<br />

<hr />

## Risks

* There is no risk of ether funds getting stolen or hacked from the crowdsale or token contracts as the contributed funds
  were collected in a multisig wallet. *DayToken* balances for each contribution was computed and
  [later minted](https://blog.chronologic.network/timemint-assignments-615f859bdc12) when the completed *DayToken* contract
  was deployed.

* This *DayToken* contract has some complexity in the minting, offer for sale, purchase and transfer of the tokens algorithm
  and there is a slight chance the algorithm could contain unintended calculations.

<br />

<hr />

## Testing

### Test 1

* Testing script [test/01_test1.sh](test/01_test1.sh) with results in [test/test1results.txt](test/test1results.txt) and raw output in [test/test1output.txt](test/test1output.txt)
* Assumptions
  * `_DayInSecs = 10`
  * `_minMintingPower = 10000000000000000000;`
  * `_maxMintingPower = 10000000000000000000;`
* Actions
  * Deployment of contract
  * Deployment of 6 minters
  * Testing token transfers
  * Place 2 minters on sale
  * Purchase of 1 minter
  * Sanity check of the resulting token distribution

<br />

### Test 2

* Testing script [test/02_test2.sh](test/02_test2.sh) with results in [test/test2results.txt](test/test2results.txt) and raw output in [test/test2output.txt](test/test2output.txt)
* Assumptions
  * `_DayInSecs = 10`
  * `_minMintingPower = 0;`
  * `_maxMintingPower = 0;`
* Actions
  * Deployment of contract
  * Deployment of 6 minters
  * Testing token transfers
  * Place 2 minters on sale
  * Purchase of 1 minter
  * Sanity check of the resulting token distribution


<br />

<hr />

## Code Review

* [x] [code-review/Ownable.md](code-review/Ownable.md)
  * [x] contract Ownable
* [x] [code-review/SafeMathLib.md](code-review/SafeMathLib.md)
  * [x] contract SafeMathLib
* [x] [code-review/ERC20Basic.md](code-review/ERC20Basic.md)
  * [x] contract ERC20Basic
* [x] [code-review/ERC20.md](code-review/ERC20.md)
  * [x] contract ERC20 is ERC20Basic
* [x] [code-review/ReleasableToken.md](code-review/ReleasableToken.md)
  * [x] contract ReleasableToken is ERC20, Ownable
* [x] [code-review/StandardToken.md](code-review/StandardToken.md)
  * [x] contract StandardToken is ERC20, SafeMathLib 
* [x] [code-review/MintableToken.md](code-review/MintableToken.md)
  * [x] contract MintableToken is StandardToken, Ownable
* [x] [code-review/UpgradeAgent.md](code-review/UpgradeAgent.md)
  * [x] contract UpgradeAgent
* [x] [code-review/UpgradeableToken.md](code-review/UpgradeableToken.md)
  * [x] contract UpgradeableToken is StandardToken 
* [x] [code-review/DayToken.md](code-review/DayToken.md)
  * [x] contract DayToken is  ReleasableToken, MintableToken, UpgradeableToken

<br />

### Not Reviewed

#### ConsenSys Multisig Wallet

[../contracts/ConsenSysWallet.sol](../contracts/ConsenSysWallet.sol) is outside the scope of this review.

The following are the differences between the version in this repository and the original ConsenSys
[MultiSigWallet.sol](https://raw.githubusercontent.com/ConsenSys/MultiSigWallet/e3240481928e9d2b57517bd192394172e31da487/contracts/solidity/MultiSigWallet.sol):

    $ diff -w OriginalConsenSysMultisigWallet.sol ConsenSysWallet.sol 
    1c1
    < pragma solidity 0.4.4;
    ---
    > pragma solidity ^0.4.13;
    367d366
    < 

The only difference is in the Solidity version number.

<br />

The following are the differences between the version in this repository and the ConsenSys MultiSigWallet deployed 
at [0xa646e29877d52b9e2de457eca09c724ff16d0a2b](https://etherscan.io/address/0xa646e29877d52b9e2de457eca09c724ff16d0a2b#code)
by Status.im and is currently holding 284,732.64 Ether:

    $ diff -w ConsenSysWallet.sol StatusConsenSysMultisigWallet.sol 
    1c1
    < pragma solidity ^0.4.13;
    ---
    > pragma solidity ^0.4.11;
    10,18c10,18
    <     event Confirmation(address indexed sender, uint indexed transactionId);
    <     event Revocation(address indexed sender, uint indexed transactionId);
    <     event Submission(uint indexed transactionId);
    <     event Execution(uint indexed transactionId);
    <     event ExecutionFailure(uint indexed transactionId);
    <     event Deposit(address indexed sender, uint value);
    <     event OwnerAddition(address indexed owner);
    <     event OwnerRemoval(address indexed owner);
    <     event RequirementChange(uint required);
    ---
    >     event Confirmation(address indexed _sender, uint indexed _transactionId);
    >     event Revocation(address indexed _sender, uint indexed _transactionId);
    >     event Submission(uint indexed _transactionId);
    >     event Execution(uint indexed _transactionId);
    >     event ExecutionFailure(uint indexed _transactionId);
    >     event Deposit(address indexed _sender, uint _value);
    >     event OwnerAddition(address indexed _owner);
    >     event OwnerRemoval(address indexed _owner);
    >     event RequirementChange(uint _required);
    295c295
    <     /// @dev Returns total number of transactions after filers are applied.
    ---
    >     /// @dev Returns total number of transactions after filters are applied.

The only differences are in the Solidity version number and the prefixing of the event variables with `_`s.

This [link](https://etherscan.io/find-similiar-contracts?a=0xa646e29877d52b9e2de457eca09c724ff16d0a2b) will display
79 (currently) other multisig wallet contracts with high similarity to the ConsenSys MultiSigWallet deployed by Status.im .

Some further information on the ConsenSys multisig wallet:

* [The Gnosis MultiSig Wallet and our Commitment to Security](https://blog.gnosis.pm/the-gnosis-multisig-wallet-and-our-commitment-to-security-ce9aca0d17f6)
* [Release of new Multisig Wallet](https://blog.gnosis.pm/release-of-new-multisig-wallet-59b6811f7edc)

An audit on a previous version of this multisig has already been done by [Martin Holst Swende](https://gist.github.com/holiman/77dfe5addab521bf28ea552591ef8ac4).

<br />

#### Unused Testing Framework

The following file is used for the testing framework are is outside the scope of this review: 
* [../contracts/Migrations.sol](../contracts/Migrations.sol)

<br />

<br />

(c) BokkyPooBah / Bok Consulting Pty Ltd for ChronoLogic - Sep 17 2017. The MIT Licence.