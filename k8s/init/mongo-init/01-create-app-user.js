print('=== Criando usuário application_user no banco raffles_db ===');

db = db.getSiblingDB('raffles_db');

db.createUser({
  user: 'application_user',
  pwd: 'securepassword123',
  roles: [
    { role: 'readWrite', db: 'raffles_db' }
  ]
});

print('=== Criado usuário application_user no banco raffles_db ===');
