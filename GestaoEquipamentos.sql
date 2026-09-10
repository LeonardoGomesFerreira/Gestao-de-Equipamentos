drop database if exists  GestaoEquipamentos;
create database GestaoEquipamentos;
use GestaoEquipamentos;

create table Usuario(
    Id_usuario int not null auto_increment primary key,
    Nome varchar(150) not null,
    Email varchar(150) not null unique,
    Setor varchar(100) not null,
    Tipo enum('administrador','responsavel','colaborador') not null default 'colaborador',
    Status enum('ativo','inativo') not null default 'ativo',
    Data_cadastro datetime not null default current_timestamp
) engine=InnoDB;

create table Localizacao(
    Id_localizacao int not null auto_increment primary key,
    Nome varchar(150) not null,
    Descricao varchar(300),
    Status enum('ativo','inativo') not null default 'ativo'
) engine=InnoDB;

create table Categoria(
    Id_categoria int not null auto_increment primary key,
    Nome varchar(100) not null unique,
    Descricao varchar(300),
    Status enum('ativo','inativo') not null default 'ativo'
) engine=InnoDB;

create table Objeto(
    Id_objeto int not null auto_increment primary key,
    Id_categoria int not null,
    Id_localizacao int not null,
    Nome varchar(150) not null,
    Identificacao varchar(100) unique,
    Estado enum('normal','em_uso','alterado','danificado','em_manutencao','desaparecido','indisponivel') not null default 'normal',
    Descricao text,
    Data_cadastro datetime not null default current_timestamp,
    constraint Fk_objeto_categoria foreign key (Id_categoria) references Categoria(Id_categoria),
    constraint Fk_objeto_localizacao foreign key (Id_localizacao) references Localizacao(Id_localizacao)
) engine=InnoDB;

create table Acao(
    Id_acao int not null auto_increment primary key,
    Nome varchar(100) not null unique,
    Descricao varchar(300),
    Status enum('ativo','inativo') not null default 'ativo'
) engine=InnoDB;

create table Registro(
    Id_registro int not null auto_increment primary key,
    Id_objeto int not null,
    Id_usuario int not null,
    Id_acao int not null,
    Id_local_anterior int,
    Id_local_novo int,
    Estado_anterior varchar(50),
    Estado_novo varchar(50),
    Motivo varchar(500),
    Observacao varchar(500),
    Data_registro datetime not null default current_timestamp,
    constraint Fk_registro_objeto foreign key (Id_objeto) references Objeto(Id_objeto),
    constraint Fk_registro_usuario foreign key (Id_usuario) references Usuario(Id_usuario),
    constraint Fk_registro_acao foreign key (Id_acao) references Acao(Id_acao),
    constraint Fk_registro_local_anterior foreign key (Id_local_anterior) references Localizacao(Id_localizacao),
    constraint Fk_registro_local_novo foreign key (Id_local_novo) references Localizacao(Id_localizacao)
) engine=InnoDB;

create table Evidencia(
    Id_evidencia int not null auto_increment primary key,
    Id_registro int not null,
    Nome_arquivo varchar(255) not null,
    Tipo_arquivo varchar(100),
    Caminho_arquivo varchar(500),
    Data_upload datetime not null default current_timestamp,
    constraint Fk_evidencia_registro foreign key (Id_registro) references Registro(Id_registro) on delete cascade
) engine=InnoDB;

create table Notificacao(
    Id_notificacao int not null auto_increment primary key,
    Id_usuario int not null,
    Id_registro int,
    Titulo varchar(200) not null,
    Mensagem varchar(500) not null,
    Tipo enum('informacao','alteracao','problema','alerta') not null default 'informacao',
    Lida boolean not null default false,
    Data_notificacao datetime not null default current_timestamp,
    constraint Fk_notificacao_usuario foreign key (Id_usuario) references Usuario(Id_usuario),
    constraint Fk_notificacao_registro foreign key (Id_registro) references Registro(Id_registro)
) engine=InnoDB;

create table Auditoria(
    Id_auditoria int not null auto_increment primary key,
    Id_objeto int,
    Id_usuario int,
    Operacao enum('insert','update','delete') not null,
    Descricao varchar(1000) not null,
    Data_operacao datetime not null default current_timestamp,
    constraint Fk_auditoria_objeto foreign key (Id_objeto) references Objeto(Id_objeto),
    constraint Fk_auditoria_usuario foreign key (Id_usuario) references Usuario(Id_usuario)
) engine=InnoDB;

create index idx_usuario_nome on Usuario(Nome);
create index idx_usuario_setor on Usuario(Setor);
create index idx_objeto_nome on Objeto(Nome);
create index idx_objeto_identificacao on Objeto(Identificacao);
create index idx_objeto_localizacao on Objeto(Id_localizacao);
create index idx_objeto_estado on Objeto(Estado);
create index idx_registro_objeto on Registro(Id_objeto);
create index idx_registro_usuario on Registro(Id_usuario);
create index idx_registro_data on Registro(Data_registro);
create index idx_notificacao_usuario on Notificacao(Id_usuario);
create index idx_notificacao_lida on Notificacao(Lida);
create index idx_auditoria_data on Auditoria(Data_operacao);

delimiter //

create trigger trg_objeto_insert
after insert on Objeto
for each row
begin
    insert into Auditoria(Id_objeto, Operacao, Descricao)
    values(
        NEW.Id_objeto,
        'insert',
        concat('Objeto cadastrado: ', NEW.Nome,
               ' | Identificacao: ', coalesce(NEW.Identificacao, 'Nao informada'))
    );
end//

create trigger trg_objeto_update
after update on Objeto
for each row
begin
    insert into Auditoria(Id_objeto, Operacao, Descricao)
    values(
        NEW.Id_objeto,
        'update',
        concat('Objeto alterado | Estado: ', OLD.Estado,
               ' -> ', NEW.Estado,
               ' | Localizacao alterada')
    );
end//

create trigger trg_registro_insert
after insert on Registro
for each row
begin
    update Objeto
    set Estado = coalesce(NEW.Estado_novo, Estado),
        Id_localizacao = coalesce(NEW.Id_local_novo, Id_localizacao)
    where Id_objeto = NEW.Id_objeto;
end//

create trigger trg_registro_problema
after insert on Registro
for each row
begin
    if NEW.Estado_novo in ('danificado','indisponivel','desaparecido') then
        insert into Notificacao(Id_usuario, Id_registro, Titulo, Mensagem, Tipo)
        select
            u.Id_usuario,
            NEW.Id_registro,
            'Problema identificado',
            concat('O objeto de ID ', NEW.Id_objeto, ' foi registrado como ', NEW.Estado_novo),
            'problema'
        from Usuario u
        where u.Status = 'ativo'
        and u.Tipo in ('administrador','responsavel');
    end if;
end//

create procedure sp_registrar_acao(
    in p_id_objeto int,
    in p_id_usuario int,
    in p_id_acao int,
    in p_id_local_novo int,
    in p_estado_novo varchar(50),
    in p_motivo varchar(500),
    in p_observacao varchar(500)
)
begin
    declare v_local_anterior int;
    declare v_estado_anterior varchar(50);

    select Id_localizacao, Estado
    into v_local_anterior, v_estado_anterior
    from Objeto
    where Id_objeto = p_id_objeto;

    insert into Registro(
        Id_objeto, Id_usuario, Id_acao,
        Id_local_anterior, Id_local_novo,
        Estado_anterior, Estado_novo,
        Motivo, Observacao
    )
    values(
        p_id_objeto, p_id_usuario, p_id_acao,
        v_local_anterior, p_id_local_novo,
        v_estado_anterior, p_estado_novo,
        p_motivo, p_observacao
    );
end//

create procedure sp_historico_objeto(
    in p_id_objeto int
)
begin
    select
        r.Id_registro,
        o.Nome as Objeto,
        o.Identificacao,
        u.Nome as Usuario,
        u.Setor,
        a.Nome as Acao,
        la.Nome as Local_anterior,
        ln.Nome as Local_novo,
        r.Estado_anterior,
        r.Estado_novo,
        r.Motivo,
        r.Observacao,
        r.Data_registro
    from Registro r
    inner join Objeto o on o.Id_objeto = r.Id_objeto
    inner join Usuario u on u.Id_usuario = r.Id_usuario
    inner join Acao a on a.Id_acao = r.Id_acao
    left join Localizacao la on la.Id_localizacao = r.Id_local_anterior
    left join Localizacao ln on ln.Id_localizacao = r.Id_local_novo
    where r.Id_objeto = p_id_objeto
    order by r.Data_registro desc;
end//

create procedure sp_ultima_acao_objeto(
    in p_id_objeto int
)
begin
    select
        o.Nome as Objeto,
        o.Identificacao,
        u.Nome as Ultimo_usuario,
        u.Setor,
        a.Nome as Ultima_acao,
        r.Motivo,
        r.Observacao,
        r.Data_registro
    from Registro r
    inner join Objeto o on o.Id_objeto = r.Id_objeto
    inner join Usuario u on u.Id_usuario = r.Id_usuario
    inner join Acao a on a.Id_acao = r.Id_acao
    where r.Id_objeto = p_id_objeto
    order by r.Data_registro desc
    limit 1;
end//

create procedure sp_objetos_por_local(
    in p_id_localizacao int
)
begin
    select
        o.Id_objeto,
        o.Nome,
        o.Identificacao,
        c.Nome as Categoria,
        l.Nome as Localizacao,
        o.Estado
    from Objeto o
    inner join Categoria c on c.Id_categoria = o.Id_categoria
    inner join Localizacao l on l.Id_localizacao = o.Id_localizacao
    where o.Id_localizacao = p_id_localizacao
    order by o.Nome;
end//

create procedure sp_objetos_com_problema()
begin
    select
        o.Id_objeto,
        o.Nome,
        o.Identificacao,
        c.Nome as Categoria,
        l.Nome as Localizacao,
        o.Estado
    from Objeto o
    inner join Categoria c on c.Id_categoria = o.Id_categoria
    inner join Localizacao l on l.Id_localizacao = o.Id_localizacao
    where o.Estado in ('danificado','em_manutencao','desaparecido','indisponivel')
    order by o.Nome;
end//

create procedure sp_historico_usuario(
    in p_id_usuario int
)
begin
    select
        r.Id_registro,
        u.Nome as Usuario,
        o.Nome as Objeto,
        a.Nome as Acao,
        r.Motivo,
        r.Observacao,
        r.Data_registro
    from Registro r
    inner join Usuario u on u.Id_usuario = r.Id_usuario
    inner join Objeto o on o.Id_objeto = r.Id_objeto
    inner join Acao a on a.Id_acao = r.Id_acao
    where r.Id_usuario = p_id_usuario
    order by r.Data_registro desc;
end//

create procedure sp_buscar_objeto(
    in p_nome varchar(150)
)
begin
    select
        o.Id_objeto,
        o.Nome,
        o.Identificacao,
        c.Nome as Categoria,
        l.Nome as Localizacao,
        o.Estado,
        o.Descricao
    from Objeto o
    inner join Categoria c on c.Id_categoria = o.Id_categoria
    inner join Localizacao l on l.Id_localizacao = o.Id_localizacao
    where o.Nome like concat('%', p_nome, '%')
       or o.Identificacao like concat('%', p_nome, '%')
    order by o.Nome;
end//

delimiter ;
