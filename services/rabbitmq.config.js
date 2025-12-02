// Configuração central de conexão com RabbitMQ
module.exports = {
  RABBITMQ_URL: process.env.RABBITMQ_URL || 'amqps://bpdogpco:(senha)d@jackal.rmq.cloudamqp.com/bpdogpco',
  EXCHANGE: 'shopping_events',
  ROUTING_KEY: 'list.checkout.completed',
  QUEUE_LOG: 'queue.list.checkout.log',
  QUEUE_ANALYTICS: 'queue.list.checkout.analytics',
};
