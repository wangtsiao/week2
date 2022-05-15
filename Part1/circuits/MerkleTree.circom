pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";

template ComputeNextLevel(n) {
    assert(n>1);
    assert(n&(n-1)==0);

    var m = n>>1;

    signal input levelIn[n];
    signal output levelOut[m];
    
    component pdHash[m];
    signal hash;
    for (var i=0; i<m; i++) {
        pdHash[i] = Poseidon(2);
        pdHash[i].inputs[0] <== levelIn[i<<1];
        pdHash[i].inputs[1] <== levelIn[(i<<1)|1];
        levelOut[i] <== pdHash[i].out;
    }
}


template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;

    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves
    signal value[2**(n)-1];
    component nxtLevel[n+1];
    nxtLevel[n] = ComputeNextLevel(2**n);
    for (var i=0; i<2**n; i++) {
        nxtLevel[n].levelIn[i] <== leaves[i];
    }

    for (var level=n-1; level>0; level--) {
        nxtLevel[level] = ComputeNextLevel(2**level);
        for (var i=0; i<2**level; i++) {
            nxtLevel[level].levelIn[i] <== nxtLevel[level+1].levelOut[i];
        }
    }
    root <== nxtLevel[1].levelOut[0];
}


template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path

    /*
                     14                       Level  2
                 /        \                 
                12        13                  Level  1
              /   \      /   \ 
             8     9    10    11              Level  0
            / \   / \   / \   / \
           O   1 2   3 4   5 6   7            Level -
    */

    signal hash[n+1];
    component pdHash[n];
    hash[0] <== leaf;
    signal val[n][6];
    for (var i=0; i<n; i++) {
        pdHash[i] = Poseidon(2);

        val[i][0] <== 1 - path_index[i];
        val[i][1] <== path_index[i];

        val[i][2] <== hash[i] * val[i][0]; // hash * (1 - index)
        val[i][3] <== hash[i] * val[i][1]; // hash * index
        val[i][4] <== path_elements[i] * val[i][0]; // elem * (1 - index)
        val[i][5] <== path_elements[i] * val[i][1]; // elem * index

        pdHash[i].inputs[ 0 ] <== val[i][2] + val[i][5]; // left  = hash * (1 - index) + elem * index
        pdHash[i].inputs[ 1 ] <== val[i][3] + val[i][4]; // right = hash * index + elem * (1 - index)

        hash[i+1] <== pdHash[i].out;
    }

    root <== hash[n];

}