pragma solidity ^0.4.15;

/**
 * @title ICrowdsale
 *
 * Base crowdsale interface to manages the sale of 
 * an ERC20 token
 *
 * #created 29/09/2017
 * #author Frank Bonnet
 */
contract ICrowdsale {

    /**
     * Allows the implementing contract to validate a 
     * contributing account
     *
     * @param _contributor Address that is being validated
     * @return Wheter the contributor is accepted or not
     */
    function isAcceptedContributor(address _contributor) returns (bool);


    /**
     * Returns true if the contract is currently in the presale phase
     *
     * @return True if in presale phase
     */
    function isInPresalePhase() constant returns (bool);


    /**
     * Returns true if `_beneficiary` has a balance allocated
     *
     * @param _beneficiary The account that the balance is allocated for
     * @param _releaseDate The date after which the balance can be withdrawn
     * @return True if there is a balance that belongs to `_beneficiary`
     */
    function hasBalance(address _beneficiary, uint _releaseDate) constant returns (bool);


    /** 
     * Get the allocated token balance of `_owner`
     * 
     * @param _owner The address from which the allocated token balance will be retrieved
     * @return The allocated token balance
     */
    function balanceOf(address _owner) constant returns (uint);


    /** 
     * Get the allocated eth balance of `_owner`
     * 
     * @param _owner The address from which the allocated eth balance will be retrieved
     * @return The allocated eth balance
     */
    function ethBalanceOf(address _owner) constant returns (uint);


    /** 
     * Get invested and refundable balance of `_owner` (only contributions during the ICO phase are registered)
     * 
     * @param _owner The address from which the refundable balance will be retrieved
     * @return The invested refundable balance
     */
    function refundableEthBalanceOf(address _owner) constant returns (uint);


    /**
     * Returns the current rate and bonus release date
     *
     * @param _volume The amount wei used to determin what volume multiplier to use
     * @return (rate, releaseDate)
     */
    function getCurrentRate(uint _volume) constant returns (uint, uint);


    /**
     * Convert `_wei` to an amount in tokens using 
     * the `_rate`
     *
     * @param _wei amount of wei to convert
     * @param _rate rate to use for the conversion
     * @return Amount in tokens
     */
    function toTokens(uint _wei, uint _rate) constant returns (uint);


    /**
     * Receive Eth and issue tokens to the sender
     */
    function contribute() payable;


    /**
     * Withdraw allocated tokens
     */
    function withdrawTokens();


    /**
     * Withdraw allocated ether
     */
    function withdrawEther();


    /**
     * Refund in the case of an unsuccessful crowdsale. The 
     * crowdsale is considered unsuccessful if minAmount was 
     * not raised before end of the crowdsale
     */
    function refund();
}