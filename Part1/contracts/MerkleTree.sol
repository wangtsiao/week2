//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { PoseidonT3 } from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract

contract MerkleTree is Verifier {
    uint256[] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root

    // Add some attributes
    uint8 internal constant DEPTH = 3;

    uint256[DEPTH] internal zeros;

    constructor() {
        // [assignment] initialize a Merkle tree of 8 with blank leaves
        

        // all cell initialize to _zeroValue.
        uint256 _zeroValue = 0;
        for (uint8 i=0; i<15; i++) {
            hashes.push(_zeroValue);
        }
        zeros[0] = _zeroValue;
        

        /*
                       14                       Level 3
                   /        \                 
                  12        13                  Level 2
                /   \      /   \ 
               8     9    10    11              Level 1
              / \   / \   / \   / \
             O   1 2   3 4   5 6   7            Level 0
        */


        // `hashes[ 16-(1<<(4-i))+j ]` indicates j'th cell in i'th level.
        
        uint256 hashedValue = 0;
        uint256 left = 0;
        uint256 right = 0;
        for (uint8 i=1; i<=DEPTH; i++) {
            for (uint8 j=0; j<(1<<(DEPTH-i)); j++) {
                left = hashes[ 16-(1<<(4-(i-1)))+(j<<1) ];
                right = hashes[ 16-(1<<(4-(i-1)))+((j<<1)|1) ];
                hashedValue = PoseidonT3.poseidon([left, right]);
                hashes[ 16-(1<<(4-i))+j ] = hashedValue;
            }
            if(i != DEPTH) {
                zeros[i] = hashes[ 16-(1<<(4-i)) ];
            }
        }

        root = hashes[ 16-(1<<(4-3))+0 ];

    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        // [assignment] insert a hashed leaf into the Merkle tree
        uint256 currentIndex = index;
        require(currentIndex < 8, "IncrementalMerkleTree: tree is full");
        index += 1;
        
        hashes[currentIndex] = hashedLeaf;

        uint256 hashedValue = 0;
        uint256 left = 0;
        uint256 right = 0;

        for (uint8 i=1; i<=DEPTH; i++) {

            if (currentIndex % 2 == 0) {
                // current node at left
                left = hashes[ 16-(1<<(4-(i-1)))+currentIndex ];
                right = zeros[ i-1 ];
                hashedValue = PoseidonT3.poseidon([left, right]);
                
                hashes[ 16-(1<<(4-i))+(currentIndex>>1) ] = hashedValue;
            } else {
                // current node at right
                left = hashes[ 16-(1<<(4-(i-1)))+currentIndex-1 ];
                right = hashes[ 16-(1<<(4-(i-1)))+currentIndex ];
                hashedValue = PoseidonT3.poseidon([left, right]);
                
                hashes[ 16-(1<<(4-i))+(currentIndex>>1) ] = hashedValue;
            }
            
            currentIndex >>= 1;
        }

        root = hashes[ 16-(1<<(4-3))+0 ];
        return currentIndex;

    }

    function verify(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[1] memory input
        ) public view returns (bool) {

        // [assignment] verify an inclusion proof and check that the proof root matches current root
        return verifyProof(a, b, c, input) && input[0] == root;
    }
}
