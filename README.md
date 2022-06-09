
# CryptoSandwiches Contract

---

This repo contains all the contracts used in CryptoSandwiches. It contains its smart contracts, deploy script, test environment and unique config files.

---

## Infomations

[Our home page.](https://cryptosandwiches.com)

You can get white paper from [here](https://foodverse.me/cryptosandwiches-gamingpaper).

---

## Require

node version \>= 10.

solidity version\>= 0.8.0.

truffle version \>= 5.4.0

---

## Local development

First clone the repository:

```
git clone https://github.com/CryptoSandwiches/cryptosandwiches-contract.git
```

Move into the cryptosandwiches working directory

```
cd cryptosandwiches/
```

Install dependencies

```
npm i
```

Compile contracts

```
truffle compile
```

Before deploy, you must config local network node and accounts at truffle\-config.js.

Deploy contracts

```
truffle migrate
```

Run test

```
truffle test
```

You will see output like the following:

```
  Contract: BellyBox
    createBellyBox
      √ should work (49ms)
      √ should confirm if cswCoin was received when bellyBox was created (44ms)
    setBellyBox
      √ should get the same price as set (53ms)
```

## License

CryptoSandwiches  are released under the [MIT License](https://github.com/CryptoSandwiches/cryptosandwiches-contract/blob/main/LICENSE).
