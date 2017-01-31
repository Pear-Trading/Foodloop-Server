CREATE TABLE Organisations (
  OrganisationalId INTEGER PRIMARY KEY UNIQUE NOT NULL,
  Name TEXT NOT NULL,
  FullAddress TEXT NOT NULL,
  PostCode TEXT NOT NULL
);

CREATE TABLE AgeRanges (
  AgeRangeId INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
  AgeRangeString TEXT NOT NULL UNIQUE
);

INSERT INTO AgeRanges (AgeRangeString) VALUES ('20-35');
INSERT INTO AgeRanges (AgeRangeString) VALUES ('35-50');
INSERT INTO AgeRanges (AgeRangeString) VALUES ('50+');

CREATE TABLE Customers (
  CustomerId INTEGER PRIMARY KEY UNIQUE NOT NULL,
  UserName TEXT NOT NULL UNIQUE,
  AgeRange_FK INTEGER NOT NULL,
  PostCode TEXT NOT NULL,
  FOREIGN KEY (AgeRange_FK) REFERENCES AgeRanges (AgeRangeId)
);

CREATE TABLE Users (
  UserId INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
  CustomerId_FK INTEGER UNIQUE,
  OrganisationalId_FK INTEGER UNIQUE,
  Email TEXT NOT NULL UNIQUE,
  JoinDate INTEGER NOT NULL,
  HashedPassword TEXT NOT NULL,
  FOREIGN KEY (CustomerId_FK) REFERENCES Customer (CustomerId),
  FOREIGN KEY (OrganisationalId_FK) REFERENCES Organisation (OrganisationalId),
  CHECK ((CustomerId_FK NOTNULL AND OrganisationalId_FK ISNULL) OR (CustomerId_FK ISNULL AND OrganisationalId_FK NOTNULL))
);

CREATE TABLE Transactions (
  TransactionId INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
  BuyerUserId_FK INTEGER NOT NULL,
  SellerOrganisationId_FK INTEGER NOT NULL,
  Date TEXT NOT NULL,
  ValueMicroCurrency INTEGER NOT NULL,
  ProofImage TEXT NOT NULL UNIQUE,
  FOREIGN KEY (BuyerUserId_FK) REFERENCES User (UserId),
  FOREIGN KEY (SellerOrganisationId_FK) REFERENCES Organisation (OrganisationalId),
  CHECK ((BuyerUserId_FK IN (SELECT UserId FROM Users WHERE UserId = BuyerUserId_FK AND CustomerId_FK IS NOT NULL)) OR (BuyerUserId_FK IN (SELECT UserId FROM Users WHERE UserId = BuyerUserId_FK AND OrganisationalId_FK IS NOT NULL AND OrganisationalId_FK IS NOT SellerOrganisationId_FK)))
);

CREATE TABLE Tokens (
  TokenId INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
  TokenName TEXT UNIQUE NOT NULL,
  Used INTEGER NOT NULL DEFAULT 0
);
