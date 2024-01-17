# Subsidy Provider 🏦

*User must have `Goerli` tokens to test the contract*

## Introduction

This contract represents a Gas Agency backed that provides users with a card, (a 12 digit card, like a debit card) from which they can make payment for their gas, this card is directly linked with their wallet address and amounts are deducted from their balance excluding the subsidy, contract owner has the right to approve the cards to users from the requests that made by the users.

## Getting Started

### Requirements
* Nodejs
* git
* Yarn

* Clone this repository 
* Install packages

```
yarn install
```

## Usage

Compile and deploy contract on `Goerli` testnet

```
hh deploy --network goerli
```
