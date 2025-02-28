
import {Script, console} from "forge-std/Script.sol";
import {Faucet} from "../src/Faucet.sol";
import {Token} from "../src/Token.sol";

contract AddTokenScript is Script {
    address public faucetAddress;
    address public wethAddress;
    address public usdcAddress;
    address public pepeAddress;
    address public linkAddress;
    address public wbtcAddress;

    function setUp() public {
        faucetAddress = vm.envAddress("FAUCET_ADDRESS");
        wethAddress = vm.envAddress("WETH_ADDRESS");
        usdcAddress = vm.envAddress("USDC_ADDRESS");
        pepeAddress = vm.envAddress("PEPE_ADDRESS");
        linkAddress = vm.envAddress("LINK_ADDRESS");
        wbtcAddress = vm.envAddress("WBTC_ADDRESS");
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

    function setPEPEAddress(address _pepeAddress) public {
        pepeAddress = _pepeAddress;
    }

    function setLINKAddress(address _linkAddress) public {
        linkAddress = _linkAddress;
    }

    function setWBTCAddress(address _wbtcAddress) public {
        wbtcAddress = _wbtcAddress;
    }

    function run() public {      
        string memory rpcUrl = vm.envString("RPC_URL");
        string memory privateKey = vm.envString("PRIVATE_KEY");
        
        vm.startBroadcast();

        console.log("Faucet address:", faucetAddress);
        console.log("WETH address:", wethAddress);
        console.log("USDC address:", usdcAddress);
        console.log("PEPE address:", pepeAddress);
        console.log("LINK address:", linkAddress);
        console.log("WBTC address:", wbtcAddress);

        Faucet faucet = Faucet(faucetAddress);
        Token weth = Token(wethAddress);
        Token usdc = Token(usdcAddress);
        Token pepe = Token(pepeAddress);
        Token link = Token(linkAddress);
        Token wbtc = Token(wbtcAddress);

        uint256 availableTokensLength = faucet.getAvailableTokensLength();
        console.log("Previous Faucet available tokens length :", availableTokensLength);
        
        faucet.addToken(wethAddress);
        faucet.addToken(usdcAddress);
        faucet.addToken(pepeAddress);
        faucet.addToken(linkAddress);
        faucet.addToken(wbtcAddress);
        
        availableTokensLength = faucet.getAvailableTokensLength();
        console.log("Current Faucet available tokens length :", availableTokensLength);

        weth.mint(faucetAddress, 1000e18);
        usdc.mint(faucetAddress, 1000e18);
        pepe.mint(faucetAddress, 1000e18);
        link.mint(faucetAddress, 1000e18);
        wbtc.mint(faucetAddress, 1000e18);

        vm.stopBroadcast();
    }
}