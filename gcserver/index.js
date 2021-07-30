const express = require("express");
const bodyParser = require("body-parser");
const fs = require("fs");
const ip = require("ip");
const os = require("os");
const path = require("path");
const qrcode = require("qrcode-terminal");

const app = express();
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

const http = require("http").createServer(app);
const io = require("socket.io")(http);

const DolphinConfigDirectory = path.join(
  os.homedir(),
  "Library",
  "Application Support",
  "Dolphin"
);

const IP = ip.address();
const SOCKET_PORT = 4000;
const BROADCAST_PORT = process.env.PORT || 3000;

class Controller {
  constructor(id) {
    this.id = id;
    this.isConnected = false;
  }

  openPipe() {
    const fpath = path.join(DolphinConfigDirectory, "Pipes", `ctrl${this.id}`);
    this.ws = fs.createWriteStream(fpath);
  }

  closePipe() {
    this.ws.end();
  }
}

const CONTROLLERS = [
  new Controller(1),
  new Controller(2),
  new Controller(3),
  new Controller(4),
];

app.get("/controller", function (req, res) {
  res.status(200).send("Use this endpoint to set up your controllers");
});

app.get("/controller/connect", (req, res) => {
  var availableIDs = [];
  for (c of CONTROLLERS) {
    if (!c.isConnected) {
      availableIDs.push(c.id);
    }
  }

  res.status(200).json({ controllers: availableIDs, socket: SOCKET_PORT });
});

app.post("/controller/connect", (req, res) => {
  const requestedIdx = req.body.player_idx;

  if (!CONTROLLERS[requestedIdx - 1].isConnected) {
    CONTROLLERS[requestedIdx - 1].isConnected = true;
    console.log(`Player ${requestedIdx} has been claimed.`);
    res.status(200).send(`You are now Player ${requestedIdx}`);
  } else {
    res.status(402).send(`Player ${requestedIdx} has already been claimed.`);
  }
});

app.post("/controller/disconnect", (req, res) => {
  const requestedIdx = req.body.player_idx;

  if (CONTROLLERS[requestedIdx - 1].isConnected) {
    CONTROLLERS[requestedIdx - 1].isConnected = false;
    console.log(`Player ${requestedIdx} has been relinquished.`);
    res.status(200).send(`You have been disconnected`);
  } else {
    res.status(402).send(`Player ${requestedIdx} is already disconnected.`);
  }
});

function executeCommand(json, player) {
  if (!(json.action && json.input_name)) {
    throw new Error("All commands require both an action and a control item.");
  }
  var input_string = json.action + " " + json.input_name;
  if (json.value) {
    input_string = input_string + " " + json.value;
  }

  var command = input_string.toUpperCase();
  // console.log(command);
  CONTROLLERS[player - 1].ws.write(command + "\n", (err) => {
    if (err) {
      console.error(player, err);
    }
  });
}

app.post("/controller/command", (req, res) => {
  const json = req.body;
  const player = json.player_idx;
  if (!player) {
    return res.status(402).send("You must specify which player you are.");
  }

  executeCommand(json, player);
  res.status(200).send("Success");
});

io.on("connection", function (socket) {
  console.log("Controller has connected");
  var connectionPlayerNumber = null;

  socket.on("disconnect", function () {
    if (!connectionPlayerNumber) {
      return;
    }
    if (CONTROLLERS[connectionPlayerNumber - 1].isConnected) {
      CONTROLLERS[connectionPlayerNumber - 1].isConnected = false;
      CONTROLLERS[connectionPlayerNumber - 1].closePipe();
      console.log(`Player ${connectionPlayerNumber} has been relinquished.`);
    }
  });

  socket.on("claim", function (requestedPlayerNumber) {
    if (!CONTROLLERS[requestedPlayerNumber - 1].isConnected) {
      CONTROLLERS[requestedPlayerNumber - 1].isConnected = true;
      CONTROLLERS[requestedPlayerNumber - 1].openPipe();
      console.log(`Player ${requestedPlayerNumber} has been claimed.`);
      connectionPlayerNumber = requestedPlayerNumber;
      socket.emit(
        "claim",
        makeResponse(200, {
          msg: `You are now Player ${requestedPlayerNumber}`,
        })
      );
    } else {
      socket.emit(
        "claim",
        makeResponse(
          402,
          null,
          `Player ${requestedPlayerNumber} has already been claimed. ${err}`
        )
      );
    }
  });

  socket.on("command", function (command) {
    executeCommand(command, connectionPlayerNumber);
  });
});

function makeResponse(status, payload, err = null) {
  return {
    status: status,
    error: err,
    data: { payload },
  };
}

app.listen(BROADCAST_PORT, function () {
  console.log(
    `Main Communication Service listening on ${IP}:${BROADCAST_PORT}`
  );
  qrcode.generate(`${IP}:${BROADCAST_PORT}`);
});
http.listen(SOCKET_PORT);
