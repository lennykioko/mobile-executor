var express = require('express');
var router = express.Router();

const records = require('./records');

function asyncHandler(cb){
    return async (req, res, next) => {
        try {
            await cb(req, res, next);
        } catch(err) {
            next(err);
        }
    }
}

// GET most recent trade
router.get('/trade', asyncHandler(async (req, res) => {
    const trade = await records.getTrade();
    res.json(trade);
}));

// DELETE most recent trade
router.delete('/trade', asyncHandler(async (req, res) => {
  let trade = await records.getTrade();

  if(trade.length > 1){
    trade = await records.deletePrevTrade();
    res.json({message: "Previous trade deleted succesfullly"});
  } else {
    res.json({message: "Previous trade already deleted"});
  }
}));

// GET currencies
router.get('/currencies', asyncHandler(async (req, res) => {
    const currencies = await records.getCurrencies();
    res.json(currencies);
}));

// GET accounts
router.get('/accounts', asyncHandler(async (req, res) => {
    const accounts = await records.getAccounts();
    res.json(accounts);
}));

// POST trade info from UI
router.post('/trade', asyncHandler(async (req, res) => {
    const info = await req.body.trade;
    const prevTrade = await records.getTrade();

    if(info.symbol != prevTrade.symbol && info.slPrice != prevTrade.slPrice){
      records.deletePrevTrade();
      let trade = await records.createTrade(info);
      trade = await records.updateTradeStatus("Received from UI");
      res.json(trade);
    } else {
      res.json({message: "Trade already exists"});
    }
}));

// READ from mql4
router.get('/mql4', asyncHandler(async (req, res) => {
  let trade = await records.getTrade();

  if(trade && trade.status != "Read by MQL4"){
    await records.updateTradeStatus("Read by MQL4");
    res.json(trade);
  } else if(trade.status == "Read by MQL4"){
    res.json({message: "Trade already read by MQL4"})
  } else if(!trade){
    res.json({message: "Trade is empty"})
  }
}));

// Check success from mql4
router.get('/mql4/:tradeID', asyncHandler(async (req, res) => {
  let trade = await records.getTrade();
  let tradeID = parseInt(req.params.tradeID);

  if(tradeID > 0){
    await records.updateTradeStatus("Executed Successfully");
    res.json(trade);
  } else {
    await records.updateTradeStatus("Execution Failed");
    res.json({message: "Trade execution failed"})
  }
}));

module.exports = router;
