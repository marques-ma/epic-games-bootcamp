const main = async () => {
    const gameContractFactory = await hre.ethers.getContractFactory("MyEpicGame");
    const gameContract = await gameContractFactory.deploy(
      ["Guerreiro", "Arqueira", "Mago"],
          [
              "https://img.freepik.com/vetores-premium/guerreiro-viking-em-estilo-cartoon_96980-246.jpg?w=740",
              "https://elements-cover-images-0.imgix.net/58b4008c-e6e5-4c58-a807-133650ea12d0?auto=compress%2Cformat&fit=max&w=1370&s=4bfc450ef5c321b3ed2b306dda18024f",
              "https://pm1.narvii.com/6902/2a3aa8043d7f52948287410c41572f84649af654r1-250-250v2_hq.jpg",
          ],
      [300+(parseInt(Math.random() * 300)), 200+(parseInt(Math.random() * 200)),    100+(parseInt(Math.random() * 200))], // HP values
      [2*(parseInt(Math.random() * 75)), 2*(parseInt(Math.random() * 50)),      1*(parseInt(Math.random() * 75))], // Attack damage values
      [1*(parseInt(Math.random() * 20)),   2*(parseInt(Math.random() * 35)),      3*(parseInt(Math.random() * 50))], // Attack bonus values
      [3*(parseInt(Math.random() * 35)),   2*(parseInt(Math.random() * 25)),      1*(parseInt(Math.random() * 20))], // defense points values,
      "Red Dragon",
      "https://static.wikia.nocookie.net/forgottenrealms/images/8/84/Monster_Manual_5e_-_Dragon%2C_Red_-_p97.jpg/revision/latest?cb=20200827230918",
      1000+(parseInt(Math.random() * 1000)),
      4*(parseInt(Math.random() * 100))
    );
    await gameContract.deployed();
    console.log("Contrato implantado no endereço:", gameContract.address);

    let txn;
    txn = await gameContract.mintCharacterNFT(0);
    await txn.wait();
    
    txn = await gameContract.attackBoss();
    await txn.wait();
  
    txn = await gameContract.attackBoss();
    await txn.wait();

    // Pega o valor da URI da NFT
    let returnedTokenUri = await gameContract.tokenURI(1);
    console.log("Token URI:", returnedTokenUri);
  };
  
  const runMain = async () => {
    try {
      await main();
      process.exit(0);
    } catch (error) {
      console.log(error);
      process.exit(1);
    }
  };
  
  runMain();