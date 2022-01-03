# Example for Dynamic Forms
This is an example app for dynamic forms.
Including the following features:
* Loading dropdown items
* Search completion for text inputs
* Adding additional fields

This README is a guide on how i got to my solution.
The latest commit is the solution itself.

## Loading dropdown items
The goal is to load the items of a dropdown field from the database when an item of another dropdown is selected.
Our setting is a simple book collection website, consisting of books, their authors and collections of those books.
To reduce the scope we will only add a controller for the collections.
The books and authors will be seeded in the library.

### Setup
To start we set up a simple one to many relationship and one many to many relationship:
* One author can have multiple books and each book belongs to an author
* Each collection can have any number of books and each book can belong to any number of collections

The following commands generate the models, relationships and the controller.
```
bin/rails generate model author name:uniq
bin/rails generate model book name:index author:references
bin/rails generate scaffold collection name:index
bin/rails generate migration CreateJoinTableCollectionsBooks collections books
```
Afterwards update the database
```
bin/rails db:migrate
```

Next we add the relationships to the models:
* `has_many :books` in [app/models/author.rb](app/models/author.rb)
* `has_and_belongs_to_many :collections` in [app/models/book.rb](app/models/book.rb)
* `has_and_belongs_to_many :books` in [app/models/collection.rb](app/models/collection.rb)
