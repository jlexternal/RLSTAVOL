// import modules
var http    = require('http');
var fs      = require('fs');
var express = require('express');
var path    = require('path');

var app     = express();
app.set('port', process.env.PORT || 8000);
app.use(express.static(path.join(__dirname, 'public')));

// launch server
var server = http.createServer(app);
server.listen(app.get('port'), function () {
  console.log("Express server listening on port " + app.get('port'));
});

//create a route
app.get('/', function (req, res) {

  // keep code for sake of example
  var test = fs.readdirSync(__dirname); // this may need to be more specific to prevent file access protection

/* for reading content inside single directories and not internal directories
  fs.readdir('public/jspsych-6.3.0/', (error, files) => {
    if (error) {
        console.error(error);
        return;
    }
    files.forEach(file => {
        console.log(file);
    });
  });
*/

  fs.readFile('public/run_expe.html', function(err, data) {
    //res.write(data); https://stackoverflow.com/questions/7042340/error-cant-set-headers-after-they-are-sent-to-the-client
    return res.end();
  });

  res.sendfile('public/run_expe.html');
});
