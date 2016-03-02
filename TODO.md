## TODO:

#### Steps:

  - Setup Database SQL
	- Setup Init DB Script
	- Setup Test Data Script
	- Setup Account & Users
	- Setup Auth






### Notes:

/		GET
/:product		POST, GET (materials, items, printers)
	/:id	GET, PUT, DELETE
	/:id/attributes	POST, GET


/attributes		POST, GET
	/:id	GET, PUT, DELETE
	/:id/relations	POST, GET (used only for indexing cross attributes)


/accounts		POST   (create new account)
	/:id	GET, PUT, DELETE  (single account)
	/auth	POST   (login/logout/api key)
	/settings	GET, PUT, DELETE    (admin account settings/subscription updates)


/users		POST, GET(Admin)
	/:id	GET, PUT, DELETE(Admin)

/stats
	/attributes	POST, GET
	/users	POST, GET
	/:products	POST, GET


Feature
  Material-
  Printer-
  Item-
  Account-
  Users-

Attributes
  Brand-
  Color-
  price points-
  nozzles-
  volume-
  types-
  base-
  weight-
