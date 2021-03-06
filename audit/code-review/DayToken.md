# DayToken

Source file [../../contracts/DayToken.sol](../../contracts/DayToken.sol).

<br />

<hr />

```javascript
// BK Ok
pragma solidity ^0.4.13; 

// BK Next 5 Ok
import "./StandardToken.sol"; 
import "./UpgradeableToken.sol"; 
import "./ReleasableToken.sol"; 
import "./MintableToken.sol";
import "./SafeMathLib.sol"; 

/**
 * A crowdsale token.
 *
 * An ERC-20 token designed specifically for crowdsales with investor protection and 
 * further development path.
 *
 * - The token transfer() is disabled until the crowdsale is over
 * - The token contract gives an opt-in upgrade path to a new contract
 * - The same token can be part of several crowdsales through approve() mechanism
 * - The token can be capped (supply set in the constructor) 
 *   or uncapped (crowdsale contract can mint new tokens)
 */
// BK Ok
contract DayToken is  ReleasableToken, MintableToken, UpgradeableToken {

    // BK Ok            0          1        2
    enum sellingStatus {NOTONSALE, EXPIRED, ONSALE}

    /** Basic structure for a contributor with a minting Address
     * adr address of the contributor
     * initialContributionDay initial contribution of the contributor in wei
     * lastUpdatedOn day count from Minting Epoch when the account balance was last updated
     * mintingPower Initial Minting power of the address
     * expiryBlockNumber Variable to mark end of Minting address sale. Set by user
     * minPriceInDay minimum price of Minting address in Day tokens. Set by user
     * status Selling status Variable for transfer Minting address.
     * sellingPriceInDay Variable for transfer Minting address. Price at which the address is actually sold
     */ 
    // BK Next block Ok
    struct Contributor {
        address adr;
        uint256 initialContributionDay;
        uint256 lastUpdatedOn; //Day from Minting Epoch
        uint256 mintingPower;
        uint expiryBlockNumber;
        uint256 minPriceInDay;
        sellingStatus status;
    }

    /* Stores maximum days for which minting will happen since minting epoch */
    // BK Ok
    uint256 public maxMintingDays = 1095;

    /* Mapping to store id of each minting address */
    // BK Ok
    mapping (address => uint) public idOf;
    /* Mapping from id of each minting address to their respective structures */
    // BK Ok
    mapping (uint256 => Contributor) public contributors;
    /* mapping to store unix timestamp of when the minting address is issued to each team member */
    // BK Ok
    mapping (address => uint256) public teamIssuedTimestamp;
    // BK Ok
    mapping (address => bool) public soldAddresses;
    // BK Ok
    mapping (address => uint256) public sellingPriceInDayOf;

    /* Stores the id of the first  contributor */
    // BK Ok
    uint256 public firstContributorId;
    /* Stores total Pre + Post ICO TimeMints */
    // BK Ok
    uint256 public totalNormalContributorIds;
    /* Stores total Normal TimeMints allocated */
    // BK Ok
    uint256 public totalNormalContributorIdsAllocated = 0;
    
    /* Stores the id of the first team TimeMint */
    // BK Ok
    uint256 public firstTeamContributorId;
    /* Stores the total team TimeMints */
    // BK Ok
    uint256 public totalTeamContributorIds;
    /* Stores total team TimeMints allocated */
    // BK Ok
    uint256 public totalTeamContributorIdsAllocated = 0;

    /* Stores the id of the first Post ICO contributor (for auctionable TimeMints) */
    // BK Ok
    uint256 public firstPostIcoContributorId;
    /* Stores total Post ICO TimeMints (for auction) */
    // BK Ok
    uint256 public totalPostIcoContributorIds;
    /* Stores total Auction TimeMints allocated */
    // BK Ok
    uint256 public totalPostIcoContributorIdsAllocated = 0;

    /* Maximum number of address */
    // BK Ok
    uint256 public maxAddresses;

    /* Min Minting power with 19 decimals: 0.5% : 5000000000000000000 */
    // BK Ok
    uint256 public minMintingPower;
    /* Max Minting power with 19 decimals: 1% : 10000000000000000000 */
    // BK Ok
    uint256 public maxMintingPower;
    /* Halving cycle in days (88) */
    // BK Ok
    uint256 public halvingCycle; 
    /* Unix timestamp when minting is to be started */
    // BK Ok
    uint256 public initialBlockTimestamp;
    /* Flag to prevent setting initialBlockTimestamp more than once */
    // BK Ok
    bool public isInitialBlockTimestampSet;
    /* number of decimals in minting power */
    // BK Ok
    uint256 public mintingDec; 

    /* Minimum Balance in Day tokens required to sell a minting address */
    // BK Ok
    uint256 public minBalanceToSell;
    /* Team address lock down period from issued time, in seconds */
    // BK Ok
    uint256 public teamLockPeriodInSec;  //Initialize and set function
    /* Duration in secs that we consider as a day. (For test deployment purposes, 
       if we want to decrease length of a day. default: 84600)*/
    // BK Ok
    uint256 public DayInSecs;

    // BK Next 6 Ok
    event UpdatedTokenInformation(string newName, string newSymbol); 
    event MintingAdrTransferred(uint id, address from, address to);
    event ContributorAdded(address adr, uint id);
    event TimeMintOnSale(uint id, address seller, uint minPriceInDay, uint expiryBlockNumber);
    event TimeMintSold(uint id, address buyer, uint offerInDay);
    event PostInvested(address investor, uint weiAmount, uint tokenAmount, uint customerId, uint contributorId);
    
    // BK Ok
    event TeamAddressAdded(address teamAddress, uint id);
    // Tell us invest was success
    // BK Ok
    event Invested(address receiver, uint weiAmount, uint tokenAmount, uint customerId, uint contributorId);

    // BK Ok
    modifier onlyContributor(uint id){
        require(isValidContributorId(id));
        _;
    }

    // BK Ok
    string public name; 

    // BK Ok
    string public symbol; 

    // BK Ok
    uint8 public decimals; 

    /**
        * Construct the token.
        *
        * This token must be created through a team multisig wallet, so that it is owned by that wallet.
        *
        * @param _name Token name
        * @param _symbol Token symbol - should be all caps
        * @param _initialSupply How many tokens we start with
        * @param _decimals Number of decimal places
        * _mintable Are new tokens created over the crowdsale or do we distribute only the initial supply?
        */
    // BK Ok - Constructor
    function DayToken(string _name, string _symbol, uint _initialSupply, uint8 _decimals, 
        bool _mintable, uint _maxAddresses, uint _firstTeamContributorId, uint _totalTeamContributorIds, 
        uint _totalPostIcoContributorIds, uint256 _minMintingPower, uint256 _maxMintingPower, uint _halvingCycle, 
        uint256 _minBalanceToSell, uint256 _dayInSecs, uint256 _teamLockPeriodInSec) 
        UpgradeableToken(msg.sender) {
        
        // Create any address, can be transferred
        // to team multisig via changeOwner(),
        // also remember to call setUpgradeMaster()
        // BK Next 5 Ok
        owner = msg.sender; 
        name = _name; 
        symbol = _symbol;  
        totalSupply = _initialSupply; 
        decimals = _decimals; 
        // Create initially all balance on the team multisig
        // BK Ok
        balances[owner] = totalSupply; 
        // BK Ok 
        maxAddresses = _maxAddresses;
        // BK Ok
        require(maxAddresses > 1); // else division by zero will occur in setInitialMintingPowerOf
        
        // BK Ok
        firstContributorId = 1;
        // BK Ok
        totalNormalContributorIds = maxAddresses - _totalTeamContributorIds - _totalPostIcoContributorIds;

        // check timeMint total is sane
        // BK Ok
        require(totalNormalContributorIds >= 1);

        // BK Next 3 Ok
        firstTeamContributorId = _firstTeamContributorId;
        totalTeamContributorIds = _totalTeamContributorIds;
        totalPostIcoContributorIds = _totalPostIcoContributorIds;
        
        // calculate first contributor id to be auctioned post ICO
        // BK Ok
        firstPostIcoContributorId = maxAddresses - totalPostIcoContributorIds + 1;
        // BK Ok
        minMintingPower = _minMintingPower;
        // BK Ok
        maxMintingPower = _maxMintingPower;
        // BK Ok
        halvingCycle = _halvingCycle;
        // setting future date far far away, year 2020, 
        // call setInitialBlockTimestamp to set proper timestamp
        // BK Ok
        initialBlockTimestamp = 1577836800;
        // BK Ok
        isInitialBlockTimestampSet = false;
        // use setMintingDec to change this
        // BK Ok
        mintingDec = 19;
        // BK Next 3 Ok
        minBalanceToSell = _minBalanceToSell;
        DayInSecs = _dayInSecs;
        teamLockPeriodInSec = _teamLockPeriodInSec;
        
        // BK Ok
        if (totalSupply > 0) {
            // BK NOTE - Would be useful to have a Transfer(0x0, owner, totalSupply) event for block explorers to pick up
            // BK Ok
            Minted(owner, totalSupply); 
        }

        // BK Ok
        if (!_mintable) {
            // BK Ok
            mintingFinished = true; 
            // BK Ok 
            require(totalSupply != 0); 
        }
    }

    /**
    * Used to set timestamp at which minting power of TimeMints is activated
    * Can be called only by owner
    * @param _initialBlockTimestamp timestamp to be set.
    */
    // BK Ok - Internal function, called by releaseTokens(...). Can only be set once
    function setInitialBlockTimestamp(uint _initialBlockTimestamp) internal onlyOwner {
        // BK Ok
        require(!isInitialBlockTimestampSet);
        // BK Ok
        isInitialBlockTimestampSet = true;
        // BK Ok
        initialBlockTimestamp = _initialBlockTimestamp;
    }

    /**
    * check if mintining power is activated and Day token and Timemint transfer is enabled
    */
    // BK Ok
    function isDayTokenActivated() constant returns (bool isActivated) {
        // BK Ok
        return (block.timestamp >= initialBlockTimestamp);
    }


    /**
    * to check if an id is a valid contributor
    * @param _id contributor id to check.
    */
    // BK Ok
    function isValidContributorId(uint _id) constant returns (bool isValidContributor) {
        // BK Ok
        return (_id > 0 && _id <= maxAddresses && contributors[_id].adr != 0 
            && idOf[contributors[_id].adr] == _id); // cross checking
    }

    /**
    * to check if an address is a valid contributor
    * @param _address  contributor address to check.
    */
    // BK Ok
    function isValidContributorAddress(address _address) constant returns (bool isValidContributor) {
        // BK Ok
        return isValidContributorId(idOf[_address]);
    }


    /**
    * In case of Team address check if lock-in period is over (returns true for all non team addresses)
    * @param _address team address to check lock in period for.
    */
    // BK Ok
    function isTeamLockInPeriodOverIfTeamAddress(address _address) constant returns (bool isLockInPeriodOver) {
        // BK Ok
        isLockInPeriodOver = true;
        // BK Ok
        if (teamIssuedTimestamp[_address] != 0) {
                // BK Ok
                if (block.timestamp - teamIssuedTimestamp[_address] < teamLockPeriodInSec)
                    // BK Ok
                    isLockInPeriodOver = false;
        }

        // BK Ok
        return isLockInPeriodOver;
    }

    /**
    * Used to set mintingDec
    * Can be called only by owner
    * @param _mintingDec bounty to be set.
    */
    // BK NOTE - Can only be called before the initialBlockTimestamp is set. Changes calculations drastically
    // BK Ok
    function setMintingDec(uint256 _mintingDec) onlyOwner {
        // BK Ok
        require(!isInitialBlockTimestampSet);
        // BK Ok
        mintingDec = _mintingDec;
    }

    /**
        * When token is released to be transferable, enforce no new tokens can be created.
        */
    // BK Ok
    function releaseTokenTransfer() public onlyOwner {
        // BK Ok
        require(isInitialBlockTimestampSet);
        // BK Ok
        mintingFinished = true; 
        // BK Ok 
        super.releaseTokenTransfer(); 
    }

    /**
        * Allow upgrade agent functionality kick in only if the crowdsale was success.
        */
    // BK Ok
    function canUpgrade() public constant returns(bool) {
        // BK Ok
        return released && super.canUpgrade(); 
    }

    /**
        * Owner can update token information here
        */
    // BK NOTE - Some systems will expect these values to be hard-coded
    // BK Ok
    function setTokenInformation(string _name, string _symbol) onlyOwner {
        // BK Ok
        name = _name; 
        // BK Ok 
        symbol = _symbol; 
        // BK Ok - Log event 
        UpdatedTokenInformation(name, symbol); 
    }

    /**
        * Returns the current phase.  
        * Note: Phase starts with 1
        * @param _day Number of days since Minting Epoch
        */
    // BK Ok - Constant function
    function getPhaseCount(uint _day) public constant returns (uint phase) {
        // BK Ok
        phase = (_day/halvingCycle) + 1; 
        // BK Ok 
        return (phase); 
    }
    /**
        * Returns current day number since minting epoch 
        * or zero if initialBlockTimestamp is in future or its DayZero.
        */
    // BK Ok
    function getDayCount() public constant returns (uint daySinceMintingEpoch) {
        // BK Ok
        daySinceMintingEpoch = 0;
        // BK Ok
        if (isDayTokenActivated())
            // BK Ok
            daySinceMintingEpoch = (block.timestamp - initialBlockTimestamp)/DayInSecs; 

        // BK Ok
        return daySinceMintingEpoch; 
    }
    /**
        * Calculates and Sets the minting power of a particular id.
        * Called before Minting Epoch by constructor
        * @param _id id of the address whose minting power is to be set.
        */
    // BK Ok - Internal
    function setInitialMintingPowerOf(uint256 _id) internal onlyContributor(_id) {
        // BK Ok
        contributors[_id].mintingPower = 
            (maxMintingPower - ((_id-1) * (maxMintingPower - minMintingPower)/(maxAddresses-1))); 
    }

    /**
        * Returns minting power of a particular id.
        * @param _id Contribution id whose minting power is to be returned
        */
    // BK Ok - Constant function
    function getMintingPowerById(uint _id) public constant returns (uint256 mintingPower) {
        // BK NOTE - getPhaseCount(...) always >= 1
        // BK NOTE - Divisor always 1 or more
        // BK Ok
        return contributors[_id].mintingPower/(2**(getPhaseCount(getDayCount())-1)); 
    }

    /**
        * Returns minting power of a particular address.
        * @param _adr Address whose minting power is to be returned
        */
    // BK Ok - Constant function
    function getMintingPowerByAddress(address _adr) public constant returns (uint256 mintingPower) {
        // BK Ok
        return getMintingPowerById(idOf[_adr]);
    }


    /**
        * Calculates and returns the balance based on the minting power, day and phase.
        * Can only be called internally
        * Can calculate balance based on last updated.
        * @param _id id whose balnce is to be calculated
        * @param _dayCount day count upto which balance is to be updated
        */
    // BK Ok - Could be a constant function, but internal
    function availableBalanceOf(uint256 _id, uint _dayCount) internal returns (uint256) {
        // BK Ok
        uint256 balance = balances[contributors[_id].adr]; 
        // BK Ok
        uint maxUpdateDays = _dayCount < maxMintingDays ? _dayCount : maxMintingDays;
        // BK Ok
        uint i = contributors[_id].lastUpdatedOn + 1;
        // BK Ok
        while(i <= maxUpdateDays) {
             // BK Ok
             uint phase = getPhaseCount(i);
             // BK Ok
             uint phaseEndDay = phase * halvingCycle - 1; // as first day is 0
             // BK Ok
             uint constantFactor = contributors[_id].mintingPower / 2**(phase-1);

            // BK Ok
            for (uint j = i; j <= phaseEndDay && j <= maxUpdateDays; j++) {
                // BK Ok
                balance = safeAdd( balance, constantFactor * balance / 10**(mintingDec + 2) );
            }

            // BK Ok
            i = j;
            
        } 
        // BK Ok
        return balance; 
    }

    /**
        * Updates the balance of the specified id in its structure and also in the balances[] mapping.
        * returns true if successful.
        * Only for internal calls. Not public.
        * @param _id id whose balance is to be updated.
        */
    // BK Ok - Internal function
    function updateBalanceOf(uint256 _id) internal returns (bool success) {
        // check if its contributor
        // BK Ok
        if (isValidContributorId(_id)) {
            // BK Ok
            uint dayCount = getDayCount();
            // proceed only if not already updated today
            // BK Ok
            if (contributors[_id].lastUpdatedOn != dayCount && contributors[_id].lastUpdatedOn < maxMintingDays) {
                // BK Ok
                address adr = contributors[_id].adr;
                // BK Ok
                uint oldBalance = balances[adr];
                // BK Ok
                totalSupply = safeSub(totalSupply, oldBalance);
                // BK Ok
                uint newBalance = availableBalanceOf(_id, dayCount);
                // BK Ok
                balances[adr] = newBalance;
                // BK Ok
                totalSupply = safeAdd(totalSupply, newBalance);
                // BK Ok
                contributors[_id].lastUpdatedOn = dayCount;
                // BK Ok
                Transfer(0, adr, newBalance - oldBalance);
                // BK Ok
                return true; 
            }
        }
        // BK Ok
        return false;
    }


    /**
        * Standard ERC20 function overridden.
        * Returns the balance of the specified address.
        * Calculates the balance on fly only if it is a minting address else 
        * simply returns balance from balances[] mapping.
        * For public calls.
        * @param _adr address whose balance is to be returned.
        */
    // BK Ok - Constant function
    function balanceOf(address _adr) constant returns (uint balance) {
        // BK Ok
        uint id = idOf[_adr];
        // BK Ok
        if (id != 0)
            // BK Ok
            return balanceById(id);
        // BK Ok
        else 
            // BK Ok
            return balances[_adr]; 
    }


    /**
        * Standard ERC20 function overridden.
        * Returns the balance of the specified id.
        * Calculates the balance on fly only if it is a minting address else 
        * simply returns balance from balances[] mapping.
        * For public calls.
        * @param _id address whose balance is to be returned.
        */
    // BK Ok - Constant function
    function balanceById(uint _id) public constant returns (uint256 balance) {
        // BK Ok
        address adr = contributors[_id].adr; 
        // BK Ok 
        if (isDayTokenActivated()) {
            // BK Ok
            if (isValidContributorId(_id)) {
                // BK Ok
                return ( availableBalanceOf(_id, getDayCount()) );
            }
        }
        // BK Ok
        return balances[adr]; 
    }

    /**
        * Returns totalSupply of DAY tokens.
        */
    // BK Ok - Constant function
    function getTotalSupply() public constant returns (uint) {
        // BK Ok
        return totalSupply;
    }


    /** Function to update balance of a Timemint
        * returns true if balance updated, false otherwise
        * @param _id TimeMint to update
        */
    // BK Ok
    function updateTimeMintBalance(uint _id) public returns (bool) {
        // BK Ok
        require(isDayTokenActivated());
        // BK Ok
        return updateBalanceOf(_id);
    }

    /** Function to update balance of sender's Timemint
        * returns true if balance updated, false otherwise
        */
    // BK Ok
    function updateMyTimeMintBalance() public returns (bool) {
        // BK Ok
        require(isDayTokenActivated());
        // BK Ok
        return updateBalanceOf(idOf[msg.sender]);
    }

    /**
        * Standard ERC20 function overidden.
        * Used to transfer day tokens from caller's address to another
        * @param _to address to which Day tokens are to be transferred
        * @param _value Number of Day tokens to be transferred
        */
    // BK Ok
    function transfer(address _to, uint _value) public returns (bool success) {
        // BK Ok
        require(isDayTokenActivated());
        // if Team address, check if lock-in period is over
        // BK Ok
        require(isTeamLockInPeriodOverIfTeamAddress(msg.sender));

        // BK Ok
        updateBalanceOf(idOf[msg.sender]);

        // Check sender account has enough balance and transfer amount is non zero
        // BK Ok
        require ( balanceOf(msg.sender) >= _value && _value != 0 ); 
        
        // BK Ok
        updateBalanceOf(idOf[_to]);

        // BK Ok
        balances[msg.sender] = safeSub(balances[msg.sender], _value); 
        // BK Ok 
        balances[_to] = safeAdd(balances[_to], _value); 
        // BK Ok 
        Transfer(msg.sender, _to, _value);

        // BK Ok
        return true;
    }
    

    /**
        * Standard ERC20 Standard Token function overridden. Added Team address vesting period lock. 
        */
    // BK Ok
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        // BK Ok
        require(isDayTokenActivated());

        // if Team address, check if lock-in period is over
        // BK Ok
        require(isTeamLockInPeriodOverIfTeamAddress(_from));

        // BK Ok
        uint _allowance = allowed[_from][msg.sender];

        // BK Ok
        updateBalanceOf(idOf[_from]);

        // Check from account has enough balance, transfer amount is non zero 
        // and _value is allowed to be transferred
        // BK Ok
        require ( balanceOf(_from) >= _value && _value != 0  &&  _value <= _allowance); 

        // BK Ok
        updateBalanceOf(idOf[_to]);

        // BK Ok
        allowed[_from][msg.sender] = safeSub(_allowance, _value);
        // BK Ok
        balances[_from] = safeSub(balances[_from], _value);
        // BK Ok
        balances[_to] = safeAdd(balances[_to], _value);
    
        // BK Ok
        Transfer(_from, _to, _value);
        
        // BK Ok
        return true;
    }


    /** 
        * Add any contributor structure (For every kind of contributors: Team/Pre-ICO/ICO/Test)
        * @param _adr Address of the contributor to be added  
        * @param _initialContributionDay Initial Contribution of the contributor to be added
        */
  // BK Ok - Internal function
  function addContributor(uint contributorId, address _adr, uint _initialContributionDay) internal onlyOwner {
        // BK Ok
        require(contributorId <= maxAddresses);
        //address should not be an existing contributor
        // BK Ok
        require(!isValidContributorAddress(_adr));
        //TimeMint should not be already allocated
        // BK Ok
        require(!isValidContributorId(contributorId));
        // BK Ok
        contributors[contributorId].adr = _adr;
        // BK Ok
        idOf[_adr] = contributorId;
        // BK Ok
        setInitialMintingPowerOf(contributorId);
        // BK Ok
        contributors[contributorId].initialContributionDay = _initialContributionDay;
        // BK Ok
        contributors[contributorId].lastUpdatedOn = getDayCount();
        // BK Ok
        ContributorAdded(_adr, contributorId);
        // BK Ok
        contributors[contributorId].status = sellingStatus.NOTONSALE;
    }


    /** Function to be called by minting addresses in order to sell their address
        * @param _minPriceInDay Minimum price in DAY tokens set by the seller
        * @param _expiryBlockNumber Expiry Block Number set by the seller
        */
    // BK Ok
    function sellMintingAddress(uint256 _minPriceInDay, uint _expiryBlockNumber) public returns (bool) {
        // BK Ok
        require(isDayTokenActivated());
        // BK Ok
        require(_expiryBlockNumber > block.number);

        // if Team address, check if lock-in period is over
        // BK Ok
        require(isTeamLockInPeriodOverIfTeamAddress(msg.sender));

        // BK Ok
        uint id = idOf[msg.sender];
        // BK Ok
        require(contributors[id].status == sellingStatus.NOTONSALE);

        // update balance of sender address before checking for minimum required balance
        // BK Ok
        updateBalanceOf(id);
        // BK Ok
        require(balances[msg.sender] >= minBalanceToSell);
        // BK Ok
        contributors[id].minPriceInDay = _minPriceInDay;
        // BK Ok
        contributors[id].expiryBlockNumber = _expiryBlockNumber;
        // BK Ok
        contributors[id].status = sellingStatus.ONSALE;
        // BK Ok
        balances[msg.sender] = safeSub(balances[msg.sender], minBalanceToSell);
        // BK Ok
        balances[this] = safeAdd(balances[this], minBalanceToSell);
        // BK Ok
        Transfer(msg.sender, this, minBalanceToSell);
        // BK Ok
        TimeMintOnSale(id, msg.sender, contributors[id].minPriceInDay, contributors[id].expiryBlockNumber);
        // BK Ok
        return true;
    }


    /** Function to be called by minting address in order to cancel the sale of their TimeMint
        */
    // BK Ok
    function cancelSaleOfMintingAddress() onlyContributor(idOf[msg.sender]) public {
        // BK Ok
        uint id = idOf[msg.sender];
        // TimeMint should be on sale
        // BK Ok
        require(contributors[id].status == sellingStatus.ONSALE);
        // BK Ok
        contributors[id].status = sellingStatus.EXPIRED;
    }


    /** Function to be called by any user to get a list of all On Sale TimeMints
        */
    // BK Ok
    function getOnSaleIds() constant public returns(uint[]) {
        // BK Ok
        uint[] memory idsOnSale = new uint[](maxAddresses);
        // BK Ok
        uint j = 0;
        // BK Ok
        for(uint i=1; i <= maxAddresses; i++) {

            // BK Ok
            if ( isValidContributorId(i) &&
                block.number <= contributors[i].expiryBlockNumber && 
                contributors[i].status == sellingStatus.ONSALE ) {
                    // BK Ok
                    idsOnSale[j] = i;
                    // BK Ok
                    j++;     
            }
            
        }
        // BK Ok
        return idsOnSale;
    }


    /** Function to be called by any user to get status of a Time Mint.
        * returns status 0 - Not on sale, 1 - Expired, 2 - On sale,
        * @param _id ID number of the Time Mint 
        */
    // BK Ok
    function getSellingStatus(uint _id) constant public returns(sellingStatus status) {
        // BK Ok
        require(isValidContributorId(_id));
        // BK Ok
        status = contributors[_id].status;
        // BK Ok
        if ( block.number > contributors[_id].expiryBlockNumber && 
                status == sellingStatus.ONSALE )
            // BK Ok
            status = sellingStatus.EXPIRED;

        // BK Ok
        return status;
    }

    /** Function to be called by any user to buy a onsale address by offering an amount
        * @param _offerId ID number of the address to be bought by the buyer
        * @param _offerInDay Offer given by the buyer in number of DAY tokens
        */
    // BK Ok
    function buyMintingAddress(uint _offerId, uint256 _offerInDay) public returns(bool) {
        // BK Ok
        if (contributors[_offerId].status == sellingStatus.ONSALE 
            && block.number > contributors[_offerId].expiryBlockNumber)
        {
            // BK Ok
            contributors[_offerId].status = sellingStatus.EXPIRED;
        }
        // BK Ok
        address soldAddress = contributors[_offerId].adr;
        // BK Ok
        require(contributors[_offerId].status == sellingStatus.ONSALE);
        // BK Ok
        require(_offerInDay >= contributors[_offerId].minPriceInDay);

        // prevent seller from cancelling sale in between
        // BK Ok
        contributors[_offerId].status = sellingStatus.NOTONSALE;

        // first get the offered DayToken in the token contract & 
        // then transfer the total sum (minBalanceToSend+_offerInDay) to the seller
        // BK Ok
        balances[msg.sender] = safeSub(balances[msg.sender], _offerInDay);
        // BK Ok
        balances[this] = safeAdd(balances[this], _offerInDay);
        // BK Ok
        Transfer(msg.sender, this, _offerInDay);
        // BK Ok
        if(transferMintingAddress(contributors[_offerId].adr, msg.sender)) {
            //mark the offer as sold & let seller pull the proceed to their own account.
            // BK Ok
            sellingPriceInDayOf[soldAddress] = _offerInDay;
            // BK Ok
            soldAddresses[soldAddress] = true;
            // BK Ok 
            TimeMintSold(_offerId, msg.sender, _offerInDay);  
        }
        // BK Ok
        return true;
    }


    /**
        * Transfer minting address from one user to another
        * Gives the transfer-to address, the id of the original address
        * returns true if successful and false if not.
        * @param _to address of the user to which minting address is to be tranferred
        */
    // BK Ok - Internal function
    function transferMintingAddress(address _from, address _to) internal onlyContributor(idOf[_from]) returns (bool) {
        // BK Ok
        require(isDayTokenActivated());

        // _to should be non minting address
        // BK Ok
        require(!isValidContributorAddress(_to));
        
        // BK Ok
        uint id = idOf[_from];
        // update balance of from address before transferring minting power
        // BK Ok
        updateBalanceOf(id);

        // BK Ok
        contributors[id].adr = _to;
        // BK Ok
        idOf[_to] = id;
        // BK Ok
        idOf[_from] = 0;
        // BK Ok
        contributors[id].initialContributionDay = 0;
        // needed as id is assigned to new address
        // BK Ok
        contributors[id].lastUpdatedOn = getDayCount();
        // BK Ok
        contributors[id].expiryBlockNumber = 0;
        // BK Ok
        contributors[id].minPriceInDay = 0;
        // BK Ok
        MintingAdrTransferred(id, _from, _to);
        // BK Ok
        return true;
    }


    /** Function to allow seller to get back their deposited amount of day tokens(minBalanceToSell) and 
        * offer made by buyer after successful sale.
        * Throws if sale is not successful
        */
    // BK Ok
    function fetchSuccessfulSaleProceed() public  returns(bool) {
        // BK Ok
        require(soldAddresses[msg.sender] == true);
        // to prevent re-entrancy attack
        // BK Ok
        soldAddresses[msg.sender] = false;
        // BK Ok
        uint saleProceed = safeAdd(minBalanceToSell, sellingPriceInDayOf[msg.sender]);
        // BK Ok
        balances[this] = safeSub(balances[this], saleProceed);
        // BK Ok
        balances[msg.sender] = safeAdd(balances[msg.sender], saleProceed);
        // BK Ok
        Transfer(this, msg.sender, saleProceed);
        // BK Ok
        return true;
                
    }

    /** Function that lets a seller get their deposited day tokens (minBalanceToSell) back, if no buyer turns up.
        * Allowed only after expiryBlockNumber
        * Throws if any other state other than EXPIRED
        */
    // BK Ok
    function refundFailedAuctionAmount() onlyContributor(idOf[msg.sender]) public returns(bool){
        // BK Ok
        uint id = idOf[msg.sender];
        // BK Ok
        if(block.number > contributors[id].expiryBlockNumber && contributors[id].status == sellingStatus.ONSALE)
        {
            // BK Ok
            contributors[id].status = sellingStatus.EXPIRED;
        }
        // BK Ok
        require(contributors[id].status == sellingStatus.EXPIRED);
        // reset selling status
        // BK Ok
        contributors[id].status = sellingStatus.NOTONSALE;
        // BK Ok
        balances[this] = safeSub(balances[this], minBalanceToSell);
        // update balance of seller address before refunding
        // BK Ok
        updateBalanceOf(id);
        // BK Ok
        balances[msg.sender] = safeAdd(balances[msg.sender], minBalanceToSell);
        // BK Ok
        contributors[id].minPriceInDay = 0;
        // BK Ok
        contributors[id].expiryBlockNumber = 0;
        // BK Ok
        Transfer(this, msg.sender, minBalanceToSell);
        // BK Ok
        return true;
    }


    /** Function to add a team address as a contributor and store it's time issued to calculate vesting period
        * Called by owner
        */
    // BK Ok
    function addTeamTimeMints(address _adr, uint _id, uint _tokens, bool _isTest) public onlyOwner {
        //check if Id is in range of team Ids
        // BK Ok
        require(_id >= firstTeamContributorId && _id < firstTeamContributorId + totalTeamContributorIds);
        // BK Ok
        require(totalTeamContributorIdsAllocated < totalTeamContributorIds);
        // BK Ok
        addContributor(_id, _adr, 0);
        // BK Ok
        totalTeamContributorIdsAllocated++;
        // enforce lockin period if not test address
        // BK Ok
        if(!_isTest) teamIssuedTimestamp[_adr] = block.timestamp;
        // BK Ok
        mint(_adr, _tokens);
        // BK Ok
        TeamAddressAdded(_adr, _id);
    }


    /** Function to add reserved aution TimeMints post-ICO. Only by owner
        * @param _receiver Address of the minting to be added
        * @param _customerId Server side id of the customer
        * @param _id contributorId
        */
    // BK Ok
    function postAllocateAuctionTimeMints(address _receiver, uint _customerId, uint _id) public onlyOwner {

        //check if Id is in range of Auction Ids
        // BK Ok
        require(_id >= firstPostIcoContributorId && _id < firstPostIcoContributorId + totalPostIcoContributorIds);
        // BK Ok
        require(totalPostIcoContributorIdsAllocated < totalPostIcoContributorIds);
        
        // BK Ok
        require(released == true);
        // BK Ok
        addContributor(_id, _receiver, 0);
        // BK Ok
        totalPostIcoContributorIdsAllocated++;
        // BK Ok
        PostInvested(_receiver, 0, 0, _customerId, _id);
    }


    /** Function to add all contributors except team, test and Auctions TimeMints. Only by owner
        * @param _receiver Address of the minting to be added
        * @param _customerId Server side id of the customer
        * @param _id contributor id
        * @param _tokens day tokens to allocate
        * @param _weiAmount ether invested in wei
        */
    // BK Ok - Only owner can execute
    function allocateNormalTimeMints(address _receiver, uint _customerId, uint _id, uint _tokens, uint _weiAmount) public onlyOwner {
        // check if Id is in range of Normal Ids
        // BK Ok
        require(_id >= firstContributorId && _id <= totalNormalContributorIds);
        // BK Ok
        require(totalNormalContributorIdsAllocated < totalNormalContributorIds);
        // BK Ok
        addContributor(_id, _receiver, _tokens);
        // BK Ok
        totalNormalContributorIdsAllocated++;
        // BK Ok
        mint(_receiver, _tokens);
        // BK Ok
        Invested(_receiver, _weiAmount, _tokens, _customerId, _id);
        
    }


    /** Function to release token
        * Called by owner
        */
    // BK Ok - Only owner can execute
    function releaseToken(uint _initialBlockTimestamp) public onlyOwner {
        // BK Ok
        require(!released); // check not already released
        
        // BK Ok
        setInitialBlockTimestamp(_initialBlockTimestamp);

        // Make token transferable
        // BK Ok
        releaseTokenTransfer();
    }
    
}

```
