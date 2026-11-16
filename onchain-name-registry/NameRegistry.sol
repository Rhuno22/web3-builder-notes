// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract NameRegistry {
    uint256 public constant REGISTRATION_FEE = 0.01 ether;

    mapping(string => address) public nameToOwner;
    mapping(string => address) public nameToResolved;
    mapping(address => string) public primaryName;
    mapping(address => string[]) private addressToNames;

    event NameRegistered(string name, address indexed owner, address indexed resolved);
    event ResolvedAddressChanged(string name, address indexed newAddress);
    event NameTransferred(string name, address indexed oldOwner, address indexed newOwner);
    event PrimaryNameSet(address indexed user, string name);

    function registerName(string calldata name, address target) external payable {
        require(bytes(name).length > 0, "Empty name");
        require(nameToOwner[name] == address(0), "Already registered");
        require(msg.value >= REGISTRATION_FEE, "Insufficient fee");
        address resolved = target == address(0) ? msg.sender : target;
        nameToOwner[name] = msg.sender;
        nameToResolved[name] = resolved;
        addressToNames[resolved].push(name);
        if (bytes(primaryName[msg.sender]).length == 0 && resolved == msg.sender) {
            primaryName[msg.sender] = name;
        }
        emit NameRegistered(name, msg.sender, resolved);
    }

    function setResolvedAddress(string calldata name, address newTarget) external {
        require(nameToOwner[name] == msg.sender, "Not owner");
        address oldTarget = nameToResolved[name];
        _removeNameFromAddress(oldTarget, name);
        nameToResolved[name] = newTarget;
        addressToNames[newTarget].push(name);
        emit ResolvedAddressChanged(name, newTarget);
    }

    function transferName(string calldata name, address newOwner) external {
        require(nameToOwner[name] == msg.sender, "Not owner");
        require(newOwner != address(0), "Invalid owner");
        nameToOwner[name] = newOwner;
        emit NameTransferred(name, msg.sender, newOwner);
    }

    function setPrimaryName(string calldata name) external {
        require(nameToResolved[name] == msg.sender, "Name does not resolve to sender");
        primaryName[msg.sender] = name;
        emit PrimaryNameSet(msg.sender, name);
    }

    function reverseResolve(address addr) external view returns (string memory) {
        return primaryName[addr];
    }

    function getNamesForAddress(address addr) external view returns (string[] memory) {
        return addressToNames[addr];
    }

    function _removeNameFromAddress(address addr, string memory name) internal {
        string[] storage names = addressToNames[addr];
        bytes32 targetHash = keccak256(bytes(name));
        for (uint256 i = 0; i < names.length; i++) {
            if (keccak256(bytes(names[i])) == targetHash) {
                names[i] = names[names.length - 1];
                names.pop();
                break;
            }
        }
    }
}
