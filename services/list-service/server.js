// List Service adaptado para mensageria (RabbitMQ)
const express = require("express");
const helmet = require("helmet");
const cors = require("cors");
const morgan = require("morgan");
const { v4: uuidv4 } = require("uuid");
const amqp = require("amqplib");
const path = require("path");
const axios = require("axios");
const {
  RABBITMQ_URL,
  EXCHANGE,
  ROUTING_KEY
} = require("../rabbitmq.config");
const JsonDatabase = require("../shared/JsonDatabase");
const serviceRegistry = require("../shared/serviceRegistry");

class ListService {
  // Stub para registro no service registry
  registerWithRegistry() {
    // Implementação real pode ser adicionada depois
    console.log('registerWithRegistry chamado (stub)');
  }

  // Stub para health reporting
  startHealthReporting() {
    // Implementação real pode ser adicionada depois
    console.log('startHealthReporting chamado (stub)');
  }
  // Métodos CRUD reais migrados do projeto antigo
  async createList(req, res) {
    try {
      const { name, description } = req.body;
      if (!name) {
        return res.status(400).json({ success: false, message: "Nome da lista é obrigatório" });
      }
      const newList = await this.listsDb.create({
        id: uuidv4(),
        userId: req.user.id,
        name,
        description: description || "",
        status: "active",
        items: [],
        summary: { totalItems: 0, purchasedItems: 0, estimatedTotal: 0 },
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      });
      res.status(201).json({ success: true, message: "Lista criada com sucesso", data: newList });
    } catch (error) {
      console.error("Erro ao criar lista:", error);
      res.status(500).json({ success: false, message: "Erro interno do servidor" });
    }
  }
  async getLists(req, res) {
    try {
      const { status } = req.query;
      const filter = { userId: req.user.id };
      if (status) filter.status = status;
      const lists = await this.listsDb.find(filter, { sort: { updatedAt: -1 } });
      res.json({ success: true, data: lists });
    } catch (error) {
      console.error("Erro ao buscar listas:", error);
      res.status(500).json({ success: false, message: "Erro interno do servidor" });
    }
  }
  async getList(req, res) {
    try {
      const { id } = req.params;
      const list = await this.listsDb.findById(id);
      if (!list) {
        return res.status(404).json({ success: false, message: "Lista não encontrada" });
      }
      if (list.userId !== req.user.id) {
        return res.status(403).json({ success: false, message: "Acesso negado a esta lista" });
      }
      res.json({ success: true, data: list });
    } catch (error) {
      console.error("Erro ao buscar lista:", error);
      res.status(500).json({ success: false, message: "Erro interno do servidor" });
    }
  }
  async updateList(req, res) {
    try {
      const { id } = req.params;
      const { name, description, status } = req.body;
      const list = await this.listsDb.findById(id);
      if (!list) {
        return res.status(404).json({ success: false, message: "Lista não encontrada" });
      }
      if (list.userId !== req.user.id) {
        return res.status(403).json({ success: false, message: "Acesso negado a esta lista" });
      }
      const updates = {};
      if (name) updates.name = name;
      if (description !== undefined) updates.description = description;
      if (status) updates.status = status;
      updates.updatedAt = new Date().toISOString();
      const updatedList = await this.listsDb.update(id, updates);
      res.json({ success: true, message: "Lista atualizada com sucesso", data: updatedList });
    } catch (error) {
      console.error("Erro ao atualizar lista:", error);
      res.status(500).json({ success: false, message: "Erro interno do servidor" });
    }
  }
  async deleteList(req, res) {
    try {
      const { id } = req.params;
      const list = await this.listsDb.findById(id);
      if (!list) {
        return res.status(404).json({ success: false, message: "Lista não encontrada" });
      }
      if (list.userId !== req.user.id) {
        return res.status(403).json({ success: false, message: "Acesso negado a esta lista" });
      }
      await this.listsDb.delete(id);
      res.json({ success: true, message: "Lista excluída com sucesso" });
    } catch (error) {
      console.error("Erro ao excluir lista:", error);
      res.status(500).json({ success: false, message: "Erro interno do servidor" });
    }
  }
  async addItemToList(req, res) {
    try {
      const { id } = req.params;
      const { itemId, quantity, notes } = req.body;
      if (!itemId) {
        return res.status(400).json({ success: false, message: "ID do item é obrigatório" });
      }
      const list = await this.listsDb.findById(id);
      if (!list) {
        return res.status(404).json({ success: false, message: "Lista não encontrada" });
      }
      if (list.userId !== req.user.id) {
        return res.status(403).json({ success: false, message: "Acesso negado a esta lista" });
      }
      // Buscar informações do item no Item Service (mock simplificado)
      let itemInfo = { id: itemId, name: `Item ${itemId}`, unit: 'un', averagePrice: 1.0 };
      // Verificar se o item já está na lista
      const existingItemIndex = list.items.findIndex((item) => item.itemId === itemId);
      if (existingItemIndex >= 0) {
        list.items[existingItemIndex].quantity += parseFloat(quantity) || 1;
        list.items[existingItemIndex].updatedAt = new Date().toISOString();
        if (notes) list.items[existingItemIndex].notes = notes;
      } else {
        list.items.push({
          itemId: itemInfo.id,
          itemName: itemInfo.name,
          quantity: parseFloat(quantity) || 1,
          unit: itemInfo.unit,
          estimatedPrice: itemInfo.averagePrice,
          purchased: false,
          notes: notes || "",
          addedAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        });
      }
      list.summary = this.calculateSummary(list.items);
      list.updatedAt = new Date().toISOString();
      const updatedList = await this.listsDb.update(id, list);
      res.status(201).json({ success: true, message: "Item adicionado à lista", data: updatedList });
    } catch (error) {
      console.error("Erro ao adicionar item à lista:", error);
      res.status(500).json({ success: false, message: "Erro interno do servidor" });
    }
  }
  async updateItemInList(req, res) {
    try {
      const { id, itemId } = req.params;
      const { quantity, purchased, notes } = req.body;
      const list = await this.listsDb.findById(id);
      if (!list) {
        return res.status(404).json({ success: false, message: "Lista não encontrada" });
      }
      if (list.userId !== req.user.id) {
        return res.status(403).json({ success: false, message: "Acesso negado a esta lista" });
      }
      const itemIndex = list.items.findIndex((item) => item.itemId === itemId);
      if (itemIndex === -1) {
        return res.status(404).json({ success: false, message: "Item não encontrado na lista" });
      }
      if (quantity !== undefined) list.items[itemIndex].quantity = parseFloat(quantity);
      if (purchased !== undefined) list.items[itemIndex].purchased = purchased;
      if (notes !== undefined) list.items[itemIndex].notes = notes;
      list.items[itemIndex].updatedAt = new Date().toISOString();
      list.summary = this.calculateSummary(list.items);
      list.updatedAt = new Date().toISOString();
      const updatedList = await this.listsDb.update(id, list);
      res.json({ success: true, message: "Item atualizado na lista", data: updatedList });
    } catch (error) {
      console.error("Erro ao atualizar item na lista:", error);
      res.status(500).json({ success: false, message: "Erro interno do servidor" });
    }
  }
  async removeItemFromList(req, res) {
    try {
      const { id, itemId } = req.params;
      const list = await this.listsDb.findById(id);
      if (!list) {
        return res.status(404).json({ success: false, message: "Lista não encontrada" });
      }
      if (list.userId !== req.user.id) {
        return res.status(403).json({ success: false, message: "Acesso negado a esta lista" });
      }
      list.items = list.items.filter((item) => item.itemId !== itemId);
      list.summary = this.calculateSummary(list.items);
      list.updatedAt = new Date().toISOString();
      const updatedList = await this.listsDb.update(id, list);
      res.json({ success: true, message: "Item removido da lista", data: updatedList });
    } catch (error) {
      console.error("Erro ao remover item da lista:", error);
      res.status(500).json({ success: false, message: "Erro interno do servidor" });
    }
  }
  async getListSummary(req, res) {
    try {
      const { id } = req.params;
      const list = await this.listsDb.findById(id);
      if (!list) {
        return res.status(404).json({ success: false, message: "Lista não encontrada" });
      }
      if (list.userId !== req.user.id) {
        return res.status(403).json({ success: false, message: "Acesso negado a esta lista" });
      }
      res.json({ success: true, data: { summary: list.summary, items: list.items } });
    } catch (error) {
      console.error("Erro ao buscar sumário da lista:", error);
      res.status(500).json({ success: false, message: "Erro interno do servidor" });
    }
  }
  calculateSummary(items) {
    const totalItems = items.length;
    const purchasedItems = items.filter((item) => item.purchased).length;
    const estimatedTotal = items.reduce((total, item) => total + item.estimatedPrice * item.quantity, 0);
    return {
      totalItems,
      purchasedItems,
      estimatedTotal: parseFloat(estimatedTotal.toFixed(2)),
    };
  }
  constructor() {
    this.app = express();
    this.port = process.env.PORT || 3002;
    this.serviceName = "list-service";
    this.serviceUrl = `http://localhost:${this.port}`;
    this.setupDatabase();
    this.setupMiddleware();
    this.setupRoutes();
    this.setupErrorHandling();
    this.channel = null;
    this.connectRabbit();
  }

  setupDatabase() {
    const dbPath = path.join(__dirname, "./database");
    this.listsDb = new JsonDatabase(dbPath, "lists");
    console.log("List Service: Banco NoSQL inicializado");
  }

  setupMiddleware() {
    this.app.use(helmet());
    this.app.use(cors());
    this.app.use(morgan("combined"));
    this.app.use(express.json());
    this.app.use(express.urlencoded({ extended: true }));
    this.app.use((req, res, next) => {
      res.setHeader("X-Service", this.serviceName);
      res.setHeader("X-Service-Version", "2.0.0");
      res.setHeader("X-Database", "JSON-NoSQL");
      next();
    });
  }

  async connectRabbit() {
    const conn = await amqp.connect(RABBITMQ_URL);
    this.channel = await conn.createChannel();
    await this.channel.assertExchange(EXCHANGE, "topic", { durable: true });
    console.log("List Service: Conectado ao RabbitMQ");
  }

  setupRoutes() {
    // Health check
    this.app.get("/health", async (req, res) => {
      try {
        const listCount = await this.listsDb.count();
        const activeLists = await this.listsDb.count({ status: "active" });
        res.json({
          service: this.serviceName,
          status: "healthy",
          timestamp: new Date().toISOString(),
          uptime: process.uptime(),
          version: "2.0.0",
          database: {
            type: "JSON-NoSQL",
            listCount,
            activeLists,
          },
        });
      } catch (error) {
        res.status(503).json({
          service: this.serviceName,
          status: "unhealthy",
          error: error.message,
        });
      }
    });

    // Service info
    this.app.get("/", (req, res) => {
      res.json({
        service: "List Service",
        version: "2.0.0",
        description: "Microsserviço para gerenciamento de listas de compras (mensageria)",
        database: "JSON-NoSQL",
        endpoints: [
          "POST /lists",
          "GET /lists",
          "GET /lists/:id",
          "PUT /lists/:id",
          "DELETE /lists/:id",
          "POST /lists/:id/items",
          "PUT /lists/:id/items/:itemId",
          "DELETE /lists/:id/items/:itemId",
          "GET /lists/:id/summary",
          "POST /lists/:id/checkout"
        ],
      });
    });

    this.app.use(this.authMiddleware.bind(this));

    // Rotas principais com prefixo /lists
    const router = express.Router();
    router.post("/", this.createList.bind(this));
    router.get("/", this.getLists.bind(this));
    router.get("/:id", this.getList.bind(this));
    router.put("/:id", this.updateList.bind(this));
    router.delete("/:id", this.deleteList.bind(this));
    router.post("/:id/items", this.addItemToList.bind(this));
    router.put("/:id/items/:itemId", this.updateItemInList.bind(this));
    router.delete("/:id/items/:itemId", this.removeItemFromList.bind(this));
    router.get("/:id/summary", this.getListSummary.bind(this));
    // Rota de checkout (mensageria)
    router.post("/:id/checkout", this.checkoutList.bind(this));
    this.app.use("/lists", router);
  }

  setupErrorHandling() {
    this.app.use((req, res) => {
      res.status(404).json({ success: false, message: "Endpoint não encontrado", service: this.serviceName });
    });
    this.app.use((error, req, res, next) => {
      console.error("List Service Error:", error);
      res.status(500).json({ success: false, message: "Erro interno do serviço", service: this.serviceName });
    });
  }

  // ... (demais métodos CRUD e helpers iguais ao antigo projeto) ...

  // Novo método: checkoutList
  async checkoutList(req, res) {
    try {
      const { id } = req.params;
      const list = await this.listsDb.findById(id);
      if (!list) {
        return res.status(404).json({ success: false, message: "Lista não encontrada" });
      }
      if (list.userId !== req.user.id) {
        return res.status(403).json({ success: false, message: "Acesso negado a esta lista" });
      }
      // Simular obtenção de email do usuário
      const email = req.user.email || "user@exemplo.com";
      // Calcular total
      const total = list.items.reduce((sum, item) => sum + (item.estimatedPrice * item.quantity), 0);
      // Publicar evento no RabbitMQ
      const event = {
        listId: id,
        email,
        total,
        timestamp: new Date().toISOString(),
      };
      if (this.channel) {
        this.channel.publish(EXCHANGE, ROUTING_KEY, Buffer.from(JSON.stringify(event)));
      }
      // Responder imediatamente
      res.status(202).json({ message: "Checkout iniciado", event });
    } catch (error) {
      console.error("Erro no checkout:", error);
      res.status(500).json({ success: false, message: "Erro ao processar checkout" });
    }
  }

  // ... (demais métodos CRUD e helpers iguais ao antigo projeto) ...

  // Auth middleware (igual ao antigo projeto)
  async authMiddleware(req, res, next) {
    // Mock de autenticação: aceita qualquer token e popula req.user com dados mock
    const authHeader = req.header("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return res.status(401).json({ success: false, message: "Token obrigatório (mock)" });
    }
    // Usuário mock
    req.user = {
      id: 'user-1',
      name: 'João da Silva',
      email: 'joao@exemplo.com'
    };
    next();
  }

  start() {
    this.app.listen(this.port, () => {
      console.log("=====================================");
      console.log(`List Service iniciado na porta ${this.port}`);
      console.log(`URL: ${this.serviceUrl}`);
      console.log(`Health: ${this.serviceUrl}/health`);
      console.log(`Database: JSON-NoSQL`);
      console.log("=====================================");
      this.registerWithRegistry();
      this.startHealthReporting();
    });
  }

  // ...registerWithRegistry, startHealthReporting, etc. iguais ao antigo projeto...
}

if (require.main === module) {
  const listService = new ListService();
  listService.start();
  process.on("SIGTERM", () => {
    serviceRegistry.unregister("list-service");
    process.exit(0);
  });
  process.on("SIGINT", () => {
    serviceRegistry.unregister("list-service");
    process.exit(0);
  });
}

module.exports = ListService;
