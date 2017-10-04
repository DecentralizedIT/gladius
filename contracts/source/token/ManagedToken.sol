pragma solidity ^0.4.15;

import "./Token.sol";
import "./IManagedToken.sol";
import "../../infrastructure/ownership/TransferableOwnership.sol";

/**
 * @title ManagedToken
 *
 * Adds the following functionallity to the basic ERC20 token
 * - Locking
 * - Issuing
 * - Burning 
 *
 * #created 29/09/2017
 * #author Frank Bonnet
 */
contract ManagedToken is IManagedToken, Token, TransferableOwnership {

    // Token state
    bool internal locked;


    /**
     * Allow access only when not locked
     */
    modifier only_when_unlocked() {
        require(!locked);

        _;
    }


    /** 
     * Construct 
     * 
     * @param _name The full token name
     * @param _symbol The token symbol (aberration)
     * @param _locked Whether the token should be locked initially
     */
    function ManagedToken(string _name, string _symbol, bool _locked) Token(_name, _symbol) {
        locked = _locked;
    }


    /** 
     * Send `_value` token to `_to` from `msg.sender`
     * 
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transfer(address _to, uint _value) public only_when_unlocked returns (bool) {
        return super.transfer(_to, _value);
    }


    /** 
     * Send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
     * 
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transferFrom(address _from, address _to, uint _value) public only_when_unlocked returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }


    /** 
     * `msg.sender` approves `_spender` to spend `_value` tokens
     * 
     * @param _spender The address of the account able to transfer the tokens
     * @param _value The amount of tokens to be approved for transfer
     * @return Whether the approval was successful or not
     */
    function approve(address _spender, uint _value) public returns (bool) {
        return super.approve(_spender, _value);
    }


    /** 
     * Returns true if the token is locked
     * 
     * @return Wheter the token is locked
     */
    function isLocked() public constant returns (bool) {
        return locked;
    }


    /**
     * Locks the token so that the transfering of value is enabled 
     *
     * @return Whether the locking was successful or not
     */
    function lock() public only_owner returns (bool)  {
        locked = true;
        return locked;
    }


    /**
     * Unlocks the token so that the transfering of value is enabled 
     *
     * @return Whether the unlocking was successful or not
     */
    function unlock() public only_owner returns (bool)  {
        locked = false;
        return !locked;
    }


    /**
     * Issues `_value` new tokens to `_to`
     *
     * @param _to The address to which the tokens will be issued
     * @param _value The amount of new tokens to issue
     * @return Whether the approval was successful or not
     */
    function issue(address _to, uint _value) public only_owner safe_arguments(2) returns (bool) {
        
        // Check for overflows
        require(balances[_to] + _value > balances[_to]);

        // Create tokens
        balances[_to] += _value;
        totalTokenSupply += _value;

        // Notify listeners 
        Transfer(0, this, _value);
        Transfer(this, _to, _value);

        return true;
    }


    /**
     * Burns `_value` tokens of `_recipient`
     *
     * @param _from The address that owns the tokens to be burned
     * @param _value The amount of tokens to be burned
     * @return Whether the tokens where sucessfully burned or not
     */
    function burn(address _from, uint _value) public only_owner safe_arguments(2) returns (bool) {

        // Check if the token owner has enough tokens
        require(balances[_from] >= _value);

        // Check for overflows
        require(balances[_from] - _value < balances[_from]);

        // Burn tokens
        balances[_from] -= _value;
        totalTokenSupply -= _value;

        // Notify listeners 
        Transfer(_from, 0, _value);

        return true;
    }
}
