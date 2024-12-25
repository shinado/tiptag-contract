import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import "@nomicfoundation/hardhat-ignition-ethers";

const IPShareModule = buildModule("IPShare", (m) => {

  const share = m.contract("IPShare");

  return { share };
});

export default IPShareModule;

// IPShare#IPShare - 0xa73956a5fF1d3D5Ef8eD2df14299a5595a56290a