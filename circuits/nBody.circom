pragma circom 2.1.4;

include "limiter.circom";
include "calculateForce.circom";

// TODO:
// √ confirm why circom interprets negative input differently than p-n (https://github.com/0xPARC/zkrepl/issues/11)
// √ go through and make sure approximate square root is working ok
// √ go through and make sure that decimals of 10^8 are properly accounted for in exponential equations
// √ change js implementation to use square root approx function
// analyze risk here: initial thought is that valid proofs can be generated for slight variations of position. seems acceptable.
// make change input array variable of n
// make change in body variable of n
  // make sure max n is used to bound the number of bits
// generate and test prover for step of 1
// configure as recursive proof, generate and test prover for step of n
// TODO: define "types" for all the values and make sure they're within the acceptable ranges attached to those types.
// This will help us restrict bits needed for each type
// maybe can streamline the square root and division

// TODO: use inverse square root instead of division

// template calculateBodies(n) {
//     signal input bodies[n][5];
//     signal output new_bodies[n][5];

//     for (var i = 0; i < n; i++) {
//       for (var j  = i+1; j < n; j++)
//         // radius of body doesn't change
//         new_bodies[i][4] <== bodies[i][4];
//     }
// }

template Main() {
    signal input bodies[3][5];
    signal output new_bodies[3][5];
    // [0] = position_x using 10^8 decimals
    // [1] = position_y using 10^8 decimals
    // [2] = vector_x using 10^8 decimals
    // [3] = vector_y using 10^8 decimals
    // [4] = radius using 10^8 decimals

    var maxVector = 1000000000; // using 10^8 decimals
    var windowWidth = 100000000000; // using 10^8 decimals

    // radius of body doesn't change
    new_bodies[0][4] <== bodies[0][4];
    new_bodies[1][4] <== bodies[1][4];
    new_bodies[2][4] <== bodies[2][4];

// Calculate change in body 0 wrt body 1 and body 2
    component calculateForceComponent1 = CalculateForce();
    calculateForceComponent1.in_bodies[0] <== bodies[0];
    calculateForceComponent1.in_bodies[1] <== bodies[1];
    signal body0_1_v_x <== calculateForceComponent1.out_forces[0];
    signal body0_1_v_y <== calculateForceComponent1.out_forces[1];

    component calculateForceComponent2 = CalculateForce();
    calculateForceComponent2.in_bodies[0] <== bodies[0];
    calculateForceComponent2.in_bodies[1] <== bodies[2];
    signal body0_2_v_x <== calculateForceComponent2.out_forces[0];
    signal body0_2_v_y <== calculateForceComponent2.out_forces[1];
    
    signal body0_new_v_x <== bodies[0][2] + body0_1_v_x + body0_2_v_x;
    signal body0_new_v_y <== bodies[0][3] + body0_1_v_y + body0_2_v_y;

    // TODO: need to square the vector before comparing it to the maxVector squared in order to remove the sign

    // need to limit vectors
    component vectorLimiterX = Limiter(252); // TODO: confirm bits limit
    vectorLimiterX.in <== body0_new_v_x;
    vectorLimiterX.limit <== maxVector; // speedLimit
    vectorLimiterX.rather <== maxVector;
    new_bodies[0][2] <== vectorLimiterX.out;

    component vectorLimiterY = Limiter(252); // TODO: confirm bits limit
    vectorLimiterY.in <== body0_new_v_y;
    vectorLimiterY.limit <== maxVector; // speedLimit
    vectorLimiterY.rather <== maxVector;
    new_bodies[0][3] <== vectorLimiterY.out;


    // need to limit position so plane loops off edges
    component positionLimiterX = Limiter(37); // NOTE: position is limited to maxWidth + (2*maxVector) which should be under 37 bits
    // positionLimiter.x <== bodies[0][0] + vectorLimiter.limitedX;
    positionLimiterX.in <== bodies[0][0] + vectorLimiterX.out + maxVector; // NOTE: adding maxVector ensures it is never negative
    positionLimiterX.limit <== windowWidth + maxVector; // windowWidth
    positionLimiterX.rather <== maxVector;
    

    // NOTE: maxVector is still included, needs to be removed at end of calculation
    component positionLowerLimiterX = LowerLimiter(37); // NOTE: position is limited to maxWidth + (2*maxVector) which should be under 37 bits
    positionLowerLimiterX.in <== positionLimiterX.out;
    positionLowerLimiterX.limit <== maxVector;
    positionLowerLimiterX.rather <== windowWidth + maxVector;
    new_bodies[0][0] <== positionLowerLimiterX.out - maxVector;


    component positionLimiterY = Limiter(37);  // NOTE: position is limited to maxWidth + (2*maxVector) which should be under 37 bits
    positionLimiterY.in <== bodies[0][1] + vectorLimiterY.out + maxVector; // NOTE: adding maxVector ensures it is never negative
    positionLimiterY.limit <== windowWidth + maxVector; // windowWidth
    positionLimiterY.rather <== maxVector;

    // NOTE: maxVector is still included, needs to be removed at end of calculation
    component positionLowerLimiterY = LowerLimiter(37); // NOTE: position is limited to maxWidth + (2*maxVector) which should be under 37 bits
    positionLowerLimiterY.in <== positionLimiterY.out;
    positionLowerLimiterY.limit <== maxVector;
    positionLowerLimiterY.rather <== windowWidth + maxVector;
    new_bodies[0][1] <== positionLowerLimiterY.out - maxVector;


// Calculate change in body 1 wrt body 2
    component calculateForceComponent3 = CalculateForce();
    calculateForceComponent3.in_bodies[0] <== bodies[1];
    calculateForceComponent3.in_bodies[1] <== bodies[2];
    signal body1_2_v_x <== calculateForceComponent3.out_forces[0];
    signal body1_2_v_y <== calculateForceComponent3.out_forces[1];
    
    signal body1_new_v_x <== bodies[1][2] + body0_1_v_x + body1_2_v_x;
    signal body1_new_v_y <== bodies[1][3] + body0_1_v_y + body1_2_v_y;

    // need to limit vector
    component vectorLimiter2X = Limiter(252); // TODO: confirm bits limit
    vectorLimiter2X.in <== body1_new_v_x;
    vectorLimiter2X.limit <== maxVector; // speedLimit
    vectorLimiter2X.rather <== maxVector;
    new_bodies[1][2] <== vectorLimiter2X.out;
    
    component vectorLimiter2Y = Limiter(252); // TODO: confirm bits limit
    vectorLimiter2Y.in <== body1_new_v_y;
    vectorLimiter2Y.limit <== maxVector; // speedLimit
    vectorLimiter2Y.rather <== maxVector;
    new_bodies[1][3] <== vectorLimiter2Y.out;

    component positionLimiter2X = Limiter(252); // TODO: confirm bits limit
    positionLimiter2X.in <== bodies[1][0] + vectorLimiter2X.out + maxVector; // NOTE: adding maxVector ensures it is never negative
    positionLimiter2X.limit <== windowWidth + maxVector; // windowWidth
    positionLimiter2X.rather <== maxVector;

    // NOTE: maxVector is still included, needs to be removed at end of calculation
    component positionLowerLimiter2X = LowerLimiter(37); // NOTE: position is limited to maxWidth + (2*maxVector) which should be under 37 bits
    positionLowerLimiter2X.in <== positionLimiter2X.out;
    positionLowerLimiter2X.limit <== maxVector;
    positionLowerLimiter2X.rather <== windowWidth + maxVector;
    new_bodies[1][0] <== positionLowerLimiter2X.out - maxVector;

    component positionLimiter2Y = Limiter(252); // TODO: confirm bits limit
    positionLimiter2Y.in <== bodies[1][1] + vectorLimiter2Y.out;
    positionLimiter2Y.limit <== windowWidth; // windowWidth
    positionLimiter2Y.rather <== 0;
    new_bodies[1][1] <== positionLimiter2Y.out;

    component positionLowerLimiter2Y = LowerLimiter(37); // NOTE: position is limited to maxWidth + (2*maxVector) which should be under 37 bits
    positionLowerLimiter2Y.in <== positionLimiter2Y.out;
    positionLowerLimiter2Y.limit <== maxVector;
    positionLowerLimiter2Y.rather <== windowWidth + maxVector;


// Calculate change in body 2
    signal body2_new_v_x <== bodies[2][2] + body0_2_v_x + body1_2_v_x;
    signal body2_new_v_y <== bodies[2][3] + body0_2_v_y + body1_2_v_y;

    // need to limit magnitude
    component vectorLimiter3X = Limiter(252); // TODO: confirm bits limit
    vectorLimiter3X.in <== body2_new_v_x;
    vectorLimiter3X.limit <== maxVector; // speedLimit
    vectorLimiter3X.rather <== maxVector;
    new_bodies[2][2] <== vectorLimiter3X.out;

    component vectorLimiter3Y = Limiter(252); // TODO: confirm bits limit
    vectorLimiter3Y.in <== body2_new_v_y;
    vectorLimiter3Y.limit <== maxVector; // speedLimit
    vectorLimiter3Y.rather <== maxVector;
    new_bodies[2][3] <== vectorLimiter3Y.out;

    // TODO: positionLimiter3 only checks over 1000, needs to check under 0 too

    component positionLimiter3X = Limiter(252); // TODO: confirm bits limit
    positionLimiter3X.in <== bodies[2][0] + vectorLimiter3x.out;
    positionLimiter3X.limit <== windowWidth; // windowWidth
    positionLimiter3X.rather <== 0;
    new_bodies[2][0] <== positionLimiter3X.out;

    component positionLimiter3Y = Limiter(252); // TODO: confirm bits limit
    positionLimiter3Y.in <== bodies[2][1] + vectorLimiter3Y.out;
    positionLimiter3Y.limit <== windowWidth; // windowWidth
    positionLimiter3Y.rather <== 0;
    new_bodies[2][1] <== positionLimiter3Y.out;
}



component main { public [ bodies ]} = Main();

/* INPUT = {
    "bodies": [ ["22600000000", "4200000000", "-133000000", "-629000000", "10000000000"], ["36300000000", "65800000000", "-332000000", "374000000", "7500000000"], ["67900000000", "50000000000", "229000000", "252000000", "5000000000"] ]
} */