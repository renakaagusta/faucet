
import {Script, console} from "forge-std/Script.sol";
import {Faucet} from "../src/Faucet.sol";
import {IDRT} from "../src/IDRT.sol";
import {USDT} from "../src/USDT.sol";

contract AddTokenScript is Script {
    function run() public {      
        string memory rpcUrl = vm.envString("RPC_URL");
        string memory privateKey = vm.envString("PRIVATE_KEY");
        
        vm.createSelectFork(rpcUrl);

        vm.startBroadcast();

        address faucetAddress = vm.envAddress("FAUCET_ADDRESS");
        address idrtAddress = vm.envAddress("IDRT_ADDRESS");
        address usdtAddress = vm.envAddress("USDT_ADDRESS");

        Faucet faucet = Faucet(faucetAddress);
        IDRT idrt = IDRT(idrtAddress);
        USDT usdt = USDT(usdtAddress);

        uint256 availableTokensLength = faucet.getAvailableTokensLength();
        console.log("Previous Faucet available tokens length :", availableTokensLength);
        
        faucet.addToken(idrtAddress);
        faucet.addToken(usdtAddress);
        
        availableTokensLength = faucet.getAvailableTokensLength();
        console.log("Current Faucet available tokens length :", availableTokensLength);

        idrt.mint(faucetAddress, 100e18);
        usdt.mint(faucetAddress, 100e18);

        vm.stopBroadcast();
    }
}