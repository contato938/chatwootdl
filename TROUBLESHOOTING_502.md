# Troubleshooting 502 Bad Gateway Error

## ✅ Correção Principal Aplicada

A configuração do Puma foi atualizada para escutar em `0.0.0.0` em vez de `localhost`, permitindo conexões externas em ambientes containerizados/PaaS.

**Arquivo modificado:** `config/puma.rb` - linha 14

## 🔍 Checklist de Variáveis de Ambiente Obrigatórias

Verifique se todas as variáveis de ambiente abaixo estão configuradas no seu serviço de deploy:

### Críticas (Aplicação não inicia sem elas):

- [ ] **SECRET_KEY_BASE** - Gere com: `rails secret` ou `bundle exec rake secret`
  ```bash
  # Exemplo de geração:
  rails secret
  ```

- [ ] **POSTGRES_HOST** - Endereço do servidor PostgreSQL
- [ ] **POSTGRES_USERNAME** - Usuário do banco de dados
- [ ] **POSTGRES_PASSWORD** - Senha do banco de dados
- [ ] **POSTGRES_DATABASE** - Nome do banco (padrão: `chatwoot_production`)

- [ ] **REDIS_URL** - URL de conexão com Redis
  ```bash
  # Formato: redis://[:password@]host:port[/db_number]
  # Exemplo: redis://user:password@redis.example.com:6379/0
  ```

- [ ] **FRONTEND_URL** - URL completa da sua aplicação
  ```bash
  # Exemplo: https://seu-app.railway.app
  ```

- [ ] **RAILS_ENV** - Deve ser `production`

- [ ] **PORT** - Geralmente fornecido automaticamente pela plataforma

### Recomendadas:

- [ ] **RAILS_LOG_TO_STDOUT** - Defina como `true` para ver logs
- [ ] **RAILS_SERVE_STATIC_FILES** - Defina como `true` para servir assets
- [ ] **RAILS_MAX_THREADS** - Número de threads (padrão: 5)
- [ ] **WEB_CONCURRENCY** - Número de workers Puma (padrão: 0, recomendado: 2)

## 🔧 Como Verificar os Logs

Dependendo da plataforma de deploy:

### Railway:
```bash
railway logs
```

### Render:
Acesse o dashboard → Logs tab

### Heroku:
```bash
heroku logs --tail --app seu-app
```

### Docker:
```bash
docker logs nome-do-container
```

## ⚠️ Erros Comuns nos Logs

1. **"database does not exist"**
   - Solução: Execute `rails db:create db:migrate` no release phase

2. **"could not connect to server: Connection refused"**
   - Problema com POSTGRES_HOST ou PostgreSQL não está rodando

3. **"Error connecting to Redis"**
   - Problema com REDIS_URL ou Redis não está rodando

4. **"Missing `secret_key_base` for 'production' environment"**
   - SECRET_KEY_BASE não está configurado

5. **"tail: inotify cannot be used, reverting to polling: Too many open files"**
   - ✅ **RESOLVIDO**: File descriptor limits aumentados para 65536
   - A aplicação estava atingindo o limite de arquivos abertos simultaneamente
   - Correções aplicadas:
     - `docker-entrypoint.sh`: Aumentado ulimit -n para 65536
     - `docker-compose.yaml`: Adicionado ulimits.nofile para todos os serviços
     - `docker-compose.production.yaml`: Adicionado ulimits.nofile para rails e sidekiq
   
   **Se você ainda enfrentar este erro em produção:**
   
   Para Docker standalone:
   ```bash
   docker run --ulimit nofile=65536:65536 your-image
   ```
   
   Para ajustar no host Docker (requer root):
   ```bash
   # Edite /etc/security/limits.conf e adicione:
   * soft nofile 65536
   * hard nofile 65536
   
   # Ou ajuste o Docker daemon em /etc/docker/daemon.json:
   {
     "default-ulimits": {
       "nofile": {
         "Name": "nofile",
         "Hard": 65536,
         "Soft": 65536
       }
     }
   }
   
   # Reinicie o Docker daemon:
   sudo systemctl restart docker
   ```

## 🚀 Próximos Passos

1. **Rebuild da aplicação**: Faça um novo deploy após esta correção
2. **Verifique os logs**: Procure por mensagens de erro específicas
3. **Teste a conexão**: Tente acessar a URL depois que o build terminar
4. **Health Check**: Acesse `/api/v1/accounts/health` para verificar se a API está respondendo

## 📝 Comando para Testar Localmente

```bash
# Teste localmente se o servidor inicia corretamente:
RAILS_ENV=production \
SECRET_KEY_BASE=$(rails secret) \
POSTGRES_HOST=localhost \
POSTGRES_USERNAME=postgres \
POSTGRES_PASSWORD=postgres \
REDIS_URL=redis://localhost:6379 \
FRONTEND_URL=http://localhost:3000 \
bundle exec rails server -p 3000
```

## 🔗 Links Úteis

- [Chatwoot Environment Variables Docs](https://www.chatwoot.com/docs/self-hosted/configuration/environment-variables)
- [Chatwoot Production Deployment](https://www.chatwoot.com/docs/self-hosted/deployment/production)
