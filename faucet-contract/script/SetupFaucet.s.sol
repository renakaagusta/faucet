
import {Script, console} from "forge-std/Script.sol";
import {Faucet} from "../src/Faucet.sol";

contract SetupScript is Script {
    function run() public {      
        string memory rpcUrl = vm.envString("RPC_URL");
        string memory privateKey = vm.envString("PRIVATE_KEY");
        
        vm.createSelectFork(rpcUrl);

        vm.startBroadcast();

        address faucetAddress = vm.envAddress("FAUCET_ADDRESS");

        Faucet faucet = Faucet(faucetAddress);

        uint256 faucetAmount = faucet.faucetAmount();
        uint256 faucetCooldown = faucet.faucetCooldown();
        
        console.log("Previous Faucet Amount :", faucetAmount);
        console.log("Previous Faucet Cooldown :", faucetCooldown);
        
        faucet.updateFaucetAmount(1e12);
        faucet.updateFaucetCooldown(1);
        
        faucetAmount = faucet.faucetAmount();
        faucetCooldown = faucet.faucetCooldown();
        console.log("Current Faucet Amount :", faucetAmount);
        console.log("Current Faucet Cooldown :", faucetCooldown);

        vm.stopBroadcast();
    }
}