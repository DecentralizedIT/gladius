# Welcome to the Gladius crowdsale and token repository

Gladius is the decentralized solution to protect against DDoS attacks by allowing you to connect 
with protection pools near you to provide better protection and accelerate your content. With an easy 
to use interface as well as powerful insight tools, Gladius enables anyone to protect and accelerate 
their website. Visit https://gladius.io/ 

## Preparing development environment

1. `git clone` this repository.
2. Install Docker. This is needed to run the Test RCP client in an isolated
   environment.
2. Install Node Package Manager (NPM). See [installation
   instructions](https://www.npmjs.com/get-npm)
3. Install the Solidity Compiler (`solc`). See [installation
   instructions](http://solidity.readthedocs.io/en/develop/installing-solidity.html).
4. Run `npm install` to install project dependencies from `package.json`.

## Dependency Management

NPM dependencies are defined in `package.json`.
This makes it easy for all developers to use the same versions of dependencies,
instead of relying on globally installed dependencies using `npm install -g`.

To add a new dependency, execute `npm install --save-dev [package_name]`. This
adds a new entry to `package.json`. Make sure you commit this change.

## Code Style

### Solidity

We strive to adhere to the [Solidity Style
Guide](http://solidity.readthedocs.io/en/latest/style-guide.html) as much as
possible. The [Solium](https://github.com/duaraghav8/Solium)
linter has been added to check code against this Style Guide. The linter is run
automatically by Continuous Integration.

### Javascript

For plain Javascript files (e.g. tests), the [Javascript Standard
Style](https://standardjs.com/) is used. There are several
[plugins](https://standardjs.com/#are-there-text-editor-plugins) available for
widely-used editors. These also support automatic fixing. This linter is run
automatically by Continuous Integration.

## Development

Crowdsale and token developed by [Frank Bonnet](https://www.linkedin.com/in/frank-bonnet-3b890865/) and reviewd by [Hosho]() and [SmartDec]()