import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const TokenModule = buildModule("Token", (m) => {

  const token = m.contract("Token");

  return { token };
});

export default TokenModule;

// IPShare#IPShare - 0xa73956a5fF1d3D5Ef8eD2df14299a5595a56290a
// Donut#Donut - 0x509ea6811eF79AAc1F6a8577bdA50a7a9C01064E
// Pump#Pump - 0x9E9457b2b04a8596193424C4AD528706b1DB509f
// Token#Token - 0xcF754b723176F31bf73c406371e61e6dEB1790dF
