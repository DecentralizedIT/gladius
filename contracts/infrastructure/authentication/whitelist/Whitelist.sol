pragma solidity ^0.4.15;

import "./IWhitelist.sol";
import "../../ownership/TransferableOwnership.sol";

/**
 * @title Whitelist 
 *
 * Whitelist authentication list
 *
 * #created 04/10/2017
 * #author Frank Bonnet
 */
contract Whitelist is IWhitelist, TransferableOwnership {

    struct Entry {
        uint datetime;
        bool accepted;
        uint index;
    }

    mapping (address => Entry) internal list;
    address[] internal listIndex;


    /**
     * Returns wheter an entry exists for `_account`
     *
     * @param _account The account to check
     * @return wheter `_account` is has an entry in the whitelist
     */
    function hasEntry(address _account) public constant returns (bool) {
        return listIndex.length > 0 && _account == listIndex[list[_account].index];
    }


    /**
     * Add `_account` to the whitelist
     *
     * If an account is currently disabled, the account is reenabled. Otherwise 
     * a new entry is created
     *
     * @param _account The account to add
     */
    function add(address _account) public only_owner {
        if (!hasEntry(_account)) {
            list[_account] = Entry(
                now, true, listIndex.push(_account) - 1);
        } else {
            Entry storage entry = list[_account];
            if (!entry.accepted) {
                entry.accepted = true;
                entry.datetime = now;
            }
        }
    }


    /**
     * Remove `_account` from the whitelist
     *
     * Will not acctually remove the entry but disable it by updating
     * the accepted record
     *
     * @param _account The account to remove
     */
    function remove(address _account) public only_owner {
        if (hasEntry(_account)) {
            Entry storage entry = list[_account];
            entry.accepted = false;
            entry.datetime = now;
        }
    }


    /**
     * Authenticate 
     *
     * Returns wheter `_account` is on the whitelist
     *
     * @param _account The account to authenticate
     * @return wheter `_account` is successfully authenticated
     */
    function authenticate(address _account) public constant returns (bool) {
        return list[_account].accepted;
    }
}