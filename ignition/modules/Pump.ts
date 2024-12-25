import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const PumpModule = buildModule("Pump", (m) => {

  const IpShareAddr = "0xa73956a5fF1d3D5Ef8eD2df14299a5595a56290a";
  const feeAddr = "0xDCFd42aCD7b56CC9Cc6B083e5E85E5022322C3C0";

  const pump = m.contract("Pump", [IpShareAddr, feeAddr]);

  return { pump };
});

export default PumpModule;

// IPShare#IPShare - 0xa73956a5fF1d3D5Ef8eD2df14299a5595a56290a
// Donut#Donut - 0x509ea6811eF79AAc1F6a8577bdA50a7a9C01064E
// Pump#Pump - 0x9E9457b2b04a8596193424C4AD528706b1DB509f
