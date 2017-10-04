pragma solidity ^0.4.15;

/**
 * @title Token retreive interface
 *
 * Allows tokens to be retreived from a contract
 *
 * #created 29/09/2017
 * #author Frank Bonnet
 */
contract ITokenRetreiver {

    /**
     * Extracts tokens from the contract
     *
     * @param _tokenContract The address of ERC20 compatible token
     */
    function retreiveTokens(address _tokenContract);
}