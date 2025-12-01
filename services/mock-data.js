
// População de dados mock em grande escala
const fs = require('fs');
const path = require('path');

const listsPath = path.join(__dirname, 'list-service', 'database', 'lists.json');

const user = {
  id: 'user-1',
  name: 'João da Silva',
  email: 'joao@exemplo.com',
};

const itemNames = ['Arroz', 'Feijão', 'Macarrão', 'Óleo', 'Açúcar', 'Sal', 'Café', 'Leite', 'Biscoito', 'Farinha', 'Carne', 'Frango', 'Peixe', 'Batata', 'Cenoura', 'Tomate', 'Alface', 'Banana', 'Maçã', 'Laranja'];

function randomItem(id) {
  const name = itemNames[Math.floor(Math.random() * itemNames.length)];
  return {
    itemId: `item-${id}`,
    itemName: name,
    quantity: Math.floor(Math.random() * 5) + 1,
    unit: 'un',
    estimatedPrice: parseFloat((Math.random() * 20 + 1).toFixed(2)),
    purchased: false,
    notes: '',
    addedAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };
}

function randomList(i) {
  const nItems = Math.floor(Math.random() * 10) + 3;
  const items = Array.from({ length: nItems }, (_, idx) => randomItem(i * 100 + idx));
  const estimatedTotal = items.reduce((sum, it) => sum + it.estimatedPrice * it.quantity, 0);
  return {
    id: `list-${i}`,
    userId: user.id,
    name: `Lista ${i}`,
    description: `Compras do mês ${i}`,
    status: 'active',
    items,
    summary: {
      totalItems: items.length,
      purchasedItems: 0,
      estimatedTotal: parseFloat(estimatedTotal.toFixed(2))
    },
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };
}

function fixedList(i) {
  const items = Array.from({ length: 3 }, (_, idx) => randomItem(i * 100 + idx));
  const estimatedTotal = items.reduce((sum, it) => sum + it.estimatedPrice * it.quantity, 0);
  return {
    id: `list-${i}`,
    userId: user.id,
    name: `Lista ${i}`,
    description: `Compras do mês ${i}`,
    status: 'active',
    items,
    summary: {
      totalItems: items.length,
      purchasedItems: 0,
      estimatedTotal: parseFloat(estimatedTotal.toFixed(2))
    },
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };
}

const smallMock = Array.from({ length: 10 }, (_, i) => fixedList(i + 1));
fs.writeFileSync(listsPath, JSON.stringify(smallMock, null, 2));
console.log('Mock de listas reduzido populado em', listsPath);
