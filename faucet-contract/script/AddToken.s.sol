
import {Script, console} from "forge-std/Script.sol";
import {Faucet} from "../src/Faucet.sol";
import {IDRT} from "../src/IDRT.sol";
import {USDT} from "../src/USDT.sol";

contract AddTokenScript is Script {
    address public faucetAddress;
    address public idrtAddress;
    address public usdtAddress;

    function setUp() public {
        faucetAddress = vm.envAddress("FAUCET_ADDRESS");
        idrtAddress = vm.envAddress("IDRT_ADDRESS");
        usdtAddress = vm.envAddress("USDT_ADDRESS");
    }

    function setFaucetAddress(address _faucetAddress) public {
        faucetAddress = _faucetAddress;
    }

    function setIdrtAddress(address _idrtAddress) public {
        idrtAddress = _idrtAddress;
    }

    function setUsdtAddress(address _usdtAddress) public {
        usdtAddress = _usdtAddress;
    }

    function run() public {      
        string memory rpcUrl = vm.envString("RPC_URL");
        string memory privateKey = vm.envString("PRIVATE_KEY");
        
        vm.startBroadcast();

        console.log("Faucet address:", faucetAddress);
        console.log("IDRT address:", idrtAddress);
        console.log("USDT address:", usdtAddress);

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