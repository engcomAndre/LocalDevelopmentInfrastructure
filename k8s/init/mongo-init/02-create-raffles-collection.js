print('=== Criando collection raffles no banco raffles_db ===');

db = db.getSiblingDB('raffles_db');
db.createCollection('raffles');

print('=== Collection criada raffles no banco raffles_db ===');
