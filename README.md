# Gestão de Equipamentos --- Banco de Dados

## Sobre o projeto

Este repositório contém o banco de dados do projeto **Quem Mexeu
Nisso?**, desenvolvido para registrar e rastrear alterações realizadas
em objetos e equipamentos compartilhados por diferentes pessoas.

O objetivo é responder perguntas como: quem mexeu no equipamento, qual
ação foi realizada, quando aconteceu, onde estava antes e depois, qual
era o estado anterior e qual passou a ser o novo estado, além do motivo
e das observações registradas.

A proposta é aumentar a **rastreabilidade**, reduzir dúvidas, retrabalho
e conflitos e manter um histórico das movimentações e alterações
realizadas nos objetos.

## Tecnologias

-   MySQL
-   MySQL Workbench
-   SQL

## Estrutura do banco

O banco utilizado neste projeto é `GestaoEquipamentos`.

Ele foi estruturado utilizando **Primary Keys (PKs)**, **Foreign Keys
(FKs)**, índices, triggers e stored procedures.

### Tabelas

**Usuario:** armazena as pessoas que utilizam o sistema, incluindo nome,
e-mail, setor, tipo e status.

**Localizacao:** armazena os locais onde os objetos podem estar, como
salas, laboratórios, oficinas ou almoxarifados.

**Categoria:** organiza os objetos em categorias.

**Objeto:** representa os equipamentos ou objetos monitorados pelo
sistema. Armazena nome, identificação, categoria, localização, estado,
descrição e data de cadastro.

**Acao:** armazena os tipos de ações realizadas sobre os objetos, como
retirada, devolução, manutenção, alteração, transferência e troca.

**Registro:** é uma das principais tabelas do banco. Registra o
histórico das ações realizadas nos objetos, relacionando usuário, ação,
objeto, localização anterior e nova, estado anterior e novo, motivo,
observação e data.

**Evidencia:** permite associar arquivos a um registro, como fotos ou
documentos relacionados a uma ocorrência.

**Notificacao:** armazena notificações geradas pelo sistema para
informar usuários sobre alterações ou problemas.

**Auditoria:** registra operações realizadas sobre os objetos, mantendo
um histórico técnico das alterações.

## Relacionamentos

A estrutura principal pode ser representada assim:

``` text
Usuario
   |
   | realiza
   v
Registro <------ Acao
   |
   | relacionado a
   v
Objeto
   |
   +------ Categoria
   |
   +------ Localizacao

Registro
   |
   +------ Evidencia
   +------ Notificacao

Objeto
   |
   +------ Auditoria
```

As **Primary Keys (PKs)** identificam cada registro de forma única. As
**Foreign Keys (FKs)** conectam as tabelas e ajudam a manter a
integridade referencial.

## Índices

Foram criados índices para melhorar o desempenho das consultas em campos
utilizados com frequência, como nome de usuário, setor, nome e
identificação do objeto, localização, estado, objeto relacionado ao
registro, usuário, data do registro, notificações e auditoria.

## Triggers

### `trg_objeto_insert`

Executada depois da inclusão de um objeto e responsável por registrar
automaticamente a operação na tabela `Auditoria`.

### `trg_objeto_update`

Executada depois da alteração de um objeto e responsável por registrar a
alteração na `Auditoria`.

### `trg_registro_insert`

Executada quando uma nova ação é registrada. Atualiza automaticamente o
estado e a localização atual do objeto.

### `trg_registro_problema`

Verifica se o novo estado do objeto é **danificado, indisponível ou
desaparecido**. Quando isso acontece, cria automaticamente uma
notificação para usuários ativos que sejam administradores ou
responsáveis.

## Stored Procedures

### `sp_registrar_acao`

Registra uma nova ação realizada em um objeto e identifica
automaticamente o estado e a localização anteriores.

``` sql
CALL sp_registrar_acao(1, 2, 3, 2, 'danificado', 'Problema identificado', 'Equipamento apresentou falha');
```

### `sp_historico_objeto`

Consulta todo o histórico de ações realizadas em determinado objeto.

``` sql
CALL sp_historico_objeto(1);
```

### `sp_ultima_acao_objeto`

Mostra a última ação registrada para um objeto, incluindo o usuário
responsável.

``` sql
CALL sp_ultima_acao_objeto(1);
```

Essa procedure está diretamente relacionada à proposta do projeto, pois
ajuda a responder: **"Quem mexeu nisso por último?"**

### `sp_objetos_por_local`

Lista os objetos que estão em determinada localização.

``` sql
CALL sp_objetos_por_local(1);
```

### `sp_objetos_com_problema`

Lista objetos que estão danificados, em manutenção, desaparecidos ou
indisponíveis.

``` sql
CALL sp_objetos_com_problema();
```

### `sp_historico_usuario`

Mostra as ações realizadas por determinado usuário.

``` sql
CALL sp_historico_usuario(1);
```

### `sp_buscar_objeto`

Permite pesquisar objetos pelo nome ou pela identificação.

``` sql
CALL sp_buscar_objeto('Impressora');
```

## Exemplo de funcionamento

Imagine uma impressora compartilhada.

Inicialmente:

``` text
Objeto: Impressora 02
Localização: Sala 1
Estado: Normal
```

Um usuário registra uma manutenção:

``` text
Usuário: João
Ação: Manutenção
Local anterior: Sala 1
Local novo: Sala 2
Estado anterior: Normal
Estado novo: Em manutenção
Motivo: Problema no cartucho
```

O registro é armazenado na tabela `Registro`. A trigger
`trg_registro_insert` atualiza automaticamente o objeto para a nova
localização e o novo estado.

Depois, a procedure `sp_ultima_acao_objeto` pode informar quem realizou
a última ação.

Assim, o banco mantém uma linha do tempo do objeto e permite descobrir o
que aconteceu.

## Integridade e rastreabilidade

-   **PK:** identifica registros de forma única.
-   **FK:** cria relacionamentos e mantém a integridade referencial.
-   **Índice:** melhora o desempenho das consultas.
-   **Trigger:** executa ações automaticamente após determinados
    eventos.
-   **Stored Procedure:** centraliza operações e consultas frequentes.
-   **Registro:** mantém o histórico das ações realizadas.
-   **Auditoria:** mantém o histórico das operações realizadas sobre os
    objetos.

## Objetivo

O banco foi desenvolvido como base para o projeto **Quem Mexeu Nisso?**,
cujo foco é solucionar o problema da falta de rastreabilidade em
ambientes onde equipamentos e objetos são utilizados por várias pessoas.

A ideia é permitir que uma organização consiga reconstruir o histórico
de um objeto e descobrir:

**quem fez, o que fez, quando fez, onde estava, para onde foi e qual foi
o resultado da ação.**

## Arquivo do projeto

O arquivo `GestaoEquipamentos.sql` contém a implementação do banco,
incluindo:

-   Criação do banco
-   Criação das tabelas
-   Primary Keys
-   Foreign Keys
-   Índices
-   Triggers
-   Stored Procedures

Para utilizar o banco, abra o arquivo `GestaoEquipamentos.sql` no
**MySQL Workbench** e execute o script.

## Autor

**Leonardo Gomes Ferreira**

Projeto acadêmico --- Banco de Dados / Projeto **Quem Mexeu Nisso?**
