const { exec } = require("child_process");
const fs = require("fs");
let sharesBurned = 1;
let minTez = 1;
let minTokens = 1;
const { address: dexAddress } = JSON.parse(
  fs.readFileSync("./deployed/Dex.json").toString()
);
const { address: tokenAddress } = JSON.parse(
  fs.readFileSync("./deployed/Token.json").toString()
);
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

exec(
  `ligo compile-parameter ./contracts/Dex.ligo main -s pascaligo "DivestLiquidity(${sharesBurned}n, ${minTez}n, ${minTokens}n)"`,
  async (error, stdout, stderr) => {
    if (error) {
      console.error(`exec error: ${error}`);
      return;
    }

    exec(
      `./babylonnet.sh client -A rpcalpha.tzbeta.net -P 443 -S  transfer 0 from alice to "${dexAddress}" --arg "${stdout.trim()}" --burn-cap 0.5`,
      async (error, stdout, stderr) => {
        console.log(stdout);
        sleep(50000).then(() => {
          exec(
            `node ./scripts/cli.js storage "${dexAddress}"`,
            (error, stdout, stderr) => console.log("DEX: " + stdout)
          );
          exec(
            `node ./scripts/cli.js storage "${tokenAddress}"`,
            (error, stdout, stderr) => console.log("Token: " + stdout)
          );
        });
      }
    );
  }
);
