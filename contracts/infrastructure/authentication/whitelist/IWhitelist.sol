pragma solidity ^0.4.15;

/**
 * @title IWhitelist 
 *
 * Whitelist authentication interface
 *
 * #created 04/10/2017
 * #author Frank Bonnet
 */
contract IWhitelist {
    

    /**
     * Authenticate 
     *
     * Returns wheter `_account` is on the whitelist
     *
     * @param _account The account to authenticate
     * @return wheter `_account` is successfully authenticated
     */
    function authenticate(address _account) constant returns (bool);
}