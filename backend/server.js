require('dotenv').config();
const express = require('express');
const AWS = require('aws-sdk');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 8888;

app.use(cors());
app.use(express.json());

// TODO: Change this to some config file
AWS.config.update({
  region: 'us-east-2',
  credentials: {
    accessKeyId: 'AKIA6JKEYHRTP6T3GSPL',
    secretAccessKey: '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'
  }
});

const sagemakerRuntime = new AWS.SageMakerRuntime();

app.get('/generate', async (req, res) => {

  const { input } = req.query;
  if (!input) {
    return res.status(400).json({ error: 'Missing input query parameter' });
  }

  const system_prompt = 'Translate the following medication facts into clear, concise, and easy-to-understand bullet points for a general audience. Each bullet point should summarize one key fact, using simple language without technical jargon. Ensure that the bullet points are well-structured and maintain the accuracy of the original information.'
  const prompt = `<|begin_of_text|><|start_header_id|>system<|end_header_id|>
  ${system_prompt} <|eot_id|><|start_header_id|>user<|end_header_id|>\n\n${input}\n<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n\n`;

  const payload = {
    inputs: prompt,
    parameters: {
      max_new_tokens: 256,
      top_p: 0.9,
      temperature: 0.6
    }
  };

  const params = {
    EndpointName: 'jumpstart-dft-llama-3-1-8b-instruct-20250302-093626',
    Body: JSON.stringify(payload),
    ContentType: 'application/json'
  };

  try {
    const data = await sagemakerRuntime.invokeEndpoint(params).promise();
    const result = Buffer.from(data.Body).toString('utf-8');
    res.json({ response: result });
  } catch (error) {
    console.error('Error invoking SageMaker endpoint:', error);
    res.status(500).json({ error: 'Failed to generate response' });
  }
});

app.listen(PORT, () => console.log(`Server running on http://localhost:${PORT}`));
