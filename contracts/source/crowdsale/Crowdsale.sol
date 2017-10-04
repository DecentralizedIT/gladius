pragma solidity ^0.4.15;

import "./ICrowdsale.sol";
import "../token/IManagedToken.sol";
import "../../infrastructure/modifier/Owned.sol";

/**
 * @title Crowdsale
 *
 * Abstract base crowdsale contract that manages the sale of 
 * an ERC20 token
 *
 * #created 29/09/2017
 * #author Frank Bonnet
 */
contract Crowdsale is ICrowdsale, Owned {

    enum Stages {
        Deploying,
        Deployed,
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

    struct Phase {
        uint rate;
        uint end;
        uint bonusReleaseDate;
        bool useVolumeMultiplier;
    }

    struct VolumeMultiplier {
        uint rateMultiplier;
        uint bonusReleaseDateMultiplier;
    }

    // Crowdsale details
    uint public baseRate;
    uint public minAmount; 
    uint public maxAmount; 
    uint public minAcceptedAmount;
    uint public minAmountPresale; 
    uint public maxAmountPresale;
    uint public minAcceptedAmountPresale;
    uint public stakeholdersCooldownPeriod;

    // Company address
    address public beneficiary; 
    address public confirmedBy; // Address that proved beneficiary signing capability 

    // Denominators
    uint internal percentageDenominator;
    uint internal tokenDenominator;

    // Crowdsale state
    uint public start;
    uint public presaleEnd;
    uint public crowdsaleEnd;
    uint public raised;
    uint public allocatedEth;
    uint public allocatedTokens;
    Stages public stage = Stages.Deploying;

    // Token contract
    IManagedToken public token;

    // Invested balances
    mapping (address => uint) private balances;

    // Alocated balances
    mapping (address => mapping(uint => Balance)) private allocated;
    mapping(address => uint[]) private allocatedIndex;

    // Stakeholders
    mapping (address => Percentage) private stakeholderPercentages;
    address[] private stakeholderPercentagesIndex;

    // Crowdsale phases
    Phase[] private phases;

    // Volume multipliers
    mapping (uint => VolumeMultiplier) private volumeMultipliers;
    uint[] private volumeMultiplierThresholds;


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
     * @param _token The token that is sold
     * @param _tokenDenominator The token amount of decimals that the token uses
     * @param _percentageDenominator The percision of percentages
     * @param _minAmount The min cap for the ICO
     * @param _maxAmount The max cap for the ICO
     * @param _minAcceptedAmount The lowest accepted amount during the ICO phase
     * @param _minAmountPresale The min cap for the presale
     * @param _maxAmountPresale The max cap for the presale
     * @param _minAcceptedAmountPresale The lowest accepted amount during the presale phase
     * @param _stakeholdersCooldownPeriod The period after which stakeholder tokens are released
     */
    function Crowdsale(uint _start, address _token, uint _tokenDenominator, uint _percentageDenominator, uint _minAmount, uint _maxAmount, uint _minAcceptedAmount, uint _minAmountPresale, uint _maxAmountPresale, uint _minAcceptedAmountPresale, uint _stakeholdersCooldownPeriod) {
        token = IManagedToken(_token);
        tokenDenominator = _tokenDenominator;
        percentageDenominator = _percentageDenominator;
        start = _start;
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        minAcceptedAmount = _minAcceptedAmount;
        minAmountPresale = _minAmountPresale;
        maxAmountPresale = _maxAmountPresale;
        minAcceptedAmountPresale = _minAcceptedAmountPresale;
        stakeholdersCooldownPeriod = _stakeholdersCooldownPeriod;
    }


    /**
     * Setup rates and phases
     *
     * @param _baseRate The rate without bonus
     * @param _phaseRates The rates for each phase
     * @param _phasePeriods The periods that each phase lasts (first phase is the presale phase)
     * @param _phaseBonusLockupPeriods The lockup period that each phase lasts
     * @param _phaseUsesVolumeMultiplier Wheter or not volume bonusses are used in the respective phase
     */
    function setupPhases(uint _baseRate, uint[] _phaseRates, uint[] _phasePeriods, uint[] _phaseBonusLockupPeriods, bool[] _phaseUsesVolumeMultiplier) public only_owner at_stage(Stages.Deploying) {
        baseRate = _baseRate;
        presaleEnd = start + _phasePeriods[0]; // First phase is expected to be the presale phase
        crowdsaleEnd = start; // Plus the sum of the rate phases

        for (uint i = 0; i < _phaseRates.length; i++) {
            crowdsaleEnd += _phasePeriods[i];
            phases.push(Phase(_phaseRates[i], crowdsaleEnd, 0, _phaseUsesVolumeMultiplier[i]));
        }

        for (uint ii = 0; ii < _phaseRates.length; ii++) {
            if (_phaseBonusLockupPeriods[ii] > 0) {
                phases[ii].bonusReleaseDate = crowdsaleEnd + _phaseBonusLockupPeriods[ii];
            }
        }
    }


    /**
     * Setup stakeholders
     *
     * @param _stakeholders The addresses of the stakeholders (first stakeholder is the beneficiary)
     * @param _stakeholderEthPercentages The eth percentages of the stakeholders
     * @param _stakeholderTokenPercentages The token percentages of the stakeholders
     */
    function setupStakeholders(address[] _stakeholders, uint[] _stakeholderEthPercentages, uint[] _stakeholderTokenPercentages) public only_owner at_stage(Stages.Deploying) {
        beneficiary = _stakeholders[0]; // First stakeholder is expected to be the beneficiary
        for (uint i = 0; i < _stakeholders.length; i++) {
            stakeholderPercentages[_stakeholders[i]] = Percentage(
                _stakeholderEthPercentages[i], _stakeholderTokenPercentages[i], stakeholderPercentagesIndex.push(_stakeholders[i]) - 1);
        }
    }

    
    /**
     * Setup volume multipliers
     *
     * @param _volumeMultiplierRates The rates will be multiplied by this value (denominated by 4)
     * @param _volumeMultiplierLockupPeriods The lockup periods will be multiplied by this value (denominated by 4)
     * @param _volumeMultiplierThresholds The volume thresholds for each respective multiplier
     */
    function setupVolumeMultipliers(uint[] _volumeMultiplierRates, uint[] _volumeMultiplierLockupPeriods, uint[] _volumeMultiplierThresholds) public only_owner at_stage(Stages.Deploying) {
        require(phases.length > 0);
        volumeMultiplierThresholds = _volumeMultiplierThresholds;
        for (uint i = 0; i < volumeMultiplierThresholds.length; i++) {
            volumeMultipliers[volumeMultiplierThresholds[i]] = VolumeMultiplier(_volumeMultiplierRates[i], _volumeMultiplierLockupPeriods[i]);
        }
    }
    

    /**
     * After calling the deploy function the crowdsale
     * rules become immutable 
     */
    function deploy() public only_owner at_stage(Stages.Deploying) {
        require(phases.length > 0);
        require(stakeholderPercentagesIndex.length > 0);
        stage = Stages.Deployed;
    }


    /**
     * Prove that beneficiary is able to sign transactions 
     * and start the crowdsale
     */
    function confirmBeneficiary() public only_beneficiary at_stage(Stages.Deployed) {
        stage = Stages.InProgress;
        confirmedBy = msg.sender;
    }


    /**
     * Returns true if the contract is currently in the presale phase
     *
     * @return True if in presale phase
     */
    function isInPresalePhase() public constant returns (bool) {
        return stage == Stages.InProgress && now >= start && now <= presaleEnd;
    }


    /**
     * Returns true if `_beneficiary` has a balance allocated
     *
     * @param _beneficiary The account that the balance is allocated for
     * @param _releaseDate The date after which the balance can be withdrawn
     * @return True if there is a balance that belongs to `_beneficiary`
     */
    function hasBalance(address _beneficiary, uint _releaseDate) public constant returns (bool) {
        return allocatedIndex[_beneficiary].length > 0 && _releaseDate == allocatedIndex[_beneficiary][allocated[_beneficiary][_releaseDate].index];
    }


    /** 
     * Get the allocated token balance of `_owner`
     * 
     * @param _owner The address from which the allocated token balance will be retrieved
     * @return The allocated token balance
     */
    function balanceOf(address _owner) public constant returns (uint) {
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
    function ethBalanceOf(address _owner) public constant returns (uint) {
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
    function refundableEthBalanceOf(address _owner) public constant returns (uint) {
        return now > crowdsaleEnd && raised < minAmount ? 0 : balances[_owner];
    }


    /**
     * Returns the current rate and bonus release date
     *
     * @param _volume The amount wei used to determin what volume multiplier to use
     * @return (rate, releaseDate)
     */
    function getCurrentRate(uint _volume) public constant returns (uint, uint) {
        uint rate = 0;
        uint bonusReleaseDate = 0;
        if (stage == Stages.InProgress && now >= start) {

            // Find phase
            for (uint i = 0; i < phases.length; i++) {
                Phase storage phase = phases[i];
                if (now <= phase.end) {
                    rate = phase.rate;
                    bonusReleaseDate = phase.bonusReleaseDate;
                    break;
                }
            }

            // Find volume multiplier
            if (phase.useVolumeMultiplier && volumeMultiplierThresholds.length > 0 && _volume >= volumeMultiplierThresholds[0]) {
                for (uint ii = volumeMultiplierThresholds.length - 1; ii >= 0; ii--) {
                    if (_volume >= volumeMultiplierThresholds[ii]) {
                        VolumeMultiplier storage multiplier = volumeMultipliers[volumeMultiplierThresholds[ii]];
                        rate += phase.rate * multiplier.rateMultiplier / percentageDenominator;
                        bonusReleaseDate += (phase.bonusReleaseDate - crowdsaleEnd) * multiplier.bonusReleaseDateMultiplier / percentageDenominator;
                        break;
                    }
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
        return _wei * _rate * tokenDenominator / 1 ether;
    }


    /**
     * Function to end the crowdsale by setting 
     * the stage to Ended
     */
    function endCrowdsale() public at_stage(Stages.InProgress) {
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
    function withdrawTokens() public {
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
    function withdrawEther() public {
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
     * not raised before end of the crowdsale
     */
    function refund() public only_after_crowdsale at_stage(Stages.InProgress) {
        require(raised < minAmount);

        uint receivedAmount = balances[msg.sender];
        balances[msg.sender] = 0;

        if (receivedAmount > 0 && !msg.sender.send(receivedAmount)) {
            balances[msg.sender] = receivedAmount;
        }
    }


    /**
     * Failsafe and clean-up mechanism
     */
    function destroy() public only_beneficiary only_after(180 days) {
        selfdestruct(beneficiary);
    }


    /**
     * Receive Eth and issue tokens to the sender
     */
    function () payable at_stage(Stages.InProgress) {
        uint received = msg.value;
        address sender = msg.sender;

        // During the crowdsale
        require(now >= start);
        require(now <= crowdsaleEnd);
        require(isAcceptedContributor(sender));

        // When in presale phase
        bool presalePhase = isInPresalePhase();
        require(!presalePhase || received >= minAcceptedAmountPresale);
        require(!presalePhase || raised < maxAmountPresale);

        // When in ico phase
        require(presalePhase || received >= minAcceptedAmount);
        require(presalePhase || raised >= minAmountPresale);
        require(presalePhase || raised < maxAmount);

        uint amountToRefund;
        uint acceptedAmount;

        if (presalePhase && raised + received > maxAmountPresale) {
            acceptedAmount = maxAmountPresale - raised;
        } else if (raised + received > maxAmount) {
            acceptedAmount = maxAmount - raised;
        } else {
            acceptedAmount = received;
        }

        amountToRefund = received - acceptedAmount;
        raised += acceptedAmount;
        
        if (presalePhase) {
            // During the presale phase - Non refundable
            _allocateStakeholdersEth(acceptedAmount, 0); 
        } else {
            // During the ICO phase - 100% refundable
            balances[sender] += acceptedAmount; 
        }

        // Distribute tokens
        var (rate, bonusReleaseDate) = getCurrentRate(acceptedAmount);
        uint tokensAtCurrentRate = toTokens(acceptedAmount, rate);

        uint tokensToIssue;
        if (bonusReleaseDate > now) {
            tokensToIssue = toTokens(acceptedAmount, baseRate);
            if (tokensAtCurrentRate > tokensToIssue) {
                _allocateTokens(sender, tokensAtCurrentRate - tokensToIssue, bonusReleaseDate);
            }
        } else {
            tokensToIssue = tokensAtCurrentRate;
        }

        if (!token.issue(sender, tokensToIssue)) {
            revert();
        }

        // Refund due to max cap hit
        if (amountToRefund > 0 && !sender.send(amountToRefund)) {
            revert();
        }
    }


    /**
     * Allows the implementing contract to validate a 
     * contributing account
     *
     * @param _contributor Address that is being validated
     * @return Wheter the contributor is accepted or not
     */
    function isAcceptedContributor(address _contributor) returns (bool);


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
                _allocateEth(stakeholderPercentagesIndex[i], _amount * p.eth / percentageDenominator, _releaseDate);
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
                _allocateTokens(stakeholderPercentagesIndex[i], _amount * p.tokens / percentageDenominator, _releaseDate);
            }
        }
    }
}