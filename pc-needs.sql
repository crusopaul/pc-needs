create table status (
    identifier varchar(60) not null,
    statusTypeName varchar(20) not null,
    amount int not null,
    primary key ( identifier, statusTypeName ),
    constraint check (amount between 0 and 100000)
);

create table effect (
    identifier varchar(60) not null,
    statusTypeName varchar(20) not null,
    `type` char(4) not null,
    amount int not null,
    created datetime not null,
    expires datetime,
    primary key ( identifier, statusTypeName, `type` ),
    constraint check (`type` in ('buff','enfe')),
    constraint check (amount between -100000 and 100000),
    constraint check (expires is null or expires > created)
);
