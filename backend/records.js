const fs = require('fs');

function save(data) {
  return new Promise((resolve, reject) => {
    fs.writeFile('data.json', JSON.stringify(data, null, 2), (err) => {
      if (err) {
        reject(err);
      } else {
        resolve();
      }
    });
  });
}

/**
 * Gets all the data
 * @param None
 */
function getData(){
  return new Promise((resolve, reject) => {
    fs.readFile('data.json', 'utf8', (err, data) => {
      if (err) {
        reject(err);
      } else {
        const json = JSON.parse(data);
        resolve(json);
      }
    });
  });
}

/**
 * Gets the trade
 * @param None
 */
async function getTrade(){
  const data = await getData();
  return data.trade;
}

/**
 * Gets currencies
 * @param None
 */
async function getCurrencies(){
  const data = await getData();
  return data.currencies;
}

/**
 * Gets accounts
 * @param None
 */
async function getAccounts(){
  const data = await getData();
  return data.accounts;
}


/**
 * Creates a new trade instruction
 * @param {Object} newTrade - Object containing info for new trade
 */
async function createTrade(newRecord) {
  const data = await getData();
  data.trade = newRecord
  await save(data);
  return newRecord;
}

/**
 * Updates trade status
 * @param {String} newStatus - A string of the new status to be set
 */
async function updateTradeStatus(newStatus){
  const data = await getData();
  data.trade.status = newStatus;
  await save(data);
  return data.trade
}

/**
 * Deletes previous trade data
 * @param None
 */
async function deletePrevTrade(){
  const data = await getData();
  data.trade = {};
  await save(data);
}

module.exports = {
  getData,
  getTrade,
  getCurrencies,
  getAccounts,
  createTrade,
  updateTradeStatus,
  deletePrevTrade
}
