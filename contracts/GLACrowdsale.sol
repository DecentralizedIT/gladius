pragma solidity ^0.4.15;

import "./token/IManagedToken.sol";

/**
 * @title GLACrowdsale
 *
 * Gladius is the decentralized solution to protecting against DDoS attacks by allowing you to connect 
 * to protection pools near you to provide better protection and accelerate your content. With an easy 
 * to use interface as well as powerful insight tools, Gladius enables anyone to protect and accelerate 
 * their website. Visit https://gladius.io/
 *
 * #created 29/09/2017
 * #author Frank Bonnet
 */
contract GLACrowdsale {

    enum Stages {
        InProgress,
        Ended
    }

    struct Balance {
        uint eth;
        uint tokens;
        uint index;
    }

    struct Percentage {
        uint eth;
        uint tokens;
        uint index;
    }

    struct Rate {
        uint value;
        uint end;
        uint bonusReleaseDate;
    }

    // Crowdsale details
    uint public minAmount = 2000 ether; 
    uint public maxAmountPresale = 10000 ether;
    uint public maxAmount = 130000 ether; 
    uint public minAcceptedAmount = 40 finney; // 1/25 ether
    uint public stakeholdersCooldownPeriod = 360 days;

    // Company address
    address public beneficiary; 
    address public confirmedBy; // Address that confirmed beneficiary signing capability 

    // Crowdsale rates and phases
    Rate[] private rates;
    uint public baseRate = 500;

    // Crowdsale state
    uint public start;
    uint public presaleEnd;
    uint public crowdsaleEnd;
    uint public raised;
    uint public allocatedEth;
    uint public allocatedTokens;
    Stages public stage = Stages.InProgress;

    // Token contract
    IManagedToken public token;
    uint private tokenDecimals = 8;

    // Invested balances
    mapping (address => uint) private balances;

    // Alocated balances
    mapping (address => mapping(uint => Balance)) private allocated;
    mapping(address => uint[]) private allocatedIndex;

    // Stakeholders
    mapping (address => Percentage) private stakeholderPercentages;
    address[] private stakeholderPercentagesIndex;


    /**
     * Throw if at stage other than current stage
     * 
     * @param _stage expected stage to test for
     */
    modifier at_stage(Stages _stage) {
        require(stage == _stage);
        _;
    }


    /**
     * Only after crowdsaleEnd plus `_time`
     * 
     * @param _time Time to pass
     */
    modifier only_after(uint _time) {
        require(now > crowdsaleEnd + _time);
        _;
    }


    /**
     * Only after crowdsale
     */
    modifier only_after_crowdsale() {
        require(now > crowdsaleEnd);
        _;
    }


    /**
     * Throw if sender is not beneficiary
     */
    modifier only_beneficiary() {
        require(beneficiary == msg.sender);
        _;
    }


    /**
     * Setup the crowdsale
     *
     * @param _start The timestamp of the start date
     * @param _beneficiary The address of the beneficiary
     * @param _baseRate The base rate (no bonus)
     * @param _rates The crowdsale rates
     * @param _ratePeriods The periods that each phase lasts
     * @param _rateBonusLockupPeriods The lockup period that each phase lasts
     * @param _stakeholders The addresses of the stakeholders
     * @param _stakeholderEthPercentages The eth percentages of the stakeholders (denominated by 4)
     * @param _stakeholderTokenPercentages The token percentages of the stakeholders
     */
    function GLACrowdsale(uint _start, address _token, address _beneficiary, uint _baseRate, uint[] _rates, uint[] _ratePeriods, uint[] _rateBonusLockupPeriods, address[] _stakeholders, uint[] _stakeholderEthPercentages, uint[] _stakeholderTokenPercentages) {
        token = IManagedToken(_token);
        beneficiary = _beneficiary;
        start = _start;
        crowdsaleEnd = start; // Plus the sum of the rate phases

        // Setup crowdsale rates and phases
        baseRate = _baseRate;
        for (uint j = 0; j < _rates.length; j++) {
            crowdsaleEnd += _ratePeriods[j];
            rates.push(Rate(_rates[j], crowdsaleEnd, crowdsaleEnd + _rateBonusLockupPeriods[j]));
        }

        // Setup stakeholder percentages
        for (uint i = 0; i < _stakeholders.length; i++) {
            stakeholderPercentages[_stakeholders[i]] = Percentage(
                _stakeholderEthPercentages[i], _stakeholderTokenPercentages[i], stakeholderPercentagesIndex.push(_stakeholders[i]) - 1);
        }
    }


    /**
     * Returns true if the contract is currently in the presale phase
     *
     * @return True if in presale phase
     */
    function isInPresalePhase() public constant returns (bool) {
        return now >= start && now <= presaleEnd;
    }


    /**
     * Returns true if `_owner` has a balance allocated
     *
     * @return True if there is a balance that belongs to `_owner`
     */
    function hasBalance(address _owner, uint _release) public constant returns (bool) {
        return allocatedIndex[_owner].length > 0 && _release == allocatedIndex[_owner][allocated[_owner][_release].index];
    }


    /** 
     * Get the allocated token balance of `_owner`
     * 
     * @param _owner The address from which the allocated token balance will be retrieved
     * @return The allocated token balance
     */
    function balanceOf(address _owner) external constant returns (uint) {
        uint sum = 0;
        for (uint i = 0; i < allocatedIndex[_owner].length; i++) {
            sum += allocated[_owner][allocatedIndex[_owner][i]].tokens;
        }

        return sum;
    }


    /** 
     * Get the allocated eth balance of `_owner`
     * 
     * @param _owner The address from which the allocated eth balance will be retrieved
     * @return The allocated eth balance
     */
    function ethBalanceOf(address _owner) external constant returns (uint) {
        uint sum = 0;
        for (uint i = 0; i < allocatedIndex[_owner].length; i++) {
            sum += allocated[_owner][allocatedIndex[_owner][i]].eth;
        }

        return sum;
    }


    /** 
     * Get invested and refundable balance of `_owner` (only contributions during the ICO phase are registered)
     * 
     * @param _owner The address from which the refundable balance will be retrieved
     * @return The invested refundable balance
     */
    function refundableEthBalanceOf(address _owner) external constant returns (uint) {
        return now > crowdsaleEnd && raised < minAmount ? 0 : balances[_owner];
    }


    /**
     * Prove that beneficiary is able to sign transactions
     *
     * @return The beneficiary address
     */
    function confirmBeneficiary() external payable only_beneficiary {
        confirmedBy = msg.sender;
    }


    /**
     * Returns the current rate and bonus release date
     *
     * @return (rate, bonus release date)
     */
    function getCurrentRate() public constant returns (uint, uint) {
        uint rate = 0;
        uint bonusReleaseDate = 0;
        if (now >= start) {
            for (uint i = 0; i < rates.length; i++) {
                Rate storage r = rates[i];
                if (now <= r.end) {
                    rate = r.value;
                    bonusReleaseDate = r.bonusReleaseDate;
                    break;
                }
            }
        }
        
        return (rate, bonusReleaseDate);
    }


    /**
     * Convert `_wei` to an amount in tokens using 
     * the `_rate`
     *
     * @param _wei amount of wei to convert
     * @param _rate rate to use for the conversion
     * @return Amount in tokens
     */
    function toTokens(uint _wei, uint _rate) public constant returns (uint) {
        return _wei * _rate * 10**tokenDecimals / 1 ether;
    }


    /**
     * Function to end the crowdsale by setting 
     * the stage to Ended
     */
    function endCrowdsale() external at_stage(Stages.InProgress) {
        require(now > crowdsaleEnd || raised >= maxAmount);
        require(raised >= minAmount);
        stage = Stages.Ended;

        // Unlock token
        if (!token.unlock()) {
            revert();
        }

        // Allocate tokens (no allocation can be done after this period)
        _allocateStakeholdersTokens(token.totalSupply() + allocatedTokens, crowdsaleEnd + stakeholdersCooldownPeriod);

        // Allocate remaining ETH
        _allocateStakeholdersEth(this.balance - allocatedEth, 0);
    }


    /**
     * Withdraw allocated tokens
     */
    function withdrawTokens() external {
        uint tokensToSend = 0;
        for (uint i = 0; i < allocatedIndex[msg.sender].length; i++) {
            uint releaseDate = allocatedIndex[msg.sender][i];
            if (releaseDate <= now) {
                Balance storage b = allocated[msg.sender][releaseDate];
                tokensToSend += b.tokens;
                b.tokens = 0;
            }
        }

        if (tokensToSend > 0) {
            allocatedTokens -= tokensToSend;
            if (!token.issue(msg.sender, tokensToSend)) {
                revert();
            }
        }
    }


    /**
     * Withdraw allocated ether
     */
    function withdrawEther() external {
        uint ethToSend = 0;
        for (uint i = 0; i < allocatedIndex[msg.sender].length; i++) {
            uint releaseDate = allocatedIndex[msg.sender][i];
            if (releaseDate <= now) {
                Balance storage b = allocated[msg.sender][releaseDate];
                ethToSend += b.eth;
                b.eth = 0;
            }
        }

        if (ethToSend > 0) {
            allocatedEth -= ethToSend;
            if (!msg.sender.send(ethToSend)) {
                revert();
            }
        }
    }


    /**
     * Refund in the case of an unsuccessful crowdsale. The 
     * crowdsale is considered unsuccessful if minAmount was 
     * not raised before end
     */
    function refund() external only_after_crowdsale {
        require(raised < minAmount);

        uint receivedAmount = balances[msg.sender];
        balances[msg.sender] = 0;

        if (receivedAmount > 0 && !msg.sender.send(receivedAmount)) {
            balances[msg.sender] = receivedAmount;
        }
    }


    /**
     * Failsafe mechanism
     * 
     * Allows beneficary to extract tokens from the contract
     */
    function extractToken(address _tokenContract, uint _value) external only_beneficiary {
        IToken _tokenInstance = IToken(_tokenContract);
        _tokenInstance.transfer(beneficiary, _value);
    }


    /**
     * Failsafe and clean-up mechanism
     */
    function destroy() external only_beneficiary only_after(180 days) {
        selfdestruct(beneficiary);
    }

    
    /**
     * Receive Eth and issue tokens to the sender
     */
    function () payable at_stage(Stages.InProgress) {
        require(now > start);
        require(now < crowdsaleEnd);
        require(msg.value >= minAcceptedAmount);
        require(raised < maxAmount);

        // Max cap during presale
        bool _isInPresalePhase = isInPresalePhase();
        require(!_isInPresalePhase || raised < maxAmountPresale);

        uint amountToRefund;
        uint acceptedAmount;

        if (_isInPresalePhase && raised + msg.value > maxAmountPresale) {
            acceptedAmount = maxAmountPresale - raised;
        } else if (raised + msg.value > maxAmount) {
            acceptedAmount = maxAmount - raised;
        } else {
            acceptedAmount = msg.value;
        }

        amountToRefund = msg.value - acceptedAmount;
        raised += acceptedAmount;
        
        // Allocate ETH
        if (_isInPresalePhase) {
            // During the preICO - Non refundable
            _allocateStakeholdersEth(acceptedAmount, 0); 
        } else {
            // During the ICO - 100% refundable
            balances[msg.sender] += acceptedAmount; 
        }

        // Distribute tokens
        var (rate, bonusReleaseDate) = getCurrentRate();
        uint tokensAtCurrentRate = toTokens(acceptedAmount, rate);

        uint tokensToIssue;
        if (bonusReleaseDate > 0) {
            tokensToIssue = toTokens(acceptedAmount, baseRate);
            if (tokensAtCurrentRate > tokensToIssue) {
                _allocateTokens(msg.sender, tokensAtCurrentRate - tokensToIssue, bonusReleaseDate);
            }
        } else {
            tokensToIssue = tokensAtCurrentRate;
        }

        if (!token.issue(msg.sender, tokensToIssue)) {
            revert();
        }

        // Refund due to max cap hit
        if (amountToRefund > 0 && !msg.sender.send(amountToRefund)) {
            revert();
        }
    }


    /**
     * Allocate ETH
     *
     * @param _beneficiary The account to alocate the eth for
     * @param _amount The amount of ETH to allocate
     * @param _releaseDate The date after which the eth can be withdrawn
     */    
    function _allocateEth(address _beneficiary, uint _amount, uint _releaseDate) private {
        if (hasBalance(_beneficiary, _releaseDate)) {
            allocated[_beneficiary][_releaseDate].eth += _amount;
        } else {
            allocated[_beneficiary][_releaseDate] = Balance(
                _amount, 0, allocatedIndex[_beneficiary].push(_releaseDate) - 1);
        }

        allocatedEth += _amount;
    }


    /**
     * Allocate Tokens
     *
     * @param _beneficiary The account to alocate the tokens for
     * @param _amount The amount of tokens to allocate
     * @param _releaseDate The date after which the tokens can be withdrawn
     */    
    function _allocateTokens(address _beneficiary, uint _amount, uint _releaseDate) private {
        if (hasBalance(_beneficiary, _releaseDate)) {
            allocated[_beneficiary][_releaseDate].tokens += _amount;
        } else {
            allocated[_beneficiary][_releaseDate] = Balance(
                0, _amount, allocatedIndex[_beneficiary].push(_releaseDate) - 1);
        }

        allocatedTokens += _amount;
    }


    /**
     * Allocate ETH for stakeholders
     *
     * @param _amount The amount of ETH to allocate
     * @param _releaseDate The date after which the eth can be withdrawn
     */    
    function _allocateStakeholdersEth(uint _amount, uint _releaseDate) private {
        for (uint i = 0; i < stakeholderPercentagesIndex.length; i++) {
            Percentage storage p = stakeholderPercentages[stakeholderPercentagesIndex[i]];
            if (p.eth > 0) {
                _allocateEth(stakeholderPercentagesIndex[i], _amount * p.eth / 10**4, _releaseDate);
            }
        }
    }


    /**
     * Allocate Tokens for stakeholders
     *
     * @param _amount The amount of tokens created
     * @param _releaseDate The date after which the tokens can be withdrawn
     */    
    function _allocateStakeholdersTokens(uint _amount, uint _releaseDate) private {
        for (uint i = 0; i < stakeholderPercentagesIndex.length; i++) {
            Percentage storage p = stakeholderPercentages[stakeholderPercentagesIndex[i]];
            if (p.tokens > 0) {
                _allocateTokens(stakeholderPercentagesIndex[i], _amount * p.tokens / 10**4, _releaseDate);
            }
        }
    }
}