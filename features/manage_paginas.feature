Feature: Manage Paginas
	In Order to manage static content
	As an admin
	I want to create and manage paginas
	
	Scenario: Paginas edit list
		Given I have paginas called Uma_Pagina, Outra_Pagina
		When I go to paginas index
		Then I should see "Uma_Pagina"
		And I should see "Outra_Pagina"