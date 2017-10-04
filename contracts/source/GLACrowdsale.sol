pragma solidity ^0.4.15;

import "./crowdsale/Crowdsale.sol";
import "../infrastructure/ITokenRetreiver.sol";
import "../infrastructure/authentication/whitelist/IWhitelist.sol";
import "../integration/wings/IWingsAdapter.sol";

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
contract GLACrowdsale is Crowdsale, ITokenRetreiver, IWingsAdapter {

    /**
     * Whitelist used for authentication
     */
    IWhitelist private whitelist;


    /**
     * Setup the crowdsale
     *
     * @param _start The timestamp of the start date
     * @param _token The token that is sold
     * @param _whitelist The address of the whitelist authenticator
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
    function GLACrowdsale(uint _start, address _token, address _whitelist, uint _tokenDenominator, uint _percentageDenominator, uint _minAmount, uint _maxAmount, uint _minAcceptedAmount, uint _minAmountPresale, uint _maxAmountPresale, uint _minAcceptedAmountPresale, uint _stakeholdersCooldownPeriod) 
        Crowdsale(_start, _token, _tokenDenominator, _percentageDenominator, _minAmount, _maxAmount, _minAcceptedAmount, _minAmountPresale, _maxAmountPresale, _minAcceptedAmountPresale, _stakeholdersCooldownPeriod) {
        whitelist = IWhitelist(_whitelist);
    }


    /**
     * Wings integration - Get the total raised amount of Ether
     *
     * Can only increased, means if you withdraw ETH from the wallet, should be not modified (you can use two fields 
     * to keep one with a total accumulated amount) amount of ETH in contract and totalCollected for total amount of ETH collected
     *
     * @return Total raised Ether amount
     */
    function totalCollected() public constant returns (uint) {
        return raised;
    }


    /**
     * Allows the implementing contract to validate a 
     * contributing account
     *
     * @param _contributor Address that is being validated
     * @return Wheter the contributor is accepted or not
     */
    function isAcceptedContributor(address _contributor) public returns (bool) {
        return whitelist.authenticate(_contributor);
    }


    /**
     * Failsafe mechanism
     * 
     * Allows beneficary to retreive tokens from the contract
     *
     * @param _tokenContract The address of ERC20 compatible token
     */
    function retreiveTokens(address _tokenContract) public only_beneficiary {
        IToken tokenInstance = IToken(_tokenContract);

        // Retreive tokens from our token contract
        ITokenRetreiver(token).retreiveTokens(_tokenContract);

        // Retreive tokens from crowdsale contract
        uint tokenBalance = tokenInstance.balanceOf(this);
        if (tokenBalance > 0) {
            tokenInstance.transfer(owner, tokenBalance);
        }
    }
}