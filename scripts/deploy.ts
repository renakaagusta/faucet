import hre, { network } from "hardhat";
import fs from "fs";

// Colour codes for terminal prints
const RESET = "\x1b[0m";
const GREEN = "\x1b[32m";
async function main() {
  try {
    const knjConstructorArgs = ["Koentji", "KNJ"];
    const knjContract = await hre.ethers.deployContract("Koentji");

    await knjContract.waitForDeployment();
    const knjContractAddress = await knjContract.getAddress();

    const faucetConstructorArgs = [knjContractAddress];
    const faucetContract = await hre.ethers.deployContract("Faucet", faucetConstructorArgs);

    await faucetContract.waitForDeployment();
    const faucetContractAddress = await faucetContract.getAddress();

    const tx = await knjContract.setFaucet(faucetContractAddress);
    await tx.wait();

    console.log("Koentji deployed to: " + `${knjContractAddress}\n`);
    console.log("Faucet deployed to: " + `${faucetContractAddress}\n`);

    if(network.name !== 'localhost') {
      await hre.run("verify:verify", {
        address: knjContract,
        constructorArguments: knjConstructorArgs,
      });
    }

    // Read existing deployments
    const deploymentsFile = 'deployments.json';
    let deployments: Record<string, Record<string, string>> = {};

    if (fs.existsSync(deploymentsFile)) {
      deployments = JSON.parse(fs.readFileSync(deploymentsFile, 'utf8')) as unknown as Record<string, Record<string, string>>;
    }

    // Update deployments with the new contract
    deployments["Koentji"]= deployments["Koentji"] != null ? {
      ...deployments["Koentji"],
      [new Date().toISOString()]: knjContractAddress
    } : {
      [new Date().toISOString()]: knjContractAddress
    };
    
    // Update deployments with the new contract
    deployments["Faucet"]= deployments["Faucet"] != null ? {
      ...deployments["Faucet"],
      [new Date().toISOString()]: faucetContractAddress
    } : {
      [new Date().toISOString()]: faucetContractAddress
    };

    // Write back to the file
    fs.writeFileSync(deploymentsFile, JSON.stringify(deployments, null, 2));

    console.log(`Deployment information saved to ${deploymentsFile}`);

    // Uncomment if you want to enable the `tenderly` extension
    await hre.tenderly.verify({
      name: "Koentji",
      address: knjContractAddress,
    });
    await hre.tenderly.verify({
      name: "Faucet",
      address: faucetContractAddress,
    });
  } catch(e) {
    console.log('error', (e as unknown as Error).toString());
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
