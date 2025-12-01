// Producer (List Service) - Express API
const express = require('express');
const amqp = require('amqplib');
const { RABBITMQ_URL, EXCHANGE, ROUTING_KEY } = require('../rabbitmq.config');

const app = express();
app.use(express.json());

let channel;

async function connectRabbit() {
  const conn = await amqp.connect(RABBITMQ_URL);
  channel = await conn.createChannel();
  await channel.assertExchange(EXCHANGE, 'topic', { durable: true });
}

app.post('/lists/:id/checkout', async (req, res) => {
  const listId = req.params.id;
  const { email, total } = req.body;
  const event = {
    listId,
    email,
    total,
    timestamp: new Date().toISOString(),
  };
  channel.publish(EXCHANGE, ROUTING_KEY, Buffer.from(JSON.stringify(event)));
  res.status(202).json({ message: 'Checkout iniciado', event });
});

const PORT = process.env.PORT || 3000;
connectRabbit().then(() => {
  app.listen(PORT, () => {
    console.log(`Producer (List Service) rodando na porta ${PORT}`);
  });
});
