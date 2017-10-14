module.exports = {
  networks: {
    test: {
      host: "localhost",
      port: 8545,
      network_id: "*" // Match any network id
    },
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*" // Match any network id
    },
    ropsten: {
      host: "localhost",
      port: 8546,
      network_id: 3, // Official Ethereum test network Ropsten
      from: "0xb1505aEaFe515A66c6975Bf4e62d9B5aa1cd26e4",
      gas: 3000000
    },
    main: {
      host: "localhost",
      port: 8547,
      network_id: 1, // Official Ethereum network 
      from: "0x197f48540296B76caBe1B7C27f35767338084E03",
      gas: 3000000
    }
  }
};
