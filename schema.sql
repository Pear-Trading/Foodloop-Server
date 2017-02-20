CREATE TABLE Organisations (
  OrganisationalId INTEGER PRIMARY KEY UNIQUE NOT NULL,
  Name TEXT NOT NULL COLLATE nocase,
  FullAddress TEXT NOT NULL COLLATE nocase,
  PostCode TEXT NOT NULL COLLATE nocase
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
  FOREIGN KEY (CustomerId_FK) REFERENCES Customers (CustomerId),
  FOREIGN KEY (OrganisationalId_FK) REFERENCES Organisations (OrganisationalId),
  CHECK ((CustomerId_FK NOTNULL AND OrganisationalId_FK ISNULL) OR (CustomerId_FK ISNULL AND OrganisationalId_FK NOTNULL))
);

CREATE TABLE Transactions (
  TransactionId INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
  BuyerUserId_FK INTEGER NOT NULL,
  SellerOrganisationId_FK INTEGER NOT NULL,
  ValueMicroCurrency INTEGER NOT NULL,
  ProofImage TEXT NOT NULL UNIQUE,
  TimeDateSubmitted INTEGER NOT NULL,
  FOREIGN KEY (BuyerUserId_FK) REFERENCES Users (UserId),
  FOREIGN KEY (SellerOrganisationId_FK) REFERENCES Organisations (OrganisationalId)
);

CREATE TABLE AccountTokens (
  AccountTokenId INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
  AccountTokenName TEXT UNIQUE NOT NULL,
  Used INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE SessionTokens (
  SessionTokenId INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
  SessionTokenName TEXT UNIQUE NOT NULL,
  UserIdAssignedTo_FK INTEGER NOT NULL,
  ExpireDateTime INTEGER NOT NULL,
  FOREIGN KEY (UserIdAssignedTo_FK) REFERENCES Users (UserId)
);

CREATE TABLE PendingOrganisations (
  PendingOrganisationId INTEGER PRIMARY KEY UNIQUE NOT NULL,
  UserSubmitted_FK INTEGER NOT NULL,
  TimeDateSubmitted INTEGER NOT NULL,
  Name TEXT NOT NULL COLLATE nocase,
  StreetName TEXT COLLATE nocase, 
  Town TEXT COLLATE nocase, 
  Postcode TEXT COLLATE nocase,
  FOREIGN KEY (UserSubmitted_FK) REFERENCES Users (UserId)
);

CREATE TABLE PendingTransactions (
  PendingTransactionId INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
  BuyerUserId_FK INTEGER NOT NULL,
  PendingSellerOrganisationId_FK INTEGER NOT NULL,
  ValueMicroCurrency INTEGER NOT NULL,
  ProofImage TEXT NOT NULL UNIQUE,
  TimeDateSubmitted INTEGER NOT NULL,
  FOREIGN KEY (BuyerUserId_FK) REFERENCES Users (UserId),
  FOREIGN KEY (PendingSellerOrganisationId_FK) REFERENCES PendingOrganisations (PendingOrganisationId)
);
