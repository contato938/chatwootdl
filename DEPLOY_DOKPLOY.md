# Guia de Deploy no Dokploy - Chatwoot

## 📋 Variáveis de Ambiente Obrigatórias

Configure estas variáveis no Dokploy antes de fazer o deploy:

### Banco de Dados PostgreSQL

```bash
# Endereço do servidor PostgreSQL
POSTGRES_HOST=seu-postgres-host.dokploy.internal

# Credenciais do banco
POSTGRES_USERNAME=chatwoot
POSTGRES_PASSWORD=sua-senha-segura-aqui

# Nome do banco de dados (opcional, default: chatwoot_production)
POSTGRES_DATABASE=chatwoot_production

# Porta do PostgreSQL (opcional, default: 5432)
POSTGRES_PORT=5432
```

### Redis

```bash
# URL completa de conexão com Redis
# Formato: redis://[:password@]host:port[/db_number]
REDIS_URL=redis://seu-redis-host.dokploy.internal:6379
```

### Rails e Aplicação

```bash
# Chave secreta para sessions e cookies
# CRÍTICO: Gere uma nova chave usando: rails secret
SECRET_KEY_BASE=sua-chave-secreta-aqui-gerada-com-rails-secret

# Ambiente Rails (DEVE ser production)
RAILS_ENV=production

# URL pública da sua aplicação
FRONTEND_URL=https://seu-dominio.com

# Porta (geralmente configurada automaticamente pelo Dokploy)
PORT=3000

# Servir arquivos estáticos (necessário para Dokploy)
RAILS_SERVE_STATIC_FILES=true

# Logs para stdout (necessário para visualizar logs no Dokploy)
RAILS_LOG_TO_STDOUT=true
```

### Opcionais mas Recomendadas

```bash
# Número de threads por worker (default: 5)
RAILS_MAX_THREADS=5

# Número de workers Puma (recomendado: 2 para produção)
WEB_CONCURRENCY=2

# Timeout de statement do Postgres (default: 14s)
POSTGRES_STATEMENT_TIMEOUT=14s

# Configurações de email (se necessário)
MAILER_SENDER_EMAIL=Chatwoot <noreply@seu-dominio.com>
SMTP_ADDRESS=smtp.seu-provedor.com
SMTP_PORT=587
SMTP_USERNAME=seu-usuario-smtp
SMTP_PASSWORD=sua-senha-smtp
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true

# Desabilitar signup (recomendado para produção)
ENABLE_ACCOUNT_SIGNUP=false
```

## 🚀 Processo de Deploy

O Dockerfile agora inclui um script de entrypoint (`docker-entrypoint.sh`) que automaticamente:

1. ✅ Aumenta os limites de file descriptors para 65536 (previne erro "too many open files")
2. ✅ Aguarda o PostgreSQL ficar disponível
3. ✅ Aguarda o Redis ficar disponível
4. ✅ Executa as migrations do banco de dados (`rails db:chatwoot_prepare`)
5. ✅ Configura o IP lookup database
6. ✅ Inicia o servidor Puma

### Controle de Migrations

Por padrão, as migrations são executadas automaticamente. Para desabilitar:

```bash
RUN_MIGRATIONS=false
```

## 🔍 Verificação Pós-Deploy

### 1. Verificar logs no Dokploy

Procure por estas mensagens indicando sucesso:

```
✓ PostgreSQL is ready!
✓ Redis connection check complete!
✓ Database migrations completed successfully!
✓ IP lookup setup completed!
✓ Starting Puma web server...
```

### 2. Testar a aplicação

Acesse sua URL e você deve ver a tela de login do Chatwoot.

### 3. Verificar health check

```bash
curl https://seu-dominio.com/api/v1/accounts/health
```

Deve retornar:
```json
{"status":"ok"}
```

## ⚠️ Problemas Comuns

### Erro: "PostgreSQL is not available after 30 attempts"

**Causa**: O container não consegue conectar ao PostgreSQL.

**Solução**:
- Verifique se `POSTGRES_HOST` está correto
- Verifique se o serviço PostgreSQL está rodando
- Verifique se as credenciais (`POSTGRES_USERNAME`, `POSTGRES_PASSWORD`) estão corretas
- Verifique se o banco de dados existe

### Erro: "Database migrations failed"

**Causa**: Problema durante execução das migrations.

**Solução**:
- Verifique os logs para detalhes específicos
- Verifique se o usuário do banco tem permissões adequadas
- Para primeira instalação, o banco deve estar vazio ou não existir

### Erro 502 Bad Gateway

**Causas possíveis**:

1. **Variável SECRET_KEY_BASE não configurada**
   - Gere uma nova: `docker run --rm sua-imagem rails secret`
   - Configure no Dokploy

2. **RAILS_ENV não está definida como production**
   - Verifique se `RAILS_ENV=production`

3. **Container não consegue conectar ao banco/Redis**
   - Verifique todas as variáveis de conexão
   - Verifique se os serviços estão na mesma rede do Dokploy

4. **Porta incorreta**
   - O Dokploy geralmente define automaticamente, mas verifique se `PORT` está configurado

5. **Erro: "tail: inotify cannot be used, reverting to polling: Too many open files"**
   - ✅ **RESOLVIDO**: File descriptor limits aumentados automaticamente para 65536
   - Se ainda enfrentar este erro, verifique se o Docker daemon do seu host tem limites apropriados
   - Consulte [TROUBLESHOOTING_502.md](TROUBLESHOOTING_502.md) para detalhes sobre configuração do host

## 🔐 Segurança

### Gerar SECRET_KEY_BASE

Nunca use a chave de exemplo! Gere uma nova:

```bash
# Opção 1: Localmente (se você tem Rails instalado)
rails secret

# Opção 2: Dentro de um container
docker run --rm ruby:3.4.4-alpine sh -c "gem install rails && rails secret"

# Opção 3: Usando OpenSSL
openssl rand -hex 64
```

### Gerar chaves de encriptação Active Record (para 2FA/MFA)

```bash
docker run --rm -it sua-imagem rails db:encryption:init
```

Configure as variáveis retornadas:
```bash
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=...
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=...
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=...
```

## 📊 Monitoramento

### Verificar workers Sidekiq

Para rodar workers em container separado:

```bash
# No Dokploy, crie um novo serviço "worker" usando a mesma imagem
# Comando de override: /usr/local/bin/docker-entrypoint.sh bundle exec sidekiq -C config/sidekiq.yml
```

Configure:
```bash
RUN_MIGRATIONS=false  # Não rodar migrations no worker
```

### Logs

Todos os logs são enviados para stdout/stderr e podem ser visualizados no painel do Dokploy.

## 🔄 Atualizações

Para atualizar a aplicação:

1. Faça push do código novo para o repositório
2. O Dokploy fará rebuild automático
3. As migrations serão executadas automaticamente
4. O novo container substituirá o antigo

## 📞 Suporte

- [Documentação oficial Chatwoot](https://www.chatwoot.com/docs)
- [Variáveis de ambiente](https://www.chatwoot.com/docs/self-hosted/configuration/environment-variables)
- [Troubleshooting geral](TROUBLESHOOTING_502.md)
