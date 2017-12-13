insert into users ("username","password") values ("admin","pbkdf2:sha256:50000$eGXLn1tI$3dce263bf46ac8315028ca42e6115883282d4ee6af8309d182f7cc3690aa6e62");

insert into settings ("name","value") values ("polling interval minutes", 2);
insert into settings ("name","value") values ("store temperature fahrenheit", 1);
insert into settings ("name","value") values ("hi-res data retention days", 7);
insert into settings ("name","value") values ("hourly-avg data retention days", 120);
insert into settings ("name","value") values ("rf tx pin", 11);
insert into settings ("name","value") values ("rf tx base code", 12066304);

insert into measurement_types("name") values ("temperature");
insert into measurement_types("name") values ("humidity");
insert into measurement_types("name") values ("soil-moisture");

insert into sensors("name", "tags", "address") values ("temp 1", "temperature dht22", 2);
insert into sensors("name", "tags", "address") values ("soil 1", "soil-moisture analog", 14);

