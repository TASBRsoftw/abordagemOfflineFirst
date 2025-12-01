// Consumer A - Log/Notification Service
const amqp = require('amqplib');
const { RABBITMQ_URL, EXCHANGE, QUEUE_LOG } = require('../rabbitmq.config');

async function start() {
  const conn = await amqp.connect(RABBITMQ_URL);
  const channel = await conn.createChannel();
  await channel.assertExchange(EXCHANGE, 'topic', { durable: true });
  await channel.assertQueue(QUEUE_LOG, { durable: true });
  await channel.bindQueue(QUEUE_LOG, EXCHANGE, 'list.checkout.#');

  channel.consume(QUEUE_LOG, (msg) => {
    if (msg) {
      const event = JSON.parse(msg.content.toString());
      console.log(`Enviando comprovante da lista ${event.listId} para o usuário ${event.email}`);
      channel.ack(msg);
    }
  });
  console.log('Consumer A (Log/Notification) aguardando mensagens...');
}

start();
