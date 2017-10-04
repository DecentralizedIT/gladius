
Date.prototype.getUnixTime = function() { 
  return this.getTime()/1000|0;
};

var web3 = require('web3')
var time = require('../test/lib/time.js')

// Contracts
var TokenContract = artifacts.require("GLAToken")
var CrowdsaleContract = artifacts.require("GLACrowdsale")

module.exports = function(deployer, network, accounts) {

  var tokenInstance
  var crowdsaleInstance
  var stakeholders
  var start 

  var rates
  var baseRate = 500
  var percentageDenominator = 10000 // 4 decimals

  var minAmount = web3.utils.toWei(6896, 'ether')
  var maxAmount = web3.utils.toWei(86206, 'ether')
  var minAcceptedAmount = web3.utils.toWei(40, 'finney')
  var minAmountPresale = web3.utils.toWei(6896, 'ether')
  var maxAmountPresale = web3.utils.toWei(43103, 'ether')
  var minAcceptedAmountPresale = web3.utils.toWei(34, 'ether')
  var stakeholdersCooldownPeriod = 360 * time.days
  
  var phases = [{
    period: 'Presale',
    duration: 27 * time.days,
    rate: 500,
    lockupPeriod: 30 * time.days,
    usesVolumeMultiplier: true
  }, {
    period: 'First 24 hours',
    duration: 1 * time.days,
    rate: 750,
    lockupPeriod: 0,
    usesVolumeMultiplier: false
  }, {
    period: 'First week',
    duration: 7 * time.days,
    rate: 650,
    lockupPeriod: 0,
    usesVolumeMultiplier: false
  }, {
    period: 'Second week',
    duration: 7 * time.days,
    rate: 575,
    lockupPeriod: 0,
    usesVolumeMultiplier: false
  }, {
    period: 'Third week',
    duration: 7 * time.days,
    rate: 525,
    lockupPeriod: 0,
    usesVolumeMultiplier: false
  }, {
    period: 'Last week',
    duration: 7 * time.days,
    rate: 500,
    lockupPeriod: 0,
    usesVolumeMultiplier: false
  }]

  var volumeMultipliers = [{
    rate: 4000,
    lockupPeriod: 0,
    threshold: web3.utils.toWei(34, 'ether')
  }, {
    rate: 5000,
    lockupPeriod: 5000,
    threshold: web3.utils.toWei(103, 'ether')
  }, {
    rate: 6000,
    lockupPeriod: 10000,
    threshold: web3.utils.toWei(344, 'ether')
  }, {
    rate: 7000,
    lockupPeriod: 15000,
    threshold: web3.utils.toWei(689, 'ether')
  }, {
    rate: 8000,
    lockupPeriod: 20000,
    threshold: web3.utils.toWei(1724, 'ether')
  }]

  if (network == "test" || network == "develop" || network == "development") {
    start = new Date("October 4, 2017 12:00:00 GMT+0000").getUnixTime()
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
  } else if(network == "ropsten") {
    start = new Date("October 4, 2017 12:00:00 GMT+0000").getUnixTime()
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
  } else if(network == "main") {
    start = new Date("October 4, 2017 12:00:00 GMT+0000").getUnixTime()
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
  }

  return deployer.deploy(TokenContract).then(function(){
    tokenInstance = TokenContract.at(TokenContract.address)
    return tokenInstance.decimals.call()
  })
  .then(function(_decimals){
    var tokenDenominator = Math.pow(10, _decimals.toNumber())
    return deployer.deploy(CrowdsaleContract, 
      start,
      tokenInstance.address,
      tokenDenominator,
      percentageDenominator,
      minAmount,
      maxAmount,
      minAcceptedAmount,
      minAmountPresale,
      maxAmountPresale,
      minAcceptedAmountPresale,
      stakeholdersCooldownPeriod)
  })
  .then(function () {
    return CrowdsaleContract.deployed()
  })
  .then(function(_instance){
    crowdsaleInstance = _instance
    return crowdsaleInstance.setupPhases(
      baseRate,
      Array.from(phases, val => val.rate), 
      Array.from(phases, val => val.duration), 
      Array.from(phases, val => val.lockupPeriod),
      Array.from(phases, val => val.usesVolumeMultiplier))
  })
  .then(function(){
    return crowdsaleInstance.setupStakeholders(
      Array.from(stakeholders, val => val.account), 
      Array.from(stakeholders, val => val.eth), 
      Array.from(stakeholders, val => val.tokens))
  })
  .then(function(){
    return crowdsaleInstance.setupVolumeMultipliers(
      Array.from(volumeMultipliers, val => val.rate), 
      Array.from(volumeMultipliers, val => val.lockupPeriod), 
      Array.from(volumeMultipliers, val => val.threshold))
  })
  .then(function(){
    return crowdsaleInstance.deploy()
  })
  .then(function(){
    return tokenInstance.transferOwnership(crowdsaleInstance.address)
  })
}
