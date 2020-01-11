const express 			       	= require('express')
const fs                    = require('fs'); // this engine requires the fs module
const app 			         		= express()
var ip                      = require("ip");
const os                    = require('os')
var exec = require("child_process").exec;


const port                  = process.env.PORT || 3000;

var bodyParser              = require('body-parser');



class Controller {
  constructor(id) {
    this.id = id
    this.isConnected = false
  }

}

const CONTROLLERS = [
  new Controller(1),
  new Controller(2),
  new Controller(3),
  new Controller(4)
]



// Set View Engine
app.set('view engine', 'ejs') // register the template engine
app.set('views', './views') // specify the views directory
app.use(bodyParser.urlencoded({extended: true}))
app.use(bodyParser.json())
app.use(express.static(__dirname + '/views'));


app.get('/controller', function (req, res) {
  res.status(200).send("Use this endpoint to set up your controllers")
})

app.get('/controller/connect', (req, res) => {
  var availableIDs = []
  for (c of CONTROLLERS) {
    if (!c.isConnected) {
      availableIDs.push(c.id)
    }
  }

  res.status(200).json(availableIDs)

})
app.post('/controller/connect', (req, res) => {
  const requestedIdx = req.body.player_idx

  if (!CONTROLLERS[requestedIdx-1].isConnected) {
    CONTROLLERS[requestedIdx-1].isConnected = true
    console.log(`Player ${requestedIdx} has been claimed.`);
    res.status(200).send(`You are now Player ${requestedIdx}`)
  } else {
    res.status(402).send(`Player ${requestedIdx} has already been claimed.`)

  }
})

app.post('/controller/disconnect', (req, res) => {
  const requestedIdx = req.body.player_idx

  if (CONTROLLERS[requestedIdx-1].isConnected) {
    CONTROLLERS[requestedIdx-1].isConnected = false
    console.log(`Player ${requestedIdx} has been relinquished.`);
    res.status(200).send(`You have been disconnected`)
  } else {
    res.status(402).send(`Player ${requestedIdx} is already disconnected.`)
  }
})

app.post('/controller/command', (req, res) => {
  const json = req.body
  const player = json.player_idx
  if (!player) {
    return res.status(402).send("You must specify which player you are.")
  }

  if (!(json.action && json.input_name)) {
    return res.status(402).send("All commands require both an action and a control item.")
  }
  var input_string = json.action + " " + json.input_name;
  if (json.value) {
    input_string = input_string + " " + json.value;
  }

  var command = `echo '${input_string.toUpperCase()}'`
  var target = `'${os.homedir()}/Library/Application Support/Dolphin/Pipes/ctrl${player}'`
  var process = exec(`${command} > ${target}`, { timeout: 1000 })
  console.log(`${command} > ${target}`);
  process.stdout.on("data", data => console.log(data));
  process.stderr.on("data", data => console.log(data));

  res.status(200).send("Success")

})





app.listen(port, function () {
  console.log('Example app listening on ' + `${ip.address()}:${port}` + '!')
})
