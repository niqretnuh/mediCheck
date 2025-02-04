require('dotenv').config();
const express = require('express');
const cors = require('cors');
const pool = require('./db'); // Import the database connection

const app = express();
const PORT = process.env.PORT || 8888;

app.use(cors());
app.use(express.json());

// Fetch medication by name from PostgreSQL
app.get('/medications', async (req, res) => {
    try {
        const query = req.query.name ? `%${req.query.name.toLowerCase()}%` : '%';
        const result = await pool.query(
            "SELECT * FROM medications WHERE LOWER(name) LIKE $1",
            [query]
        );
        res.json({ results: result.rows });
    } catch (err) {
        console.error(err.message);
        res.status(500).send("Server Error");
    }
});

app.listen(PORT, () => console.log(`🚀 Server running on http://localhost:${PORT}`));
