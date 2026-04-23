const express = require('express');
const axios = require('axios');
const path = require('path');

const app = express();

const API_URL = process.env.API_URL || 'http://localhost:8000';
const HOST = process.env.HOST || '0.0.0.0';
const PORT = parseInt(process.env.PORT || '3000', 10);

app.use(express.json());
app.use(express.static(path.join(__dirname, 'views')));

app.post('/submit', async (req, res) => {
  try {
    const response = await axios.post(`${API_URL}/jobs`);
    res.json(response.data);
  } catch {
    res.status(500).json({ error: 'something went wrong' });
  }
});

app.get('/status/:id', async (req, res) => {
  try {
    const response = await axios.get(`${API_URL}/jobs/${req.params.id}`);
    res.json(response.data);
  } catch (err) {
    const status = err.response?.status || 500;
    res.status(status).json({ error: 'something went wrong' });
  }
});

app.listen(PORT, HOST, () => {
  console.log(`Frontend listening on ${HOST}:${PORT}`);
});
