pragma solidity ^0.4.15;

import "./IToken.sol";

/**
 * @title ManagedToken interface
 *
 * Adds the following functionallity to the basic ERC20 token
 * - Locking
 * - Issuing
 *
 * #created 29/09/2017
 * #author Frank Bonnet
 */
contract IManagedToken is IToken { 

    /** 
     * Returns true if the token is locked
     * 
     * @return Whether the token is locked
     */
    function isLocked() constant returns (bool);


    /**
     * Unlocks the token so that the transferring of value is enabled 
     *
     * @return Whether the unlocking was successful or not
     */
    function unlock() returns (bool);


    /**
     * Issues `_value` new tokens to `_to`
     *
     * @param _to The address to which the tokens will be issued
     * @param _value The amount of new tokens to issue
     * @return Whether the tokens where sucessfully issued or not
     */
    function issue(address _to, uint _value) returns (bool);
}