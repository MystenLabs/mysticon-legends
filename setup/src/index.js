
// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

const { SuiClient } = require("@mysten/sui.js/client");
const { TransactionBlock } = require("@mysten/sui.js/transactions");
const { Ed25519Keypair } = require("@mysten/sui.js/keypairs/ed25519");

require("dotenv").config();
var fs = require("fs");

console.log("Connecting to ", process.env.SUI_NETWORK);

const getClient = () => {
  let suiNetwork = process.env.SUI_NETWORK;

  const client = new SuiClient({ url: suiNetwork });

  return client;
};

const getSigner = () => {
  const keypair = Ed25519Keypair.deriveKeypair(process.env.ADMIN_PHRASE);

  return keypair;
};

const signer = getSigner();
const client = getClient();
async function addDisplayFields() {
    let mysticonDisplayFields = getMysticonDisplayFields();
  
    let tx = new TransactionBlock();
  
    let mysticonDisplay = tx.moveCall({
      target: "0x2::display::new_with_fields",
      arguments: [
        tx.object(process.env.PUBLISHER_ID),
        tx.pure(mysticonDisplayFields.keys),
        tx.pure(mysticonDisplayFields.values),
      ],
      typeArguments: [`${process.env.PACKAGE_ID}::mysticons::Mysticon`],
    });
  
    tx.moveCall({
      target: "0x2::display::update_version",
      arguments: [mysticonDisplay],
      typeArguments: [`${process.env.PACKAGE_ID}::mysticons::Mysticon`],
    });
  
    tx.transferObjects(
      [mysticonDisplay],
      tx.pure(process.env.ADMIN_ADDRESS)
    );
    tx.setGasBudget(2000000000);
    try {
      let txRes = await client.signAndExecuteTransactionBlock({
        transactionBlock: tx,
        requestType: "WaitForLocalExecution",
        signer,
        options: {
          showEffects: true,
        },
      });
  
      console.log("display", txRes?.effects?.created?.[0]?.reference?.objectId);
      console.log("effects", txRes.effects.status.status, txRes.effects);
    } catch (e) {
      console.error("Could not create display", e);
    }
  }

  // This is the function you can update to change the display fields
function getMysticonDisplayFields(
    imageProviderUrlPrefix = "https://raw.githubusercontent.com/MystenLabs/mysticon-legends/main/assets/",
    imageProviderUrlPostfix = ".png"
  ) {
    return {
      keys: [
        "name",
        "type",
        "power_level",
        "special_ability",
        "training_status",
        "image_url",
        "description",
        "project_url",
        "creator",
      ],
      values: [
        "{name}",
        "{type}",
        "{power_level}",
        "{special_ability}",
        "training_status",
        `${imageProviderUrlPrefix}{image_url}${imageProviderUrlPostfix}`,
        "An engaging blockchain based game where players collect, train, and battle with mythical creatures.",
        "https://github.com/MystenLabs/mysticon-legends",
        "Play Beyond Summit",
      ],
    };
  }

  const mintMysticon = async () => {
    let tx = new TransactionBlock();
  
    let mysticon = tx.moveCall({
      target: `${process.env.PACKAGE_ID}::mysticons::new_mysticon`,
      arguments: [
        tx.object(process.env.ADMIN_CAP_ID),
        tx.pure("Frostwing"),
        tx.pure("Ice"),
        tx.pure(10),
        tx.pure("Ice Storm"),
        tx.pure("frost"),
      ],
    });
  
    tx.transferObjects([mysticon], tx.pure(process.env.ADMIN_ADDRESS));
  
    try {
      let txRes = await client.signAndExecuteTransactionBlock({
        transactionBlock: tx,
        requestType: "WaitForLocalExecution",
        signer,
        options: {
          showEffects: true,
        },
      });
  
      console.log("Minted Mysticon: ", txRes.effects.created?.[0]?.reference?.objectId);
    } catch (e) {
      console.error("Could not mint Mysticon", e);
    }
  };

  const updateMysticonPowerLevel = async (mysticon, power_level) => {
    let tx = new TransactionBlock();
  
    tx.moveCall({
      target: `${process.env.PACKAGE_ID}::mysticons::train_mysticon`,
      arguments: [
        tx.object(mysticon),
        tx.pure(power_level),
      ],
    });
  
    try {
      let txRes = await client.signAndExecuteTransactionBlock({
        transactionBlock: tx,
        requestType: "WaitForLocalExecution",
        signer,
        options: {
          showEffects: true,
        },
      });
  
      console.log("Trained mysticon", mysticon, power_level);
    } catch (e) {
      console.error("Could not train your mysticon", e);
    }
  };

  const lockMysticon = async (mysticon) => {
    let tx = new TransactionBlock();
  
    tx.moveCall({
      target: `${process.env.PACKAGE_ID}::mysticons::lock_mysticon`,
      arguments: [tx.object(mysticon)],
    });
  
    try {
      let txRes = await client.signAndExecuteTransactionBlock({
        transactionBlock: tx,
        requestType: "WaitForLocalExecution",
        signer,
        options: {
          showEffects: true,
        },
      });
  
      console.log(`Mysticon ${mysticon} locked`);
    } catch (e) {
      console.error("Could not lock mysticon", e);
    }
  };

  const attachCreature = async (mysticon) => {
    let tx = new TransactionBlock();
  
    let invoice = tx.moveCall({
      target: `${process.env.PACKAGE_ID}::mysticons::attach_creature`,
      arguments: [
        tx.object(mysticon),
        tx.pure("Frostbite"),
        tx.pure("A playful yet fiercely loyal arctic fox spirit that radiates a chilling aura"),
      ],
    });
    
    tx.moveCall({
      target: `${process.env.PACKAGE_ID}::mysticons::pay_invoice`,
      arguments: [
        tx.object(mysticon),
        tx.object(invoice),
      ],
    });
    tx.setGasBudget(2000000000);
    try {
      let txRes = await client.signAndExecuteTransactionBlock({
        transactionBlock: tx,
        requestType: "WaitForLocalExecution",
        signer,
        options: {
          showEffects: true,
        },
      });
  
      console.log("Minted Mysticon: ", txRes.effects);
    } catch (e) {
      console.error("Could not mint Mysticon", e);
    }
  };


  const burnMysticon = async (mysticon) => {
    let tx = new TransactionBlock();
  
    tx.moveCall({
      target: `${process.env.PACKAGE_ID}::mysticons::destroy_mysticon`,
      arguments: [tx.object(mysticon)],
    });

    tx.setGasBudget(2000000000);
    
    try {
      let txRes = await client.signAndExecuteTransactionBlock({
        transactionBlock: tx,
        requestType: "WaitForLocalExecution",
        signer,
        options: {
          showEffects: true,
        },
      });
  
      console.log("Burn Mysticon", mysticon);
    } catch (e) {
      console.error("Could not burn mysticon", e);
    }
  };

// Script Intialization code.
if (process.argv[2] === undefined) {
    addDisplayFields();
  } else {
    const command = process.argv[2];
    switch (command) {
        case "mintMysticon":
          mintMysticon();
          break;
        case "updateMysticonPowerLevel": 
          updateMysticonPowerLevel("",100);
          break;
          case "attachCreature": 
          attachCreature("");
          break;
        case "lockMysticon": 
          lockMysticon("");
          break;
        case "burnMysticon":
          burnMysticon("");
          break;
      }
    }
  