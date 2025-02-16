
import {Script, console} from "forge-std/Script.sol";
import {Faucet} from "../src/Faucet.sol";
import {Token} from "../src/Token.sol";

contract AddTokenScript is Script {
    address public faucetAddress;
    address public wethAddress;
    address public usdcAddress;

    function setUp() public {
        faucetAddress = vm.envAddress("FAUCET_ADDRESS");
        wethAddress = vm.envAddress("WETH_ADDRESS");
        usdcAddress = vm.envAddress("USDC_ADDRESS");
    }

    function setFaucetAddress(address _faucetAddress) public {
        faucetAddress = _faucetAddress;
    }

    function setWETHAddress(address _wethAddress) public {
        wethAddress = _wethAddress;
    }

    function setUSDCAddress(address _usdcAddress) public {
        usdcAddress = _usdcAddress;
    }

    function run() public {      
        string memory rpcUrl = vm.envString("RPC_URL");
        string memory privateKey = vm.envString("PRIVATE_KEY");
        
        vm.startBroadcast();

        console.log("Faucet address:", faucetAddress);
        console.log("WETH address:", wethAddress);
        console.log("USDC address:", usdcAddress);

        Faucet faucet = Faucet(faucetAddress);
        Token weth = Token(wethAddress);
        Token usdc = Token(usdcAddress);

        uint256 availableTokensLength = faucet.getAvailableTokensLength();
        console.log("Previous Faucet available tokens length :", availableTokensLength);
        
        faucet.addToken(wethAddress);
        faucet.addToken(usdcAddress);
        
        availableTokensLength = faucet.getAvailableTokensLength();
        console.log("Current Faucet available tokens length :", availableTokensLength);

        weth.mint(faucetAddress, 100e18);
        usdc.mint(faucetAddress, 100e18);

        vm.stopBroadcast();
    }
}