const { TezosToolkit } = require("@taquito/taquito");
const fs = require("fs");
const assert = require("assert");
const BigNumber = require("bignumber.js");
const { InMemorySigner } = require("@taquito/signer");
const path = require('path');
const { MichelsonMap } = require('@taquito/michelson-encoder');

const { address: tokenAddress1 } = JSON.parse(
  fs.readFileSync("./deploy/Token.json").toString()
);

const { address: initializeExchangeAddress1 } = JSON.parse(
  fs.readFileSync("./deploy/InitializeExchange.json").toString()
);

const { address: investLiquidityAddress1 } = JSON.parse(
  fs.readFileSync("./deploy/InvestLiquidity.json").toString()
);
const { address: divestLiquidityAddress1 } = JSON.parse(
  fs.readFileSync("./deploy/DivestLiquidity.json").toString()
);

const { address: tezToTokenSwapAddress1 } = JSON.parse(
  fs.readFileSync("./deploy/TezToTokenSwap.json").toString()
);

const { address: tokenToTezSwapAddress1 } = JSON.parse(
  fs.readFileSync("./deploy/TokenToTezSwap.json").toString()
);

const { address: tokenToTokenSwapAddress1 } = JSON.parse(
  fs.readFileSync("./deploy/TokenToTokenSwap.json").toString()
);

const { address: tokenToTezPaymentAddress1 } = JSON.parse(
  fs.readFileSync("./deploy/TokenToTezPayment.json").toString()
);

const { address: tezToTokenPaymentAddress1 } = JSON.parse(
  fs.readFileSync("./deploy/TezToTokenPayment.json").toString()
);

const { address: dexAddress1 } = JSON.parse(
  fs.readFileSync("./deploy/Dex.json").toString()
);

const { address: factoryAddress } = JSON.parse(
  fs.readFileSync("./deploy/Factory.json").toString()
);
const { address: tokenAddress2 } = JSON.parse(
  fs.readFileSync("./deploy/Token2.json").toString()
);

const { address: initializeExchangeAddress2 } = JSON.parse(
  fs.readFileSync("./deploy/InitializeExchange2.json").toString()
);

const { address: investLiquidityAddress2 } = JSON.parse(
  fs.readFileSync("./deploy/InvestLiquidity2.json").toString()
);
const { address: divestLiquidityAddress2 } = JSON.parse(
  fs.readFileSync("./deploy/DivestLiquidity2.json").toString()
);

const { address: tezToTokenSwapAddress2 } = JSON.parse(
  fs.readFileSync("./deploy/TezToTokenSwap2.json").toString()
);

const { address: tokenToTezSwapAddress2 } = JSON.parse(
  fs.readFileSync("./deploy/TokenToTezSwap2.json").toString()
);

const { address: tokenToTokenSwapAddress2 } = JSON.parse(
  fs.readFileSync("./deploy/TokenToTokenSwap2.json").toString()
);

const { address: tokenToTezPaymentAddress2 } = JSON.parse(
  fs.readFileSync("./deploy/TokenToTezPayment2.json").toString()
);

const { address: tezToTokenPaymentAddress2 } = JSON.parse(
  fs.readFileSync("./deploy/TezToTokenPayment2.json").toString()
);

const { address: dexAddress2 } = JSON.parse(
  fs.readFileSync("./deploy/Dex2.json").toString()
);

const provider = "http://0.0.0.0:8732";

const getContractFullStorage = async (Tezos, address, maps = {}) => {
  const contract = await Tezos.contract.at(address);
  const storage = await contract.storage();
  var result = {
    ...storage
  };
  for (let key in maps) {
    result[key + "Extended"] = await maps[key].reduce(async (prev, current) => {
      let entry;

      try {
        entry = await storage[key].get(current);
      } catch (ex) {
        console.error(ex);
      }

      return {
        ...await prev,
        [current]: entry
      };
    }, Promise.resolve({}));
  }
  return result;
};

class Dex {

  constructor(Tezos, contract, initializeExchange, investLiquidity, divestLiquidity, tezToTokenSwap, tokenToTezSwap, tokenToTokenSwap, tezToTokenPayment, tokenToTezPayment) {
    this.tezos = Tezos;
    this.contract = contract;
    this.initializeExchangeContract = initializeExchange;
    this.investLiquidityContract = investLiquidity;
    this.divestLiquidityContract = divestLiquidity;
    this.tezToTokenSwapContract = tezToTokenSwap;
    this.tezToTokenPaymentContract = tezToTokenPayment;
    this.tokenToTezSwapContract = tokenToTezSwap;
    this.tokenToTokenSwapContract = tokenToTokenSwap;
    this.tokenToTezPaymentContract = tokenToTezPayment;
  }

  static async init(Tezos,
    dexAddress,
    initializeExchangeAddress,
    investLiquidityAddress,
    divestLiquidityAddress,
    tezToTokenSwapAddress,
    tokenToTezSwapAddress,
    tokenToTokenSwapAddress,
    tezToTokenPaymentAddress,
    tokenToTezPaymentAddress) {
    return new Dex(Tezos, await Tezos.contract.at(dexAddress),
      await Tezos.contract.at(initializeExchangeAddress),
      await Tezos.contract.at(investLiquidityAddress),
      await Tezos.contract.at(divestLiquidityAddress),
      await Tezos.contract.at(tezToTokenSwapAddress),
      await Tezos.contract.at(tokenToTezSwapAddress),
      await Tezos.contract.at(tokenToTokenSwapAddress),
      await Tezos.contract.at(tezToTokenPaymentAddress),
      await Tezos.contract.at(tokenToTezPaymentAddress)
    );
  }

  async prepare() {
    let operation = await this.initializeExchangeContract.methods
      .setMain(this.contract.address)
      .send();
    await operation.confirmation();

    operation = await this.investLiquidityContract.methods
      .setMain(this.contract.address)
      .send();
    await operation.confirmation();

    operation = await this.divestLiquidityContract.methods
      .setMain(this.contract.address)
      .send();
    await operation.confirmation();

    operation = await this.tezToTokenSwapContract.methods
      .setMain(this.contract.address)
      .send();
    await operation.confirmation();

    operation = await this.tokenToTezSwapContract.methods
      .setMain(this.contract.address)
      .send();
    await operation.confirmation();

    operation = await this.tokenToTokenSwapContract.methods
      .setMain(this.contract.address)
      .send();
    await operation.confirmation();

    operation = await this.tokenToTezPaymentContract.methods
      .setMain(this.contract.address)
      .send();
    await operation.confirmation();

    operation = await this.tezToTokenPaymentContract.methods
      .setMain(this.contract.address)
      .send();
    await operation.confirmation();
  }

  async getFullStorage(maps = { shares: [] }) {
    const storage = await this.contract.storage();
    var result = {
      ...storage
    };
    for (let key in maps) {
      result[key + "Extended"] = await maps[key].reduce(async (prev, current) => {
        let entry;

        try {
          entry = await storage[key].get(current);
        } catch (ex) {
          console.error(ex);
        }

        return {
          ...await prev,
          [current]: entry
        };
      }, Promise.resolve({}));
    }
    return result;
  }

  async approve(tokenAmount, address) {
    let storage = await this.getFullStorage();
    let token = await this.tezos.contract.at(storage.tokenAddress);
    let operation = await token.methods
      .approve(address, tokenAmount)
      .send();
    await operation.confirmation();
  }

  async veto(voter) {
    const operation = await this.contract.methods
      .veto(voter)
      .send();
    await operation.confirmation();
    return operation;
  }

  async vote(voter, delegate) {
    const operation = await this.contract.methods
      .vote(voter, delegate)
      .send();
    await operation.confirmation();
    return operation;
  }

  async setVotesDelegation(voter, allowance) {
    const operation = await this.contract.methods
      .setVotesDelegation(voter, allowance)
      .send();
    await operation.confirmation();
    return operation;
  }

  async initializeExchange(tokenAmount, tezAmount) {
    await this.approve(tokenAmount, this.initializeExchangeContract.address);
    const operation = await this.initializeExchangeContract.methods
      .use(tokenAmount)
      .send({ amount: tezAmount });
    await operation.confirmation();
    return operation;
  }

  async investLiquidity(tokenAmount, tezAmount, minShares) {
    await this.approve(tokenAmount, this.investLiquidityContract.address);
    const operation = await this.investLiquidityContract.methods
      .use(minShares)
      .send({ amount: tezAmount });
    await operation.confirmation();
    return operation;
  }

  async divestLiquidity(tokenAmount, tezAmount, sharesBurned) {
    const operation = await this.divestLiquidityContract.methods
      .use(sharesBurned, tezAmount, tokenAmount)
      .send();
    await operation.confirmation();
    return operation;
  }

  async tezToTokenSwap(minTokens, tezAmount) {
    const operation = await this.tezToTokenSwapContract.methods
      .use(minTokens)
      .send({ amount: tezAmount });
    await operation.confirmation();
    return operation;
  }

  async tezToTokenPayment(minTokens, tezAmount, receiver) {
    const operation = await this.tezToTokenPaymentContract.methods
      .use(minTokens, receiver)
      .send({ amount: tezAmount });
    await operation.confirmation();
    return operation;
  }

  async tokenToTezSwap(tokenAmount, minTezOut) {
    await this.approve(tokenAmount, this.tokenToTezSwapContract.address);
    const operation = await this.tokenToTezSwapContract.methods
      .use(tokenAmount, minTezOut)
      .send();
    await operation.confirmation();
    return operation;
  }

  async tokenToTezPayment(tokenAmount, minTezOut, receiver) {
    await this.approve(tokenAmount, this.tokenToTezPaymentContract.address);
    const operation = await this.tokenToTezPaymentContract.methods
      .use(tokenAmount, minTezOut, receiver)
      .send();
    await operation.confirmation();
    return operation;
  }

  async tokenToTokenSwap(tokenAmount, minTokensOut, tokenAddress) {
    await this.approve(tokenAmount);
    const operation = await this.contract.methods
      .tokenToTokenSwap(tokenAmount, minTokensOut, tokenAddress)
      .send();
    await operation.confirmation();
    return operation;
  }

  async tokenToTokenPayment(tokenAmount, minTokensOut, tokenAddress, receiver) {
    await this.approve(tokenAmount);
    const operation = await this.contract.methods
      .tokenToTokenPayment(tokenAmount, minTokensOut, tokenAddress, receiver)
      .send();
    await operation.confirmation();
    return operation;
  }

}

const setup = async (keyPath = "../key") => {
  keyPath = path.join(__dirname, keyPath)
  const secretKey = fs.readFileSync(keyPath).toString();
  let tezos = new TezosToolkit();
  await tezos.setProvider({ rpc: provider, signer: await new InMemorySigner.fromSecretKey(secretKey) });
  return tezos;
};

class Test {
  static async before(dexAddress,
    initializeExchangeAddress,
    investLiquidityAddress,
    divestLiquidityAddress,
    tezToTokenSwapAddress,
    tokenToTezSwapAddress,
    tokenToTokenSwapAddress,
    tezToTokenPaymentAddress,
    tokenToTezPaymentAddress,
    tokenAddress) {
    let tezos = await setup();
    let tezos1 = await setup("../key1");
    let token = await tezos.contract.at(tokenAddress);
    let operation = await token.methods
      .transfer(await tezos.signer.publicKeyHash(), await tezos1.signer.publicKeyHash(), "100000")
      .send();
    await operation.confirmation();

    let dex = await Dex.init(tezos,
      dexAddress,
      initializeExchangeAddress,
      investLiquidityAddress,
      divestLiquidityAddress,
      tezToTokenSwapAddress,
      tokenToTezSwapAddress,
      tokenToTokenSwapAddress,
      tezToTokenPaymentAddress,
      tokenToTezPaymentAddress);
    await dex.prepare();
  }
  static async initializeExchange(dexAddress,
    initializeExchangeAddress,
    investLiquidityAddress,
    divestLiquidityAddress,
    tezToTokenSwapAddress,
    tokenToTezSwapAddress,
    tokenToTokenSwapAddress,
    tezToTokenPaymentAddress,
    tokenToTezPaymentAddress,
    tokenAddress) {
    let Tezos = await setup();
    let dex = await Dex.init(Tezos,
      dexAddress,
      initializeExchangeAddress,
      investLiquidityAddress,
      divestLiquidityAddress,
      tezToTokenSwapAddress,
      tokenToTezSwapAddress,
      tokenToTokenSwapAddress,
      tezToTokenPaymentAddress,
      tokenToTezPaymentAddress);
    const tokenAmount = "1000";
    const tezAmount = "1.0";
    const pkh = await Tezos.signer.publicKeyHash();
    let initialStorage = await dex.getFullStorage({ shares: [pkh] });
    assert(initialStorage.feeRate == 500);
    assert(initialStorage.invariant == 0);
    assert(initialStorage.totalShares == 0);
    assert(initialStorage.tezPool == 0);
    assert(initialStorage.tokenPool == 0);
    assert(initialStorage.tokenAddress == tokenAddress);
    assert(initialStorage.factoryAddress == factoryAddress);
    assert(initialStorage.sharesExtended[pkh] == undefined);

    let operation = await dex.initializeExchange(tokenAmount, tezAmount);
    assert(operation.status === "applied", "Operation was not applied");

    let finalStorage = await dex.getFullStorage({ shares: [pkh] });

    const mutezAmount = parseFloat(tezAmount) * 1000000;
    assert(finalStorage.feeRate == 500);
    assert(finalStorage.invariant == mutezAmount * parseInt(tokenAmount));
    assert(finalStorage.tezPool == mutezAmount);
    assert(finalStorage.tokenPool == tokenAmount);
    assert(finalStorage.tokenAddress == tokenAddress);
    assert(finalStorage.factoryAddress == factoryAddress);
    assert(finalStorage.sharesExtended[pkh] == 1000);
    assert(finalStorage.totalShares == 1000);
  }

  static async investLiquidity(dexAddress,
    initializeExchangeAddress,
    investLiquidityAddress,
    divestLiquidityAddress,
    tezToTokenSwapAddress,
    tokenToTezSwapAddress,
    tokenToTokenSwapAddress,
    tezToTokenPaymentAddress,
    tokenToTezPaymentAddress,
    tokenAddress) {
    let Tezos = await setup("../key1");
    let dex = await Dex.init(Tezos,
      dexAddress,
      initializeExchangeAddress,
      investLiquidityAddress,
      divestLiquidityAddress,
      tezToTokenSwapAddress,
      tokenToTezSwapAddress,
      tokenToTokenSwapAddress,
      tezToTokenPaymentAddress,
      tokenToTezPaymentAddress);
    let tezAmount = "5.0";
    const pkh = await Tezos.signer.publicKeyHash();
    let initialStorage = await dex.getFullStorage({ shares: [pkh] });

    const mutezAmount = parseFloat(tezAmount) * 1000000;
    const minShares = parseInt(
      (mutezAmount / initialStorage.tezPool) * initialStorage.totalShares
    );
    const tokenAmount = parseInt(
      (minShares * initialStorage.tokenPool) / initialStorage.totalShares
    );

    let operation = await dex.investLiquidity(tokenAmount, tezAmount, minShares)
    assert(operation.status === "applied", "Operation was not applied");
    let finalStorage = await dex.getFullStorage({ shares: [pkh] });

    assert(finalStorage.sharesExtended[pkh] == minShares);
    assert(
      finalStorage.tezPool ==
      parseInt(initialStorage.tezPool) + parseInt(mutezAmount)
    );
    assert(
      finalStorage.tokenPool ==
      parseInt(initialStorage.tokenPool) + parseInt(tokenAmount)
    );
    assert(
      finalStorage.totalShares ==
      parseInt(initialStorage.totalShares) + parseInt(minShares)
    );
    assert(
      finalStorage.invariant ==
      (parseInt(initialStorage.tezPool) + parseInt(mutezAmount)) *
      (parseInt(initialStorage.tokenPool) + parseInt(tokenAmount))
    );
  }

  static async tokenToTezSwap(dexAddress,
    initializeExchangeAddress,
    investLiquidityAddress,
    divestLiquidityAddress,
    tezToTokenSwapAddress,
    tokenToTezSwapAddress,
    tokenToTokenSwapAddress,
    tezToTokenPaymentAddress,
    tokenToTezPaymentAddress,
    tokenAddress) {
    let Tezos = await setup();
    let dex = await Dex.init(Tezos,
      dexAddress,
      initializeExchangeAddress,
      investLiquidityAddress,
      divestLiquidityAddress,
      tezToTokenSwapAddress,
      tokenToTezSwapAddress,
      tokenToTokenSwapAddress,
      tezToTokenPaymentAddress,
      tokenToTezPaymentAddress);
    let tokensIn = "1000";
    const pkh = await Tezos.signer.publicKeyHash();

    const initialTezBalance = await Tezos.tz.getBalance(pkh);
    const initialDexStorage = await dex.getFullStorage({ shares: [pkh] });
    const initialTokenStorage = await getContractFullStorage(Tezos, tokenAddress, { ledger: [pkh] });

    const fee = parseInt(tokensIn / initialDexStorage.feeRate);
    const newTokenPool = parseInt(+initialDexStorage.tokenPool + +tokensIn);
    const tempTokenPool = parseInt(newTokenPool - fee);
    const newTezPool = parseInt(initialDexStorage.invariant / tempTokenPool);

    const minTezOut = parseInt(parseInt(initialDexStorage.tezPool - newTezPool));
    try {
      let operation = await dex.tokenToTezSwap(tokensIn, minTezOut)
      assert(operation.status === "applied", "Operation was not applied");

    } catch (e) { console.log(e) }
    let finalStorage = await dex.getFullStorage({ shares: [pkh] });

    const finalTokenStorage = await getContractFullStorage(Tezos, tokenAddress, { ledger: [pkh] });
    const finalTezBalance = await Tezos.tz.getBalance(pkh);

    assert(
      finalTokenStorage.ledgerExtended[pkh].balance ==
      parseInt(initialTokenStorage.ledgerExtended[pkh].balance) - parseInt(tokensIn)
    );
    assert(finalTezBalance >= parseInt(initialTezBalance));
    assert(finalTezBalance <= parseInt(initialTezBalance) + parseInt(minTezOut));
    assert(
      finalStorage.tezPool ==
      parseInt(initialDexStorage.tezPool) - parseInt(minTezOut)
    );
    assert(
      finalStorage.tokenPool ==
      parseInt(initialDexStorage.tokenPool) + parseInt(tokensIn)
    );

    assert(
      finalStorage.invariant ==
      (parseInt(initialDexStorage.tezPool) - parseInt(minTezOut)) *
      (parseInt(initialDexStorage.tokenPool) + parseInt(tokensIn))
    );
  }

  static async tezToTokenSwap(dexAddress,
    initializeExchangeAddress,
    investLiquidityAddress,
    divestLiquidityAddress,
    tezToTokenSwapAddress,
    tokenToTezSwapAddress,
    tokenToTokenSwapAddress,
    tezToTokenPaymentAddress,
    tokenToTezPaymentAddress,
    tokenAddress) {
    let Tezos = await setup();
    let dex = await Dex.init(Tezos,
      dexAddress,
      initializeExchangeAddress,
      investLiquidityAddress,
      divestLiquidityAddress,
      tezToTokenSwapAddress,
      tokenToTezSwapAddress,
      tokenToTokenSwapAddress,
      tezToTokenPaymentAddress,
      tokenToTezPaymentAddress);
    let tezAmount = "0.01";
    const pkh = await Tezos.signer.publicKeyHash();
    const initialDexStorage = await dex.getFullStorage({ shares: [pkh] });
    const initialTokenStorage = await getContractFullStorage(Tezos, tokenAddress, { ledger: [pkh] });
    const initialTezBalance = await Tezos.tz.getBalance(pkh);

    const mutezAmount = parseFloat(tezAmount) * 1000000;

    const fee = parseInt(mutezAmount / initialDexStorage.feeRate);
    const newTezPool = parseInt(+initialDexStorage.tezPool + +mutezAmount);
    const tempTezPool = parseInt(newTezPool - fee);
    const newTokenPool = parseInt(initialDexStorage.invariant / tempTezPool);

    const minTokens = parseInt(
      parseInt(initialDexStorage.tokenPool - newTokenPool)
    );


    let operation = await dex.tezToTokenSwap(minTokens, tezAmount)
    assert(operation.status === "applied", "Operation was not applied");
    let finalStorage = await dex.getFullStorage({ shares: [pkh] });

    const finalTokenStorage = await getContractFullStorage(Tezos, tokenAddress, { ledger: [pkh] });
    const finalTezBalance = await Tezos.tz.getBalance(pkh);

    assert(
      finalTokenStorage.ledgerExtended[pkh].balance ==
      parseInt(initialTokenStorage.ledgerExtended[pkh].balance) + parseInt(minTokens)
    );
    assert(finalTezBalance < parseInt(initialTezBalance) - parseInt(mutezAmount));
    assert(
      finalStorage.tezPool ==
      parseInt(initialDexStorage.tezPool) + parseInt(mutezAmount)
    );
    assert(
      finalStorage.tokenPool ==
      parseInt(initialDexStorage.tokenPool) - parseInt(minTokens)
    );

    assert(
      finalStorage.invariant ==
      (parseInt(initialDexStorage.tezPool) + parseInt(mutezAmount)) *
      (parseInt(initialDexStorage.tokenPool) - parseInt(minTokens))
    );
  }

  static async tezToTokenPayment(dexAddress,
    initializeExchangeAddress,
    investLiquidityAddress,
    divestLiquidityAddress,
    tezToTokenSwapAddress,
    tokenToTezSwapAddress,
    tokenToTokenSwapAddress,
    tezToTokenPaymentAddress,
    tokenToTezPaymentAddress,
    tokenAddress) {
    let Tezos = await setup();
    let Tezos1 = await setup("../key1");
    let dex = await Dex.init(Tezos,
      dexAddress,
      initializeExchangeAddress,
      investLiquidityAddress,
      divestLiquidityAddress,
      tezToTokenSwapAddress,
      tokenToTezSwapAddress,
      tokenToTokenSwapAddress,
      tezToTokenPaymentAddress,
      tokenToTezPaymentAddress);
    let tezAmount = "0.1";
    const pkh = await Tezos.signer.publicKeyHash();
    const pkh1 = await Tezos1.signer.publicKeyHash();
    const initialDexStorage = await dex.getFullStorage({ shares: [pkh, pkh1] });
    const initialTokenStorage = await getContractFullStorage(Tezos, tokenAddress, { ledger: [pkh, pkh1] });
    const initialTezBalance = await Tezos.tz.getBalance(pkh);

    const mutezAmount = parseFloat(tezAmount) * 1000000;

    const fee = parseInt(mutezAmount / initialDexStorage.feeRate);
    const newTezPool = parseInt(+initialDexStorage.tezPool + +mutezAmount);
    const tempTezPool = parseInt(newTezPool - fee);
    const newTokenPool = parseInt(initialDexStorage.invariant / tempTezPool);

    const minTokens = parseInt(
      parseInt(initialDexStorage.tokenPool - newTokenPool)
    );

    let operation = await dex.tezToTokenPayment(minTokens, tezAmount, pkh1)
    assert(operation.status === "applied", "Operation was not applied");
    let finalStorage = await dex.getFullStorage({ shares: [pkh] });

    const finalTokenStorage = await getContractFullStorage(Tezos, tokenAddress, { ledger: [pkh1] });
    const finalTezBalance = await Tezos.tz.getBalance(pkh);

    assert(
      finalTokenStorage.ledgerExtended[pkh1].balance ==
      parseInt(initialTokenStorage.ledgerExtended[pkh1].balance) + parseInt(minTokens)
    );
    assert(finalTezBalance < parseInt(initialTezBalance) - parseInt(mutezAmount));
    assert(
      finalStorage.tezPool ==
      parseInt(initialDexStorage.tezPool) + parseInt(mutezAmount)
    );
    assert(
      finalStorage.tokenPool ==
      parseInt(initialDexStorage.tokenPool) - parseInt(minTokens)
    );

    assert(
      finalStorage.invariant ==
      (parseInt(initialDexStorage.tezPool) + parseInt(mutezAmount)) *
      (parseInt(initialDexStorage.tokenPool) - parseInt(minTokens))
    );
  }

  static async tokenToTezPayment(dexAddress,
    initializeExchangeAddress,
    investLiquidityAddress,
    divestLiquidityAddress,
    tezToTokenSwapAddress,
    tokenToTezSwapAddress,
    tokenToTokenSwapAddress,
    tezToTokenPaymentAddress,
    tokenToTezPaymentAddress,
    tokenAddress) {
    let Tezos = await setup();
    let Tezos1 = await setup("../key1");
    let dex = await Dex.init(Tezos,
      dexAddress,
      initializeExchangeAddress,
      investLiquidityAddress,
      divestLiquidityAddress,
      tezToTokenSwapAddress,
      tokenToTezSwapAddress,
      tokenToTokenSwapAddress,
      tezToTokenPaymentAddress,
      tokenToTezPaymentAddress);
    let tokensIn = "1000";
    const pkh = await Tezos.signer.publicKeyHash();
    const pkh1 = await Tezos1.signer.publicKeyHash();

    const initialTezBalance = await Tezos.tz.getBalance(pkh1);
    const initialDexStorage = await dex.getFullStorage({ shares: [pkh, pkh1] });
    const initialTokenStorage = await getContractFullStorage(Tezos, tokenAddress, { ledger: [pkh, pkh1] });

    const fee = parseInt(tokensIn / initialDexStorage.feeRate);
    const newTokenPool = parseInt(+initialDexStorage.tokenPool + +tokensIn);
    const tempTokenPool = parseInt(newTokenPool - fee);
    const newTezPool = parseInt(initialDexStorage.invariant / tempTokenPool);

    const minTezOut = parseInt(parseInt(initialDexStorage.tezPool - newTezPool));
    let operation = await dex.tokenToTezPayment(tokensIn, minTezOut, pkh1)
    assert(operation.status === "applied", "Operation was not applied");
    let finalStorage = await dex.getFullStorage({ shares: [pkh] });

    const finalTokenStorage = await getContractFullStorage(Tezos, tokenAddress, { ledger: [pkh, pkh1] });
    const finalTezBalance = await Tezos.tz.getBalance(pkh1);

    assert(
      finalTokenStorage.ledgerExtended[pkh].balance ==
      parseInt(initialTokenStorage.ledgerExtended[pkh].balance) - parseInt(tokensIn)
    );
    assert(finalTezBalance >= parseInt(initialTezBalance));
    assert(finalTezBalance <= parseInt(initialTezBalance) + parseInt(minTezOut));
    assert(
      finalStorage.tezPool ==
      parseInt(initialDexStorage.tezPool) - parseInt(minTezOut)
    );
    assert(
      finalStorage.tokenPool ==
      parseInt(initialDexStorage.tokenPool) + parseInt(tokensIn)
    );

    assert(
      finalStorage.invariant ==
      (parseInt(initialDexStorage.tezPool) - parseInt(minTezOut)) *
      (parseInt(initialDexStorage.tokenPool) + parseInt(tokensIn))
    );
  }

  static async divestLiquidity(dexAddress,
    initializeExchangeAddress,
    investLiquidityAddress,
    divestLiquidityAddress,
    tezToTokenSwapAddress,
    tokenToTezSwapAddress,
    tokenToTokenSwapAddress,
    tezToTokenPaymentAddress,
    tokenToTezPaymentAddress,
    tokenAddress) {
    let Tezos = await setup("../key1");
    let dex = await Dex.init(Tezos,
      dexAddress,
      initializeExchangeAddress,
      investLiquidityAddress,
      divestLiquidityAddress,
      tezToTokenSwapAddress,
      tokenToTezSwapAddress,
      tokenToTokenSwapAddress,
      tezToTokenPaymentAddress,
      tokenToTezPaymentAddress);
    let sharesBurned = 1;
    const pkh = await Tezos.signer.publicKeyHash();
    let initialStorage = await dex.getFullStorage({ shares: [pkh] });

    const tezPerShare = parseInt(
      initialStorage.tezPool / initialStorage.totalShares
    );
    const tokensPerShare = parseInt(
      initialStorage.tokenPool / initialStorage.totalShares
    );
    const minTez = tezPerShare * sharesBurned;
    const minTokens = tokensPerShare * sharesBurned;
    let operation = await dex.divestLiquidity(minTokens, minTez, sharesBurned);
    assert(operation.status === "applied", "Operation was not applied");
    let finalStorage = await dex.getFullStorage({ shares: [pkh] });

    assert(
      finalStorage.sharesExtended[pkh] ==
      initialStorage.sharesExtended[pkh] - sharesBurned
    );
    assert(finalStorage.tezPool == parseInt(initialStorage.tezPool) - minTez);
    assert(
      finalStorage.tokenPool == parseInt(initialStorage.tokenPool) - minTokens
    );
    assert(
      finalStorage.totalShares ==
      parseInt(initialStorage.totalShares) - sharesBurned
    );
    assert(
      finalStorage.invariant ==
      (parseInt(initialStorage.tezPool) - minTez) *
      (parseInt(initialStorage.tokenPool) - minTokens)
    );
  }
}

describe('Dex', function () {
  before(async function () {
    this.timeout(1000000);

    await Test.before(
      dexAddress1,
      initializeExchangeAddress1,
      investLiquidityAddress1,
      divestLiquidityAddress1,
      tezToTokenSwapAddress1,
      tokenToTezSwapAddress1,
      tokenToTokenSwapAddress1,
      tezToTokenPaymentAddress1,
      tokenToTezPaymentAddress1,
      tokenAddress1);
    await Test.before(
      dexAddress2,
      initializeExchangeAddress2,
      investLiquidityAddress2,
      divestLiquidityAddress2,
      tezToTokenSwapAddress2,
      tokenToTezSwapAddress2,
      tokenToTokenSwapAddress2,
      tezToTokenPaymentAddress2,
      tokenToTezPaymentAddress2,
      tokenAddress2);
  });

  describe('InitializeExchange()', function () {
    it('should initialize exchange 1', async function () {
      this.timeout(1000000);
      await Test.initializeExchange(dexAddress1,
        initializeExchangeAddress1,
        investLiquidityAddress1,
        divestLiquidityAddress1,
        tezToTokenSwapAddress1,
        tokenToTezSwapAddress1,
        tokenToTokenSwapAddress1,
        tezToTokenPaymentAddress1,
        tokenToTezPaymentAddress1,
        tokenAddress1);
    });

    it('should initialize exchange 2', async function () {
      this.timeout(1000000);
      await Test.initializeExchange(dexAddress2,
        initializeExchangeAddress2,
        investLiquidityAddress2,
        divestLiquidityAddress2,
        tezToTokenSwapAddress2,
        tokenToTezSwapAddress2,
        tokenToTokenSwapAddress2,
        tezToTokenPaymentAddress2,
        tokenToTezPaymentAddress2,
        tokenAddress2);
    });
  });

  describe('InvestLiquidity()', function () {
    it('should invest liquidity 1', async function () {
      this.timeout(1000000);
      await Test.investLiquidity(dexAddress1,
        initializeExchangeAddress1,
        investLiquidityAddress1,
        divestLiquidityAddress1,
        tezToTokenSwapAddress1,
        tokenToTezSwapAddress1,
        tokenToTokenSwapAddress1,
        tezToTokenPaymentAddress1,
        tokenToTezPaymentAddress1,
        tokenAddress1);
    });

    it('should invest liquidity 2', async function () {
      this.timeout(1000000);
      await Test.investLiquidity(dexAddress2,
        initializeExchangeAddress2,
        investLiquidityAddress2,
        divestLiquidityAddress2,
        tezToTokenSwapAddress2,
        tokenToTezSwapAddress2,
        tokenToTokenSwapAddress2,
        tezToTokenPaymentAddress2,
        tokenToTezPaymentAddress2,
        tokenAddress2);
    });
  });

  describe('TezToTokenSwap()', function () {
    it('should exchange tez to token 1', async function () {
      this.timeout(1000000);
      await Test.tezToTokenSwap(dexAddress1,
        initializeExchangeAddress1,
        investLiquidityAddress1,
        divestLiquidityAddress1,
        tezToTokenSwapAddress1,
        tokenToTezSwapAddress1,
        tokenToTokenSwapAddress1,
        tezToTokenPaymentAddress1,
        tokenToTezPaymentAddress1,
        tokenAddress1);
    });

    it('should exchange tez to token 2', async function () {
      this.timeout(1000000);
      await Test.tezToTokenSwap(dexAddress2,
        initializeExchangeAddress2,
        investLiquidityAddress2,
        divestLiquidityAddress2,
        tezToTokenSwapAddress2,
        tokenToTezSwapAddress2,
        tokenToTokenSwapAddress2,
        tezToTokenPaymentAddress2,
        tokenToTezPaymentAddress2,
        tokenAddress2);
    });
  });

  describe('TokenToTezSwap()', function () {
    it('should exchange tez to token 1', async function () {
      this.timeout(1000000);
      await Test.tokenToTezSwap(dexAddress1,
        initializeExchangeAddress1,
        investLiquidityAddress1,
        divestLiquidityAddress1,
        tezToTokenSwapAddress1,
        tokenToTezSwapAddress1,
        tokenToTokenSwapAddress1,
        tezToTokenPaymentAddress1,
        tokenToTezPaymentAddress1,
        tokenAddress1);
    });
    it('should exchange tez to token 2', async function () {
      this.timeout(1000000);
      await Test.tokenToTezSwap(dexAddress2,
        initializeExchangeAddress2,
        investLiquidityAddress2,
        divestLiquidityAddress2,
        tezToTokenSwapAddress2,
        tokenToTezSwapAddress2,
        tokenToTokenSwapAddress2,
        tezToTokenPaymentAddress2,
        tokenToTezPaymentAddress2,
        tokenAddress2);
    });
  });

  describe('TezToTokenPayment()', function () {
    it('should exchange tez to token and send to requested address 1', async function () {
      this.timeout(1000000);
      await Test.tezToTokenPayment(dexAddress1,
        initializeExchangeAddress1,
        investLiquidityAddress1,
        divestLiquidityAddress1,
        tezToTokenSwapAddress1,
        tokenToTezSwapAddress1,
        tokenToTokenSwapAddress1,
        tezToTokenPaymentAddress1,
        tokenToTezPaymentAddress1,
        tokenAddress1);
    });
    it('should exchange tez to token and send to requested address 2', async function () {
      this.timeout(1000000);
      await Test.tezToTokenPayment(dexAddress2,
        initializeExchangeAddress2,
        investLiquidityAddress2,
        divestLiquidityAddress2,
        tezToTokenSwapAddress2,
        tokenToTezSwapAddress2,
        tokenToTokenSwapAddress2,
        tezToTokenPaymentAddress2,
        tokenToTezPaymentAddress2,
        tokenAddress2);
    });
  });

  describe('TokenToTezPayment()', function () {
    it('should exchange tez to token 1', async function () {
      this.timeout(1000000);
      await Test.tokenToTezPayment(dexAddress1,
        initializeExchangeAddress1,
        investLiquidityAddress1,
        divestLiquidityAddress1,
        tezToTokenSwapAddress1,
        tokenToTezSwapAddress1,
        tokenToTokenSwapAddress1,
        tezToTokenPaymentAddress1,
        tokenToTezPaymentAddress1,
        tokenAddress1);
    });
    it('should exchange tez to token 2', async function () {
      this.timeout(1000000);
      await Test.tokenToTezPayment(dexAddress2,
        initializeExchangeAddress2,
        investLiquidityAddress2,
        divestLiquidityAddress2,
        tezToTokenSwapAddress2,
        tokenToTezSwapAddress2,
        tokenToTokenSwapAddress2,
        tezToTokenPaymentAddress2,
        tokenToTezPaymentAddress2,
        tokenAddress2);
    });
  });

  describe('DivestLiquidity()', function () {
    it('should divest liquidity 1', async function () {
      this.timeout(1000000);
      await Test.divestLiquidity(dexAddress1,
        initializeExchangeAddress1,
        investLiquidityAddress1,
        divestLiquidityAddress1,
        tezToTokenSwapAddress1,
        tokenToTezSwapAddress1,
        tokenToTokenSwapAddress1,
        tezToTokenPaymentAddress1,
        tokenToTezPaymentAddress1,
        tokenAddress1);
    });

    it('should divest liquidity 2', async function () {
      this.timeout(1000000);
      await Test.divestLiquidity(dexAddress2,
        initializeExchangeAddress2,
        investLiquidityAddress2,
        divestLiquidityAddress2,
        tezToTokenSwapAddress2,
        tokenToTezSwapAddress2,
        tokenToTokenSwapAddress2,
        tezToTokenPaymentAddress2,
        tokenToTezPaymentAddress2,
        tokenAddress2);
    });
  });
});


// | TokenToTokenSwap of (nat * nat * address)
// | TokenToTokenPayment of (nat * nat * address * address)
// | SetVotesDelegation of (address * bool)
// | Vote of (address * key_hash)
// | Veto of (address)


