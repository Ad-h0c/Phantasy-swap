async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const Elixir = await ethers.getContractFactory("Elixir");
  const elixir = await Elixir.deploy();

  await elixir.deployed();

  console.log("elixir deployed to:", elixir.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
