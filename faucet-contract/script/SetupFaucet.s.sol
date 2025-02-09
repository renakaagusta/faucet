
import {Script, console} from "forge-std/Script.sol";
import {Faucet} from "../src/Faucet.sol";

contract SetupFaucetScript is Script {
    address public faucetAddress;

    function setUp() public {
        faucetAddress = vm.envAddress("FAUCET_ADDRESS");
    }

    function setFaucetAddress(address _faucetAddress) public {
        faucetAddress = _faucetAddress;
    }

    function run() public {      
        vm.startBroadcast();

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