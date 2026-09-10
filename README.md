# 🛠️ Gestão de Equipamentos

> **Banco de dados do projeto “Quem Mexeu Nisso?”**

Um banco de dados desenvolvido para **registrar, rastrear e consultar alterações realizadas em objetos e equipamentos compartilhados por diferentes pessoas**.

---

## 🎯 Sobre o projeto

O projeto **Quem Mexeu Nisso?** surgiu a partir de um problema comum em ambientes onde várias pessoas utilizam os mesmos equipamentos:

> **Quando algo muda, quebra, desaparece ou é alterado, nem sempre é possível saber quem fez, quando fez ou o que aconteceu.**

O banco de dados foi estruturado para solucionar a parte de **rastreabilidade e histórico**, permitindo registrar:

- 👤 Quem realizou a ação
- 🛠️ O que foi feito
- 📦 Qual objeto foi alterado
- 📍 Onde estava e para onde foi
- 🔄 Qual era o estado anterior e o novo estado
- 📝 Motivo e observações
- 🕐 Data e hora da ocorrência

---

## 💻 Tecnologias

| Tecnologia | Utilização |
|---|---|
| 🐬 **MySQL** | Sistema de gerenciamento do banco |
| 🖥️ **MySQL Workbench** | Criação, modelagem e gerenciamento |
| 📄 **SQL** | Linguagem utilizada na implementação |

---

## 🗄️ Estrutura do banco

**Banco:** `GestaoEquipamentos`

O banco utiliza:

`PKs` • `FKs` • `Índices` • `Triggers` • `Stored Procedures`

### 📋 Tabelas

| Tabela | Função |
|---|---|
| 👤 `Usuario` | Armazena os usuários do sistema |
| 📍 `Localizacao` | Armazena os locais onde os objetos podem estar |
| 🏷️ `Categoria` | Organiza os objetos por categoria |
| 📦 `Objeto` | Armazena os equipamentos e objetos monitorados |
| 🔧 `Acao` | Define os tipos de ações realizadas |
| 📝 `Registro` | Guarda o histórico das ações realizadas |
| 📎 `Evidencia` | Relaciona arquivos a registros |
| 🔔 `Notificacao` | Armazena notificações e alertas |
| 🔎 `Auditoria` | Registra operações realizadas sobre os objetos |

---

## 🔗 Relacionamento entre as tabelas

A estrutura principal funciona da seguinte forma:

```text
                         ┌──────────────┐
                         │   Usuario    │
                         └──────┬───────┘
                                │
                                │ realiza
                                ▼
┌──────────────┐          ┌──────────────┐          ┌──────────────┐
│    Objeto    │◄─────────│   Registro   │─────────►│     Acao     │
└──────┬───────┘          └──────┬───────┘          └──────────────┘
       │                         │
       │                         ├──────────► Evidencia
       │                         │
       │                         └──────────► Notificacao
       │
       ├──────────► Categoria
       │
       └──────────► Localizacao

Objeto ───────────► Auditoria
```

### 🔑 Chaves

**Primary Key (PK)** identifica cada registro de forma única.

**Foreign Key (FK)** cria os relacionamentos entre as tabelas e ajuda a manter a integridade dos dados.

---

## 📦 Principais tabelas

### 👤 Usuario

Armazena as pessoas que utilizam o sistema.

Possui informações como:

- Nome
- E-mail
- Setor
- Tipo de usuário
- Status
- Data de cadastro

Tipos de usuário:

`administrador` • `responsavel` • `colaborador`

### 📍 Localizacao

Armazena os locais onde os objetos podem estar, como:

`Sala 1` • `Sala 2` • `Laboratório` • `Oficina` • `Almoxarifado`

### 📦 Objeto

Representa os equipamentos ou objetos acompanhados pelo sistema.

Exemplos:

`Impressora` • `Computador` • `Projetor` • `Máquina` • `Ferramenta`

Estados possíveis:

`normal` • `em_uso` • `alterado` • `danificado` • `em_manutencao` • `desaparecido` • `indisponivel`

### 📝 Registro

É o núcleo da rastreabilidade.

Cada registro pode informar:

```text
USUÁRIO
   ↓
AÇÃO
   ↓
OBJETO
   ↓
LOCAL ANTERIOR → LOCAL NOVO
   ↓
ESTADO ANTERIOR → ESTADO NOVO
   ↓
MOTIVO + OBSERVAÇÃO
   ↓
DATA/HORA
```

---

## ⚡ Triggers

O banco possui **4 triggers** para automatizar operações.

| Trigger | O que faz |
|---|---|
| `trg_objeto_insert` | Registra automaticamente o cadastro de um objeto na auditoria |
| `trg_objeto_update` | Registra automaticamente alterações realizadas no objeto |
| `trg_registro_insert` | Atualiza automaticamente o estado e a localização atual do objeto |
| `trg_registro_problema` | Cria notificações quando um objeto apresenta determinados problemas |

### 🚨 Exemplo

Se um registro informar:

```text
Estado novo: danificado
```

a trigger identifica o problema e cria automaticamente uma notificação para usuários ativos que sejam administradores ou responsáveis.

---

## ⚙️ Stored Procedures

O banco possui **7 Stored Procedures** para facilitar consultas e operações frequentes.

| Procedure | Função |
|---|---|
| `sp_registrar_acao` | Registra uma nova ação em um objeto |
| `sp_historico_objeto` | Consulta o histórico completo de um objeto |
| `sp_ultima_acao_objeto` | Descobre quem realizou a última ação |
| `sp_objetos_por_local` | Lista objetos de uma localização |
| `sp_objetos_com_problema` | Lista objetos que apresentam problemas |
| `sp_historico_usuario` | Consulta as ações realizadas por um usuário |
| `sp_buscar_objeto` | Pesquisa objetos por nome ou identificação |

### 🔎 A consulta principal do projeto

Para descobrir quem mexeu por último em determinado objeto:

```sql
CALL sp_ultima_acao_objeto(1);
```

O resultado pode informar:

```text
Objeto: Impressora 02
Último usuário: João
Última ação: Manutenção
Data: 10/09/2026
```

---

## 📊 Índices

Foram criados índices em campos utilizados frequentemente nas consultas, como:

- Nome do usuário
- Setor
- Nome do objeto
- Identificação
- Localização
- Estado
- Objeto relacionado ao registro
- Usuário relacionado ao registro
- Data do registro
- Notificações
- Data da auditoria

Os índices ajudam a **melhorar o desempenho das pesquisas**.

---

## 🔄 Exemplo de funcionamento

Imagine uma impressora compartilhada.

### 1. Situação inicial

```text
📦 Objeto: Impressora 02
📍 Localização: Sala 1
✅ Estado: Normal
```

### 2. João realiza uma manutenção

```text
👤 Usuário: João
🔧 Ação: Manutenção
📍 Local anterior: Sala 1
📍 Local novo: Sala 2
🔄 Estado anterior: Normal
⚠️ Estado novo: Em manutenção
📝 Motivo: Problema no cartucho
```

### 3. O banco registra a ação

A informação é armazenada na tabela `Registro`.

### 4. A trigger atualiza o objeto

O objeto passa automaticamente para:

```text
📍 Localização: Sala 2
⚠️ Estado: Em manutenção
```

### 5. O histórico pode ser consultado

```sql
CALL sp_historico_objeto(1);
```

E a última ação pode ser identificada com:

```sql
CALL sp_ultima_acao_objeto(1);
```

Assim, o banco consegue reconstruir o histórico do objeto.

---

## 🧩 O que cada recurso faz?

| Recurso | Responsabilidade |
|---|---|
| 🔑 **PK** | Identifica registros de forma única |
| 🔗 **FK** | Relaciona tabelas e mantém integridade referencial |
| ⚡ **Trigger** | Executa ações automaticamente |
| ⚙️ **Procedure** | Armazena operações e consultas reutilizáveis |
| 🚀 **Índice** | Melhora o desempenho das consultas |
| 📝 **Registro** | Guarda o histórico das ações |
| 🔎 **Auditoria** | Registra operações realizadas sobre os objetos |

---

## 📁 Arquivo do banco

O arquivo principal deste repositório é:

```text
GestaoEquipamentos.sql
```

Ele contém:

```text
✓ Criação do banco
✓ Criação das tabelas
✓ Primary Keys
✓ Foreign Keys
✓ Índices
✓ Triggers
✓ Stored Procedures
```

### ▶️ Como utilizar

1. Abra o **MySQL Workbench**.
2. Abra o arquivo `GestaoEquipamentos.sql`.
3. Execute o script.
4. O banco `GestaoEquipamentos` será criado com sua estrutura completa.

---

## 🎯 Objetivo final

O banco foi desenvolvido para dar suporte ao projeto:

# **Quem Mexeu Nisso?**

A ideia central é permitir que uma organização consiga responder, com base em registros:

> **Quem fez? O que fez? Quando fez? Onde estava? Para onde foi? E qual foi o resultado?**

Dessa forma, o banco fornece uma base de **rastreabilidade, histórico e controle de alterações** para objetos e equipamentos compartilhados.

---

## 👨‍💻 Autor

**Leonardo Gomes Ferreira**

Projeto acadêmico — Banco de Dados  
**Quem Mexeu Nisso?**

---

<div align="center">

**🛠️ Quem Mexeu Nisso? — Transformando alterações em histórico rastreável.**

</div>
