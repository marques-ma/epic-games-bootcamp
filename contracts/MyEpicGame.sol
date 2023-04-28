// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Contrato NFT para herdar.
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Funcoes de ajuda que o OpenZeppelin providencia.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";

// Helper que escrevemos para codificar em Base64
import "./libraries/Base64.sol";

// Nosso contrato herda do ERC721, que eh o contrato padrao de
// NFT!
contract MyEpicGame is ERC721 {
  // Nos vamos segurar os atributos dos nossos personagens em uma
  //struct. Sinta-se livre para adicionar o que quiser como um
  //atributo! (ex: defesa, chance de critico, etc).
  struct CharacterAttributes {
    uint characterIndex;
    string imageURI;
    string name;

    uint hp;
    uint maxHp;

    uint attackDamage;
    uint attackBonus;
    uint defensePoints;
  }

  
  // O tokenId eh o identificador unico das NFTs, eh um numero
  // que vai incrementando, como 0, 1, 2, 3, etc.

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  // Uma pequena array vai nos ajudar a segurar os dados padrao dos
  // nossos personagens. Isso vai ajudar muito quando mintarmos nossos
  // personagens novos e precisarmos saber o HP, dano de ataque e etc.
  CharacterAttributes[] defaultCharacters;

  struct BigBoss {
  string name;
  string imageURI;
  uint hp;
  uint maxHp;
  uint attackDamage;
  }

  BigBoss public bigBoss;

  // Criamos um mapping do tokenId => atributos das NFTs.
  mapping(uint256 => CharacterAttributes) public nftHolderAttributes;

  // Um mapping de um endereco => tokenId das NFTs, nos da um
  // jeito facil de armazenar o dono da NFT e referenciar ele
  // depois.
  mapping(address => uint256) public nftHolders;

  event CharacterNFTMinted(address sender, uint256 tokenId, uint256 characterIndex);
  event AttackComplete(uint newBossHp, uint newPlayerHp); 

  // Dados passados no contrato quando ele for criado inicialmente,
  // inicializando os personagens.
  // Vamos passar esse valores do run.js
  constructor(
    string[] memory characterNames,
    string[] memory characterImageURIs,
    uint[] memory characterHp,
    uint[] memory characterAttackDmg,
    uint[] memory characterAttackBonus,
    uint[] memory characterdefensePoints,
    string memory bossName,
    string memory bossImageURI,
    uint bossHp,
    uint bossAttackDamage
  )    
  ERC721("Heroes", "HERO")
  {
    // Inicializa o boss. Salva na nossa variável global de estado "bigBoss".
      bigBoss = BigBoss({
        name: bossName,
        imageURI: bossImageURI,
        hp: bossHp,
        maxHp: bossHp,
        attackDamage: bossAttackDamage
      });
      console.log("Boss inicializado com sucesso %s com HP %s, img %s", bigBoss.name, bigBoss.hp, bigBoss.imageURI);

    // Faz um loop por todos os personagens e salva os valores deles no
    // contrato para que possamos usa-los depois para mintar as NFTs
    for(uint i = 0; i < characterNames.length; i += 1) {
      defaultCharacters.push(CharacterAttributes({
        characterIndex: i,
        name:           characterNames[i],
        imageURI:       characterImageURIs[i],
        hp:             characterHp[i],
        maxHp:          characterHp[i],
        attackDamage:   characterAttackDmg[i],
        attackBonus:    characterAttackBonus[i],
        defensePoints:  characterdefensePoints[i]
      }));

      CharacterAttributes memory c = defaultCharacters[i];
      console.log("Personagem inicializado: %s com %s de HP, %s de dano", c.name, c.hp, c.attackDamage);
      console.log("Bonus do personagem: %s de bonus de dano e %s de defense points.", c.attackBonus, c.defensePoints);
    }

    // Eu incrementei tokenIds aqui para que minha primeira NFT tenha o ID 1.
    _tokenIds.increment();
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    CharacterAttributes memory charAttributes = nftHolderAttributes[_tokenId];

    string memory strHp = Strings.toString(charAttributes.hp);
    string memory strMaxHp = Strings.toString(charAttributes.maxHp);
    string memory strAttackDamage = Strings.toString(charAttributes.attackDamage);
    string memory strAttackBonus = Strings.toString(charAttributes.attackBonus);
    string memory strDefensePoints = Strings.toString(charAttributes.defensePoints);

    string memory json = Base64.encode(
      abi.encodePacked(
        '{"name": "',
        charAttributes.name,
        ' -- NFT #: ',
        Strings.toString(_tokenId),
        '", "description": "Legend of the Red Dragon (LORD) on chain", "image": "',
        charAttributes.imageURI,
        '", "attributes": [ { "trait_type": "Health Points", "value": ',strHp,', "max_value":',strMaxHp,'}, { "trait_type": "Attack Damage", "value": ',
        strAttackDamage,'}, { "trait_type": "Attack Bonus", "value": ',
        strAttackBonus,'}, { "trait_type": "Defense Points", "value": ',
        strDefensePoints,'} ]}'
      )
    );

    string memory output = string(
      abi.encodePacked("data:application/json;base64,", json)
    );

    return output;
  }
  
  // Usuarios vao poder usar essa funcao e pegar a NFT baseado no personagem que mandarem!
  function mintCharacterNFT(uint _characterIndex) external {
    // Pega o tokenId atual (começa em 1 já que incrementamos no constructor).
    uint256 newItemId = _tokenIds.current();

    // A funcao magica! Atribui o tokenID para o endereço da carteira de quem chamou o contrato.
    _safeMint(msg.sender, newItemId);

    // Nos mapeamos o tokenId => os atributos dos personagens. Mais disso abaixo

    nftHolderAttributes[newItemId] = CharacterAttributes({
      characterIndex: _characterIndex,
      name: defaultCharacters[_characterIndex].name,
      imageURI: defaultCharacters[_characterIndex].imageURI,
      hp: defaultCharacters[_characterIndex].hp,
      maxHp: defaultCharacters[_characterIndex].maxHp,
      attackDamage: defaultCharacters[_characterIndex].attackDamage,
      attackBonus:    defaultCharacters[_characterIndex].attackBonus,
      defensePoints:  defaultCharacters[_characterIndex].defensePoints
    });

    console.log("Mintou NFT c/ tokenId %s e characterIndex %s", newItemId, _characterIndex);

    // Mantem um jeito facil de ver quem possui a NFT
    nftHolders[msg.sender] = newItemId;

    // Incrementa o tokenId para a proxima pessoa que usar.
    _tokenIds.increment();
    emit CharacterNFTMinted(msg.sender, newItemId, _characterIndex);
  }

  function attackBoss() public {
    // Pega o estado do NFT do jogador
    uint256 nftTokenIdOfPlayer = nftHolders[msg.sender];
    CharacterAttributes storage player = nftHolderAttributes[nftTokenIdOfPlayer];
    console.log("\nJogador com personagem %s ira atacar. Tem %s de HP e %s de Poder de Ataque", player.name, player.hp, player.attackDamage);
    console.log("Boss %s tem %s de HP e %s de PA", bigBoss.name, bigBoss.hp, bigBoss.attackDamage);


    // Tenha certeza que o hp do jogador é maior que 0.
    require (
      player.hp > 0,
      "Error: personagem precisa ter HP para atacar o boss."
    );

    // Tenha certeza que o HP do boss seja maior que 0.
    require (
      bigBoss.hp > 0,
      "Error: boss precisa ter HP para atacar o personagem."
    );

    // Permite que o jogador ataque o boss.
    if (bigBoss.hp < player.attackDamage) {
      bigBoss.hp = 0;
    } else {
      bigBoss.hp = bigBoss.hp - (player.attackDamage + player.attackBonus);
    }

    // Permite que o boss ataque o jogador.
    if (player.hp < bigBoss.attackDamage) {
      player.hp = 0;
    } else {
      player.hp = player.hp - (bigBoss.attackDamage - player.defensePoints);
      console.log("Jogador atacou o boss. Boss ficou com HP: %s", bigBoss.hp);
      console.log("Boss atacou o jogador. Jogador ficou com hp: %s\n", player.hp);
    }
    emit AttackComplete(bigBoss.hp, player.hp);
  }

  function checkIfUserHasNFT() public view returns (CharacterAttributes memory) {
  // Pega o tokenId do personagem NFT do usuario
  uint256 userNftTokenId = nftHolders[msg.sender];
  // Se o usuario tiver um tokenId no map, retorne seu personagem
  if (userNftTokenId > 0) {
      return nftHolderAttributes[userNftTokenId];
    }
  // Senão, retorne um personagem vazio
  else {
      CharacterAttributes memory emptyStruct;
      return emptyStruct;
    }
  }

  function getAllDefaultCharacters() public view returns (CharacterAttributes[] memory) {
    return defaultCharacters;
  }

  function getBigBoss() public view returns (BigBoss memory) {
    return bigBoss;
  }
}
