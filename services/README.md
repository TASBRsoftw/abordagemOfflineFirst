# Instruções para rodar o projeto de Mensageria

## Pré-requisitos
- Node.js 18+
- RabbitMQ rodando localmente (padrão: amqp://localhost)

## Instalação de dependências

No diretório `src`, execute:

```
npm install express amqplib
```

## Como rodar

### 1. Producer (List Service)
```
node src/producer/index.js
```

### 2. Consumer A (Log/Notification)
```
node src/consumer-log/index.js
```

### 3. Consumer B (Analytics)
```
node src/consumer-analytics/index.js
```

## Testando o fluxo

1. Faça uma requisição POST para `http://localhost:3000/lists/123/checkout` com body JSON:
   ```json
   {
     "email": "usuario@exemplo.com",
     "total": 199.90
   }
   ```
2. Veja os logs dos consumers e o RabbitMQ Management.

---

Ajuste a URL do RabbitMQ via variável de ambiente `RABBITMQ_URL` se necessário.
