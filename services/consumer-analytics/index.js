// Consumer B - Analytics Service
const amqp = require('amqplib');
const { RABBITMQ_URL, EXCHANGE, QUEUE_ANALYTICS } = require('../rabbitmq.config');

async function start() {
  const conn = await amqp.connect(RABBITMQ_URL);
  const channel = await conn.createChannel();
  await channel.assertExchange(EXCHANGE, 'topic', { durable: true });
  await channel.assertQueue(QUEUE_ANALYTICS, { durable: true });
  await channel.bindQueue(QUEUE_ANALYTICS, EXCHANGE, 'list.checkout.#');

  channel.consume(QUEUE_ANALYTICS, (msg) => {
    if (msg) {
      const event = JSON.parse(msg.content.toString());
      console.log(`Analytics: Lista ${event.listId} finalizada. Total gasto: R$${event.total}`);
      channel.ack(msg);
    }
  });
  console.log('Consumer B (Analytics) aguardando mensagens...');
}

start();
