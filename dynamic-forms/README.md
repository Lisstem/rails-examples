# Example for Dynamic Forms
This is an example app for dynamic forms.
Including the following features:
* Loading dropdown items
* Search completion for text inputs
* Adding additional fields

This README is a guide on how i got to my solution.
The latest commit is the solution itself.

## Setup
Our setting is a simple book collection website, consisting of books, their authors and collections of those books.
To reduce the scope we will only add a controller for the collections.
The books and authors will be seeded in the library.

To start we set up a simple one to many relationship and one many to many relationship:
* One author can have multiple books and each book belongs to an author
* Each collection can have any number of books and each book can belong to any number of collections

The following commands generate the models, relationships and the controller.
```shell
bin/rails generate model author name:uniq
bin/rails generate model book name:index author:references
bin/rails generate scaffold collection name:index
bin/rails generate migration CreateJoinTableCollectionsBooks collections books
```
Afterwards update the database
```shell
bin/rails db:migrate
```

Next we add the relationships to the models:
* `has_many :books` in [app/models/author.rb](app/models/author.rb)
* `has_and_belongs_to_many :collections` in [app/models/book.rb](app/models/book.rb)
* `has_and_belongs_to_many :books` in [app/models/collection.rb](app/models/collection.rb)

To add some data for authors and their books run
```shell
bin/rails db:seed
```
The data is provided by [author_book_data.yaml](author_book_data.yaml).
You can add your favourite books if you want :)


## Loading dropdown items
In this section we make it possible to add books to our collections.
We will create a page for this purpose.
On this page we will have a dropdown for the authors and one for their books.
The goal of this section is to update the dropdown for the books whenever another author is selected.

First we add two methods to the [collections controller](app/controllers/collections_controller.rb) `add_book` and `insert_book`.
`add_book` will display the page to add the book to the collection and `insert_book` handles the post request from the former page.
To get the page to render we need to update the [routes](config/routes.rb) as well as to create the actual [view](app/views/collections/add_book.html.erb).
In the view we create a form which posts to the `insert_book_url` for our collection and which contains the dropdowns (collection_selects) for the authors and their books.
```erbruby
<%= form_with url: insert_book_collection_url(@collection) do |form| %>
  <% authors = Author.order(:name) %>
  # ...
    <%= form.collection_select :author_id, authors, :id, :name %>
  # ...
    <%= form.collection_select :book_id, authors.first.books, :id, :name, {} %>
  # ...
<% end %>
```
Notice that the contents of the second dropdown are set to the books of the first author. 
The first author is selected by default and this way the correct books are displayed.
