var http    = require('http');
var fs      = require('fs');
var express = require('express');
var path    = require('path');

var app     = express();

app.configure(function () {
  app.set('port', process.env.PORT || 8000);
  app.use(express.static(path.join(__dirname, 'public')));

  console.log(__dirname); // __dirname is the working directory of the server
  fs.readdir('img', (error, files) => {
    if (error) {
        console.error(error);
        return;
    }
    files.forEach(file => {
        console.log(file);
    });
  });

  fs.readFile('public/demofile1.html', function(err, data) {
    res.writeHead(200, {'Content-Type': 'text/html'});
    res.write(data);
    return res.end();
  });

});


/* testing */
var server = http.createServer(app);
server.listen(app.get('port'), function () {
  console.log("Express server listening on port " + app.get('port'));
});

//create a route
app.get('/', function (req, res) {
  res.sendfile('public/test.html');
});
/* end testing */

/*
var server = http.createServer(function (req, res) {
  console.log(__dirname); // __dirname is the working directory of the server
  fs.readdir('img', (error, files) => {
    if (error) {
        console.error(error);
        return;
    }
    files.forEach(file => {
        console.log(file);
    });
  });

  fs.readFile('demofile1.html', function(err, data) {
    res.writeHead(200, {'Content-Type': 'text/html'});
    res.write(data);
    return res.end();
  });
});
*/
