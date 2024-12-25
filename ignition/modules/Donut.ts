import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DonutModule = buildModule("Donut", (m) => {

  const IpShareAddr = "0xa73956a5fF1d3D5Ef8eD2df14299a5595a56290a";

  const donut = m.contract("Donut", [IpShareAddr]);

  return { donut };
});

export default DonutModule;

// IPShare#IPShare - 0xa73956a5fF1d3D5Ef8eD2df14299a5595a56290a
// Donut#Donut - 0x509ea6811eF79AAc1F6a8577bdA50a7a9C01064E