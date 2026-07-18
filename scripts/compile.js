// Compile WatchedMovies.sol and print the CREATE2 deploy payload.
// Run in Bankr sandbox: packages = ["solc@0.8.28", "@openzeppelin/contracts@5.1.0", "viem@2.21.0"]
// Usage: bun scripts/compile.js <ownerAddress>
const solc = require('solc');
const fs = require('fs');
const path = require('path');
const { encodeAbiParameters, keccak256, toHex, getContractAddress, concat } = require('viem');

const owner = process.argv[2];
if (!owner || !/^0x[0-9a-fA-F]{40}$/.test(owner)) {
  console.error('usage: bun scripts/compile.js <ownerAddress>');
  process.exit(1);
}

const input = {
  language: 'Solidity',
  sources: { 'WatchedMovies.sol': { content: fs.readFileSync('contracts/WatchedMovies.sol', 'utf8') } },
  settings: {
    optimizer: { enabled: true, runs: 200 },
    outputSelection: { '*': { '*': ['abi', 'evm.bytecode.object'] } },
  },
};

function findImports(p) {
  try { return { contents: fs.readFileSync(path.join('node_modules', p), 'utf8') }; }
  catch (e) { return { error: 'not found: ' + p }; }
}

const out = JSON.parse(solc.compile(JSON.stringify(input), { import: findImports }));
const fatal = (out.errors || []).filter((e) => e.severity === 'error');
if (fatal.length) { console.error(JSON.stringify(fatal, null, 2)); process.exit(1); }

const c = out.contracts['WatchedMovies.sol']['WatchedMovies'];
const bytecode = '0x' + c.evm.bytecode.object;
const ctorArgs = encodeAbiParameters([{ type: 'address' }], [owner]);
const initcode = concat([bytecode, ctorArgs]);
const salt = keccak256(toHex('watched-movies-v1-' + owner.toLowerCase()));
const deployer = '0x4e59b44847b379578588920cA78FbF26c0B4956C';
const predicted = getContractAddress({ from: deployer, opcode: 'CREATE2', salt, bytecode: initcode });
const payload = concat([salt, initcode]);

console.log('PREDICTED_ADDRESS', predicted);
console.log('SALT', salt);
console.log('PAYLOAD_START');
console.log(payload);
console.log('PAYLOAD_END');
