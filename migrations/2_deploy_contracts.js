
Date.prototype.getUnixTime = function() { 
  return this.getTime()/1000|0;
};

var time = require('../test/lib/time.js')

// Permissions
var ModifierOwned = artifacts.require("modifier/Owned")
var ModifierInputValidator = artifacts.require("modifier/InputValidator")

// Contracts
var GLAToken = artifacts.require("token/GLAToken")
var GLACrowdsale = artifacts.require("GLACrowdsale")

module.exports = function(deployer, network, accounts) {

  var tokenInstance;
  var crowdsaleInstance;
  var stakeholders;
  var rates;
  var baseRate = 500;

  return deployer.deploy(GLAToken).then(function(){
    tokenInstance = GLAToken.at(GLAToken.address);
    
    if (network == "test" || network == "develop") {
      stakeholders = [{
          account: accounts[0], // Beneficiary 
          tokens: 0,
          eth: 8000
        }, {
          account: accounts[3], // Dev team
          tokens: 1500,
          eth: 0
        }, {
          account: accounts[4], // TLG
          tokens: 750,
          eth: 1000
        }, {
          account: accounts[5], // Inbound
          tokens: 750,
          eth: 1000
        }, {
          account: accounts[6], // Bounty
          tokens: 1000,
          eth: 0
        }
      ]

      var phases = [{
          period: 'Presale',
          duration: 27 * time.days,
          rate: 900,
          lockupPeriod: 120 * time.days
      }, {
          period: 'First 24 hours',
          duration: 1 * time.days,
          rate: 750,
          lockupPeriod: 110 * time.days
      }, {
          period: 'First week',
          duration: 7 * time.days,
          rate: 650,
          lockupPeriod: 100 * time.days
      }, {
          period: 'Second week',
          duration: 7 * time.days,
          rate: 575,
          lockupPeriod: 90 * time.days
      }, {
          period: 'Third week',
          duration: 7 * time.days,
          rate: 525,
          lockupPeriod: 80 * time.days
      }, {
          period: 'Last week',
          duration: 7 * time.days,
          rate: 500,
          lockupPeriod: 0 * time.days
      }]

      // Use dummy beneficiary
      return deployer.deploy(GLACrowdsale, 
        new Date("October 4, 2017 12:00:00 GMT+0000").getUnixTime(),
        tokenInstance.address, 
        accounts[0],
        baseRate,
        Array.from(phases, val => val.rate), 
        Array.from(phases, val => val.duration), 
        Array.from(phases, val => val.lockupPeriod),
        Array.from(stakeholders, val => val.account), 
        Array.from(stakeholders, val => val.eth), 
        Array.from(stakeholders, val => val.tokens));

    } else if(network == "ropsten") {

      // Use hardcoded beneficiary on test network
      return deployer.deploy(
        GLACrowdsale, tokenInstance.address, "0xfe4DDDda6eDE6d8ed894fC4c2469383A842686ce", "0x3cAf983aCCccc2551195e0809B7824DA6FDe4EC8", 1506597147); // Now

    } else if(network == "main") {

      // Use hardcoded beneficiary on main network
      return deployer.deploy(
        GLACrowdsale, tokenInstance.address, "0xA2593feA1B725e78822704FDa8D66e0C92C1E223", "0x556762f231c38742B9E04df7C5557005F5Bf5ce5", 1506859200); // "October 1, 2017 12:00:00 GMT+0000
    }

  }).then(function(){
    crowdsaleInstance = GLACrowdsale.at(GLACrowdsale.address);
    if (network == "test" || network == "develop") {
      return tokenInstance.transferOwnership(crowdsaleInstance.address);
    } else {
      return tokenInstance.transferOwnership(crowdsaleInstance.address);
    }
  });
};
