async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  let facAddress = ""; // First deploy factory contract then enter the factory address here.

  const Router = await ethers.getContractFactory("PhantasySwapRouterV01");
  const router = await Router.deploy(facAddress);

  await router.deployed();

  console.log("Router deployed to:", router.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
