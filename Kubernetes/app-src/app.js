// Boilerplate sourced and adapted for Kubernetes from: [mangya/node-express-mysql-boilerplate]
// Setting up constants not to be changed later.
const express = require('express');
const mysql = require('mysql2');
const app = express();
app.set('trust proxy', true);
const port = 8080;
const db = mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME
});

// Using console.log and console.error for debug purposes.
db.connect((err) => {
    if (err) {
        console.error('Database connection failed: ' + err.stack);
        return;
    }
    console.log('Connected to MySQL database via Kubernetes network.');
});

app.get('/', (req, res) => {
    res.send('<h1>Success!</h1>');
});

app.listen(port, '0.0.0.0', () => {
    console.log(`App listening on port ${port}`);
});


