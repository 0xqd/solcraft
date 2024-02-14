pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import "./utils/mocks/MockEIP712.sol";

import "./utils/TestPlus.sol";
import "../src/utils/proxy/LibClone.sol";

contract EIP712Test is Test, TestPlus {
    MockEIP712 mockEIP712;

    function setUp() public {
        mockEIP712 = new MockEIP712();
    }

    function testHashTypedData() public {
        string memory name = "nameTest";
        string memory message = "messageTest";

        bytes32 type_hash = keccak256(abi.encode("Message(string name, string message)"));
        bytes32 structHash = keccak256(abi.encode(type_hash, name, message));
        bytes32 expectedDigest =
            keccak256(abi.encodePacked("\x19\x01", mockEIP712.DOMAIN_SEPARATOR(), structHash));

        assertEq(mockEIP712.hashTypedData(structHash), expectedDigest);

        // test recover uint
        (address signer, uint256 privateKey) = _randomSigner();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, expectedDigest);
        address recoveredAddress = ecrecover(expectedDigest, v, r, s);
        assertEq(signer, recoveredAddress);
    }

    function testDomainSeparator() public {
        bytes32 expectedDomainSeparator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("Solcraft")),
                keccak256(bytes("0.1.0")),
                block.chainid,
                address(mockEIP712)
            )
        );

        assertEq(mockEIP712.DOMAIN_SEPARATOR(), expectedDomainSeparator);
    }

    struct _testEIP5267Variables {
        bytes1 fields;
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
        bytes32 salt;
        uint256[] extensions;
    }

    function testEIP5267() public {
        _testEIP5267Variables memory t;
        (t.fields, t.name, t.version, t.chainId, t.verifyingContract, t.salt, t.extensions) =
            mockEIP712.eip712Domain();

        assertEq(t.fields, hex"0f");
        assertEq(t.name, "Solcraft");
        assertEq(t.version, "0.1.0");
        assertEq(t.chainId, block.chainid);
        assertEq(t.verifyingContract, address(mockEIP712));
        assertEq(t.salt, bytes32(0));
        assertEq(t.extensions, new uint256[](0));
    }
}
